// AuthManager.swift
// SurgiTrack
// Created on 06/03/2025

import Foundation
import LocalAuthentication
import SwiftUI
import ClerkSDK

class AuthManager: ObservableObject {
    // Authentication states
    @Published var isAuthenticated = false
    @Published var biometricsAvailable = false
    @Published var biometricType: BiometricType = .none
    @Published var authError: String?
    
    // User defaults keys
    private let authMethodKey = "authMethod"
    private let pinHashKey = "pinHash"
    private let credentialsKey = "credentials"
    private let rememberMeKey = "rememberMe"
    
    // Keychain service name
    private let keychainService = "com.surgitrack.credentials"
    
    // Saved credentials
    @AppStorage("username") private var savedUsername = ""
    
    // Auth attempt tracking
    private var loginAttempts = 0
    private let maxLoginAttempts = 5
    private var lockoutEndTime: Date?
    
    enum BiometricType {
        case none
        case faceID
        case touchID
    }
    
    enum AuthMethod: String {
        case none
        case pin
        case credentials
        case biometric
    }
    
    init() {
        checkBiometricAvailability()
        attemptAutoLogin()
    }
    
    // MARK: - Authentication Methods
    
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            self.authError = error?.localizedDescription ?? "Biometric authentication unavailable"
            completion(false)
            return
        }
        
        let reason = "Log into your SurgiTrack account"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    self.authError = nil
                    completion(true)
                } else {
                    self.authError = error?.localizedDescription ?? "Authentication failed"
                    completion(false)
                }
            }
        }
    }
    
    func authenticateWithPIN(_ pin: String) -> Bool {
        guard pin.count == 6 else {
                authError = "Please enter a 6-digit PIN"
                return false
        }
        guard !isLockedOut() else {
            authError = "Too many failed attempts. Try again later."
            return false
        }
        
        guard let storedPinHash = UserDefaults.standard.string(forKey: pinHashKey) else {
            // No PIN set - we'll consider this an error for now
            authError = "No PIN has been set up"
            return false
        }
        
        // Hash the provided PIN and compare
        if hashPin(pin) == storedPinHash {
            isAuthenticated = true
            loginAttempts = 0
            authError = nil
            return true
        } else {
            loginAttempts += 1
            
            if loginAttempts >= maxLoginAttempts {
                setLockout()
            }
            
            authError = "Incorrect PIN"
            return false
        }
    }
    
    func authenticateWithCredentials(username: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        ClerkAuthService.shared.signIn(email: username, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.isAuthenticated = true
                    self.loginAttempts = 0
                    self.authError = nil
                    completion(true, nil)
                case .failure(let error):
                    self.loginAttempts += 1
                    if self.loginAttempts >= self.maxLoginAttempts {
                        self.setLockout()
                    }
                    self.authError = error.localizedDescription
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func registerWithCredentials(username: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        ClerkAuthService.shared.signUp(email: username, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    completion(true, nil)
                case .failure(let error):
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    func setPIN(_ pin: String) -> Bool {
        guard pin.count >= 4, pin.allSatisfy({ $0.isNumber }) else {
            authError = "PIN must be at least 4 digits"
            return false
        }
        
        // Check PIN strength
        if isPinTooWeak(pin) {
            authError = "PIN is too weak. Avoid sequential or repeated digits."
            return false
        }
        
        let pinHash = hashPin(pin)
        UserDefaults.standard.set(pinHash, forKey: pinHashKey)
        UserDefaults.standard.set(AuthMethod.pin.rawValue, forKey: authMethodKey)
        return true
    }
    
    private func isPinTooWeak(_ pin: String) -> Bool {
        // Check for sequential digits (e.g., 1234, 4321)
        let digits = pin.compactMap { Int(String($0)) }
        
        // Check for all digits being the same
        if Set(digits).count == 1 {
            return true
        }
        
        // Check for sequential patterns
        for i in 0..<(digits.count - 2) {
            // Check ascending sequence
            if digits[i] + 1 == digits[i+1] && digits[i+1] + 1 == digits[i+2] {
                return true
            }
            
            // Check descending sequence
            if digits[i] - 1 == digits[i+1] && digits[i+1] - 1 == digits[i+2] {
                return true
            }
        }
        
        return false
    }
    
    func saveCredentials(username: String, password: String, rememberMe: Bool) -> Bool {
        // Never save password in UserDefaults in a real app
        // This is a simplified version - would use Keychain in production
        savedUsername = username
        UserDefaults.standard.set(rememberMe, forKey: rememberMeKey)
        
        if rememberMe {
            UserDefaults.standard.set(AuthMethod.credentials.rawValue, forKey: authMethodKey)
            
            // In a real app, use Keychain instead
            let credentials = "\(username):\(hashPassword(password))"
            UserDefaults.standard.set(credentials, forKey: credentialsKey)
        }
        
        return true
    }
    
    func logout() {
        isAuthenticated = false
        
        // If remember me is not enabled, clear credentials
        if !UserDefaults.standard.bool(forKey: rememberMeKey) {
            UserDefaults.standard.removeObject(forKey: credentialsKey)
        }
    }
    
    func clearSavedCredentials() {
        UserDefaults.standard.removeObject(forKey: credentialsKey)
        UserDefaults.standard.removeObject(forKey: pinHashKey)
        UserDefaults.standard.removeObject(forKey: authMethodKey)
        UserDefaults.standard.removeObject(forKey: rememberMeKey)
        savedUsername = ""
    }
    
    // MARK: - Helper Methods
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsAvailable = true
            if #available(iOS 11.0, *) {
                switch context.biometryType {
                case .faceID:
                    biometricType = .faceID
                case .touchID:
                    biometricType = .touchID
                default:
                    biometricType = .none
                }
            } else {
                biometricType = .touchID
            }
        } else {
            biometricsAvailable = false
            biometricType = .none
        }
    }
    
    private func attemptAutoLogin() {
        guard let authMethod = UserDefaults.standard.string(forKey: authMethodKey),
              let method = AuthMethod(rawValue: authMethod),
              UserDefaults.standard.bool(forKey: rememberMeKey) else {
            return
        }
        
        // Auto login only happens with biometrics or if remember me is enabled
        switch method {
        case .biometric:
            if biometricsAvailable {
                authenticateWithBiometrics { _ in }
            }
        case .credentials:
            // Don't auto-login with credentials, just pre-fill the username
            break
        default:
            break
        }
    }
    
    private func hashPin(_ pin: String) -> String {
        // In a real app, use a secure hash function with proper salt
        // This is a simplified version for demo purposes
        return "hash_\(pin)"
    }
    
    private func hashPassword(_ password: String) -> String {
        // In a real app, use a secure hash function with proper salt
        // This is a simplified version for demo purposes
        return "hash_\(password)"
    }
    
    private func checkSavedCredentials(username: String, password: String) -> Bool {
        guard let savedCredentialsString = UserDefaults.standard.string(forKey: credentialsKey) else {
            return false
        }
        
        let parts = savedCredentialsString.split(separator: ":")
        guard parts.count == 2 else { return false }
        
        let savedUsername = String(parts[0])
        let savedPasswordHash = String(parts[1])
        
        return username == savedUsername && hashPassword(password) == savedPasswordHash
    }
    
    private func isLockedOut() -> Bool {
        guard let lockoutEnd = lockoutEndTime else {
            return false
        }
        
        if Date() > lockoutEnd {
            // Lockout period is over
            lockoutEndTime = nil
            loginAttempts = 0
            return false
        }
        
        return true
    }
    
    private func setLockout() {
        // Lock out for 5 minutes
        lockoutEndTime = Date().addingTimeInterval(5 * 60)
    }
    
    // Helper to get saved username (for UI)
    func getSavedUsername() -> String {
        return savedUsername
    }
    
    // Helper to check if "remember me" is enabled
    func isRememberMeEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: rememberMeKey)
    }
    
    // Helper to get the preferred auth method
    func getPreferredAuthMethod() -> AuthMethod {
        guard let authMethodString = UserDefaults.standard.string(forKey: authMethodKey),
              let authMethod = AuthMethod(rawValue: authMethodString) else {
            return .none
        }
        
        return authMethod
    }
}
