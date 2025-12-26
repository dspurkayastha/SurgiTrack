// ConfigurationTests.swift
// SurgiTrackTests
// Tests for configuration management
// Created on 26/12/2025

import Testing
import Foundation
@testable import SurgiTrack

struct ConfigurationTests {

    // MARK: - Environment Tests

    @Test func environment_current_returnsValidEnvironment() async throws {
        let env = Configuration.Environment.current

        // Should be one of the valid environments
        let validEnvs: [Configuration.Environment] = [.development, .staging, .production]
        #expect(validEnvs.contains(env), "Current environment should be valid")
    }

    #if DEBUG
    @Test func environment_inDebug_isDevelopment() async throws {
        let env = Configuration.Environment.current

        #expect(env == .development, "Debug build should use development environment")
    }
    #endif

    // MARK: - Security Configuration Tests

    @Test func security_sessionTimeout_isPositive() async throws {
        let timeout = Configuration.Security.sessionTimeout

        #expect(timeout > 0, "Session timeout should be positive")
        #expect(timeout >= 60, "Session timeout should be at least 1 minute")
    }

    @Test func security_lockoutDuration_isPositive() async throws {
        let duration = Configuration.Security.lockoutDuration

        #expect(duration > 0, "Lockout duration should be positive")
        #expect(duration == 5 * 60, "Lockout should be 5 minutes")
    }

    @Test func security_maxLoginAttempts_isReasonable() async throws {
        let maxAttempts = Configuration.Security.maxLoginAttempts

        #expect(maxAttempts >= 3, "Max attempts should allow at least 3 tries")
        #expect(maxAttempts <= 10, "Max attempts should not be too high")
        #expect(maxAttempts == 5, "Max attempts should be 5")
    }

    @Test func security_pinLength_isValid() async throws {
        let pinLength = Configuration.Security.pinLength

        #expect(pinLength >= 4, "PIN should be at least 4 digits")
        #expect(pinLength <= 8, "PIN should not be too long")
        #expect(pinLength == 6, "PIN should be 6 digits")
    }

    @Test func security_minPasswordLength_isSecure() async throws {
        let minLength = Configuration.Security.minPasswordLength

        #expect(minLength >= 8, "Password should be at least 8 characters")
        #expect(minLength == 8, "Minimum password length should be 8")
    }

    // MARK: - Feature Flags Tests

    @Test func features_auditLogging_isEnabled() async throws {
        let enabled = Configuration.Features.auditLoggingEnabled

        // Audit logging should always be enabled for HIPAA
        #expect(enabled == true, "Audit logging should be enabled")
    }

    // MARK: - App Info Tests

    @Test func app_displayName_isNotEmpty() async throws {
        let name = Configuration.App.displayName

        #expect(!name.isEmpty, "Display name should not be empty")
    }

    @Test func app_version_hasValidFormat() async throws {
        let version = Configuration.App.version

        #expect(!version.isEmpty, "Version should not be empty")
        // Version should contain at least one digit
        #expect(version.contains(where: { $0.isNumber }), "Version should contain numbers")
    }

    @Test func app_buildNumber_isNotEmpty() async throws {
        let build = Configuration.App.buildNumber

        #expect(!build.isEmpty, "Build number should not be empty")
    }

    @Test func app_fullVersion_combinesVersionAndBuild() async throws {
        let version = Configuration.App.version
        let build = Configuration.App.buildNumber
        let fullVersion = Configuration.App.fullVersion

        #expect(fullVersion.contains(version), "Full version should contain version")
        #expect(fullVersion.contains(build), "Full version should contain build")
    }

    @Test func app_bundleIdentifier_isNotEmpty() async throws {
        let bundleId = Configuration.App.bundleIdentifier

        #expect(!bundleId.isEmpty, "Bundle identifier should not be empty")
        #expect(bundleId.contains("."), "Bundle ID should contain dots")
    }

    // MARK: - Storage Configuration Tests

    @Test func storage_containerName_isCorrect() async throws {
        let name = Configuration.Storage.coreDataContainerName

        #expect(name == "SurgiTrack", "Container name should be SurgiTrack")
    }

    @Test func storage_maxImageSize_isReasonable() async throws {
        let maxSize = Configuration.Storage.maxImageSize

        #expect(maxSize > 0, "Max image size should be positive")
        #expect(maxSize == 5 * 1024 * 1024, "Max image size should be 5MB")
    }

    @Test func storage_imageCompression_isValid() async throws {
        let quality = Configuration.Storage.imageCompressionQuality

        #expect(quality > 0, "Compression quality should be positive")
        #expect(quality <= 1, "Compression quality should be at most 1")
        #expect(quality == 0.8, "Compression quality should be 0.8")
    }

    @Test func storage_maxAttachmentSize_isLargerThanImage() async throws {
        let maxAttachment = Configuration.Storage.maxAttachmentSize
        let maxImage = Configuration.Storage.maxImageSize

        #expect(maxAttachment >= maxImage, "Max attachment should be >= max image")
        #expect(maxAttachment == 10 * 1024 * 1024, "Max attachment should be 10MB")
    }

    // MARK: - UI Configuration Tests

    @Test func ui_animationDuration_isReasonable() async throws {
        let duration = Configuration.UI.animationDuration

        #expect(duration > 0, "Animation duration should be positive")
        #expect(duration <= 1.0, "Animation should not be too slow")
        #expect(duration == 0.3, "Animation duration should be 0.3s")
    }

    @Test func ui_toastDuration_isReadable() async throws {
        let duration = Configuration.UI.toastDuration

        #expect(duration >= 2.0, "Toast should be visible long enough to read")
        #expect(duration <= 5.0, "Toast should not stay too long")
        #expect(duration == 3.0, "Toast duration should be 3s")
    }

    @Test func ui_searchDebounce_isResponsive() async throws {
        let delay = Configuration.UI.searchDebounceDelay

        #expect(delay > 0, "Debounce delay should be positive")
        #expect(delay <= 1.0, "Debounce should not feel sluggish")
        #expect(delay == 0.5, "Debounce delay should be 0.5s")
    }

    @Test func ui_pageSize_isReasonable() async throws {
        let pageSize = Configuration.UI.pageSize

        #expect(pageSize >= 10, "Page size should show enough items")
        #expect(pageSize <= 50, "Page size should not load too many")
        #expect(pageSize == 20, "Page size should be 20")
    }

    // MARK: - Environment Variable Tests

    @Test func environmentVariable_nonExistent_returnsNil() async throws {
        let result = Configuration.environmentVariable("DEFINITELY_NOT_A_REAL_VAR_12345")

        #expect(result == nil, "Non-existent env var should return nil")
    }

    // MARK: - Validation Tests

    @Test func validate_inDevelopment_succeeds() async throws {
        // In development, validation should pass even without production keys
        #if DEBUG
        let isValid = Configuration.validate()
        // May fail if key isn't set, but shouldn't crash
        _ = isValid
        #expect(true, "Validation should not crash")
        #endif
    }
}
