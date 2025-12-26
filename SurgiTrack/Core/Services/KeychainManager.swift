// KeychainManager.swift
// SurgiTrack
// Secure credential storage using iOS Keychain
// Created on 26/12/2025

import Foundation
import Security

/// A manager for securely storing and retrieving sensitive data using the iOS Keychain.
/// This replaces UserDefaults for all sensitive authentication data.
final class KeychainManager {

    // MARK: - Singleton

    static let shared = KeychainManager()

    private init() {}

    // MARK: - Constants

    private let service = "com.surgitrack.app"

    enum KeychainKey: String {
        case pinHash = "surgitrack.pin.hash"
        case pinSalt = "surgitrack.pin.salt"
        case credentialsEmail = "surgitrack.credentials.email"
        case credentialsPasswordHash = "surgitrack.credentials.hash"
        case credentialsSalt = "surgitrack.credentials.salt"
        case authToken = "surgitrack.auth.token"
        case refreshToken = "surgitrack.auth.refresh"
        case biometricEnabled = "surgitrack.biometric.enabled"
        case lastAuthMethod = "surgitrack.auth.method"
        case sessionExpiry = "surgitrack.session.expiry"
    }

    // MARK: - Keychain Errors

    enum KeychainError: LocalizedError {
        case unableToStore
        case unableToRetrieve
        case unableToDelete
        case unexpectedData
        case duplicateItem
        case itemNotFound
        case authFailed
        case unknown(OSStatus)

        var errorDescription: String? {
            switch self {
            case .unableToStore:
                return "Unable to store item in Keychain"
            case .unableToRetrieve:
                return "Unable to retrieve item from Keychain"
            case .unableToDelete:
                return "Unable to delete item from Keychain"
            case .unexpectedData:
                return "Unexpected data format in Keychain"
            case .duplicateItem:
                return "Item already exists in Keychain"
            case .itemNotFound:
                return "Item not found in Keychain"
            case .authFailed:
                return "Authentication failed for Keychain access"
            case .unknown(let status):
                return "Unknown Keychain error: \(status)"
            }
        }
    }

    // MARK: - Public Methods

    /// Stores a string value securely in the Keychain
    /// - Parameters:
    ///   - value: The string value to store
    ///   - key: The key to associate with the value
    /// - Throws: KeychainError if storage fails
    func store(_ value: String, for key: KeychainKey) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        try store(data, for: key)
    }

    /// Stores data securely in the Keychain
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to associate with the data
    /// - Throws: KeychainError if storage fails
    func store(_ data: Data, for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // First try to delete any existing item
        SecItemDelete(query as CFDictionary)

        // Then add the new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw mapError(status)
        }
    }

    /// Retrieves a string value from the Keychain
    /// - Parameter key: The key associated with the value
    /// - Returns: The stored string value, or nil if not found
    func retrieve(key: KeychainKey) -> String? {
        guard let data = retrieveData(key: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Retrieves data from the Keychain
    /// - Parameter key: The key associated with the data
    /// - Returns: The stored data, or nil if not found
    func retrieveData(key: KeychainKey) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    /// Deletes a value from the Keychain
    /// - Parameter key: The key associated with the value to delete
    /// - Throws: KeychainError if deletion fails
    func delete(key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw mapError(status)
        }
    }

    /// Checks if a key exists in the Keychain
    /// - Parameter key: The key to check
    /// - Returns: true if the key exists, false otherwise
    func exists(key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Clears all SurgiTrack items from the Keychain
    /// - Throws: KeychainError if clearing fails
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw mapError(status)
        }
    }

    // MARK: - Convenience Methods for Authentication

    /// Stores PIN credentials securely
    /// - Parameters:
    ///   - hash: The hashed PIN
    ///   - salt: The salt used for hashing
    func storePIN(hash: String, salt: String) throws {
        try store(hash, for: .pinHash)
        try store(salt, for: .pinSalt)
    }

    /// Retrieves stored PIN hash and salt
    /// - Returns: Tuple of (hash, salt) or nil if not stored
    func retrievePIN() -> (hash: String, salt: String)? {
        guard let hash = retrieve(key: .pinHash),
              let salt = retrieve(key: .pinSalt) else {
            return nil
        }
        return (hash, salt)
    }

    /// Stores user credentials securely
    /// - Parameters:
    ///   - email: The user's email
    ///   - passwordHash: The hashed password
    ///   - salt: The salt used for hashing
    func storeCredentials(email: String, passwordHash: String, salt: String) throws {
        try store(email, for: .credentialsEmail)
        try store(passwordHash, for: .credentialsPasswordHash)
        try store(salt, for: .credentialsSalt)
    }

    /// Retrieves stored credentials
    /// - Returns: Tuple of (email, passwordHash, salt) or nil if not stored
    func retrieveCredentials() -> (email: String, passwordHash: String, salt: String)? {
        guard let email = retrieve(key: .credentialsEmail),
              let hash = retrieve(key: .credentialsPasswordHash),
              let salt = retrieve(key: .credentialsSalt) else {
            return nil
        }
        return (email, hash, salt)
    }

    /// Clears all stored credentials
    func clearCredentials() throws {
        try delete(key: .credentialsEmail)
        try delete(key: .credentialsPasswordHash)
        try delete(key: .credentialsSalt)
        try delete(key: .pinHash)
        try delete(key: .pinSalt)
    }

    /// Stores auth tokens securely
    /// - Parameters:
    ///   - authToken: The authentication token
    ///   - refreshToken: The refresh token (optional)
    func storeTokens(authToken: String, refreshToken: String? = nil) throws {
        try store(authToken, for: .authToken)
        if let refresh = refreshToken {
            try store(refresh, for: .refreshToken)
        }
    }

    /// Retrieves stored auth token
    /// - Returns: The auth token or nil if not stored
    func retrieveAuthToken() -> String? {
        return retrieve(key: .authToken)
    }

    /// Retrieves stored refresh token
    /// - Returns: The refresh token or nil if not stored
    func retrieveRefreshToken() -> String? {
        return retrieve(key: .refreshToken)
    }

    /// Clears all auth tokens
    func clearTokens() throws {
        try delete(key: .authToken)
        try delete(key: .refreshToken)
    }

    /// Stores biometric enabled preference
    func setBiometricEnabled(_ enabled: Bool) throws {
        try store(enabled ? "true" : "false", for: .biometricEnabled)
    }

    /// Retrieves biometric enabled preference
    func isBiometricEnabled() -> Bool {
        return retrieve(key: .biometricEnabled) == "true"
    }

    /// Stores the last used authentication method
    func setLastAuthMethod(_ method: String) throws {
        try store(method, for: .lastAuthMethod)
    }

    /// Retrieves the last used authentication method
    func getLastAuthMethod() -> String? {
        return retrieve(key: .lastAuthMethod)
    }

    /// Stores session expiry time
    func setSessionExpiry(_ date: Date) throws {
        let timestamp = String(date.timeIntervalSince1970)
        try store(timestamp, for: .sessionExpiry)
    }

    /// Retrieves session expiry time
    func getSessionExpiry() -> Date? {
        guard let timestamp = retrieve(key: .sessionExpiry),
              let interval = Double(timestamp) else {
            return nil
        }
        return Date(timeIntervalSince1970: interval)
    }

    /// Checks if the current session is valid (not expired)
    func isSessionValid() -> Bool {
        guard let expiry = getSessionExpiry() else {
            return false
        }
        return Date() < expiry
    }

    // MARK: - Private Methods

    private func mapError(_ status: OSStatus) -> KeychainError {
        switch status {
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecItemNotFound:
            return .itemNotFound
        case errSecAuthFailed:
            return .authFailed
        case errSecSuccess:
            return .unknown(status) // Should not happen
        default:
            return .unknown(status)
        }
    }
}
