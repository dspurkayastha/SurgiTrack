// DepartmentManager.swift
// SurgiTrack → MedTrack
// Department configuration and management service
// Created on 26/12/2025

import Foundation
import SwiftUI
import Combine

// MARK: - Department Configuration

/// Configuration settings for a department
struct DepartmentConfiguration: Codable {
    var workflowSettings: WorkflowSettings
    var notificationSettings: NotificationSettings
    var displaySettings: DisplaySettings
    var assessmentSettings: AssessmentSettings

    struct WorkflowSettings: Codable {
        var defaultEncounterType: EncounterType
        var requiresPreAssessment: Bool
        var autoAssignProvider: Bool
        var enableBedManagement: Bool
        var enableWaitlist: Bool
        var maxWaitMinutes: Int?
    }

    struct NotificationSettings: Codable {
        var notifyOnNewReferral: Bool
        var notifyOnCriticalResult: Bool
        var notifyOnDischarge: Bool
        var notifyOnAssessmentDue: Bool
        var escalationTimeMinutes: Int
    }

    struct DisplaySettings: Codable {
        var showBedBoard: Bool
        var showWaitingList: Bool
        var showSurgerySchedule: Bool
        var defaultPatientListSort: String
        var enableQuickActions: Bool
    }

    struct AssessmentSettings: Codable {
        var enabledAssessments: [AssessmentType]
        var requiredOnAdmission: [AssessmentType]
        var requiredOnDischarge: [AssessmentType]
        var customAssessmentIds: [UUID]
    }

    static var `default`: DepartmentConfiguration {
        DepartmentConfiguration(
            workflowSettings: WorkflowSettings(
                defaultEncounterType: .outpatientVisit,
                requiresPreAssessment: false,
                autoAssignProvider: false,
                enableBedManagement: false,
                enableWaitlist: true,
                maxWaitMinutes: nil
            ),
            notificationSettings: NotificationSettings(
                notifyOnNewReferral: true,
                notifyOnCriticalResult: true,
                notifyOnDischarge: false,
                notifyOnAssessmentDue: true,
                escalationTimeMinutes: 30
            ),
            displaySettings: DisplaySettings(
                showBedBoard: false,
                showWaitingList: true,
                showSurgerySchedule: false,
                defaultPatientListSort: "name",
                enableQuickActions: true
            ),
            assessmentSettings: AssessmentSettings(
                enabledAssessments: [.news2],
                requiredOnAdmission: [],
                requiredOnDischarge: [],
                customAssessmentIds: []
            )
        )
    }

    static func defaultFor(departmentType: DepartmentType) -> DepartmentConfiguration {
        var config = DepartmentConfiguration.default

        // Customize based on department type
        switch departmentType.category {
        case .surgical:
            config.workflowSettings.defaultEncounterType = .preOperative
            config.workflowSettings.requiresPreAssessment = true
            config.displaySettings.showSurgerySchedule = true
            config.assessmentSettings.enabledAssessments = departmentType.availableAssessments
            config.assessmentSettings.requiredOnAdmission = [.asaPhysicalStatus, .rcri]

        case .criticalCare:
            config.workflowSettings.defaultEncounterType = .emergencyVisit
            config.workflowSettings.enableBedManagement = true
            config.displaySettings.showBedBoard = true
            config.displaySettings.showWaitingList = true
            config.notificationSettings.escalationTimeMinutes = 15
            config.assessmentSettings.enabledAssessments = departmentType.availableAssessments

        case .medicine:
            config.workflowSettings.defaultEncounterType = .outpatientVisit
            config.assessmentSettings.enabledAssessments = departmentType.availableAssessments

        case .womensHealth:
            config.workflowSettings.defaultEncounterType = .outpatientVisit
            config.assessmentSettings.enabledAssessments = departmentType.availableAssessments

        case .pediatrics:
            config.workflowSettings.defaultEncounterType = .outpatientVisit
            config.assessmentSettings.enabledAssessments = departmentType.availableAssessments

        case .mentalHealth:
            config.workflowSettings.defaultEncounterType = .outpatientVisit
            config.assessmentSettings.requiredOnAdmission = [.phq9]
            config.assessmentSettings.enabledAssessments = departmentType.availableAssessments

        case .diagnostics, .rehabilitation, .support:
            config.workflowSettings.defaultEncounterType = .outpatientVisit
            config.displaySettings.showWaitingList = false
        }

        return config
    }
}

// MARK: - Department Manager

/// Manages department operations and configuration
@MainActor
class DepartmentManager: ObservableObject {

    static let shared = DepartmentManager()

    // MARK: - Published Properties

    @Published var currentDepartment: DepartmentInfo?
    @Published var availableDepartments: [DepartmentInfo] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        loadDepartments()
    }

    // MARK: - Public Methods

    /// Switch to a different department
    func switchDepartment(to department: DepartmentInfo) {
        Logger.info("Switching to department: \(department.name)", category: .general)
        currentDepartment = department
        UserDefaults.standard.set(department.id.uuidString, forKey: "currentDepartmentId")
    }

    /// Get configuration for a department
    func getConfiguration(for departmentType: DepartmentType) -> DepartmentConfiguration {
        // In production, this would load from CoreData
        return DepartmentConfiguration.defaultFor(departmentType: departmentType)
    }

    /// Update department configuration
    func updateConfiguration(_ config: DepartmentConfiguration, for departmentId: UUID) {
        // In production, this would save to CoreData
        Logger.info("Updated configuration for department \(departmentId)", category: .general)
    }

    /// Get available assessments for current department
    func availableAssessments() -> [AssessmentType] {
        guard let department = currentDepartment else {
            return [.news2] // Default universal assessment
        }
        return department.type.availableAssessments
    }

    /// Check if user has permission for an action
    func hasPermission(_ permission: Permission, role: StaffRole) -> Bool {
        return role.permissions.contains(permission)
    }

    // MARK: - Private Methods

    private func loadDepartments() {
        // In production, this would load from CoreData
        // For now, create sample departments
        availableDepartments = [
            DepartmentInfo(
                id: UUID(),
                name: "General Surgery",
                type: .generalSurgery,
                facilityName: "Main Hospital",
                staffCount: 24,
                activePatients: 18
            ),
            DepartmentInfo(
                id: UUID(),
                name: "Emergency Department",
                type: .emergencyMedicine,
                facilityName: "Main Hospital",
                staffCount: 45,
                activePatients: 32
            ),
            DepartmentInfo(
                id: UUID(),
                name: "Cardiology",
                type: .cardiology,
                facilityName: "Main Hospital",
                staffCount: 18,
                activePatients: 42
            ),
            DepartmentInfo(
                id: UUID(),
                name: "Orthopedic Surgery",
                type: .orthopedicSurgery,
                facilityName: "Surgical Center",
                staffCount: 15,
                activePatients: 12
            )
        ]

        // Restore last selected department
        if let savedId = UserDefaults.standard.string(forKey: "currentDepartmentId"),
           let uuid = UUID(uuidString: savedId),
           let department = availableDepartments.first(where: { $0.id == uuid }) {
            currentDepartment = department
        } else {
            currentDepartment = availableDepartments.first
        }
    }
}

// MARK: - Department Info

/// Lightweight department information for display
struct DepartmentInfo: Identifiable {
    let id: UUID
    let name: String
    let type: DepartmentType
    let facilityName: String
    let staffCount: Int
    let activePatients: Int

    var icon: String { type.icon }
    var color: Color { type.color }
}

// MARK: - Department Header View

/// Header showing current department context
struct DepartmentHeaderView: View {

    @EnvironmentObject var departmentManager: DepartmentManager
    @State private var showingSelector = false

    var body: some View {
        if let department = departmentManager.currentDepartment {
            Button(action: { showingSelector = true }) {
                HStack(spacing: MedicalSpacing.sm) {
                    Image(systemName: department.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(department.color)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(department.name)
                            .font(MedicalTypography.labelMedium)
                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                        Text(department.facilityName)
                            .font(MedicalTypography.caption)
                            .foregroundColor(MedicalColors.Neutral.textSecondary)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                }
                .padding(.horizontal, MedicalSpacing.md)
                .padding(.vertical, MedicalSpacing.sm)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(MedicalCardStyle.radiusSmall)
            }
            .sheet(isPresented: $showingSelector) {
                DepartmentSelectorView()
            }
        }
    }
}

// MARK: - Preview

#Preview("Department Header") {
    DepartmentHeaderView()
        .environmentObject(DepartmentManager.shared)
        .padding()
}
