import SwiftUI

/// Defines the main navigation sections for the app
enum NavigationSection: String, CaseIterable, Hashable, Identifiable {
    case dashboard
    case patients
    case appointments
    case reports
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .patients:
            return "Patients"
        case .appointments:
            return "Appointments"
        case .reports:
            return "Reports"
        case .settings:
            return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:
            return "chart.bar.fill"
        case .patients:
            return "person.3.fill"
        case .appointments:
            return "calendar"
        case .reports:
            return "doc.text.fill"
        case .settings:
            return "gear"
        }
    }

    var color: Color {
        switch self {
        case .dashboard:
            return .blue
        case .patients:
            return .green
        case .appointments:
            return .orange
        case .reports:
            return .purple
        case .settings:
            return .gray
        }
    }
}

/// Quick action items for the sidebar
enum QuickAction: String, CaseIterable, Hashable, Identifiable {
    case newPatient
    case scheduleAppointment
    case riskCalculator
    case operativeNote

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newPatient:
            return "New Patient"
        case .scheduleAppointment:
            return "Schedule"
        case .riskCalculator:
            return "Risk Calculator"
        case .operativeNote:
            return "Operative Note"
        }
    }

    var icon: String {
        switch self {
        case .newPatient:
            return "person.badge.plus"
        case .scheduleAppointment:
            return "calendar.badge.plus"
        case .riskCalculator:
            return "function"
        case .operativeNote:
            return "pencil.and.outline"
        }
    }

    var color: Color {
        switch self {
        case .newPatient:
            return Color(red: 0.33, green: 0.62, blue: 0.57)
        case .scheduleAppointment:
            return Color(red: 0.25, green: 0.52, blue: 0.74)
        case .riskCalculator:
            return Color(red: 0.55, green: 0.35, blue: 0.64)
        case .operativeNote:
            return Color(red: 0.67, green: 0.58, blue: 0.32)
        }
    }
}
