// AccessControlManager.swift
// SurgiTrack → MedTrack
// Role-based access control system
// Created on 26/12/2025

import Foundation
import SwiftUI
import Combine

// MARK: - Staff Member

/// Represents a staff member with role and permissions
struct StaffMember: Identifiable, Codable {
    let id: UUID
    let userId: String // Clerk user ID
    let firstName: String
    let lastName: String
    let email: String
    let role: StaffRole
    let departmentId: UUID
    let departmentName: String
    let facilityId: UUID
    let organizationId: UUID
    var isActive: Bool
    var customPermissions: Set<Permission>? // Override default role permissions
    let createdAt: Date
    var lastActiveAt: Date?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    var effectivePermissions: Set<Permission> {
        customPermissions ?? role.permissions
    }

    func hasPermission(_ permission: Permission) -> Bool {
        effectivePermissions.contains(permission)
    }

    func canAccess(departmentId: UUID) -> Bool {
        // Organization admins can access all departments
        if role >= .facilityAdmin {
            return true
        }
        // Others can only access their own department
        return self.departmentId == departmentId
    }
}

// MARK: - Session Context

/// Current user session context
struct SessionContext {
    let staffMember: StaffMember
    let organization: OrganizationInfo
    let facility: FacilityInfo
    let department: DepartmentInfo
    let sessionStarted: Date

    var isExpired: Bool {
        let timeout: TimeInterval = 8 * 60 * 60 // 8 hours
        return Date().timeIntervalSince(sessionStarted) > timeout
    }
}

struct OrganizationInfo: Codable {
    let id: UUID
    let name: String
    let type: OrganizationType
    let subscriptionTier: SubscriptionTier
}

struct FacilityInfo: Codable {
    let id: UUID
    let name: String
    let address: String
}

// MARK: - Access Control Manager

@MainActor
class AccessControlManager: ObservableObject {

    static let shared = AccessControlManager()

    // MARK: - Published Properties

    @Published var currentSession: SessionContext?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupSampleSession()
    }

    // MARK: - Authentication

    /// Set up session after successful authentication
    func establishSession(for userId: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // In production, this would fetch staff member from backend
        let staffMember = try await fetchStaffMember(userId: userId)
        let organization = try await fetchOrganization(id: staffMember.organizationId)
        let facility = try await fetchFacility(id: staffMember.facilityId)
        let department = DepartmentInfo(
            id: staffMember.departmentId,
            name: staffMember.departmentName,
            type: .generalSurgery, // Would come from backend
            facilityName: facility.name,
            staffCount: 24,
            activePatients: 18
        )

        currentSession = SessionContext(
            staffMember: staffMember,
            organization: organization,
            facility: facility,
            department: department,
            sessionStarted: Date()
        )

        isAuthenticated = true

        Logger.auth("Session established for \(staffMember.fullName)", level: .info)
        AuditLogger.shared.logLogin(
            userId: staffMember.id.uuidString,
            userName: staffMember.fullName,
            outcome: .success
        )
    }

    /// End current session
    func endSession() {
        if let session = currentSession {
            AuditLogger.shared.logLogout()
            Logger.auth("Session ended for \(session.staffMember.fullName)", level: .info)
        }

        currentSession = nil
        isAuthenticated = false
    }

    // MARK: - Permission Checking

    /// Check if current user has a permission
    func hasPermission(_ permission: Permission) -> Bool {
        guard let session = currentSession else { return false }
        return session.staffMember.hasPermission(permission)
    }

    /// Check if current user can access a department
    func canAccessDepartment(_ departmentId: UUID) -> Bool {
        guard let session = currentSession else { return false }
        return session.staffMember.canAccess(departmentId: departmentId)
    }

    /// Check if current user has minimum role level
    func hasMinimumRole(_ role: StaffRole) -> Bool {
        guard let session = currentSession else { return false }
        return session.staffMember.role >= role
    }

    /// Get list of actions user can perform
    func allowedActions() -> [Permission] {
        guard let session = currentSession else { return [] }
        return Array(session.staffMember.effectivePermissions)
    }

    // MARK: - Staff Management

    /// Invite a new staff member
    func inviteStaffMember(
        email: String,
        firstName: String,
        lastName: String,
        role: StaffRole,
        departmentId: UUID
    ) async throws {
        guard hasPermission(.manageStaff) else {
            throw AccessControlError.permissionDenied
        }

        // In production, this would send invitation email and create pending staff record
        Logger.info("Invited \(email) as \(role.rawValue)", category: .general)
    }

    /// Update staff member role
    func updateStaffRole(staffId: UUID, newRole: StaffRole) async throws {
        guard hasPermission(.manageStaff) else {
            throw AccessControlError.permissionDenied
        }

        // Cannot assign role higher than your own
        guard let session = currentSession, newRole <= session.staffMember.role else {
            throw AccessControlError.insufficientPrivileges
        }

        // In production, this would update CoreData
        Logger.info("Updated staff \(staffId) to role \(newRole.rawValue)", category: .general)
    }

    /// Deactivate a staff member
    func deactivateStaff(staffId: UUID) async throws {
        guard hasPermission(.manageStaff) else {
            throw AccessControlError.permissionDenied
        }

        // In production, this would update CoreData
        Logger.info("Deactivated staff \(staffId)", category: .general)
    }

    // MARK: - Private Methods

    private func fetchStaffMember(userId: String) async throws -> StaffMember {
        // Simulated API call
        try await Task.sleep(nanoseconds: 100_000_000)

        return StaffMember(
            id: UUID(),
            userId: userId,
            firstName: "John",
            lastName: "Smith",
            email: "john.smith@hospital.com",
            role: .attendingPhysician,
            departmentId: UUID(),
            departmentName: "General Surgery",
            facilityId: UUID(),
            organizationId: UUID(),
            isActive: true,
            customPermissions: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        )
    }

    private func fetchOrganization(id: UUID) async throws -> OrganizationInfo {
        return OrganizationInfo(
            id: id,
            name: "Metro General Hospital",
            type: .hospital,
            subscriptionTier: .professional
        )
    }

    private func fetchFacility(id: UUID) async throws -> FacilityInfo {
        return FacilityInfo(
            id: id,
            name: "Main Campus",
            address: "123 Medical Center Drive"
        )
    }

    private func setupSampleSession() {
        // Create sample session for development
        let staffMember = StaffMember(
            id: UUID(),
            userId: "sample_user",
            firstName: "John",
            lastName: "Smith",
            email: "john.smith@hospital.com",
            role: .attendingPhysician,
            departmentId: UUID(),
            departmentName: "General Surgery",
            facilityId: UUID(),
            organizationId: UUID(),
            isActive: true,
            customPermissions: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        )

        let organization = OrganizationInfo(
            id: UUID(),
            name: "Metro General Hospital",
            type: .hospital,
            subscriptionTier: .professional
        )

        let facility = FacilityInfo(
            id: UUID(),
            name: "Main Campus",
            address: "123 Medical Center Drive"
        )

        let department = DepartmentInfo(
            id: staffMember.departmentId,
            name: "General Surgery",
            type: .generalSurgery,
            facilityName: facility.name,
            staffCount: 24,
            activePatients: 18
        )

        currentSession = SessionContext(
            staffMember: staffMember,
            organization: organization,
            facility: facility,
            department: department,
            sessionStarted: Date()
        )

        isAuthenticated = true
    }
}

// MARK: - Access Control Errors

enum AccessControlError: LocalizedError {
    case notAuthenticated
    case sessionExpired
    case permissionDenied
    case insufficientPrivileges
    case userNotFound
    case departmentAccessDenied

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to continue"
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .insufficientPrivileges:
            return "You cannot assign a role higher than your own"
        case .userNotFound:
            return "User not found"
        case .departmentAccessDenied:
            return "You don't have access to this department"
        }
    }
}

// MARK: - View Modifiers

/// Conditionally shows content based on permission
struct RequirePermission<Content: View>: View {

    let permission: Permission
    let content: Content
    let fallback: AnyView?

    @EnvironmentObject var accessControl: AccessControlManager

    init(
        _ permission: Permission,
        @ViewBuilder content: () -> Content,
        fallback: AnyView? = nil
    ) {
        self.permission = permission
        self.content = content()
        self.fallback = fallback
    }

    var body: some View {
        if accessControl.hasPermission(permission) {
            content
        } else if let fallback = fallback {
            fallback
        }
    }
}

extension View {
    /// Only show this view if user has the required permission
    func requirePermission(_ permission: Permission) -> some View {
        RequirePermission(permission) {
            self
        }
    }

    /// Disable this view if user lacks the required permission
    func disableWithoutPermission(_ permission: Permission) -> some View {
        modifier(PermissionDisableModifier(permission: permission))
    }
}

struct PermissionDisableModifier: ViewModifier {
    let permission: Permission
    @EnvironmentObject var accessControl: AccessControlManager

    func body(content: Content) -> some View {
        content
            .disabled(!accessControl.hasPermission(permission))
            .opacity(accessControl.hasPermission(permission) ? 1.0 : 0.5)
    }
}

// MARK: - User Info Header

struct UserInfoHeader: View {

    @EnvironmentObject var accessControl: AccessControlManager

    var body: some View {
        if let session = accessControl.currentSession {
            HStack(spacing: MedicalSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(MedicalColors.Brand.primary.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Text(session.staffMember.initials)
                        .font(MedicalTypography.labelLarge)
                        .foregroundColor(MedicalColors.Brand.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.staffMember.fullName)
                        .font(MedicalTypography.titleMedium)
                        .foregroundColor(MedicalColors.Neutral.textPrimary)

                    Text(session.staffMember.role.rawValue)
                        .font(MedicalTypography.caption)
                        .foregroundColor(MedicalColors.Neutral.textSecondary)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Role Badge

struct RoleBadge: View {

    let role: StaffRole

    var body: some View {
        Text(role.rawValue)
            .font(MedicalTypography.captionBold)
            .foregroundColor(roleColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(roleColor.opacity(0.15))
            .clipShape(Capsule())
    }

    private var roleColor: Color {
        switch role.category {
        case "Administrative":
            return Color(hex: "7C3AED")
        case "Physician":
            return MedicalColors.Brand.primary
        case "Nursing":
            return Color(hex: "EC4899")
        case "Allied Health":
            return Color(hex: "0EA5E9")
        case "Support":
            return Color(hex: "F59E0B")
        default:
            return Color(hex: "6B7280")
        }
    }
}

// MARK: - Preview

#Preview("User Info Header") {
    VStack {
        UserInfoHeader()
            .padding()
            .background(Color(.systemBackground))
    }
    .environmentObject(AccessControlManager.shared)
}

#Preview("Role Badges") {
    VStack(spacing: MedicalSpacing.md) {
        ForEach([StaffRole.organizationAdmin, .attendingPhysician, .registeredNurse, .technician, .administrativeStaff], id: \.rawValue) { role in
            HStack {
                Text(role.rawValue)
                Spacer()
                RoleBadge(role: role)
            }
        }
    }
    .padding()
}
