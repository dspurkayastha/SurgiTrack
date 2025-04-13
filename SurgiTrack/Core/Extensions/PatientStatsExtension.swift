//
//  PatientStatsExtension.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 10/03/25.
//

// PatientStatsExtensions.swift
// SurgiTrack
// Created on 10/03/25.

import SwiftUI
import CoreData

extension Patient {
    // Check if a patient has completed their surgical journey
    var hasCompletedSurgicalJourney: Bool {
        let hasInitialPresentation = initialPresentation != nil
        let hasSurgery = (operativeData as? Set<OperativeData>)?.count ?? 0 > 0
        let hasFollowUp = (followUps as? Set<FollowUp>)?.count ?? 0 > 0
        let hasBeenDischarged = isDischargedStatus
        
        return hasInitialPresentation && hasSurgery && hasFollowUp && hasBeenDischarged
    }
    
    // Calculate total length of stay across all admissions
    var totalLengthOfStay: Int {
        // Current implementation just handles single stay
        return lengthOfStay
    }
    
    // Get most recent surgery date
    var mostRecentSurgeryDate: Date? {
        return (operativeData as? Set<OperativeData>)?
            .compactMap { $0.operationDate }
            .sorted(by: >)
            .first
    }
}

