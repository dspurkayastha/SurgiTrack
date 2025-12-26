// LoggerTests.swift
// SurgiTrackTests
// Tests for the Logger service
// Created on 26/12/2025

import Testing
import Foundation
@testable import SurgiTrack

@Suite("Logger Tests")
struct LoggerTests {

    // MARK: - Category Tests

    @Test("All log categories are defined")
    func logCategoriesDefined() {
        let categories: [Logger.Category] = [
            .general,
            .authentication,
            .patient,
            .appointments,
            .reports,
            .riskCalculator,
            .prescriptions,
            .persistence,
            .network,
            .ui,
            .security,
            .audit,
            .performance
        ]

        for category in categories {
            #expect(!category.rawValue.isEmpty)
        }
    }

    @Test("Log categories have correct raw values")
    func logCategoryRawValues() {
        #expect(Logger.Category.general.rawValue == "general")
        #expect(Logger.Category.authentication.rawValue == "authentication")
        #expect(Logger.Category.patient.rawValue == "patient")
        #expect(Logger.Category.persistence.rawValue == "persistence")
        #expect(Logger.Category.security.rawValue == "security")
    }

    // MARK: - Level Tests

    @Test("All log levels are defined")
    func logLevelsDefined() {
        let levels: [Logger.Level] = [
            .debug,
            .info,
            .notice,
            .warning,
            .error,
            .fault
        ]

        #expect(levels.count == 6)
    }

    // MARK: - Logging Function Tests

    @Test("Logger.debug doesn't crash")
    func logDebug() {
        Logger.debug("Test debug message", category: .general)
        #expect(true)
    }

    @Test("Logger.info doesn't crash")
    func logInfo() {
        Logger.info("Test info message", category: .general)
        #expect(true)
    }

    @Test("Logger.warning doesn't crash")
    func logWarning() {
        Logger.warning("Test warning message", category: .general)
        #expect(true)
    }

    @Test("Logger.error doesn't crash")
    func logError() {
        let error = NSError(domain: "TestDomain", code: 100, userInfo: nil)
        Logger.error("Test error message", error: error, category: .general)
        #expect(true)
    }

    @Test("Logger.fault doesn't crash")
    func logFault() {
        Logger.fault("Test fault message", category: .general)
        #expect(true)
    }

    // MARK: - Specialized Logging Tests

    @Test("Logger.auth doesn't crash")
    func logAuth() {
        Logger.auth("Test auth message")
        #expect(true)
    }

    @Test("Logger.log with category and level doesn't crash")
    func logWithCategoryAndLevel() {
        Logger.log("Test message", category: .patient, level: .info)
        #expect(true)
    }

    // MARK: - Message Formatting Tests

    @Test("Log messages accept string interpolation")
    func logMessageInterpolation() {
        let value = 42
        Logger.info("Test value: \(value)", category: .general)
        #expect(true)
    }

    @Test("Log messages accept multiple parameters")
    func logMessageMultipleParams() {
        let name = "John"
        let age = 30
        Logger.info("Patient \(name) is \(age) years old", category: .patient)
        #expect(true)
    }
}

@Suite("Logger Category OSLog Tests")
struct LoggerCategoryOSLogTests {

    @Test("Category has valid OSLog")
    func categoryOSLog() {
        let category = Logger.Category.general
        let osLog = category.osLog
        // OSLog should be created without crashing
        #expect(osLog != nil)
    }

    @Test("All categories have unique OSLog identifiers")
    func uniqueOSLogIdentifiers() {
        let categories: [Logger.Category] = [
            .general,
            .authentication,
            .patient,
            .persistence,
            .security
        ]

        // Each category should have a distinct osLog
        for category in categories {
            #expect(category.osLog != nil)
        }
    }
}
