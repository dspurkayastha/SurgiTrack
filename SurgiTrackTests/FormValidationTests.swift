// FormValidationTests.swift
// SurgiTrackTests
// Tests for form validation framework
// Created on 26/12/2025

import Testing
import Foundation
@testable import SurgiTrack

struct FormValidationTests {

    // MARK: - Required Rule Tests

    @Test func requiredRule_withEmptyString_returnsInvalid() async throws {
        let rule = RequiredRule(fieldName: "Name")

        let result = rule.validate("")

        #expect(result.isValid == false, "Empty string should fail required validation")
        #expect(result.errorMessage?.contains("required") == true)
    }

    @Test func requiredRule_withWhitespaceOnly_returnsInvalid() async throws {
        let rule = RequiredRule(fieldName: "Name")

        let result = rule.validate("   \t\n  ")

        #expect(result.isValid == false, "Whitespace-only string should fail")
    }

    @Test func requiredRule_withValue_returnsValid() async throws {
        let rule = RequiredRule(fieldName: "Name")

        let result = rule.validate("John Doe")

        #expect(result.isValid == true, "Non-empty string should pass")
    }

    // MARK: - Min Length Rule Tests

    @Test func minLengthRule_withShortString_returnsInvalid() async throws {
        let rule = MinLengthRule(minLength: 8, fieldName: "Password")

        let result = rule.validate("short")

        #expect(result.isValid == false, "String shorter than min should fail")
        #expect(result.errorMessage?.contains("8") == true)
    }

    @Test func minLengthRule_withExactLength_returnsValid() async throws {
        let rule = MinLengthRule(minLength: 8, fieldName: "Password")

        let result = rule.validate("12345678")

        #expect(result.isValid == true, "String at exact min length should pass")
    }

    @Test func minLengthRule_withLongerString_returnsValid() async throws {
        let rule = MinLengthRule(minLength: 8, fieldName: "Password")

        let result = rule.validate("thisIsALongPassword123")

        #expect(result.isValid == true, "String longer than min should pass")
    }

    // MARK: - Max Length Rule Tests

    @Test func maxLengthRule_withLongString_returnsInvalid() async throws {
        let rule = MaxLengthRule(maxLength: 10, fieldName: "Code")

        let result = rule.validate("thisIsTooLong")

        #expect(result.isValid == false, "String longer than max should fail")
    }

    @Test func maxLengthRule_withinLimit_returnsValid() async throws {
        let rule = MaxLengthRule(maxLength: 10, fieldName: "Code")

        let result = rule.validate("short")

        #expect(result.isValid == true, "String within limit should pass")
    }

    // MARK: - Email Rule Tests

    @Test func emailRule_withValidEmail_returnsValid() async throws {
        let rule = EmailRule()

        let validEmails = [
            "test@example.com",
            "user.name@domain.org",
            "user+tag@company.io"
        ]

        for email in validEmails {
            let result = rule.validate(email)
            #expect(result.isValid == true, "Valid email '\(email)' should pass")
        }
    }

    @Test func emailRule_withInvalidEmail_returnsInvalid() async throws {
        let rule = EmailRule()

        let invalidEmails = [
            "notanemail",
            "missing@tld",
            "@nodomain.com",
            "spaces in@email.com"
        ]

        for email in invalidEmails {
            let result = rule.validate(email)
            #expect(result.isValid == false, "Invalid email '\(email)' should fail")
        }
    }

    @Test func emailRule_withEmptyString_returnsValid() async throws {
        let rule = EmailRule()

        // Empty is valid (use RequiredRule for requiring email)
        let result = rule.validate("")

        #expect(result.isValid == true, "Empty email should pass (use RequiredRule separately)")
    }

    // MARK: - Phone Rule Tests

    @Test func phoneRule_withValidPhone_returnsValid() async throws {
        let rule = PhoneRule()

        let validPhones = [
            "1234567890",
            "123-456-7890",
            "(123) 456-7890",
            "+1 234 567 8901"
        ]

        for phone in validPhones {
            let result = rule.validate(phone)
            #expect(result.isValid == true, "Valid phone '\(phone)' should pass")
        }
    }

    @Test func phoneRule_withShortNumber_returnsInvalid() async throws {
        let rule = PhoneRule()

        let result = rule.validate("12345")

        #expect(result.isValid == false, "Short phone number should fail")
    }

    // MARK: - Medical Record Number Rule Tests

    @Test func mrnRule_withValidMRN_returnsValid() async throws {
        let rule = MedicalRecordNumberRule()

        let validMRNs = [
            "ABC123",
            "123456",
            "PATIENT001",
            "MRN12345678"
        ]

        for mrn in validMRNs {
            let result = rule.validate(mrn)
            #expect(result.isValid == true, "Valid MRN '\(mrn)' should pass")
        }
    }

    @Test func mrnRule_withInvalidMRN_returnsInvalid() async throws {
        let rule = MedicalRecordNumberRule()

        let invalidMRNs = [
            "AB12",          // Too short
            "MRN-123-456",   // Contains hyphens
            "1234567890123456" // Too long
        ]

        for mrn in invalidMRNs {
            let result = rule.validate(mrn)
            #expect(result.isValid == false, "Invalid MRN '\(mrn)' should fail")
        }
    }

    // MARK: - Date of Birth Rule Tests

    @Test func dobRule_withValidDOB_returnsValid() async throws {
        let rule = DateOfBirthRule()

        let validDOB = Calendar.current.date(byAdding: .year, value: -30, to: Date())

        let result = rule.validate(validDOB)

        #expect(result.isValid == true, "Valid DOB should pass")
    }

    @Test func dobRule_withFutureDOB_returnsInvalid() async throws {
        let rule = DateOfBirthRule()

        let futureDOB = Calendar.current.date(byAdding: .day, value: 1, to: Date())

        let result = rule.validate(futureDOB)

        #expect(result.isValid == false, "Future DOB should fail")
    }

    @Test func dobRule_withNil_returnsInvalid() async throws {
        let rule = DateOfBirthRule()

        let result = rule.validate(nil)

        #expect(result.isValid == false, "Nil DOB should fail")
    }

    @Test func dobRule_withAncientDOB_returnsInvalid() async throws {
        let rule = DateOfBirthRule()

        let ancientDOB = Calendar.current.date(byAdding: .year, value: -200, to: Date())

        let result = rule.validate(ancientDOB)

        #expect(result.isValid == false, "DOB over 150 years ago should fail")
    }

    // MARK: - Vital Sign Rule Tests

    @Test func vitalSignRule_heartRate_validRange() async throws {
        let rule = VitalSignRule(vitalType: .heartRate)

        #expect(rule.validate(60.0).isValid == true, "60 bpm should be valid")
        #expect(rule.validate(100.0).isValid == true, "100 bpm should be valid")
        #expect(rule.validate(10.0).isValid == false, "10 bpm should be invalid")
        #expect(rule.validate(350.0).isValid == false, "350 bpm should be invalid")
    }

    @Test func vitalSignRule_bloodPressure_validRange() async throws {
        let systolicRule = VitalSignRule(vitalType: .systolicBP)
        let diastolicRule = VitalSignRule(vitalType: .diastolicBP)

        #expect(systolicRule.validate(120.0).isValid == true, "120 systolic should be valid")
        #expect(diastolicRule.validate(80.0).isValid == true, "80 diastolic should be valid")
        #expect(systolicRule.validate(400.0).isValid == false, "400 systolic should be invalid")
    }

    @Test func vitalSignRule_oxygenSaturation_validRange() async throws {
        let rule = VitalSignRule(vitalType: .oxygenSaturation)

        #expect(rule.validate(98.0).isValid == true, "98% O2 should be valid")
        #expect(rule.validate(100.0).isValid == true, "100% O2 should be valid")
        #expect(rule.validate(40.0).isValid == false, "40% O2 should be invalid")
        #expect(rule.validate(105.0).isValid == false, "105% O2 should be invalid")
    }

    @Test func vitalSignRule_nil_returnsValid() async throws {
        let rule = VitalSignRule(vitalType: .heartRate)

        let result = rule.validate(nil)

        #expect(result.isValid == true, "Nil vital should pass (use RequiredRule separately)")
    }

    // MARK: - Range Rule Tests

    @Test func rangeRule_withinRange_returnsValid() async throws {
        let rule = RangeRule(range: 0...100, fieldName: "Score")

        #expect(rule.validate(50.0).isValid == true, "50 in 0-100 should be valid")
        #expect(rule.validate(0.0).isValid == true, "0 at lower bound should be valid")
        #expect(rule.validate(100.0).isValid == true, "100 at upper bound should be valid")
    }

    @Test func rangeRule_outsideRange_returnsInvalid() async throws {
        let rule = RangeRule(range: 0...100, fieldName: "Score")

        #expect(rule.validate(-1.0).isValid == false, "-1 below range should be invalid")
        #expect(rule.validate(101.0).isValid == false, "101 above range should be invalid")
    }

    // MARK: - Positive Number Rule Tests

    @Test func positiveNumberRule_withPositive_returnsValid() async throws {
        let rule = PositiveNumberRule(fieldName: "Amount")

        #expect(rule.validate(100.0).isValid == true, "Positive number should be valid")
        #expect(rule.validate(0.0).isValid == true, "Zero should be valid")
    }

    @Test func positiveNumberRule_withNegative_returnsInvalid() async throws {
        let rule = PositiveNumberRule(fieldName: "Amount")

        let result = rule.validate(-50.0)

        #expect(result.isValid == false, "Negative number should be invalid")
    }

    // MARK: - Regex Rule Tests

    @Test func regexRule_matching_returnsValid() async throws {
        let rule = RegexRule(pattern: "^[A-Z]{3}[0-9]{4}$", message: "Invalid format")

        #expect(rule.validate("ABC1234").isValid == true, "Matching pattern should be valid")
    }

    @Test func regexRule_notMatching_returnsInvalid() async throws {
        let rule = RegexRule(pattern: "^[A-Z]{3}[0-9]{4}$", message: "Invalid format")

        #expect(rule.validate("abc1234").isValid == false, "Non-matching should be invalid")
        #expect(rule.validate("ABCD123").isValid == false, "Wrong format should be invalid")
    }

    // MARK: - Validation Result Tests

    @Test func validationResult_valid_properties() async throws {
        let result = ValidationResult.valid

        #expect(result.isValid == true)
        #expect(result.errorMessage == nil)
    }

    @Test func validationResult_invalid_properties() async throws {
        let result = ValidationResult.invalid(message: "Test error")

        #expect(result.isValid == false)
        #expect(result.errorMessage == "Test error")
    }

    @Test func validationResult_equality() async throws {
        let valid1 = ValidationResult.valid
        let valid2 = ValidationResult.valid
        let invalid1 = ValidationResult.invalid(message: "Error")
        let invalid2 = ValidationResult.invalid(message: "Error")
        let invalid3 = ValidationResult.invalid(message: "Different")

        #expect(valid1 == valid2, "Two valid results should be equal")
        #expect(invalid1 == invalid2, "Same error messages should be equal")
        #expect(invalid1 != invalid3, "Different error messages should not be equal")
        #expect(valid1 != invalid1, "Valid and invalid should not be equal")
    }
}
