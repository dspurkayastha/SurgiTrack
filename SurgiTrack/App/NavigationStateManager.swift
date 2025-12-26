import SwiftUI
import Combine
import CoreData

/// Manages the navigation state for iPad split view
class NavigationStateManager: ObservableObject {
    @Published var selectedSection: NavigationSection? = .dashboard
    @Published var selectedPatientID: NSManagedObjectID?
    @Published var selectedAppointmentID: NSManagedObjectID?
    @Published var selectedReportID: NSManagedObjectID?
    @Published var columnVisibility: NavigationSplitViewVisibility = .all

    // Detail presentation states
    @Published var showingPatientDetail = false
    @Published var showingAppointmentDetail = false
    @Published var showingReportDetail = false

    init() {
        Logger.info("NavigationStateManager initialized", category: .ui)
    }

    /// Select a patient for detail view
    func selectPatient(_ objectID: NSManagedObjectID) {
        selectedPatientID = objectID
        showingPatientDetail = true
        Logger.debug("Selected patient: \(objectID)", category: .ui)
    }

    /// Select an appointment for detail view
    func selectAppointment(_ objectID: NSManagedObjectID) {
        selectedAppointmentID = objectID
        showingAppointmentDetail = true
        Logger.debug("Selected appointment: \(objectID)", category: .ui)
    }

    /// Select a report for detail view
    func selectReport(_ objectID: NSManagedObjectID) {
        selectedReportID = objectID
        showingReportDetail = true
        Logger.debug("Selected report: \(objectID)", category: .ui)
    }

    /// Clear all selections
    func clearSelections() {
        selectedPatientID = nil
        selectedAppointmentID = nil
        selectedReportID = nil
        showingPatientDetail = false
        showingAppointmentDetail = false
        showingReportDetail = false
    }

    /// Navigate to a specific section
    func navigateTo(_ section: NavigationSection) {
        selectedSection = section
        clearSelections()
    }
}
