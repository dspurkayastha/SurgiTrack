//
//  ScrollOffsetPreferenceKey.swift
//  SurgiTrack
//  Created by Devraj Shome Purkayastha on 10/03/25.
//

import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct QuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
enum QuickAction: String, CaseIterable {
    case schedule
    case newPatient
    case reports
    case riskCalculators
    
    var title: String {
        switch self {
        case .schedule: return "Schedule"
        case .newPatient: return "Add Patient"
        case .reports: return "Reports"
        case .riskCalculators: return "Assess Risk"
        }
    }
    
    var iconName: String {
        switch self {
        case .schedule: return "calendar"
        case .newPatient: return "person.badge.plus"
        case .reports: return "clipboard.fill"
        case .riskCalculators: return "function"
        }
    }
    
    var color: Color {
        switch self {
        case .schedule: return .blue
        case .newPatient: return .green
        case .reports: return .orange
        case .riskCalculators: return .purple
        }
    }
}

enum NewQuickAction: String, CaseIterable, Hashable {
    case prescriptions
    case trends
    case operativeNotes
    
    var title: String {
        switch self {
        case .prescriptions: return "Prescriptions"
        case .trends: return "Trends"
        case .operativeNotes: return "Operative Notes"
        }
    }
    
    var iconName: String {
        switch self {
        case .prescriptions: return "doc.text.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .operativeNotes: return "pencil.and.outline"
        }
    }
    
    var color: Color {
        switch self {
        case .prescriptions: return .green
        case .trends: return .blue
        case .operativeNotes: return .orange
        }
    }
}
struct DashboardStats {
    var patientCount: Int = 0
    var surgeryCount: Int = 0
    var todayAppointments: Int = 0
    var pendingFollowUps: Int = 0
}
extension Patient {
    var initials: String {
        let first = (firstName ?? "").prefix(1)
        let last = (lastName ?? "").prefix(1)
        
        return String(first) + String(last)
    }
}
