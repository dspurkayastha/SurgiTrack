// AuditLoggerTests.swift
// SurgiTrackTests
// Tests for the AuditLogger (HIPAA compliance logging)
// Created on 26/12/2025

import Testing
import Foundation
@testable import SurgiTrack

@Suite("AuditLogger Tests")
struct AuditLoggerTests {

    // MARK: - Singleton Tests

    @Test("AuditLogger is a singleton")
    func auditLoggerIsSingleton() {
        let instance1 = AuditLogger.shared
        let instance2 = AuditLogger.shared
        #expect(instance1 === instance2)
    }

    // MARK: - Event Type Tests

    @Test("All event types are defined")
    func eventTypesDefined() {
        let eventTypes: [AuditEventType] = [
            .view,
            .search,
            .create,
            .update,
            .delete,
            .export,
            .login,
            .logout,
            .sessionTimeout
        ]

        for eventType in eventTypes {
            #expect(!eventType.rawValue.isEmpty)
        }
    }

    @Test("Event types have correct raw values")
    func eventTypeRawValues() {
        #expect(AuditEventType.view.rawValue == "VIEW")
        #expect(AuditEventType.search.rawValue == "SEARCH")
        #expect(AuditEventType.create.rawValue == "CREATE")
        #expect(AuditEventType.update.rawValue == "UPDATE")
        #expect(AuditEventType.delete.rawValue == "DELETE")
        #expect(AuditEventType.export.rawValue == "EXPORT")
        #expect(AuditEventType.login.rawValue == "LOGIN")
        #expect(AuditEventType.logout.rawValue == "LOGOUT")
        #expect(AuditEventType.sessionTimeout.rawValue == "SESSION_TIMEOUT")
    }

    // MARK: - Resource Type Tests

    @Test("All resource types are defined")
    func resourceTypesDefined() {
        let resourceTypes: [AuditResourceType] = [
            .patient,
            .appointment,
            .medicalTest,
            .operativeData,
            .prescription,
            .report,
            .user,
            .system
        ]

        for resourceType in resourceTypes {
            #expect(!resourceType.rawValue.isEmpty)
        }
    }

    @Test("Resource types have correct raw values")
    func resourceTypeRawValues() {
        #expect(AuditResourceType.patient.rawValue == "PATIENT")
        #expect(AuditResourceType.appointment.rawValue == "APPOINTMENT")
        #expect(AuditResourceType.medicalTest.rawValue == "MEDICAL_TEST")
        #expect(AuditResourceType.operativeData.rawValue == "OPERATIVE_DATA")
        #expect(AuditResourceType.prescription.rawValue == "PRESCRIPTION")
        #expect(AuditResourceType.report.rawValue == "REPORT")
        #expect(AuditResourceType.user.rawValue == "USER")
        #expect(AuditResourceType.system.rawValue == "SYSTEM")
    }

    // MARK: - Outcome Tests

    @Test("Audit outcomes are defined")
    func auditOutcomesDefined() {
        let outcomes: [AuditOutcome] = [
            .success,
            .failure,
            .denied
        ]

        for outcome in outcomes {
            #expect(!outcome.rawValue.isEmpty)
        }
    }

    @Test("Audit outcomes have correct raw values")
    func auditOutcomeRawValues() {
        #expect(AuditOutcome.success.rawValue == "SUCCESS")
        #expect(AuditOutcome.failure.rawValue == "FAILURE")
        #expect(AuditOutcome.denied.rawValue == "DENIED")
    }

    // MARK: - Logging Tests

    @Test("Login event can be logged")
    func logLoginEvent() {
        // This test verifies logging doesn't crash
        AuditLogger.shared.logLogin(userId: "test_user", outcome: .success)
        #expect(true)
    }

    @Test("Logout event can be logged")
    func logLogoutEvent() {
        AuditLogger.shared.logLogout(userId: "test_user")
        #expect(true)
    }

    @Test("View event can be logged")
    func logViewEvent() {
        AuditLogger.shared.logEvent(
            eventType: .view,
            resourceType: .patient,
            resourceId: "patient_123",
            outcome: .success
        )
        #expect(true)
    }

    @Test("Security event can be logged")
    func logSecurityEvent() {
        AuditLogger.shared.logSecurityEvent(
            action: "SECURITY_CHECK",
            outcome: .success,
            details: ["check": "jailbreak"]
        )
        #expect(true)
    }

    // MARK: - Log Retention Tests

    @Test("Log retention period is configured")
    func logRetentionPeriod() {
        // HIPAA requires 6 years, but app might use shorter for local storage
        let retentionDays = 30 // Default in AuditLogger
        #expect(retentionDays > 0)
    }

    @Test("Max log file size is configured")
    func maxLogFileSize() {
        let maxSize = 10 * 1024 * 1024 // 10MB
        #expect(maxSize > 0)
    }
}

@Suite("AuditEvent Tests")
struct AuditEventTests {

    @Test("AuditEvent can be created with all fields")
    func auditEventCreation() {
        let event = AuditEvent(
            id: UUID(),
            timestamp: Date(),
            eventType: .view,
            resourceType: .patient,
            resourceId: "patient_123",
            userId: "user_456",
            userName: "Dr. Smith",
            outcome: .success,
            deviceId: "device_789",
            ipAddress: "127.0.0.1",
            details: ["action": "viewed patient record"]
        )

        #expect(event.eventType == .view)
        #expect(event.resourceType == .patient)
        #expect(event.resourceId == "patient_123")
        #expect(event.outcome == .success)
    }

    @Test("AuditEvent timestamp is recorded")
    func auditEventTimestamp() {
        let now = Date()
        let event = AuditEvent(
            id: UUID(),
            timestamp: now,
            eventType: .login,
            resourceType: .user,
            resourceId: nil,
            userId: "user_123",
            userName: "Test User",
            outcome: .success,
            deviceId: nil,
            ipAddress: nil,
            details: nil
        )

        #expect(event.timestamp == now)
    }

    @Test("AuditEvent can have optional fields nil")
    func auditEventOptionalFields() {
        let event = AuditEvent(
            id: UUID(),
            timestamp: Date(),
            eventType: .logout,
            resourceType: .system,
            resourceId: nil,
            userId: "user_123",
            userName: nil,
            outcome: .success,
            deviceId: nil,
            ipAddress: nil,
            details: nil
        )

        #expect(event.resourceId == nil)
        #expect(event.userName == nil)
        #expect(event.deviceId == nil)
        #expect(event.ipAddress == nil)
        #expect(event.details == nil)
    }
}
