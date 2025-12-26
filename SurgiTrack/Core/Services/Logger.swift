// Logger.swift
// SurgiTrack
// Unified logging infrastructure using OSLog
// Created on 26/12/2025

import Foundation
import OSLog

/// Centralized logging service for SurgiTrack.
/// Uses Apple's OSLog for performant, privacy-aware logging.
struct Logger {

    // MARK: - Log Categories

    /// Categories for organizing log messages
    enum Category: String {
        case general = "General"
        case authentication = "Authentication"
        case patient = "Patient"
        case appointments = "Appointments"
        case reports = "Reports"
        case riskCalculator = "RiskCalculator"
        case prescriptions = "Prescriptions"
        case persistence = "Persistence"
        case network = "Network"
        case ui = "UI"
        case security = "Security"
        case audit = "Audit"
        case performance = "Performance"

        var subsystem: String {
            return "com.surgitrack.app"
        }

        var osLog: OSLog {
            return OSLog(subsystem: subsystem, category: rawValue)
        }
    }

    // MARK: - Log Levels

    /// Log levels matching OSLog types
    enum Level {
        case debug
        case info
        case notice
        case warning
        case error
        case fault

        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .notice: return .default
            case .warning: return .error  // OSLog doesn't have warning
            case .error: return .error
            case .fault: return .fault
            }
        }

        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .notice: return "📝"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .fault: return "💥"
            }
        }
    }

    // MARK: - Configuration

    /// Whether to enable console logging in debug builds
    #if DEBUG
    private static let isDebugLoggingEnabled = true
    #else
    private static let isDebugLoggingEnabled = false
    #endif

    /// Whether to include file/line info in logs
    private static let includeSourceLocation = true

    // MARK: - Logging Methods

    /// Logs a debug message (only in debug builds)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    static func debug(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }

    /// Logs an info message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    static func info(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }

    /// Logs a notice message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    static func notice(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .notice, category: category, file: file, function: function, line: line)
    }

    /// Logs a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The log category
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    static func warning(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }

    /// Logs an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object
    ///   - category: The log category
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    static func error(
        _ message: String,
        error: Error? = nil,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .error, category: category, file: file, function: function, line: line)
    }

    /// Logs a fault message (critical system errors)
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object
    ///   - category: The log category
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    static func fault(
        _ message: String,
        error: Error? = nil,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, level: .fault, category: category, file: file, function: function, line: line)
    }

    // MARK: - Convenience Methods

    /// Logs authentication-related events
    static func auth(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: level, category: .authentication, file: file, function: function, line: line)
    }

    /// Logs patient-related events
    static func patient(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: level, category: .patient, file: file, function: function, line: line)
    }

    /// Logs persistence/CoreData events
    static func persistence(_ message: String, level: Level = .info, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: level, category: .persistence, file: file, function: function, line: line)
    }

    /// Logs security-related events (for monitoring)
    static func security(_ message: String, level: Level = .notice, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: level, category: .security, file: file, function: function, line: line)
    }

    /// Logs performance-related events
    static func performance(_ message: String, duration: TimeInterval? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let duration = duration {
            fullMessage += String(format: " (%.3fms)", duration * 1000)
        }
        log(fullMessage, level: .debug, category: .performance, file: file, function: function, line: line)
    }

    // MARK: - Private Methods

    private static func log(
        _ message: String,
        level: Level,
        category: Category,
        file: String,
        function: String,
        line: Int
    ) {
        // Skip debug logs in release builds
        if level == .debug && !isDebugLoggingEnabled {
            return
        }

        let fileName = (file as NSString).lastPathComponent
        let location = includeSourceLocation ? "[\(fileName):\(line)] " : ""

        let formattedMessage = "\(level.emoji) \(location)\(message)"

        // Log to OSLog
        os_log("%{public}@", log: category.osLog, type: level.osLogType, formattedMessage)

        // Also print to console in debug builds for convenience
        #if DEBUG
        if isDebugLoggingEnabled {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            print("[\(timestamp)] [\(category.rawValue)] \(formattedMessage)")
        }
        #endif
    }
}

// MARK: - Performance Measurement

extension Logger {

    /// Measures the execution time of a closure
    /// - Parameters:
    ///   - label: A label for the measurement
    ///   - category: The log category
    ///   - operation: The closure to measure
    /// - Returns: The result of the closure
    @discardableResult
    static func measure<T>(
        _ label: String,
        category: Category = .performance,
        operation: () throws -> T
    ) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let duration = CFAbsoluteTimeGetCurrent() - start
        performance("\(label)", duration: duration)
        return result
    }

    /// Measures the execution time of an async closure
    /// - Parameters:
    ///   - label: A label for the measurement
    ///   - category: The log category
    ///   - operation: The async closure to measure
    /// - Returns: The result of the closure
    @discardableResult
    static func measureAsync<T>(
        _ label: String,
        category: Category = .performance,
        operation: () async throws -> T
    ) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - start
        performance("\(label)", duration: duration)
        return result
    }
}

// MARK: - Signpost Support for Instruments

extension Logger {

    /// Creates a signpost for Instruments profiling
    static func signpost(
        _ name: StaticString,
        category: Category = .performance
    ) -> OSSignpostID {
        return OSSignpostID(log: category.osLog)
    }

    /// Begins an interval signpost
    static func signpostBegin(
        _ name: StaticString,
        id: OSSignpostID,
        category: Category = .performance
    ) {
        os_signpost(.begin, log: category.osLog, name: name, signpostID: id)
    }

    /// Ends an interval signpost
    static func signpostEnd(
        _ name: StaticString,
        id: OSSignpostID,
        category: Category = .performance
    ) {
        os_signpost(.end, log: category.osLog, name: name, signpostID: id)
    }
}
