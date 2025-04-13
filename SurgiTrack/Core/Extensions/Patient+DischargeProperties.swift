// Patient+DischargeProperties.swift
// SurgiTrack
// Created on 10/03/25.

import Foundation
import CoreData

extension Patient {
    // Computed properties for discharge status and length of stay
    var isActive: Bool {
        return !isDischargedStatus
    }
    
    var lengthOfStay: Int {
        guard let dischargeDate = dischargeSummary?.dischargeDate,
              let admissionDate = dateCreated else {
            return 0
        }
        
        return Calendar.current.dateComponents([.day], from: admissionDate, to: dischargeDate).day ?? 0
    }
}
