// TestUtilities.swift
// SurgiTrackTests
// Common test utilities, mocks, and helpers
// Created on 26/12/2025

import Foundation
import CoreData
@testable import SurgiTrack

// MARK: - Test Utilities

/// Common test utilities and helpers
enum TestUtilities {

    // MARK: - Mock Data

    /// Creates a mock patient dictionary for testing
    static func mockPatientData() -> [String: Any] {
        return [
            "firstName": "John",
            "lastName": "Doe",
            "dateOfBirth": Calendar.current.date(byAdding: .year, value: -45, to: Date())!,
            "gender": "Male",
            "medicalRecordNumber": "MRN123456",
            "phone": "555-123-4567",
            "email": "john.doe@example.com",
            "address": "123 Main St, City, ST 12345"
        ]
    }

    /// Creates mock prescription data for testing
    static func mockPrescriptionData() -> [String: Any] {
        return [
            "drugName": "Lisinopril",
            "dosage": "10mg",
            "frequency": "Once daily",
            "route": "Oral",
            "startDate": Date(),
            "endDate": Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            "prescribingPhysician": "Dr. Smith",
            "notes": "Take with food"
        ]
    }

    /// Creates mock vital signs for testing
    static func mockVitalSigns() -> [String: Double] {
        return [
            "heartRate": 72.0,
            "systolicBP": 120.0,
            "diastolicBP": 80.0,
            "temperature": 98.6,
            "respiratoryRate": 16.0,
            "oxygenSaturation": 98.0
        ]
    }

    // MARK: - Validation Helpers

    /// Validates that a string is a valid hex string
    static func isValidHexString(_ string: String) -> Bool {
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return string.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) }
    }

    /// Validates email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    /// Validates phone number format (at least 10 digits)
    static func isValidPhone(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 10
    }

    // MARK: - Date Helpers

    /// Creates a date with specific components
    static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Creates a date relative to now
    static func dateRelative(days: Int = 0, hours: Int = 0, minutes: Int = 0) -> Date {
        var date = Date()
        date = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
        date = Calendar.current.date(byAdding: .hour, value: hours, to: date) ?? date
        date = Calendar.current.date(byAdding: .minute, value: minutes, to: date) ?? date
        return date
    }

    // MARK: - Async Helpers

    /// Waits for a condition to be true with timeout
    static func waitFor(
        timeout: TimeInterval = 5.0,
        condition: @escaping () -> Bool
    ) async -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        return false
    }

    // MARK: - String Helpers

    /// Generates a random string of specified length
    static func randomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }

    /// Generates a random email address
    static func randomEmail() -> String {
        return "\(randomString(length: 8))@\(randomString(length: 5)).com"
    }

    /// Generates a random phone number
    static func randomPhone() -> String {
        let digits = (0..<10).map { _ in String(Int.random(in: 0...9)) }
        return digits.joined()
    }
}

// MARK: - Mock Services

/// Mock keychain for testing without affecting real keychain
class MockKeychainStorage {
    private var storage: [String: Data] = [:]

    func store(_ value: String, for key: String) {
        storage[key] = value.data(using: .utf8)
    }

    func retrieve(key: String) -> String? {
        guard let data = storage[key] else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        storage.removeValue(forKey: key)
    }

    func clear() {
        storage.removeAll()
    }
}

/// Mock logger for testing
class MockLogger {
    var logs: [(level: String, message: String, category: String)] = []

    func log(_ message: String, level: String = "info", category: String = "general") {
        logs.append((level, message, category))
    }

    func clear() {
        logs.removeAll()
    }

    func contains(_ substring: String) -> Bool {
        logs.contains { $0.message.contains(substring) }
    }

    var lastLog: (level: String, message: String, category: String)? {
        logs.last
    }
}

// MARK: - Test Expectations

/// Custom test expectation helpers
enum TestExpectation {

    /// Expects a value to be within a range
    static func expectInRange<T: Comparable>(_ value: T, min: T, max: T, message: String = "") -> Bool {
        value >= min && value <= max
    }

    /// Expects a string to match a pattern
    static func expectMatches(_ string: String, pattern: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(string.startIndex..., in: string)
        return regex?.firstMatch(in: string, range: range) != nil
    }

    /// Expects a date to be within a time window
    static func expectDateNear(_ date: Date, reference: Date, tolerance: TimeInterval) -> Bool {
        abs(date.timeIntervalSince(reference)) <= tolerance
    }
}

// MARK: - Performance Testing

/// Simple performance measurement for tests
struct PerformanceMeasure {
    let name: String
    let startTime: CFAbsoluteTime

    init(name: String) {
        self.name = name
        self.startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() -> TimeInterval {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("[\(name)] Elapsed time: \(elapsed * 1000) ms")
        return elapsed
    }
}
