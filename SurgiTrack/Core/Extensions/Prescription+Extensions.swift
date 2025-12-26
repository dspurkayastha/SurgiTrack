//
//  Prescription+Extensions.swift
//  SurgiTrack
//
//  Extensions for Prescription and PrescriptionItem entities
//  Created on December 26, 2025
//

import Foundation
import SwiftUI

// MARK: - Prescription Extensions

extension Prescription {

    /// Returns the number of items in this prescription
    var itemCount: Int {
        return (items as? Set<PrescriptionItem>)?.count ?? 0
    }

    /// Returns prescription items as a sorted array
    var sortedItems: [PrescriptionItem] {
        guard let items = items as? Set<PrescriptionItem> else { return [] }
        return items.sorted { ($0.drugName ?? "") < ($1.drugName ?? "") }
    }

    /// Returns active prescription items (within their start/end date range)
    var activeItems: [PrescriptionItem] {
        guard let items = items as? Set<PrescriptionItem> else { return [] }
        let now = Date()

        return items.filter { item in
            guard let startDate = item.startDate else { return false }

            if let endDate = item.endDate {
                return startDate <= now && now <= endDate
            } else {
                return startDate <= now
            }
        }
    }

    /// Formatted date created string
    var formattedDateCreated: String {
        guard let date = dateCreated else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Status color for UI display
    var statusColor: Color {
        switch status?.lowercased() {
        case "active":
            return .green
        case "completed":
            return .blue
        case "discontinued":
            return .red
        default:
            return .gray
        }
    }

    /// Status display name
    var statusDisplayName: String {
        return status?.capitalized ?? "Unknown"
    }

    /// Returns true if the prescription is currently active
    var isActive: Bool {
        return status?.lowercased() == "active"
    }

    /// Returns true if any items in the prescription are currently active
    var hasActiveItems: Bool {
        return !activeItems.isEmpty
    }
}

// MARK: - PrescriptionItem Extensions

extension PrescriptionItem {

    /// Full medication display name (drug name + strength)
    var fullMedicationName: String {
        var name = drugName ?? "Unknown Medication"
        if let strength = strength, !strength.isEmpty {
            name += " \(strength)"
        }
        return name
    }

    /// Dosing information string
    var dosingInfo: String {
        var info = dosage ?? ""
        if let frequency = frequency, !frequency.isEmpty {
            if !info.isEmpty {
                info += ", "
            }
            info += frequency
        }
        if let route = route, !route.isEmpty {
            if !info.isEmpty {
                info += ", "
            }
            info += route
        }
        return info
    }

    /// Formatted start date
    var formattedStartDate: String {
        guard let date = startDate else { return "Not specified" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Formatted end date
    var formattedEndDate: String {
        guard let date = endDate else { return "Ongoing" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Returns true if the item is currently active (within date range)
    var isCurrentlyActive: Bool {
        guard let startDate = startDate else { return false }
        let now = Date()

        if let endDate = endDate {
            return startDate <= now && now <= endDate
        } else {
            return startDate <= now
        }
    }

    /// Returns the number of days this medication has been/will be taken
    var durationInDays: Int? {
        guard let startDate = startDate else { return nil }

        let endDate = self.endDate ?? Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)

        return components.day
    }

    /// Returns a human-readable duration string
    var durationDisplayString: String {
        if let days = durationInDays {
            if days == 0 {
                return "Started today"
            } else if days == 1 {
                return "1 day"
            } else if days < 7 {
                return "\(days) days"
            } else if days < 30 {
                let weeks = days / 7
                return "\(weeks) week\(weeks == 1 ? "" : "s")"
            } else {
                let months = days / 30
                return "\(months) month\(months == 1 ? "" : "s")"
            }
        } else if let duration = duration, !duration.isEmpty {
            return duration
        } else {
            return "Ongoing"
        }
    }

    /// Status of the medication item
    enum ItemStatus {
        case notStarted
        case active
        case completed
        case expired

        var displayName: String {
            switch self {
            case .notStarted: return "Not Started"
            case .active: return "Active"
            case .completed: return "Completed"
            case .expired: return "Expired"
            }
        }

        var color: Color {
            switch self {
            case .notStarted: return .orange
            case .active: return .green
            case .completed: return .blue
            case .expired: return .gray
            }
        }
    }

    /// Returns the current status of this prescription item
    var itemStatus: ItemStatus {
        guard let startDate = startDate else { return .notStarted }
        let now = Date()

        if startDate > now {
            return .notStarted
        }

        if let endDate = endDate {
            if now > endDate {
                return .completed
            } else {
                return .active
            }
        }

        return .active
    }

    /// Returns the parent prescription's status
    var prescriptionStatus: String {
        return prescription?.status ?? "unknown"
    }

    /// Returns true if this item should be shown as discontinued
    var isDiscontinued: Bool {
        return prescription?.status?.lowercased() == "discontinued"
    }
}
