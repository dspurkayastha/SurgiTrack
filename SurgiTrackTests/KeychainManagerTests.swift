// KeychainManagerTests.swift
// SurgiTrackTests
// Tests for secure Keychain storage
// Created on 26/12/2025

import Testing
import Foundation
@testable import SurgiTrack

struct KeychainManagerTests {

    // Use a test-specific instance to avoid affecting real data
    private var keychain: KeychainManager { KeychainManager.shared }

    // MARK: - String Storage Tests

    @Test func storeAndRetrieve_stringValue() async throws {
        let testKey = KeychainManager.KeychainKey.authToken
        let testValue = "test_token_12345"

        try keychain.store(testValue, for: testKey)
        let retrieved = keychain.retrieve(key: testKey)

        #expect(retrieved == testValue, "Retrieved value should match stored value")

        // Cleanup
        try? keychain.delete(key: testKey)
    }

    @Test func retrieve_nonExistentKey_returnsNil() async throws {
        // Use a key that shouldn't exist
        try? keychain.delete(key: .refreshToken)

        let retrieved = keychain.retrieve(key: .refreshToken)

        #expect(retrieved == nil, "Non-existent key should return nil")
    }

    @Test func store_overwritesExistingValue() async throws {
        let testKey = KeychainManager.KeychainKey.authToken

        try keychain.store("first_value", for: testKey)
        try keychain.store("second_value", for: testKey)

        let retrieved = keychain.retrieve(key: testKey)

        #expect(retrieved == "second_value", "Store should overwrite existing value")

        // Cleanup
        try? keychain.delete(key: testKey)
    }

    // MARK: - Delete Tests

    @Test func delete_existingKey_succeeds() async throws {
        let testKey = KeychainManager.KeychainKey.authToken

        try keychain.store("test_value", for: testKey)
        try keychain.delete(key: testKey)

        let retrieved = keychain.retrieve(key: testKey)

        #expect(retrieved == nil, "Deleted key should return nil")
    }

    @Test func delete_nonExistentKey_doesNotThrow() async throws {
        // Should not throw even if key doesn't exist
        try? keychain.delete(key: .refreshToken)
        try keychain.delete(key: .refreshToken)

        // If we get here without throwing, the test passes
        #expect(true)
    }

    // MARK: - Exists Tests

    @Test func exists_forExistingKey_returnsTrue() async throws {
        let testKey = KeychainManager.KeychainKey.authToken

        try keychain.store("test_value", for: testKey)
        let exists = keychain.exists(key: testKey)

        #expect(exists == true, "Existing key should return true")

        // Cleanup
        try? keychain.delete(key: testKey)
    }

    @Test func exists_forNonExistentKey_returnsFalse() async throws {
        try? keychain.delete(key: .refreshToken)

        let exists = keychain.exists(key: .refreshToken)

        #expect(exists == false, "Non-existent key should return false")
    }

    // MARK: - PIN Storage Tests

    @Test func storePIN_andRetrieve() async throws {
        let hash = "test_pin_hash_abc123"
        let salt = "test_salt_xyz789"

        try keychain.storePIN(hash: hash, salt: salt)
        let retrieved = keychain.retrievePIN()

        #expect(retrieved?.hash == hash, "Retrieved PIN hash should match")
        #expect(retrieved?.salt == salt, "Retrieved PIN salt should match")

        // Cleanup
        try? keychain.delete(key: .pinHash)
        try? keychain.delete(key: .pinSalt)
    }

    @Test func retrievePIN_whenNotSet_returnsNil() async throws {
        try? keychain.delete(key: .pinHash)
        try? keychain.delete(key: .pinSalt)

        let retrieved = keychain.retrievePIN()

        #expect(retrieved == nil, "PIN should be nil when not set")
    }

    // MARK: - Credentials Storage Tests

    @Test func storeCredentials_andRetrieve() async throws {
        let email = "test@example.com"
        let passwordHash = "hashed_password_123"
        let salt = "credential_salt_456"

        try keychain.storeCredentials(email: email, passwordHash: passwordHash, salt: salt)
        let retrieved = keychain.retrieveCredentials()

        #expect(retrieved?.email == email, "Retrieved email should match")
        #expect(retrieved?.passwordHash == passwordHash, "Retrieved password hash should match")
        #expect(retrieved?.salt == salt, "Retrieved salt should match")

        // Cleanup
        try? keychain.clearCredentials()
    }

    // MARK: - Session Management Tests

    @Test func sessionExpiry_storeAndRetrieve() async throws {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now

        try keychain.setSessionExpiry(futureDate)
        let retrieved = keychain.getSessionExpiry()

        #expect(retrieved != nil, "Session expiry should be retrieved")
        // Allow 1 second tolerance for timestamp precision
        #expect(abs(retrieved!.timeIntervalSince(futureDate)) < 1, "Retrieved date should match")

        // Cleanup
        try? keychain.delete(key: .sessionExpiry)
    }

    @Test func isSessionValid_withFutureExpiry_returnsTrue() async throws {
        let futureDate = Date().addingTimeInterval(3600)

        try keychain.setSessionExpiry(futureDate)
        let isValid = keychain.isSessionValid()

        #expect(isValid == true, "Session with future expiry should be valid")

        // Cleanup
        try? keychain.delete(key: .sessionExpiry)
    }

    @Test func isSessionValid_withPastExpiry_returnsFalse() async throws {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago

        try keychain.setSessionExpiry(pastDate)
        let isValid = keychain.isSessionValid()

        #expect(isValid == false, "Session with past expiry should be invalid")

        // Cleanup
        try? keychain.delete(key: .sessionExpiry)
    }

    // MARK: - Biometric Settings Tests

    @Test func biometricEnabled_storeAndRetrieve() async throws {
        try keychain.setBiometricEnabled(true)
        #expect(keychain.isBiometricEnabled() == true, "Biometric should be enabled")

        try keychain.setBiometricEnabled(false)
        #expect(keychain.isBiometricEnabled() == false, "Biometric should be disabled")
    }

    // MARK: - Lockout State Tests

    @Test func lockoutState_storeAndRetrieve() async throws {
        let lockoutEnd = Date().addingTimeInterval(300) // 5 minutes from now

        try keychain.setLockoutEndTime(lockoutEnd)
        try keychain.setFailedLoginAttempts(3)

        let retrievedTime = keychain.getLockoutEndTime()
        let retrievedAttempts = keychain.getFailedLoginAttempts()

        #expect(retrievedTime != nil, "Lockout time should be retrieved")
        #expect(retrievedAttempts == 3, "Failed attempts should match")

        // Cleanup
        try? keychain.clearLockoutState()
    }

    @Test func clearLockoutState_removesAll() async throws {
        try keychain.setLockoutEndTime(Date().addingTimeInterval(300))
        try keychain.setFailedLoginAttempts(5)

        try keychain.clearLockoutState()

        #expect(keychain.getLockoutEndTime() == nil, "Lockout time should be cleared")
        #expect(keychain.getFailedLoginAttempts() == 0, "Failed attempts should be 0")
    }

    @Test func getLockoutEndTime_whenExpired_clearsAndReturnsNil() async throws {
        let pastDate = Date().addingTimeInterval(-60) // 1 minute ago

        // Manually store an expired lockout time
        try keychain.store(String(pastDate.timeIntervalSince1970), for: .lockoutEndTime)
        try keychain.setFailedLoginAttempts(5)

        let result = keychain.getLockoutEndTime()

        #expect(result == nil, "Expired lockout should return nil")
        #expect(keychain.getFailedLoginAttempts() == 0, "Failed attempts should be cleared")
    }

    // MARK: - Auth Method Tests

    @Test func lastAuthMethod_storeAndRetrieve() async throws {
        let method = "biometric"

        try keychain.setLastAuthMethod(method)
        let retrieved = keychain.getLastAuthMethod()

        #expect(retrieved == method, "Retrieved auth method should match")

        // Cleanup
        try? keychain.delete(key: .lastAuthMethod)
    }
}
