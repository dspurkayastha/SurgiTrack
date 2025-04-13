//
//  DischargeSummaryExtensions.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 10/03/25.
//

// DischargeSummaryExtensions.swift
// SurgiTrack
// Created on 10/03/25.

import SwiftUI
import CoreData

// MARK: - Patient Extension for Discharge-Related Properties

extension Patient {
    // Extension to check if a patient can be discharged
    var isEligibleForDischarge: Bool {
        // Patient must not already be discharged
        guard !isDischargedStatus else { return false }
        
        // Patient must have at least one operative data entry
        guard (operativeData as? Set<OperativeData>)?.count ?? 0 > 0 else { return false }
        
        // Patient must have an initial presentation record
        guard initialPresentation != nil else { return false }
        
        return true
    }
    
    // Check if patient has a discharge summary
    var hasDischargeRecord: Bool {
        return dischargeSummary != nil
    }
    
    // Get total number of hospital stays
    var hospitalStayCount: Int {
        // In the current model, a patient can only have one hospital stay
        // But this could be extended to count multiple stays
        return isDischargedStatus || hasDischargeRecord ? 1 : 0
    }
    
    // Get latest procedure name
    var latestProcedureName: String? {
        guard let procedures = operativeData as? Set<OperativeData>,
              !procedures.isEmpty else {
            return nil
        }
        
        let sortedProcedures = procedures.sorted { ($0.operationDate ?? Date()) > ($1.operationDate ?? Date()) }
        return sortedProcedures.first?.procedureName
    }
}

// MARK: - DischargeSummary Extensions

extension DischargeSummary {
    // Check if all recommended follow-up items are completed
    var isFollowUpComplete: Bool {
        return followUpAppointmentScheduled
    }
    
    // Get primary diagnosis in a sanitized format
    var formattedPrimaryDiagnosis: String {
        return primaryDiagnosis?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Not specified"
    }
    
    // Calculate length of hospital stay
    var lengthOfStay: Int {
        guard let patient = patient,
              let admissionDate = patient.dateCreated,
              let dischargeDate = self.dischargeDate else {
            return 0
        }
        
        return Calendar.current.dateComponents([.day], from: admissionDate, to: dischargeDate).day ?? 0
    }
    
    // Create a formatted summary text
    var summaryText: String {
        var text = "DISCHARGE SUMMARY\n\n"
        
        if let patientName = patient?.fullName {
            text += "Patient: \(patientName)\n"
        }
        
        if let dischargeDate = dischargeDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            text += "Discharge Date: \(formatter.string(from: dischargeDate))\n"
        }
        
        if let primaryDiagnosis = primaryDiagnosis, !primaryDiagnosis.isEmpty {
            text += "\nPrimary Diagnosis: \(primaryDiagnosis)"
        }
        
        if let secondaryDiagnoses = secondaryDiagnoses, !secondaryDiagnoses.isEmpty {
            text += "\nSecondary Diagnoses: \(secondaryDiagnoses)"
        }
        
        if let treatmentSummary = treatmentSummary, !treatmentSummary.isEmpty {
            text += "\n\nTreatment Summary: \(treatmentSummary)"
        }
        
        if let procedures = procedures, !procedures.isEmpty {
            text += "\nProcedures: \(procedures)"
        }
        
        if let medicationsAtDischarge = medicationsAtDischarge, !medicationsAtDischarge.isEmpty {
            text += "\n\nMedications at Discharge: \(medicationsAtDischarge)"
        }
        
        if let followUpInstructions = followUpInstructions, !followUpInstructions.isEmpty {
            text += "\n\nFollow-up Instructions: \(followUpInstructions)"
        }
        
        if let dischargingPhysician = dischargingPhysician, !dischargingPhysician.isEmpty {
            text += "\n\nDischarging Physician: \(dischargingPhysician)"
        }
        
        return text
    }
}
