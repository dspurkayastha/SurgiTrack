// SecureHasher.swift
// SurgiTrack
// Cryptographically secure hashing for passwords and PINs
// Created on 26/12/2025
// Updated: PBKDF2 implementation for HIPAA-compliant password hashing

import Foundation
import CryptoKit
import CommonCrypto

/// Provides secure cryptographic hashing for sensitive data like passwords and PINs.
/// Uses PBKDF2-HMAC-SHA256 with high iteration count for secure storage.
/// Compliant with NIST SP 800-132 and HIPAA security requirements.
struct SecureHasher {

    // MARK: - Configuration

    /// The number of iterations for PBKDF2 key derivation
    /// NIST recommends minimum 10,000; we use 310,000 for enhanced security
    /// This value should be increased over time as hardware improves
    private static let pbkdf2Iterations: UInt32 = 310_000

    /// Salt length in bytes (256 bits as recommended by NIST)
    private static let saltLength = 32

    /// Derived key length in bytes (256 bits)
    private static let derivedKeyLength = 32

    /// Version identifier for hash format (for future migration support)
    private static let hashVersion = "v2"

    // MARK: - Public Methods

    /// Generates a cryptographically secure random salt
    /// - Returns: A hex-encoded salt string
    static func generateSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: saltLength)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard status == errSecSuccess else {
            // This should never happen in practice, but log if it does
            Logger.security("SecRandomCopyBytes failed, using fallback", level: .error)
            // Fallback using multiple UUIDs for entropy
            let uuid1 = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let uuid2 = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            return String((uuid1 + uuid2).prefix(64))
        }

        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// Hashes a password using PBKDF2-HMAC-SHA256
    /// - Parameters:
    ///   - password: The plaintext password to hash
    ///   - salt: The salt to use for hashing (hex-encoded)
    /// - Returns: A versioned hex-encoded hash string (format: "v2:hash")
    static func hashPassword(_ password: String, salt: String) -> String {
        guard let passwordData = password.data(using: .utf8),
              let saltData = Data(hexString: salt) else {
            Logger.security("Failed to encode password or salt for hashing", level: .error)
            return ""
        }

        var derivedKey = [UInt8](repeating: 0, count: derivedKeyLength)

        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password,
            passwordData.count,
            [UInt8](saltData),
            saltData.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            pbkdf2Iterations,
            &derivedKey,
            derivedKeyLength
        )

        guard status == kCCSuccess else {
            Logger.security("PBKDF2 derivation failed with status: \(status)", level: .error)
            return ""
        }

        let hashHex = derivedKey.map { String(format: "%02x", $0) }.joined()
        return "\(hashVersion):\(hashHex)"
    }

    /// Hashes a PIN using PBKDF2-HMAC-SHA256
    /// - Parameters:
    ///   - pin: The plaintext PIN to hash
    ///   - salt: The salt to use for hashing
    /// - Returns: A versioned hex-encoded hash string
    static func hashPIN(_ pin: String, salt: String) -> String {
        return hashPassword(pin, salt: salt)
    }

    /// Verifies a password against a stored hash
    /// Supports both legacy (v1/unversioned) and current (v2) hash formats
    /// - Parameters:
    ///   - password: The plaintext password to verify
    ///   - hash: The stored hash to compare against
    ///   - salt: The salt that was used for hashing
    /// - Returns: true if the password matches, false otherwise
    static func verifyPassword(_ password: String, againstHash hash: String, salt: String) -> Bool {
        // Check for versioned hash format
        if hash.hasPrefix("v2:") {
            // Current PBKDF2 format
            let computedHash = hashPassword(password, salt: salt)
            return constantTimeCompare(computedHash, hash)
        } else if hash.hasPrefix("v1:") {
            // Legacy format with version prefix
            let legacyHash = hashPasswordLegacy(password, salt: salt)
            return constantTimeCompare("v1:\(legacyHash)", hash)
        } else {
            // Unversioned legacy format (pre-v2 migration)
            let legacyHash = hashPasswordLegacy(password, salt: salt)
            return constantTimeCompare(legacyHash, hash)
        }
    }

    /// Legacy SHA-256 hashing for backward compatibility
    /// Used only for verification of old hashes, not for creating new ones
    private static func hashPasswordLegacy(_ password: String, salt: String) -> String {
        let saltedPassword = password + salt
        guard let data = saltedPassword.data(using: .utf8) else {
            return ""
        }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
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

    /// Checks if a hash needs to be upgraded to the current format
    /// - Parameter hash: The hash to check
    /// - Returns: true if the hash should be re-hashed with PBKDF2
    static func needsHashUpgrade(_ hash: String) -> Bool {
        return !hash.hasPrefix("v2:")
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

// MARK: - Data Hex String Extension

extension Data {
    /// Initializes Data from a hex-encoded string
    /// - Parameter hexString: The hex string to convert (e.g., "48656c6c6f")
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex

        for _ in 0..<len {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }

        self = data
    }

    /// Converts Data to a hex-encoded string
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
