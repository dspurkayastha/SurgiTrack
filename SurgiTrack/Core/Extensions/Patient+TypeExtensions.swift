//
//  Patient+TypeExtensions.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 10/03/25.
//

// Patient+TypeExtensions.swift
// SurgiTrack
// Created on 10/03/25.

import SwiftUI
import CoreData

// Extension to provide improved type extensions for Patient
extension Patient {
    // Get patient's age or "Unknown" if no birth date
    var age: String {
        guard let dob = dateOfBirth else { return "Unknown" }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        if let age = ageComponents.year {
            return "\(age)"
        }
        return "Unknown"
    }
    
    // Get formatted admission date
    var formattedAdmissionDate: String {
        guard let date = dateCreated else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Get formatted last modified date
    var formattedLastModifiedDate: String {
        guard let date = dateModified else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Get patient's BMI if height and weight are available
    var bmi: String? {
        guard height > 0, weight > 0 else { return nil }
        let heightInMeters = height / 100
        let bmi = weight / (heightInMeters * heightInMeters)
        return String(format: "%.1f", bmi)
    }
    
    // Get patient's BMI category
    var bmiCategory: String? {
        guard let bmiValue = Double(bmi ?? "0") else { return nil }
        
        switch bmiValue {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal weight"
        case 25..<30:
            return "Overweight"
        case 30..<35:
            return "Class I obesity"
        case 35..<40:
            return "Class II obesity"
        default:
            return "Class III obesity"
        }
    }
    
    // Get formatted height in cm/ft
    var formattedHeight: String {
        guard height > 0 else { return "Not recorded" }
        let heightInInches = height / 2.54
        let feet = Int(heightInInches / 12)
        let inches = Int(heightInInches.truncatingRemainder(dividingBy: 12))
        return String(format: "%.1f cm (%d ft %d in)", height, feet, inches)
    }
    
    // Get formatted weight in kg/lb
    var formattedWeight: String {
        guard weight > 0 else { return "Not recorded" }
        let weightInPounds = weight * 2.20462
        return String(format: "%.1f kg (%.1f lb)", weight, weightInPounds)
    }
    
    // Check if patient has complete demographics
    var hasCompleteDemographics: Bool {
        return firstName != nil && !firstName!.isEmpty &&
               lastName != nil && !lastName!.isEmpty &&
               dateOfBirth != nil &&
               gender != nil && !gender!.isEmpty &&
               medicalRecordNumber != nil && !medicalRecordNumber!.isEmpty
    }
    
    // Check if patient has at least one contact method
    var hasContactInfo: Bool {
        return (contactInfo != nil && !contactInfo!.isEmpty) ||
               (phone != nil && !phone!.isEmpty) ||
               (address != nil && !address!.isEmpty)
    }
    
    // Get a concatenated list of current medical issues
    var currentMedicalIssues: String {
        var issues: [String] = []
        
        // Get diagnosis from initial presentation
        if let initialDiagnosis = initialPresentation?.initialDiagnosis, !initialDiagnosis.isEmpty {
            issues.append(initialDiagnosis)
        }
        
        // Get procedures
        if let procedures = operativeData as? Set<OperativeData>, !procedures.isEmpty {
            let procedureNames = procedures.compactMap { $0.procedureName }
            issues.append(contentsOf: procedureNames)
        }
        
        // Get from follow-ups
        if let followUps = followUps as? Set<FollowUp>, !followUps.isEmpty {
            let complications = followUps.compactMap { $0.complications }.filter { !$0.isEmpty }
            issues.append(contentsOf: complications)
        }
        
        return issues.joined(separator: ", ")
    }
}
