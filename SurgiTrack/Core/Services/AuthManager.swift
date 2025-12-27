// AuthManager.swift
// SurgiTrack
// Secure authentication manager
// Created on 06/03/2025
// Updated on 26/12/2025 - Added secure hashing, Keychain storage, and audit logging

import Foundation
import LocalAuthentication
import SwiftUI
import Clerk

/// Manages all authentication flows for SurgiTrack.
/// Uses secure storage (Keychain) and cryptographic hashing for credentials.
@MainActor
class AuthManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var biometricsAvailable = false
    @Published var biometricType: BiometricType = .none
    @Published var authError: AppError?
    @Published var isLockedOut = false
    @Published var lockoutRemainingSeconds: Int = 0

    /// Shows when session is about to expire
    @Published var showSessionWarning = false
    /// Remaining seconds until session expires (shown in warning)
    @Published var sessionWarningSeconds: Int = 0

    // MARK: - Private Properties

    private let keychain = KeychainManager.shared
    private var loginAttempts = 0
    private var lockoutEndTime: Date?
    private var lockoutTimer: Timer?
    private var sessionTimer: Timer?
    private var lastActivityTime = Date()

    // User defaults keys (for non-sensitive preferences only)
    private let rememberMeKey = "rememberMe"

    // Saved username (non-sensitive, can stay in AppStorage)
    @AppStorage("username") private var savedUsername = ""

    // MARK: - Types

    enum BiometricType {
        case none
        case faceID
        case touchID

        var displayName: String {
            switch self {
            case .none: return "None"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            }
        }
    }

    enum AuthMethod: String, Codable {
        case none
        case pin
        case credentials
        case biometric
    }

    // MARK: - Initialization

    init() {
        checkBiometricAvailability()
        loadLockoutState()
        attemptAutoLogin()
        setupSessionTimeout()
    }

    deinit {
        lockoutTimer?.invalidate()
        sessionTimer?.invalidate()
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authError = .biometricNotAvailable
            Logger.auth("Biometric authentication not available", level: .warning)
            completion(false)
            return
        }

        let reason = "Log into your SurgiTrack account"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            Task { @MainActor in
                guard let self = self else { return }

                if success {
                    self.handleSuccessfulAuth(method: .biometric)
                    Logger.auth("Biometric authentication successful")
                    AuditLogger.shared.logLogin(userId: self.savedUsername, userName: nil, outcome: .success)
                    completion(true)
                } else {
                    self.authError = .biometricFailed
                    Logger.auth("Biometric authentication failed", level: .warning)
                    AuditLogger.shared.logLogin(userId: self.savedUsername, userName: nil, outcome: .failure, errorMessage: error?.localizedDescription)
                    completion(false)
                }
            }
        }
    }

    // MARK: - PIN Authentication

    func authenticateWithPIN(_ pin: String) -> Bool {
        // Validate PIN length
        guard pin.count == AppConfiguration.Security.pinLength else {
            authError = .validationFailed(field: "PIN", message: "Please enter a \(AppConfiguration.Security.pinLength)-digit PIN")
            return false
        }

        // Check lockout
        guard !checkLockout() else {
            return false
        }

        // Retrieve stored PIN from Keychain
        guard let storedCredentials = keychain.retrievePIN() else {
            authError = .pinNotSet
            Logger.auth("No PIN set up", level: .warning)
            return false
        }

        // Verify PIN using secure comparison
        if SecureHasher.verifyPIN(pin, againstHash: storedCredentials.hash, salt: storedCredentials.salt) {
            handleSuccessfulAuth(method: .pin)
            Logger.auth("PIN authentication successful")
            AuditLogger.shared.logLogin(userId: savedUsername, userName: nil, outcome: .success)
            return true
        } else {
            handleFailedAuth()
            authError = .invalidPIN
            Logger.auth("PIN authentication failed - incorrect PIN", level: .warning)
            AuditLogger.shared.logLogin(userId: savedUsername, userName: nil, outcome: .failure, errorMessage: "Incorrect PIN")
            return false
        }
    }

    func setPIN(_ pin: String) -> Bool {
        // Validate PIN length
        guard pin.count >= 4, pin.allSatisfy({ $0.isNumber }) else {
            authError = .validationFailed(field: "PIN", message: "PIN must be at least 4 digits")
            return false
        }

        // Check PIN strength
        if isPinTooWeak(pin) {
            authError = .pinTooWeak
            return false
        }

        // Generate salt and hash
        let salt = SecureHasher.generateSalt()
        let hash = SecureHasher.hashPIN(pin, salt: salt)

        // Store in Keychain
        do {
            try keychain.storePIN(hash: hash, salt: salt)
            try keychain.setLastAuthMethod(AuthMethod.pin.rawValue)
            Logger.auth("PIN set successfully")
            return true
        } catch {
            Logger.error("Failed to store PIN", error: error, category: .security)
            authError = .keychainError(underlying: error)
            return false
        }
    }

    func hasPINSet() -> Bool {
        return keychain.retrievePIN() != nil
    }

    private func isPinTooWeak(_ pin: String) -> Bool {
        let digits = pin.compactMap { Int(String($0)) }

        // Check for all digits being the same
        if Set(digits).count == 1 {
            return true
        }

        // Check for sequential patterns
        for i in 0..<(digits.count - 2) {
            // Ascending sequence
            if digits[i] + 1 == digits[i+1] && digits[i+1] + 1 == digits[i+2] {
                return true
            }
            // Descending sequence
            if digits[i] - 1 == digits[i+1] && digits[i+1] - 1 == digits[i+2] {
                return true
            }
        }

        return false
    }

    // MARK: - Credentials Authentication

    func authenticateWithCredentials(username: String, password: String) async throws {
        guard !checkLockout() else {
            throw authError ?? .accountLocked(remainingTime: TimeInterval(lockoutRemainingSeconds))
        }

        do {
            try await ClerkAuthService.shared.signIn(email: username, password: password)
            handleSuccessfulAuth(method: .credentials)
            savedUsername = username
            Logger.auth("Credential authentication successful for: \(username)")
            AuditLogger.shared.logLogin(userId: username, userName: nil, outcome: .success)
        } catch {
            handleFailedAuth()
            let appError = AppError.authenticationFailed(reason: error.localizedDescription)
            authError = appError
            Logger.auth("Credential authentication failed: \(error.localizedDescription)", level: .warning)
            AuditLogger.shared.logLogin(userId: username, userName: nil, outcome: .failure, errorMessage: error.localizedDescription)
            throw appError
        }
    }

    func registerWithCredentials(username: String, password: String) async throws {
        // Validate password strength
        guard password.count >= AppConfiguration.Security.minPasswordLength else {
            throw AppError.valueTooShort(field: "Password", minLength: AppConfiguration.Security.minPasswordLength)
        }

        do {
            try await ClerkAuthService.shared.signUp(email: username, password: password)
            Logger.auth("Registration successful for: \(username)")
        } catch {
            let appError = AppError.authenticationFailed(reason: error.localizedDescription)
            Logger.auth("Registration failed: \(error.localizedDescription)", level: .error)
            throw appError
        }
    }

    // MARK: - Credential Storage

    func saveCredentials(username: String, password: String, rememberMe: Bool) -> Bool {
        savedUsername = username
        UserDefaults.standard.set(rememberMe, forKey: rememberMeKey)

        if rememberMe {
            // Generate salt and hash for secure storage
            let salt = SecureHasher.generateSalt()
            let hash = SecureHasher.hashPassword(password, salt: salt)

            do {
                try keychain.storeCredentials(email: username, passwordHash: hash, salt: salt)
                try keychain.setLastAuthMethod(AuthMethod.credentials.rawValue)
                Logger.auth("Credentials saved securely")
                return true
            } catch {
                Logger.error("Failed to save credentials", error: error, category: .security)
                return false
            }
        }

        return true
    }

    // MARK: - Session Management

    func logout() {
        isAuthenticated = false
        AuditLogger.shared.logLogout()
        Logger.auth("User logged out")

        // Clear session
        sessionTimer?.invalidate()

        // If remember me is not enabled, clear credentials
        if !UserDefaults.standard.bool(forKey: rememberMeKey) {
            do {
                try keychain.clearCredentials()
                try keychain.clearTokens()
            } catch {
                Logger.error("Failed to clear credentials on logout", error: error, category: .security)
            }
        }

        // Sign out from Clerk
        Task {
            try? await ClerkAuthService.shared.signOut()
        }

        AuditLogger.shared.clearCurrentUser()
    }

    func clearSavedCredentials() {
        do {
            try keychain.clearCredentials()
            try keychain.clearTokens()
            savedUsername = ""
            UserDefaults.standard.removeObject(forKey: rememberMeKey)
            Logger.auth("All saved credentials cleared")
        } catch {
            Logger.error("Failed to clear saved credentials", error: error, category: .security)
        }
    }

    /// Called when user interacts with the app to reset session timeout
    func recordActivity() {
        lastActivityTime = Date()
    }

    private func setupSessionTimeout() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkSessionTimeout()
            }
        }
    }

    private func checkSessionTimeout() {
        guard isAuthenticated else { return }

        let idleTime = Date().timeIntervalSince(lastActivityTime)
        let timeUntilTimeout = AppConfiguration.Security.sessionTimeout - idleTime
        let warningThreshold: TimeInterval = 5 * 60 // 5 minutes before timeout

        if idleTime > AppConfiguration.Security.sessionTimeout {
            // Session expired
            showSessionWarning = false
            Logger.auth("Session timed out after \(Int(idleTime)) seconds of inactivity")
            AuditLogger.shared.logSessionTimeout()
            logout()
        } else if timeUntilTimeout <= warningThreshold {
            // Show warning
            showSessionWarning = true
            sessionWarningSeconds = Int(timeUntilTimeout)
            if !showSessionWarning {
                Logger.auth("Session warning: \(Int(timeUntilTimeout)) seconds until timeout")
            }
        } else {
            // Clear warning if user became active
            if showSessionWarning {
                showSessionWarning = false
            }
        }
    }

    /// Extends the current session by resetting activity timer
    /// Called when user acknowledges session warning
    func extendSession() {
        recordActivity()
        showSessionWarning = false
        sessionWarningSeconds = 0
        Logger.auth("Session extended by user")
    }

    // MARK: - Lockout Management

    private func handleSuccessfulAuth(method: AuthMethod) {
        isAuthenticated = true
        loginAttempts = 0
        authError = nil
        lockoutEndTime = nil
        isLockedOut = false
        lastActivityTime = Date()

        // Store the auth method preference
        do {
            try keychain.setLastAuthMethod(method.rawValue)
        } catch {
            Logger.error("Failed to save auth method preference", error: error, category: .security)
        }

        // Set session expiry
        let sessionExpiry = Date().addingTimeInterval(AppConfiguration.Security.sessionTimeout)
        try? keychain.setSessionExpiry(sessionExpiry)

        // Set current user for audit logging
        AuditLogger.shared.setCurrentUser(userId: savedUsername, userName: nil)
    }

    private func handleFailedAuth() {
        loginAttempts += 1
        Logger.security("Failed login attempt \(loginAttempts)/\(AppConfiguration.Security.maxLoginAttempts)")

        if loginAttempts >= AppConfiguration.Security.maxLoginAttempts {
            setLockout()
        }
    }

    private func checkLockout() -> Bool {
        guard let lockoutEnd = lockoutEndTime else {
            isLockedOut = false
            return false
        }

        if Date() > lockoutEnd {
            // Lockout period is over
            lockoutEndTime = nil
            loginAttempts = 0
            isLockedOut = false
            lockoutTimer?.invalidate()
            Logger.auth("Lockout period ended")
            return false
        }

        let remaining = lockoutEnd.timeIntervalSince(Date())
        authError = .accountLocked(remainingTime: remaining)
        return true
    }

    private func setLockout() {
        lockoutEndTime = Date().addingTimeInterval(AppConfiguration.Security.lockoutDuration)
        isLockedOut = true
        Logger.security("Account locked for \(Int(AppConfiguration.Security.lockoutDuration/60)) minutes")

        // Start timer to update remaining time
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateLockoutTimer()
            }
        }

        // Store lockout state securely in Keychain
        do {
            try keychain.setLockoutEndTime(lockoutEndTime)
            try keychain.setFailedLoginAttempts(loginAttempts)
        } catch {
            Logger.error("Failed to store lockout state in Keychain", error: error, category: .security)
        }
    }

    private func updateLockoutTimer() {
        guard let lockoutEnd = lockoutEndTime else {
            lockoutTimer?.invalidate()
            return
        }

        let remaining = lockoutEnd.timeIntervalSince(Date())
        if remaining <= 0 {
            lockoutEndTime = nil
            isLockedOut = false
            loginAttempts = 0
            lockoutRemainingSeconds = 0
            lockoutTimer?.invalidate()
            // Clear lockout state from Keychain
            do {
                try keychain.clearLockoutState()
            } catch {
                Logger.error("Failed to clear lockout state from Keychain", error: error, category: .security)
            }
            authError = nil
        } else {
            lockoutRemainingSeconds = Int(remaining)
        }
    }

    private func loadLockoutState() {
        // Load lockout state from Keychain (secure storage)
        if let lockoutEnd = keychain.getLockoutEndTime() {
            if lockoutEnd > Date() {
                lockoutEndTime = lockoutEnd
                loginAttempts = keychain.getFailedLoginAttempts()
                isLockedOut = true
                // Restart the timer
                lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        self?.updateLockoutTimer()
                    }
                }
            }
        }
    }

    // MARK: - Biometric Availability

    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsAvailable = true
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .opticID:
                biometricType = .none // Not supported yet
            @unknown default:
                biometricType = .none
            }
            Logger.auth("Biometric available: \(biometricType.displayName)")
        } else {
            biometricsAvailable = false
            biometricType = .none
            Logger.auth("Biometric not available: \(error?.localizedDescription ?? "unknown")")
        }
    }

    private func attemptAutoLogin() {
        guard let authMethodString = keychain.getLastAuthMethod(),
              let method = AuthMethod(rawValue: authMethodString),
              UserDefaults.standard.bool(forKey: rememberMeKey) else {
            return
        }

        switch method {
        case .biometric:
            if biometricsAvailable && keychain.isBiometricEnabled() {
                Logger.auth("Attempting auto-login with biometrics")
                authenticateWithBiometrics { _ in }
            }
        case .credentials, .pin:
            // Don't auto-login, just pre-fill username
            break
        case .none:
            break
        }
    }

    // MARK: - Public Helpers

    func getSavedUsername() -> String {
        return savedUsername
    }

    func isRememberMeEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: rememberMeKey)
    }

    func getPreferredAuthMethod() -> AuthMethod {
        guard let authMethodString = keychain.getLastAuthMethod(),
              let authMethod = AuthMethod(rawValue: authMethodString) else {
            return .none
        }
        return authMethod
    }

    func enableBiometric(_ enabled: Bool) {
        do {
            try keychain.setBiometricEnabled(enabled)
            if enabled {
                try keychain.setLastAuthMethod(AuthMethod.biometric.rawValue)
            }
            Logger.auth("Biometric enabled: \(enabled)")
        } catch {
            Logger.error("Failed to set biometric preference", error: error, category: .security)
        }
    }

    func isBiometricEnabled() -> Bool {
        return keychain.isBiometricEnabled()
    }

    /// Clears any displayed auth error
    func clearError() {
        authError = nil
    }
}
