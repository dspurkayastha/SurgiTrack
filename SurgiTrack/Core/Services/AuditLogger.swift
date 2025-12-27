// AuditLogger.swift
// SurgiTrack
// HIPAA-compliant audit logging for PHI access
// Created on 26/12/2025

import Foundation
import CoreData

/// HIPAA-compliant audit logger for tracking access to Protected Health Information (PHI).
/// Records all access, modifications, and exports of patient data.
final class AuditLogger {

    // MARK: - Singleton

    static let shared = AuditLogger()

    private init() {
        // Ensure audit log directory exists
        createAuditLogDirectoryIfNeeded()
    }

    // MARK: - Audit Event Types

    /// Types of auditable actions
    enum AuditAction: String, Codable {
        // Access events
        case view = "VIEW"
        case search = "SEARCH"
        case list = "LIST"

        // Modification events
        case create = "CREATE"
        case update = "UPDATE"
        case delete = "DELETE"

        // Export/Print events
        case export = "EXPORT"
        case print = "PRINT"
        case share = "SHARE"

        // Authentication events
        case login = "LOGIN"
        case logout = "LOGOUT"
        case loginFailed = "LOGIN_FAILED"
        case sessionTimeout = "SESSION_TIMEOUT"

        // Administrative events
        case settingsChange = "SETTINGS_CHANGE"
        case permissionChange = "PERMISSION_CHANGE"

        // Security events
        case securityAlert = "SECURITY_ALERT"
    }

    /// Types of resources being accessed
    enum ResourceType: String, Codable {
        case patient = "PATIENT"
        case appointment = "APPOINTMENT"
        case medicalTest = "MEDICAL_TEST"
        case operativeData = "OPERATIVE_DATA"
        case prescription = "PRESCRIPTION"
        case dischargeSummary = "DISCHARGE_SUMMARY"
        case attachment = "ATTACHMENT"
        case riskCalculation = "RISK_CALCULATION"
        case userProfile = "USER_PROFILE"
        case settings = "SETTINGS"
        case system = "SYSTEM"
        case referral = "REFERRAL"
    }

    /// Outcome of the audited action
    enum Outcome: String, Codable {
        case success = "SUCCESS"
        case failure = "FAILURE"
        case denied = "DENIED"
    }

    // MARK: - Audit Event Model

    /// Represents a single audit log event
    struct AuditEvent: Codable {
        let id: UUID
        let timestamp: Date
        let action: AuditAction
        let resourceType: ResourceType
        let resourceId: String?
        let resourceDescription: String?
        let userId: String?
        let userName: String?
        let deviceId: String
        let ipAddress: String?
        let outcome: Outcome
        let details: [String: String]?
        let errorMessage: String?

        init(
            action: AuditAction,
            resourceType: ResourceType,
            resourceId: String? = nil,
            resourceDescription: String? = nil,
            userId: String? = nil,
            userName: String? = nil,
            outcome: Outcome = .success,
            details: [String: String]? = nil,
            errorMessage: String? = nil
        ) {
            self.id = UUID()
            self.timestamp = Date()
            self.action = action
            self.resourceType = resourceType
            self.resourceId = resourceId
            self.resourceDescription = resourceDescription
            self.userId = userId
            self.userName = userName
            self.deviceId = AuditLogger.deviceIdentifier
            self.ipAddress = AuditLogger.currentIPAddress
            self.outcome = outcome
            self.details = details
            self.errorMessage = errorMessage
        }
    }

    // MARK: - Properties

    private let logQueue = DispatchQueue(label: "com.surgitrack.auditlog", qos: .utility)
    private var currentUserId: String?
    private var currentUserName: String?
    private let maxLogFileSize = 10 * 1024 * 1024 // 10MB
    private let maxLogFiles = 30 // Keep 30 days of logs

    /// The current device identifier
    private static var deviceIdentifier: String {
        // Use identifierForVendor for device tracking
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    /// Gets the current IP address (placeholder - would need network framework)
    private static var currentIPAddress: String? {
        return "local" // In production, implement actual IP detection
    }

    // MARK: - Configuration

    /// Sets the current user for audit logging
    /// - Parameters:
    ///   - userId: The user's unique identifier
    ///   - userName: The user's display name
    func setCurrentUser(userId: String?, userName: String?) {
        logQueue.async {
            self.currentUserId = userId
            self.currentUserName = userName
        }
    }

    /// Clears the current user (on logout)
    func clearCurrentUser() {
        logQueue.async {
            self.currentUserId = nil
            self.currentUserName = nil
        }
    }

    // MARK: - Logging Methods

    /// Logs an audit event
    /// - Parameter event: The event to log
    func log(_ event: AuditEvent) {
        guard AppConfiguration.Features.auditLoggingEnabled else { return }

        logQueue.async {
            self.writeEventToLog(event)
            Logger.info("Audit: \(event.action.rawValue) \(event.resourceType.rawValue) \(event.resourceId ?? "N/A")", category: .audit)
        }
    }

    /// Logs a view action
    func logView(
        resourceType: ResourceType,
        resourceId: String,
        resourceDescription: String? = nil,
        details: [String: String]? = nil
    ) {
        let event = AuditEvent(
            action: .view,
            resourceType: resourceType,
            resourceId: resourceId,
            resourceDescription: resourceDescription,
            userId: currentUserId,
            userName: currentUserName,
            details: details
        )
        log(event)
    }

    /// Logs a search action
    func logSearch(
        resourceType: ResourceType,
        searchTerm: String,
        resultCount: Int
    ) {
        let event = AuditEvent(
            action: .search,
            resourceType: resourceType,
            userId: currentUserId,
            userName: currentUserName,
            details: [
                "searchTerm": searchTerm,
                "resultCount": String(resultCount)
            ]
        )
        log(event)
    }

    /// Logs a create action
    func logCreate(
        resourceType: ResourceType,
        resourceId: String,
        resourceDescription: String? = nil,
        outcome: Outcome = .success,
        errorMessage: String? = nil
    ) {
        let event = AuditEvent(
            action: .create,
            resourceType: resourceType,
            resourceId: resourceId,
            resourceDescription: resourceDescription,
            userId: currentUserId,
            userName: currentUserName,
            outcome: outcome,
            errorMessage: errorMessage
        )
        log(event)
    }

    /// Logs an update action
    func logUpdate(
        resourceType: ResourceType,
        resourceId: String,
        resourceDescription: String? = nil,
        changedFields: [String]? = nil,
        outcome: Outcome = .success,
        errorMessage: String? = nil
    ) {
        var details: [String: String]? = nil
        if let fields = changedFields {
            details = ["changedFields": fields.joined(separator: ", ")]
        }

        let event = AuditEvent(
            action: .update,
            resourceType: resourceType,
            resourceId: resourceId,
            resourceDescription: resourceDescription,
            userId: currentUserId,
            userName: currentUserName,
            outcome: outcome,
            details: details,
            errorMessage: errorMessage
        )
        log(event)
    }

    /// Logs a delete action
    func logDelete(
        resourceType: ResourceType,
        resourceId: String,
        resourceDescription: String? = nil,
        outcome: Outcome = .success,
        errorMessage: String? = nil
    ) {
        let event = AuditEvent(
            action: .delete,
            resourceType: resourceType,
            resourceId: resourceId,
            resourceDescription: resourceDescription,
            userId: currentUserId,
            userName: currentUserName,
            outcome: outcome,
            errorMessage: errorMessage
        )
        log(event)
    }

    /// Logs an export action
    func logExport(
        resourceType: ResourceType,
        resourceId: String? = nil,
        exportFormat: String,
        recordCount: Int? = nil
    ) {
        var details: [String: String] = ["format": exportFormat]
        if let count = recordCount {
            details["recordCount"] = String(count)
        }

        let event = AuditEvent(
            action: .export,
            resourceType: resourceType,
            resourceId: resourceId,
            userId: currentUserId,
            userName: currentUserName,
            details: details
        )
        log(event)
    }

    /// Logs a print action
    func logPrint(
        resourceType: ResourceType,
        resourceId: String,
        resourceDescription: String? = nil
    ) {
        let event = AuditEvent(
            action: .print,
            resourceType: resourceType,
            resourceId: resourceId,
            resourceDescription: resourceDescription,
            userId: currentUserId,
            userName: currentUserName
        )
        log(event)
    }

    /// Logs a login event
    func logLogin(userId: String, userName: String?, outcome: Outcome, errorMessage: String? = nil) {
        let event = AuditEvent(
            action: outcome == .success ? .login : .loginFailed,
            resourceType: .system,
            userId: userId,
            userName: userName,
            outcome: outcome,
            errorMessage: errorMessage
        )
        log(event)
    }

    /// Logs a logout event
    func logLogout() {
        let event = AuditEvent(
            action: .logout,
            resourceType: .system,
            userId: currentUserId,
            userName: currentUserName
        )
        log(event)
    }

    /// Logs a session timeout
    func logSessionTimeout() {
        let event = AuditEvent(
            action: .sessionTimeout,
            resourceType: .system,
            userId: currentUserId,
            userName: currentUserName
        )
        log(event)
    }

    /// Logs a security event
    func logSecurityEvent(action: String, details: [String: Any]) {
        let stringDetails = details.mapValues { "\($0)" }
        var allDetails = stringDetails
        allDetails["securityAction"] = action

        let event = AuditEvent(
            action: .securityAlert,
            resourceType: .system,
            userId: currentUserId,
            userName: currentUserName,
            details: allDetails
        )
        log(event)
    }

    // MARK: - File Operations

    private var auditLogDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("AuditLogs", isDirectory: true)
    }

    private func createAuditLogDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: auditLogDirectory.path) {
            try? fileManager.createDirectory(at: auditLogDirectory, withIntermediateDirectories: true)
        }
    }

    private func currentLogFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return "audit_\(dateFormatter.string(from: Date())).jsonl"
    }

    private func writeEventToLog(_ event: AuditEvent) {
        let logFile = auditLogDirectory.appendingPathComponent(currentLogFileName())

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let eventData = try encoder.encode(event)

            guard var eventString = String(data: eventData, encoding: .utf8) else { return }
            eventString += "\n"

            if FileManager.default.fileExists(atPath: logFile.path) {
                let fileHandle = try FileHandle(forWritingTo: logFile)
                fileHandle.seekToEndOfFile()
                if let data = eventString.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try eventString.write(to: logFile, atomically: true, encoding: .utf8)
            }

            // Rotate logs if needed
            rotateLogsIfNeeded()
        } catch {
            Logger.error("Failed to write audit log", error: error, category: .audit)
        }
    }

    private func rotateLogsIfNeeded() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: auditLogDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        // Sort by creation date, oldest first
        let sortedFiles = files.sorted { file1, file2 in
            let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 < date2
        }

        // Remove old files if we have too many
        if sortedFiles.count > maxLogFiles {
            let filesToDelete = sortedFiles.prefix(sortedFiles.count - maxLogFiles)
            for file in filesToDelete {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    // MARK: - Log Retrieval (for compliance/admin)

    /// Retrieves audit logs for a specific date
    /// - Parameter date: The date to retrieve logs for
    /// - Returns: Array of audit events
    func getLogsForDate(_ date: Date) -> [AuditEvent] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "audit_\(dateFormatter.string(from: date)).jsonl"
        let logFile = auditLogDirectory.appendingPathComponent(fileName)

        guard let contents = try? String(contentsOf: logFile, encoding: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return contents.split(separator: "\n").compactMap { line in
            guard let data = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(AuditEvent.self, from: data)
        }
    }

    /// Exports all audit logs for a date range
    /// - Parameters:
    ///   - startDate: Start of the range
    ///   - endDate: End of the range
    /// - Returns: Combined array of all events
    func exportLogs(from startDate: Date, to endDate: Date) -> [AuditEvent] {
        var allEvents: [AuditEvent] = []
        var currentDate = startDate

        let calendar = Calendar.current
        while currentDate <= endDate {
            allEvents.append(contentsOf: getLogsForDate(currentDate))
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return allEvents.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - UIDevice Extension

import UIKit

extension AuditLogger {
    /// Gets device information for audit context
    static var deviceInfo: [String: String] {
        return [
            "model": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "name": UIDevice.current.name
        ]
    }
}
