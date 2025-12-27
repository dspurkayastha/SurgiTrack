// Configuration.swift
// SurgiTrack
// Environment-based configuration management
// Created on 26/12/2025

import Foundation

/// Centralized configuration management for SurgiTrack.
/// Supports different environments (development, staging, production).
/// Note: Named AppConfiguration to avoid shadowing SwiftUI's ButtonStyle.Configuration
enum AppConfiguration {

    // MARK: - Environment

    /// The current build environment
    enum Environment: String {
        case development
        case staging
        case production

        /// Determines the current environment based on build configuration
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            // In a real app, this could be determined by a build flag or config file
            // For now, default to production for release builds
            return .production
            #endif
        }
    }

    /// The current environment
    static let environment = Environment.current

    // MARK: - API Configuration

    /// API configuration for Clerk authentication
    enum ClerkAPI {
        /// The Clerk publishable key for the current environment
        /// SECURITY: Keys must be provided via xcconfig files, never hardcoded
        static var publishableKey: String {
            guard let key = Bundle.main.infoDictionary?["ClerkPublishableKey"] as? String,
                  !key.isEmpty,
                  !key.hasPrefix("$(") else { // Check for unexpanded variable
                Logger.fault("Clerk API key not configured! Add CLERK_PUBLISHABLE_KEY to xcconfig.", category: .security)
                return ""
            }

            // Additional validation for production
            if environment == .production && key.contains("test") {
                Logger.fault("Test API key used in production! This is a security violation.", category: .security)
                return ""
            }

            return key
        }

        /// Validates that the API key is properly configured
        static var isConfigured: Bool {
            let key = publishableKey
            return !key.isEmpty
        }
    }

    // MARK: - Security Configuration

    /// Security-related configuration
    enum Security {
        /// Session timeout in seconds (15 minutes default)
        static var sessionTimeout: TimeInterval {
            switch environment {
            case .development:
                return 60 * 60 // 1 hour for development
            case .staging, .production:
                return 15 * 60 // 15 minutes
            }
        }

        /// Account lockout duration in seconds
        static let lockoutDuration: TimeInterval = 5 * 60 // 5 minutes

        /// Maximum failed login attempts before lockout
        static let maxLoginAttempts = 5

        /// PIN length requirement
        static let pinLength = 6

        /// Minimum password length
        static let minPasswordLength = 8

        /// Whether to require biometric confirmation for sensitive actions
        static var requireBiometricForSensitiveActions: Bool {
            switch environment {
            case .development:
                return false
            case .staging, .production:
                return true
            }
        }
    }

    // MARK: - Feature Flags

    /// Feature flags for gradual rollout
    enum Features {
        /// Whether the new Liquid Glass UI is enabled
        static var liquidGlassEnabled: Bool {
            // Enable in iOS 26+
            if #available(iOS 26, *) {
                return true
            }
            return false
        }

        /// Whether audit logging is enabled
        static var auditLoggingEnabled: Bool {
            switch environment {
            case .development:
                return true // Enable for testing
            case .staging, .production:
                return true // Always enabled in production for HIPAA
            }
        }

        /// Whether debug logging is enabled
        static var debugLoggingEnabled: Bool {
            return environment == .development
        }

        /// Whether crash reporting is enabled
        static var crashReportingEnabled: Bool {
            return environment != .development
        }

        /// Whether analytics are enabled
        static var analyticsEnabled: Bool {
            switch environment {
            case .development:
                return false
            case .staging, .production:
                return true
            }
        }
    }

    // MARK: - App Info

    /// Application information
    enum App {
        /// App display name
        static var displayName: String {
            return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "SurgiTrack"
        }

        /// App version
        static var version: String {
            return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        }

        /// Build number
        static var buildNumber: String {
            return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        }

        /// Full version string
        static var fullVersion: String {
            return "\(version) (\(buildNumber))"
        }

        /// Bundle identifier
        static var bundleIdentifier: String {
            return Bundle.main.bundleIdentifier ?? "com.surgitrack.app"
        }
    }

    // MARK: - Storage Configuration

    /// Storage-related configuration
    enum Storage {
        /// CoreData container name
        static let coreDataContainerName = "SurgiTrack"

        /// Maximum image size in bytes (5MB)
        static let maxImageSize = 5 * 1024 * 1024

        /// Image compression quality
        static let imageCompressionQuality: CGFloat = 0.8

        /// Maximum attachment size in bytes (10MB)
        static let maxAttachmentSize = 10 * 1024 * 1024

        /// Cache expiration in seconds (1 hour)
        static let cacheExpiration: TimeInterval = 60 * 60
    }

    // MARK: - UI Configuration

    /// UI-related configuration
    enum UI {
        /// Default animation duration
        static let animationDuration: TimeInterval = 0.3

        /// Toast display duration
        static let toastDuration: TimeInterval = 3.0

        /// Debounce delay for search
        static let searchDebounceDelay: TimeInterval = 0.5

        /// Minimum characters for search
        static let minSearchCharacters = 3

        /// Page size for list pagination
        static let pageSize = 20

        /// Maximum items to load at once
        static let maxLoadItems = 100
    }

    // MARK: - Validation

    /// Validates that required configuration is present
    static func validate() -> Bool {
        var isValid = true

        // Check Clerk API key
        if environment == .production && ClerkAPI.publishableKey.isEmpty {
            Logger.fault("Missing production Clerk API key", category: .security)
            isValid = false
        }

        // Add more validation as needed

        return isValid
    }
}

// MARK: - Environment Variable Access

extension AppConfiguration {

    /// Gets an environment variable value
    /// - Parameter key: The environment variable key
    /// - Returns: The value or nil if not set
    static func environmentVariable(_ key: String) -> String? {
        return ProcessInfo.processInfo.environment[key]
    }

    /// Gets a value from Info.plist
    /// - Parameter key: The plist key
    /// - Returns: The value or nil if not found
    static func plistValue<T>(_ key: String) -> T? {
        return Bundle.main.infoDictionary?[key] as? T
    }
}

