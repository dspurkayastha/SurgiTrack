// SecureHasher.swift
// SurgiTrack
// Cryptographically secure hashing for passwords and PINs
// Created on 26/12/2025

import Foundation
import CryptoKit

/// Provides secure cryptographic hashing for sensitive data like passwords and PINs.
/// Uses SHA-256 with salt for secure storage.
struct SecureHasher {

    // MARK: - Configuration

    /// The number of iterations for key derivation (increase for stronger security)
    private static let iterations = 100_000

    /// Salt length in bytes
    private static let saltLength = 32

    // MARK: - Public Methods

    /// Generates a cryptographically secure random salt
    /// - Returns: A hex-encoded salt string
    static func generateSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: saltLength)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard status == errSecSuccess else {
            // Fallback to UUID-based salt if SecRandomCopyBytes fails
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }

        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// Hashes a password using SHA-256 with the provided salt
    /// - Parameters:
    ///   - password: The plaintext password to hash
    ///   - salt: The salt to use for hashing
    /// - Returns: A hex-encoded hash string
    static func hashPassword(_ password: String, salt: String) -> String {
        let saltedPassword = password + salt
        guard let data = saltedPassword.data(using: .utf8) else {
            return ""
        }

        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Hashes a PIN using SHA-256 with the provided salt
    /// - Parameters:
    ///   - pin: The plaintext PIN to hash
    ///   - salt: The salt to use for hashing
    /// - Returns: A hex-encoded hash string
    static func hashPIN(_ pin: String, salt: String) -> String {
        return hashPassword(pin, salt: salt)
    }

    /// Verifies a password against a stored hash
    /// - Parameters:
    ///   - password: The plaintext password to verify
    ///   - hash: The stored hash to compare against
    ///   - salt: The salt that was used for hashing
    /// - Returns: true if the password matches, false otherwise
    static func verifyPassword(_ password: String, againstHash hash: String, salt: String) -> Bool {
        let computedHash = hashPassword(password, salt: salt)
        return constantTimeCompare(computedHash, hash)
    }

    /// Verifies a PIN against a stored hash
    /// - Parameters:
    ///   - pin: The plaintext PIN to verify
    ///   - hash: The stored hash to compare against
    ///   - salt: The salt that was used for hashing
    /// - Returns: true if the PIN matches, false otherwise
    static func verifyPIN(_ pin: String, againstHash hash: String, salt: String) -> Bool {
        return verifyPassword(pin, againstHash: hash, salt: salt)
    }

    /// Creates a secure hash with a new salt (convenience method)
    /// - Parameter password: The plaintext password to hash
    /// - Returns: A tuple containing (hash, salt)
    static func createSecureHash(for password: String) -> (hash: String, salt: String) {
        let salt = generateSalt()
        let hash = hashPassword(password, salt: salt)
        return (hash, salt)
    }

    /// Derives a key using HKDF (HMAC-based Key Derivation Function)
    /// - Parameters:
    ///   - password: The password to derive a key from
    ///   - salt: The salt data
    ///   - info: Optional context/application-specific info
    /// - Returns: A derived symmetric key
    static func deriveKey(from password: String, salt: Data, info: Data = Data()) -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            return SymmetricKey(size: .bits256)
        }

        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            info: info,
            outputByteCount: 32
        )

        return key
    }

    /// Generates a secure random token for session IDs or similar purposes
    /// - Parameter length: The length of the token in bytes (default 32)
    /// - Returns: A hex-encoded random token
    static func generateSecureToken(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard status == errSecSuccess else {
            // Fallback
            return UUID().uuidString + UUID().uuidString
        }

        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private Methods

    /// Performs a constant-time comparison to prevent timing attacks
    /// - Parameters:
    ///   - a: First string to compare
    ///   - b: Second string to compare
    /// - Returns: true if strings are equal, false otherwise
    private static func constantTimeCompare(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count else {
            return false
        }

        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)

        var result: UInt8 = 0
        for i in 0..<aBytes.count {
            result |= aBytes[i] ^ bBytes[i]
        }

        return result == 0
    }
}

// MARK: - Data Encryption Extension

extension SecureHasher {

    /// Encrypts data using AES-GCM with a derived key
    /// - Parameters:
    ///   - data: The data to encrypt
    ///   - key: The symmetric key to use for encryption
    /// - Returns: The encrypted data (nonce + ciphertext + tag), or nil on failure
    static func encrypt(_ data: Data, using key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            return nil
        }
    }

    /// Decrypts data using AES-GCM with a derived key
    /// - Parameters:
    ///   - encryptedData: The encrypted data (nonce + ciphertext + tag)
    ///   - key: The symmetric key to use for decryption
    /// - Returns: The decrypted data, or nil on failure
    static func decrypt(_ encryptedData: Data, using key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            return nil
        }
    }
}
