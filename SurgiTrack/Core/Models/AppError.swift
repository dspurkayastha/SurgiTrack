// AppError.swift
// SurgiTrack
// Unified error types for the application
// Created on 26/12/2025

import Foundation

/// Unified error types for SurgiTrack application.
/// Provides user-friendly error messages and recovery suggestions.
enum AppError: LocalizedError, Equatable {

    // MARK: - Authentication Errors

    case authenticationFailed(reason: String)
    case invalidCredentials
    case accountLocked(remainingTime: TimeInterval)
    case biometricNotAvailable
    case biometricFailed
    case sessionExpired
    case pinNotSet
    case pinTooWeak
    case invalidPIN

    // MARK: - Validation Errors

    case validationFailed(field: String, message: String)
    case requiredFieldMissing(field: String)
    case invalidFormat(field: String, expected: String)
    case valueTooLong(field: String, maxLength: Int)
    case valueTooShort(field: String, minLength: Int)

    // MARK: - Persistence Errors

    case persistenceError(underlying: Error)
    case saveError(entity: String)
    case fetchError(entity: String)
    case deleteError(entity: String)
    case migrationError
    case dataCorruption

    // MARK: - Network Errors

    case networkUnavailable
    case networkTimeout
    case serverError(statusCode: Int)
    case invalidResponse
    case networkError(underlying: Error)

    // MARK: - Security Errors

    case keychainError(underlying: Error)
    case encryptionError
    case decryptionError
    case unauthorizedAccess

    // MARK: - File Errors

    case fileNotFound(path: String)
    case fileReadError(path: String)
    case fileWriteError(path: String)
    case fileTooLarge(maxSize: Int)
    case unsupportedFileType(type: String)

    // MARK: - General Errors

    case unknown(underlying: Error?)
    case operationCancelled
    case notImplemented(feature: String)

    // MARK: - LocalizedError Conformance

    var errorDescription: String? {
        switch self {
        // Authentication
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .invalidCredentials:
            return "Invalid email or password"
        case .accountLocked(let remaining):
            let minutes = Int(remaining / 60)
            return "Account locked. Try again in \(minutes) minute\(minutes == 1 ? "" : "s")"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricFailed:
            return "Biometric authentication failed"
        case .sessionExpired:
            return "Your session has expired. Please log in again"
        case .pinNotSet:
            return "PIN has not been set up"
        case .pinTooWeak:
            return "PIN is too weak. Avoid sequential or repeated digits"
        case .invalidPIN:
            return "Incorrect PIN"

        // Validation
        case .validationFailed(let field, let message):
            return "\(field): \(message)"
        case .requiredFieldMissing(let field):
            return "\(field) is required"
        case .invalidFormat(let field, let expected):
            return "\(field) format is invalid. Expected: \(expected)"
        case .valueTooLong(let field, let maxLength):
            return "\(field) exceeds maximum length of \(maxLength) characters"
        case .valueTooShort(let field, let minLength):
            return "\(field) must be at least \(minLength) characters"

        // Persistence
        case .persistenceError:
            return "Failed to save data"
        case .saveError(let entity):
            return "Failed to save \(entity)"
        case .fetchError(let entity):
            return "Failed to load \(entity)"
        case .deleteError(let entity):
            return "Failed to delete \(entity)"
        case .migrationError:
            return "Database migration failed"
        case .dataCorruption:
            return "Data appears to be corrupted"

        // Network
        case .networkUnavailable:
            return "No internet connection"
        case .networkTimeout:
            return "Request timed out"
        case .serverError(let statusCode):
            return "Server error (code: \(statusCode))"
        case .invalidResponse:
            return "Received invalid response from server"
        case .networkError:
            return "Network error occurred"

        // Security
        case .keychainError:
            return "Failed to access secure storage"
        case .encryptionError:
            return "Failed to encrypt data"
        case .decryptionError:
            return "Failed to decrypt data"
        case .unauthorizedAccess:
            return "You don't have permission to perform this action"

        // File
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .fileReadError(let path):
            return "Failed to read file: \(path)"
        case .fileWriteError(let path):
            return "Failed to write file: \(path)"
        case .fileTooLarge(let maxSize):
            let mb = maxSize / (1024 * 1024)
            return "File exceeds maximum size of \(mb)MB"
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"

        // General
        case .unknown:
            return "An unexpected error occurred"
        case .operationCancelled:
            return "Operation was cancelled"
        case .notImplemented(let feature):
            return "\(feature) is not yet available"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        // Authentication
        case .invalidCredentials:
            return "Please check your email and password and try again"
        case .accountLocked:
            return "Wait for the lockout period to end, then try again"
        case .biometricNotAvailable:
            return "Enable Face ID or Touch ID in device settings, or use PIN/password instead"
        case .biometricFailed:
            return "Try again or use an alternative login method"
        case .sessionExpired:
            return "Please log in again to continue"
        case .pinNotSet:
            return "Set up a PIN in Settings > Security"
        case .pinTooWeak:
            return "Choose a PIN that doesn't use sequential (1234) or repeated (1111) digits"

        // Validation
        case .requiredFieldMissing:
            return "Please fill in all required fields"
        case .invalidFormat(_, let expected):
            return "Please enter a valid \(expected)"

        // Persistence
        case .persistenceError, .saveError, .fetchError, .deleteError:
            return "Try again. If the problem persists, restart the app"
        case .migrationError:
            return "Please update to the latest version of the app"
        case .dataCorruption:
            return "Contact support for assistance"

        // Network
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .networkTimeout:
            return "Check your connection and try again"
        case .serverError:
            return "Try again later. If the problem persists, contact support"

        // Security
        case .keychainError:
            return "Try logging out and back in. If the problem persists, reinstall the app"
        case .unauthorizedAccess:
            return "Contact your administrator for access"

        // File
        case .fileTooLarge(let maxSize):
            let mb = maxSize / (1024 * 1024)
            return "Choose a file smaller than \(mb)MB"
        case .unsupportedFileType:
            return "Choose a supported file type"

        // General
        case .unknown:
            return "Please try again. If the problem persists, restart the app"
        case .operationCancelled:
            return nil

        default:
            return nil
        }
    }

    var failureReason: String? {
        switch self {
        case .persistenceError(let underlying):
            return underlying.localizedDescription
        case .networkError(let underlying):
            return underlying.localizedDescription
        case .keychainError(let underlying):
            return underlying.localizedDescription
        case .unknown(let underlying):
            return underlying?.localizedDescription
        default:
            return nil
        }
    }

    // MARK: - Equatable

    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
             (.biometricNotAvailable, .biometricNotAvailable),
             (.biometricFailed, .biometricFailed),
             (.sessionExpired, .sessionExpired),
             (.pinNotSet, .pinNotSet),
             (.pinTooWeak, .pinTooWeak),
             (.invalidPIN, .invalidPIN),
             (.networkUnavailable, .networkUnavailable),
             (.networkTimeout, .networkTimeout),
             (.invalidResponse, .invalidResponse),
             (.encryptionError, .encryptionError),
             (.decryptionError, .decryptionError),
             (.unauthorizedAccess, .unauthorizedAccess),
             (.migrationError, .migrationError),
             (.dataCorruption, .dataCorruption),
             (.operationCancelled, .operationCancelled):
            return true

        case (.authenticationFailed(let l), .authenticationFailed(let r)),
             (.validationFailed(let l, _), .validationFailed(let r, _)),
             (.requiredFieldMissing(let l), .requiredFieldMissing(let r)),
             (.saveError(let l), .saveError(let r)),
             (.fetchError(let l), .fetchError(let r)),
             (.deleteError(let l), .deleteError(let r)),
             (.fileNotFound(let l), .fileNotFound(let r)),
             (.fileReadError(let l), .fileReadError(let r)),
             (.fileWriteError(let l), .fileWriteError(let r)),
             (.unsupportedFileType(let l), .unsupportedFileType(let r)),
             (.notImplemented(let l), .notImplemented(let r)):
            return l == r

        case (.accountLocked(let l), .accountLocked(let r)):
            return abs(l - r) < 1 // Within 1 second

        case (.serverError(let l), .serverError(let r)),
             (.fileTooLarge(let l), .fileTooLarge(let r)),
             (.valueTooLong(_, let l), .valueTooLong(_, let r)),
             (.valueTooShort(_, let l), .valueTooShort(_, let r)):
            return l == r

        default:
            return false
        }
    }
}

// MARK: - Error Conversion

extension AppError {

    /// Creates an AppError from a generic Error
    /// - Parameter error: The error to convert
    /// - Returns: An appropriate AppError
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        let nsError = error as NSError

        // Check for common error domains
        switch nsError.domain {
        case NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkUnavailable
            case NSURLErrorTimedOut:
                return .networkTimeout
            default:
                return .networkError(underlying: error)
            }

        case NSOSStatusErrorDomain:
            return .keychainError(underlying: error)

        default:
            return .unknown(underlying: error)
        }
    }
}

// MARK: - Convenience Initializers

extension AppError {

    /// Creates a validation error for an empty required field
    static func emptyField(_ fieldName: String) -> AppError {
        return .requiredFieldMissing(field: fieldName)
    }

    /// Creates a validation error for invalid email format
    static func invalidEmail() -> AppError {
        return .invalidFormat(field: "Email", expected: "email address")
    }

    /// Creates a validation error for invalid phone format
    static func invalidPhone() -> AppError {
        return .invalidFormat(field: "Phone", expected: "phone number")
    }

    /// Creates a CoreData save error
    static func coreDateSaveError(_ error: Error) -> AppError {
        return .persistenceError(underlying: error)
    }
}
