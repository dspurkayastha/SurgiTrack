import SwiftUI
import CoreData

/// This SearchResult struct is used in MainPageView for representing search results.
struct SearchResult: Identifiable {
    let id: String                   // A unique identifier (e.g., generated via UUID)
    let objectID: NSManagedObjectID  // Core Data objectID for retrieving the underlying object
    let resultType: SearchResultType // The type of result (patient, procedure, appointment, or test)
    let title: String                // The main title to display
    let subtitle: String             // A subtitle with additional information
    let iconName: String             // The system image name for the result
    let color: Color                 // A color to visually represent the result
}

enum SearchResultType: String {
    case patient
    case procedure
    case appointment
    case test
    
    var displayName: String {
        switch self {
        case .patient: return "Patients"
        case .procedure: return "Procedures"
        case .appointment: return "Appointments"
        case .test: return "Tests"
        }
    }
}

enum SearchCategory: String, CaseIterable {
    case all
    case patients
    case procedures
    case appointments
    case tests
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .patients: return "Patients"
        case .procedures: return "Procedures"
        case .appointments: return "Appointments"
        case .tests: return "Tests"
        }
    }
}
