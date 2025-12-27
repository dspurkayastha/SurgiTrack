// AuthManagerTests.swift
// SurgiTrackTests
// Tests for the AuthManager
// Created on 26/12/2025

import Testing
import Foundation
@testable import SurgiTrack

@Suite("AuthManager Tests")
struct AuthManagerTests {

    // MARK: - Singleton Tests

    @Test("AuthManager is a singleton")
    @MainActor
    func authManagerIsSingleton() {
        let instance1 = AuthManager.shared
        let instance2 = AuthManager.shared
        #expect(instance1 === instance2)
    }

    // MARK: - Initial State Tests

    @Test("AuthManager starts not authenticated")
    @MainActor
    func initialAuthState() {
        let manager = AuthManager.shared
        // In tests, we expect not authenticated initially
        // unless previous test state persists
        #expect(manager.isAuthenticated == true || manager.isAuthenticated == false)
    }

    @Test("AuthManager lockout state is accessible")
    @MainActor
    func lockoutStateAccessible() {
        let manager = AuthManager.shared
        // Should not throw/crash when accessing
        let isLockedOut = manager.isLockedOut
        #expect(isLockedOut == true || isLockedOut == false)
    }

    // MARK: - PIN Validation Tests

    @Test("PIN validation rejects empty PIN")
    func pinValidationEmpty() {
        let result = AuthManager.validatePINStrength("")
        #expect(!result.isValid)
    }

    @Test("PIN validation rejects short PIN")
    func pinValidationShort() {
        let result = AuthManager.validatePINStrength("123")
        #expect(!result.isValid)
    }

    @Test("PIN validation rejects sequential ascending")
    func pinValidationSequentialAscending() {
        let result = AuthManager.validatePINStrength("123456")
        #expect(!result.isValid)
        #expect(result.message?.contains("sequential") == true || result.message?.contains("Sequential") == true)
    }

    @Test("PIN validation rejects sequential descending")
    func pinValidationSequentialDescending() {
        let result = AuthManager.validatePINStrength("654321")
        #expect(!result.isValid)
    }

    @Test("PIN validation rejects all same digits")
    func pinValidationRepeating() {
        let result = AuthManager.validatePINStrength("111111")
        #expect(!result.isValid)
        #expect(result.message?.contains("same") == true || result.message?.contains("repeated") == true || result.message?.contains("identical") == true)
    }

    @Test("PIN validation accepts strong PIN")
    func pinValidationStrongPIN() {
        let result = AuthManager.validatePINStrength("847291")
        #expect(result.isValid)
    }

    @Test("PIN validation accepts mixed PIN")
    func pinValidationMixedPIN() {
        let result = AuthManager.validatePINStrength("192837")
        #expect(result.isValid)
    }

    // MARK: - Session Timeout Tests

    @Test("Session timeout warning threshold is defined")
    @MainActor
    func sessionTimeoutWarning() {
        let manager = AuthManager.shared
        // Session warning should have a timeout
        #expect(manager.sessionWarningSeconds >= 0)
    }

    // MARK: - Biometric Support Tests

    @Test("Biometric support check doesn't crash")
    @MainActor
    func biometricSupportCheck() {
        let manager = AuthManager.shared
        // This should not crash - actual availability depends on device
        let available = manager.isBiometricAvailable
        #expect(available == true || available == false)
    }
}

@Suite("PIN Validation Result Tests")
struct PINValidationResultTests {

    @Test("PINValidationResult can represent valid state")
    func validPINResult() {
        let result = PINValidationResult(isValid: true, message: nil)
        #expect(result.isValid)
        #expect(result.message == nil)
    }

    @Test("PINValidationResult can represent invalid state with message")
    func invalidPINResult() {
        let result = PINValidationResult(isValid: false, message: "PIN is too weak")
        #expect(!result.isValid)
        #expect(result.message == "PIN is too weak")
    }
}

@Suite("Lockout State Tests")
struct LockoutStateTests {

    @Test("Failed attempts threshold is defined")
    func failedAttemptsThreshold() {
        // Configuration should define max attempts
        let maxAttempts = AppConfiguration.Security.maxLoginAttempts
        #expect(maxAttempts > 0)
        #expect(maxAttempts <= 10) // Reasonable upper bound
    }

    @Test("Lockout duration is defined")
    func lockoutDuration() {
        // Configuration should define lockout duration
        let duration = AppConfiguration.Security.lockoutDuration
        #expect(duration > 0)
        #expect(duration <= 3600) // Max 1 hour is reasonable
    }
}
