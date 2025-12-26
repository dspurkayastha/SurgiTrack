// FormValidationFramework.swift
// SurgiTrack
// Real-time form validation with medical field support
// Created on 26/12/2025

import Foundation
import SwiftUI
import Combine

// MARK: - Validation Rules

/// Protocol for all validation rules
protocol ValidationRule {
    associatedtype Value
    func validate(_ value: Value) -> ValidationResult
}

/// Result of a validation check
enum ValidationResult: Equatable {
    case valid
    case invalid(message: String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

// MARK: - String Validation Rules

struct RequiredRule: ValidationRule {
    let fieldName: String

    func validate(_ value: String) -> ValidationResult {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(message: "\(fieldName) is required")
        }
        return .valid
    }
}

struct MinLengthRule: ValidationRule {
    let minLength: Int
    let fieldName: String

    func validate(_ value: String) -> ValidationResult {
        if value.count < minLength {
            return .invalid(message: "\(fieldName) must be at least \(minLength) characters")
        }
        return .valid
    }
}

struct MaxLengthRule: ValidationRule {
    let maxLength: Int
    let fieldName: String

    func validate(_ value: String) -> ValidationResult {
        if value.count > maxLength {
            return .invalid(message: "\(fieldName) must be no more than \(maxLength) characters")
        }
        return .valid
    }
}

struct EmailRule: ValidationRule {
    func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else { return .valid } // Allow empty if not required
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        if !predicate.evaluate(with: value) {
            return .invalid(message: "Please enter a valid email address")
        }
        return .valid
    }
}

struct PhoneRule: ValidationRule {
    func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else { return .valid }
        let digits = value.filter { $0.isNumber }
        if digits.count < 10 {
            return .invalid(message: "Phone number must have at least 10 digits")
        }
        return .valid
    }
}

struct RegexRule: ValidationRule {
    let pattern: String
    let message: String

    func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else { return .valid }
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        if !predicate.evaluate(with: value) {
            return .invalid(message: message)
        }
        return .valid
    }
}

// MARK: - Medical Field Validation Rules

struct MedicalRecordNumberRule: ValidationRule {
    func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else { return .valid }
        // MRN format: alphanumeric, 6-15 characters
        let mrnRegex = #"^[A-Za-z0-9]{6,15}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", mrnRegex)
        if !predicate.evaluate(with: value) {
            return .invalid(message: "MRN must be 6-15 alphanumeric characters")
        }
        return .valid
    }
}

struct DateOfBirthRule: ValidationRule {
    func validate(_ value: Date?) -> ValidationResult {
        guard let dob = value else {
            return .invalid(message: "Date of birth is required")
        }

        if dob > Date() {
            return .invalid(message: "Date of birth cannot be in the future")
        }

        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: dob, to: Date()).year ?? 0
        if age > 150 {
            return .invalid(message: "Please verify date of birth")
        }

        return .valid
    }
}

struct VitalSignRule: ValidationRule {
    enum VitalType {
        case heartRate
        case systolicBP
        case diastolicBP
        case temperature
        case oxygenSaturation
        case respiratoryRate

        var validRange: ClosedRange<Double> {
            switch self {
            case .heartRate: return 20...300
            case .systolicBP: return 50...300
            case .diastolicBP: return 20...200
            case .temperature: return 90...110 // Fahrenheit
            case .oxygenSaturation: return 50...100
            case .respiratoryRate: return 4...60
            }
        }

        var name: String {
            switch self {
            case .heartRate: return "Heart rate"
            case .systolicBP: return "Systolic BP"
            case .diastolicBP: return "Diastolic BP"
            case .temperature: return "Temperature"
            case .oxygenSaturation: return "Oxygen saturation"
            case .respiratoryRate: return "Respiratory rate"
            }
        }
    }

    let vitalType: VitalType

    func validate(_ value: Double?) -> ValidationResult {
        guard let vital = value else { return .valid }

        if !vitalType.validRange.contains(vital) {
            return .invalid(message: "\(vitalType.name) should be between \(Int(vitalType.validRange.lowerBound)) and \(Int(vitalType.validRange.upperBound))")
        }
        return .valid
    }
}

// MARK: - Numeric Validation Rules

struct RangeRule: ValidationRule {
    let range: ClosedRange<Double>
    let fieldName: String

    func validate(_ value: Double?) -> ValidationResult {
        guard let num = value else { return .valid }
        if !range.contains(num) {
            return .invalid(message: "\(fieldName) must be between \(Int(range.lowerBound)) and \(Int(range.upperBound))")
        }
        return .valid
    }
}

struct PositiveNumberRule: ValidationRule {
    let fieldName: String

    func validate(_ value: Double?) -> ValidationResult {
        guard let num = value else { return .valid }
        if num < 0 {
            return .invalid(message: "\(fieldName) must be a positive number")
        }
        return .valid
    }
}

// MARK: - Field Validator

/// Validates a single field with multiple rules
class FieldValidator<Value>: ObservableObject {
    @Published var value: Value
    @Published private(set) var validationState: ValidationState = .pristine
    @Published private(set) var errorMessage: String?

    private var rules: [(Value) -> ValidationResult] = []
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval

    enum ValidationState {
        case pristine    // Not yet validated
        case validating  // Currently validating
        case valid       // Passed all rules
        case invalid     // Failed validation
    }

    init(initialValue: Value, debounceInterval: TimeInterval = 0.3) {
        self.value = initialValue
        self.debounceInterval = debounceInterval
        setupValidation()
    }

    private func setupValidation() {
        $value
            .dropFirst() // Don't validate initial value
            .debounce(for: .seconds(debounceInterval), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                self?.validate(newValue)
            }
            .store(in: &cancellables)
    }

    func addRule(_ rule: @escaping (Value) -> ValidationResult) {
        rules.append(rule)
    }

    func validate(_ value: Value? = nil) {
        let valueToValidate = value ?? self.value
        validationState = .validating

        for rule in rules {
            let result = rule(valueToValidate)
            if case .invalid(let message) = result {
                errorMessage = message
                validationState = .invalid
                return
            }
        }

        errorMessage = nil
        validationState = .valid
    }

    func reset() {
        validationState = .pristine
        errorMessage = nil
    }

    var isValid: Bool {
        validationState == .valid
    }
}

// MARK: - Form Validator

/// Validates an entire form with multiple fields
@MainActor
class FormValidator: ObservableObject {
    @Published private(set) var isValid = false
    @Published private(set) var errors: [String: String] = [:]
    @Published private(set) var validationState: FieldValidator<String>.ValidationState = .pristine

    private var fieldValidators: [String: () -> ValidationResult] = [:]

    func registerField(_ name: String, validator: @escaping () -> ValidationResult) {
        fieldValidators[name] = validator
    }

    func validateAll() -> Bool {
        errors.removeAll()
        var allValid = true

        for (name, validator) in fieldValidators {
            let result = validator()
            if case .invalid(let message) = result {
                errors[name] = message
                allValid = false
            }
        }

        isValid = allValid
        validationState = allValid ? .valid : .invalid
        return allValid
    }

    func validateField(_ name: String) -> ValidationResult {
        guard let validator = fieldValidators[name] else {
            return .valid
        }

        let result = validator()
        if case .invalid(let message) = result {
            errors[name] = message
        } else {
            errors.removeValue(forKey: name)
        }

        return result
    }

    func reset() {
        errors.removeAll()
        isValid = false
        validationState = .pristine
    }
}

// MARK: - SwiftUI Components

/// A text field with real-time validation
struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    let rules: [(String) -> ValidationResult]
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    @State private var errorMessage: String?
    @State private var hasBeenEdited = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    hasBeenEdited = true
                    validateInput(newValue)
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused && hasBeenEdited {
                        validateInput(text)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )

            if let error = errorMessage, hasBeenEdited {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }

    private var borderColor: Color {
        if let _ = errorMessage, hasBeenEdited {
            return .red
        }
        if isFocused {
            return .accentColor
        }
        return .gray.opacity(0.3)
    }

    private func validateInput(_ value: String) {
        for rule in rules {
            let result = rule(value)
            if case .invalid(let message) = result {
                errorMessage = message
                return
            }
        }
        errorMessage = nil
    }
}

/// A secure field with validation
struct ValidatedSecureField: View {
    let title: String
    @Binding var text: String
    let rules: [(String) -> ValidationResult]

    @State private var errorMessage: String?
    @State private var hasBeenEdited = false
    @State private var isSecure = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Group {
                    if isSecure {
                        SecureField(title, text: $text)
                    } else {
                        TextField(title, text: $text)
                    }
                }
                .onChange(of: text) { _, newValue in
                    hasBeenEdited = true
                    validateInput(newValue)
                }

                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(errorMessage != nil && hasBeenEdited ? .red : .gray.opacity(0.3), lineWidth: 1)
            )

            if let error = errorMessage, hasBeenEdited {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }

    private func validateInput(_ value: String) {
        for rule in rules {
            let result = rule(value)
            if case .invalid(let message) = result {
                errorMessage = message
                return
            }
        }
        errorMessage = nil
    }
}

// MARK: - Convenience Rule Builders

extension ValidationRule where Value == String {
    static func required(_ fieldName: String) -> RequiredRule {
        RequiredRule(fieldName: fieldName)
    }

    static func minLength(_ length: Int, fieldName: String) -> MinLengthRule {
        MinLengthRule(minLength: length, fieldName: fieldName)
    }

    static func maxLength(_ length: Int, fieldName: String) -> MaxLengthRule {
        MaxLengthRule(maxLength: length, fieldName: fieldName)
    }

    static var email: EmailRule { EmailRule() }
    static var phone: PhoneRule { PhoneRule() }
    static var mrn: MedicalRecordNumberRule { MedicalRecordNumberRule() }
}

// MARK: - Validation Extensions

extension String {
    func validate(with rules: [any ValidationRule]) -> ValidationResult {
        for rule in rules {
            if let stringRule = rule as? any ValidationRule<String> {
                let result = stringRule.validate(self)
                if !result.isValid {
                    return result
                }
            }
        }
        return .valid
    }
}
