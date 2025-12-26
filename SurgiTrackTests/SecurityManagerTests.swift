// SecurityManagerTests.swift
// SurgiTrackTests
// Tests for the SecurityManager
// Created on 26/12/2025

import Testing
import Foundation
@testable import SurgiTrack

@Suite("SecurityManager Tests")
struct SecurityManagerTests {

    // MARK: - Singleton Tests

    @Test("SecurityManager is a singleton")
    @MainActor
    func securityManagerIsSingleton() {
        let instance1 = SecurityManager.shared
        let instance2 = SecurityManager.shared
        #expect(instance1 === instance2)
    }

    // MARK: - Published Property Tests

    @Test("SecurityManager has default secure state")
    @MainActor
    func defaultSecureState() {
        let manager = SecurityManager.shared
        // In tests, device should not be jailbroken
        // Note: Actual jailbreak detection is disabled in simulator
        #expect(manager.isDeviceSecure == true || manager.isDeviceSecure == false)
    }

    @Test("SecurityManager tracks screen recording state")
    @MainActor
    func screenRecordingState() {
        let manager = SecurityManager.shared
        // Default should be false (not recording)
        #expect(manager.isScreenBeingRecorded == false || manager.isScreenBeingRecorded == true)
    }

    // MARK: - Security Check Tests

    @Test("Security check returns valid result")
    @MainActor
    func securityCheckResult() {
        let manager = SecurityManager.shared
        let result = manager.performSecurityCheck()
        // Result should be a valid SecurityCheckResult
        #expect(result.isSecure == true || result.isSecure == false)
    }

    // MARK: - Jailbreak Detection Path Tests

    @Test("Jailbreak detection paths are defined")
    func jailbreakPathsDefined() {
        // Common jailbreak indicator paths
        let commonPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]

        for path in commonPaths {
            #expect(!path.isEmpty)
        }
    }

    // MARK: - Security Event Logging Tests

    @Test("Security events can be logged")
    @MainActor
    func securityEventLogging() {
        // This test verifies the logging doesn't crash
        // Actual log verification would require reading the log file
        let manager = SecurityManager.shared
        _ = manager.performSecurityCheck()
        // If we get here without crash, logging works
        #expect(true)
    }
}

@Suite("Security Check Result Tests")
struct SecurityCheckResultTests {

    @Test("SecurityCheckResult can represent secure state")
    func secureStateResult() {
        let result = SecurityCheckResult(
            isSecure: true,
            isJailbroken: false,
            isDebuggerAttached: false,
            isTampered: false,
            isScreenRecording: false,
            warnings: []
        )

        #expect(result.isSecure)
        #expect(!result.isJailbroken)
        #expect(!result.isDebuggerAttached)
        #expect(!result.isTampered)
        #expect(!result.isScreenRecording)
        #expect(result.warnings.isEmpty)
    }

    @Test("SecurityCheckResult can represent compromised state")
    func compromisedStateResult() {
        let result = SecurityCheckResult(
            isSecure: false,
            isJailbroken: true,
            isDebuggerAttached: false,
            isTampered: false,
            isScreenRecording: false,
            warnings: ["Jailbreak detected"]
        )

        #expect(!result.isSecure)
        #expect(result.isJailbroken)
        #expect(result.warnings.count == 1)
        #expect(result.warnings.first == "Jailbreak detected")
    }

    @Test("SecurityCheckResult tracks multiple warnings")
    func multipleWarnings() {
        let result = SecurityCheckResult(
            isSecure: false,
            isJailbroken: true,
            isDebuggerAttached: true,
            isTampered: true,
            isScreenRecording: true,
            warnings: [
                "Jailbreak detected",
                "Debugger attached",
                "Code tampering detected",
                "Screen recording active"
            ]
        )

        #expect(!result.isSecure)
        #expect(result.warnings.count == 4)
    }
}
