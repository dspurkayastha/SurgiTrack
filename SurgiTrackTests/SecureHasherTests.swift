// SecureHasherTests.swift
// SurgiTrackTests
// Tests for cryptographic hashing utilities
// Created on 26/12/2025

import Testing
@testable import SurgiTrack

struct SecureHasherTests {

    // MARK: - Salt Generation Tests

    @Test func saltGeneration_producesUniqueSalts() async throws {
        let salt1 = SecureHasher.generateSalt()
        let salt2 = SecureHasher.generateSalt()

        #expect(salt1 != salt2, "Each salt generation should be unique")
        #expect(salt1.count == 64, "Salt should be 32 bytes (64 hex characters)")
        #expect(salt2.count == 64, "Salt should be 32 bytes (64 hex characters)")
    }

    @Test func saltGeneration_containsOnlyHexCharacters() async throws {
        let salt = SecureHasher.generateSalt()
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")

        for char in salt.unicodeScalars {
            #expect(hexCharacterSet.contains(char), "Salt should only contain hex characters")
        }
    }

    // MARK: - Password Hashing Tests

    @Test func passwordHashing_producesConsistentHash() async throws {
        let password = "TestPassword123!"
        let salt = SecureHasher.generateSalt()

        let hash1 = SecureHasher.hashPassword(password, salt: salt)
        let hash2 = SecureHasher.hashPassword(password, salt: salt)

        #expect(hash1 == hash2, "Same password and salt should produce same hash")
    }

    @Test func passwordHashing_differentSaltsProduceDifferentHashes() async throws {
        let password = "TestPassword123!"
        let salt1 = SecureHasher.generateSalt()
        let salt2 = SecureHasher.generateSalt()

        let hash1 = SecureHasher.hashPassword(password, salt: salt1)
        let hash2 = SecureHasher.hashPassword(password, salt: salt2)

        #expect(hash1 != hash2, "Different salts should produce different hashes")
    }

    @Test func passwordHashing_differentPasswordsProduceDifferentHashes() async throws {
        let salt = SecureHasher.generateSalt()

        let hash1 = SecureHasher.hashPassword("Password1", salt: salt)
        let hash2 = SecureHasher.hashPassword("Password2", salt: salt)

        #expect(hash1 != hash2, "Different passwords should produce different hashes")
    }

    @Test func passwordHashing_hashIsSHA256Length() async throws {
        let hash = SecureHasher.hashPassword("test", salt: "salt")

        // SHA-256 produces 256 bits = 32 bytes = 64 hex characters
        #expect(hash.count == 64, "Hash should be SHA-256 (64 hex characters)")
    }

    // MARK: - Password Verification Tests

    @Test func passwordVerification_correctPasswordVerifies() async throws {
        let password = "SecurePassword123!"
        let salt = SecureHasher.generateSalt()
        let hash = SecureHasher.hashPassword(password, salt: salt)

        let isValid = SecureHasher.verifyPassword(password, againstHash: hash, salt: salt)

        #expect(isValid == true, "Correct password should verify successfully")
    }

    @Test func passwordVerification_wrongPasswordFails() async throws {
        let password = "SecurePassword123!"
        let wrongPassword = "WrongPassword456!"
        let salt = SecureHasher.generateSalt()
        let hash = SecureHasher.hashPassword(password, salt: salt)

        let isValid = SecureHasher.verifyPassword(wrongPassword, againstHash: hash, salt: salt)

        #expect(isValid == false, "Wrong password should fail verification")
    }

    @Test func passwordVerification_wrongSaltFails() async throws {
        let password = "SecurePassword123!"
        let salt1 = SecureHasher.generateSalt()
        let salt2 = SecureHasher.generateSalt()
        let hash = SecureHasher.hashPassword(password, salt: salt1)

        let isValid = SecureHasher.verifyPassword(password, againstHash: hash, salt: salt2)

        #expect(isValid == false, "Wrong salt should fail verification")
    }

    // MARK: - PIN Hashing Tests

    @Test func pinHashing_worksLikePasswordHashing() async throws {
        let pin = "123456"
        let salt = SecureHasher.generateSalt()

        let pinHash = SecureHasher.hashPIN(pin, salt: salt)
        let passwordHash = SecureHasher.hashPassword(pin, salt: salt)

        #expect(pinHash == passwordHash, "PIN hashing should use same algorithm as password")
    }

    @Test func pinVerification_correctPinVerifies() async throws {
        let pin = "654321"
        let salt = SecureHasher.generateSalt()
        let hash = SecureHasher.hashPIN(pin, salt: salt)

        let isValid = SecureHasher.verifyPIN(pin, againstHash: hash, salt: salt)

        #expect(isValid == true, "Correct PIN should verify successfully")
    }

    // MARK: - Secure Hash Creation Tests

    @Test func createSecureHash_returnsBothHashAndSalt() async throws {
        let password = "MySecurePassword"

        let result = SecureHasher.createSecureHash(for: password)

        #expect(result.hash.count == 64, "Hash should be 64 hex characters")
        #expect(result.salt.count == 64, "Salt should be 64 hex characters")
        #expect(result.hash != result.salt, "Hash and salt should be different")
    }

    @Test func createSecureHash_canBeVerified() async throws {
        let password = "MySecurePassword"

        let result = SecureHasher.createSecureHash(for: password)
        let isValid = SecureHasher.verifyPassword(password, againstHash: result.hash, salt: result.salt)

        #expect(isValid == true, "Created hash should be verifiable")
    }

    // MARK: - Secure Token Generation Tests

    @Test func secureTokenGeneration_producesCorrectLength() async throws {
        let token16 = SecureHasher.generateSecureToken(length: 16)
        let token32 = SecureHasher.generateSecureToken(length: 32)
        let token64 = SecureHasher.generateSecureToken(length: 64)

        #expect(token16.count == 32, "16-byte token should be 32 hex characters")
        #expect(token32.count == 64, "32-byte token should be 64 hex characters")
        #expect(token64.count == 128, "64-byte token should be 128 hex characters")
    }

    @Test func secureTokenGeneration_producesUniqueTokens() async throws {
        let token1 = SecureHasher.generateSecureToken()
        let token2 = SecureHasher.generateSecureToken()

        #expect(token1 != token2, "Each token should be unique")
    }

    // MARK: - Encryption Tests

    @Test func encryption_roundTrip() async throws {
        let originalData = "Sensitive patient data".data(using: .utf8)!
        let key = SecureHasher.deriveKey(from: "password", salt: Data("salt".utf8))

        guard let encrypted = SecureHasher.encrypt(originalData, using: key) else {
            #expect(Bool(false), "Encryption should succeed")
            return
        }

        guard let decrypted = SecureHasher.decrypt(encrypted, using: key) else {
            #expect(Bool(false), "Decryption should succeed")
            return
        }

        #expect(decrypted == originalData, "Decrypted data should match original")
    }

    @Test func encryption_wrongKeyFails() async throws {
        let originalData = "Sensitive data".data(using: .utf8)!
        let key1 = SecureHasher.deriveKey(from: "password1", salt: Data("salt".utf8))
        let key2 = SecureHasher.deriveKey(from: "password2", salt: Data("salt".utf8))

        guard let encrypted = SecureHasher.encrypt(originalData, using: key1) else {
            #expect(Bool(false), "Encryption should succeed")
            return
        }

        let decrypted = SecureHasher.decrypt(encrypted, using: key2)

        #expect(decrypted == nil, "Decryption with wrong key should fail")
    }
}
