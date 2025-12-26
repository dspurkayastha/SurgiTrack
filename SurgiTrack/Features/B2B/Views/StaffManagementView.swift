// StaffManagementView.swift
// SurgiTrack → MedTrack
// B2B Staff Management UI
// Created on 26/12/2025

import SwiftUI

/// Comprehensive staff management for department administrators
struct StaffManagementView: View {

    @EnvironmentObject var accessControl: AccessControlManager
    @EnvironmentObject var departmentManager: DepartmentManager
    @State private var staffMembers: [StaffMember] = []
    @State private var searchText = ""
    @State private var selectedRole: StaffRole?
    @State private var showingInviteSheet = false
    @State private var selectedStaffMember: StaffMember?
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                        .padding(.horizontal, MedicalSpacing.lg)
                        .padding(.vertical, MedicalSpacing.md)
                        .background(Color(.systemBackground))

                    // Filter Bar
                    filterBar
                        .padding(.horizontal, MedicalSpacing.lg)
                        .padding(.vertical, MedicalSpacing.sm)

                    // Stats Bar
                    statsBar
                        .padding(.horizontal, MedicalSpacing.lg)
                        .padding(.bottom, MedicalSpacing.sm)

                    // Staff List
                    if filteredStaff.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: MedicalSpacing.md) {
                                ForEach(groupedStaff.keys.sorted(), id: \.self) { category in
                                    Section {
                                        ForEach(groupedStaff[category] ?? []) { staff in
                                            StaffMemberCard(
                                                staff: staff,
                                                onTap: {
                                                    selectedStaffMember = staff
                                                }
                                            )
                                        }
                                    } header: {
                                        categoryHeader(category)
                                    }
                                }
                            }
                            .padding(.horizontal, MedicalSpacing.lg)
                            .padding(.vertical, MedicalSpacing.md)
                        }
                    }
                }
            }
            .navigationTitle("Staff Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingInviteSheet = true }) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20))
                    }
                    .accessibilityLabel("Invite new staff member")
                    .disableWithoutPermission(.manageStaff)
                }
            }
            .sheet(item: $selectedStaffMember) { staff in
                StaffDetailView(staff: staff)
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteStaffView()
                    .environmentObject(accessControl)
                    .environmentObject(departmentManager)
            }
            .onAppear {
                loadStaffMembers()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: MedicalSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MedicalColors.Neutral.textTertiary)
                .accessibilityHidden(true)

            TextField("Search staff...", text: $searchText)
                .textFieldStyle(.plain)
                .font(MedicalTypography.bodyMedium)
                .accessibilityLabel("Search staff members")

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(MedicalSpacing.md)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(MedicalCardStyle.radiusSmall)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MedicalSpacing.sm) {
                FilterChip(
                    title: "All",
                    count: staffMembers.count,
                    isSelected: selectedRole == nil,
                    action: { selectedRole = nil }
                )

                ForEach([StaffRole.attendingPhysician, .registeredNurse, .resident, .technician, .administrativeStaff], id: \.self) { role in
                    let count = staffMembers.filter { $0.role == role }.count
                    if count > 0 {
                        FilterChip(
                            title: role.rawValue,
                            count: count,
                            isSelected: selectedRole == role,
                            action: { selectedRole = role }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: MedicalSpacing.lg) {
            StatItem(
                icon: "person.2.fill",
                value: "\(staffMembers.filter { $0.isActive }.count)",
                label: "Active",
                color: MedicalColors.Clinical.normal
            )

            Divider()
                .frame(height: 24)

            StatItem(
                icon: "stethoscope",
                value: "\(staffMembers.filter { $0.role.category == "Physician" }.count)",
                label: "Physicians",
                color: MedicalColors.Brand.primary
            )

            Divider()
                .frame(height: 24)

            StatItem(
                icon: "cross.case.fill",
                value: "\(staffMembers.filter { $0.role.category == "Nursing" }.count)",
                label: "Nurses",
                color: Color(hex: "EC4899")
            )
        }
        .padding(MedicalSpacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(MedicalCardStyle.radiusMedium)
    }

    // MARK: - Category Header

    private func categoryHeader(_ category: String) -> some View {
        HStack {
            Image(systemName: categoryIcon(for: category))
                .font(.system(size: 14))
                .foregroundColor(MedicalColors.Neutral.textSecondary)
                .accessibilityHidden(true)

            Text(category)
                .font(MedicalTypography.labelLarge)
                .foregroundColor(MedicalColors.Neutral.textSecondary)

            Spacer()

            let count = (groupedStaff[category] ?? []).count
            Text("\(count)")
                .font(MedicalTypography.caption)
                .foregroundColor(MedicalColors.Neutral.textTertiary)
        }
        .padding(.horizontal, MedicalSpacing.md)
        .padding(.vertical, MedicalSpacing.sm)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MedicalSpacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundColor(MedicalColors.Neutral.textTertiary)

            VStack(spacing: MedicalSpacing.xs) {
                Text("No Staff Members Found")
                    .font(MedicalTypography.headlineMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                Text(searchText.isEmpty ?
                    "No staff members in this department" :
                    "No staff members match your search")
                    .font(MedicalTypography.bodyMedium)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if accessControl.hasPermission(.manageStaff) {
                Button(action: { showingInviteSheet = true }) {
                    Text("Invite Staff Member")
                        .font(MedicalTypography.button)
                        .foregroundColor(.white)
                        .padding(.horizontal, MedicalSpacing.xl)
                        .padding(.vertical, MedicalSpacing.md)
                        .background(MedicalColors.Brand.primary)
                        .cornerRadius(MedicalCardStyle.radiusSmall)
                }
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(MedicalSpacing.xl)
    }

    // MARK: - Computed Properties

    private var filteredStaff: [StaffMember] {
        var result = staffMembers

        if let role = selectedRole {
            result = result.filter { $0.role == role }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText) ||
                $0.role.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private var groupedStaff: [String: [StaffMember]] {
        Dictionary(grouping: filteredStaff) { $0.role.category }
    }

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Physician": return "stethoscope"
        case "Nursing": return "cross.case.fill"
        case "Allied Health": return "heart.text.square.fill"
        case "Administrative": return "person.text.rectangle.fill"
        case "Support": return "hand.raised.fill"
        default: return "person.fill"
        }
    }

    // MARK: - Data Loading

    private func loadStaffMembers() {
        // In production, this would load from CoreData
        guard let currentDept = departmentManager.currentDepartment else { return }

        staffMembers = [
            StaffMember(
                id: UUID(),
                userId: "user_1",
                firstName: "Sarah",
                lastName: "Johnson",
                email: "sarah.johnson@hospital.com",
                role: .attendingPhysician,
                departmentId: currentDept.id,
                departmentName: currentDept.name,
                facilityId: UUID(),
                organizationId: UUID(),
                isActive: true,
                customPermissions: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            StaffMember(
                id: UUID(),
                userId: "user_2",
                firstName: "Michael",
                lastName: "Chen",
                email: "michael.chen@hospital.com",
                role: .registeredNurse,
                departmentId: currentDept.id,
                departmentName: currentDept.name,
                facilityId: UUID(),
                organizationId: UUID(),
                isActive: true,
                customPermissions: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            StaffMember(
                id: UUID(),
                userId: "user_3",
                firstName: "Emily",
                lastName: "Williams",
                email: "emily.williams@hospital.com",
                role: .resident,
                departmentId: currentDept.id,
                departmentName: currentDept.name,
                facilityId: UUID(),
                organizationId: UUID(),
                isActive: true,
                customPermissions: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            StaffMember(
                id: UUID(),
                userId: "user_4",
                firstName: "David",
                lastName: "Martinez",
                email: "david.martinez@hospital.com",
                role: .technician,
                departmentId: currentDept.id,
                departmentName: currentDept.name,
                facilityId: UUID(),
                organizationId: UUID(),
                isActive: true,
                customPermissions: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            StaffMember(
                id: UUID(),
                userId: "user_5",
                firstName: "Jennifer",
                lastName: "Davis",
                email: "jennifer.davis@hospital.com",
                role: .administrativeStaff,
                departmentId: currentDept.id,
                departmentName: currentDept.name,
                facilityId: UUID(),
                organizationId: UUID(),
                isActive: true,
                customPermissions: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            )
        ]
    }
}

// MARK: - Staff Member Card

struct StaffMemberCard: View {
    let staff: StaffMember
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MedicalSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(staff.isActive ? MedicalColors.Brand.primary.opacity(0.15) : MedicalColors.Neutral.textTertiary.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Text(staff.initials)
                        .font(MedicalTypography.titleMedium)
                        .foregroundColor(staff.isActive ? MedicalColors.Brand.primary : MedicalColors.Neutral.textTertiary)
                }
                .overlay(alignment: .bottomTrailing) {
                    if staff.isActive {
                        Circle()
                            .fill(MedicalColors.Clinical.normal)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                    }
                }
                .accessibilityHidden(true)

                // Staff Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: MedicalSpacing.sm) {
                        Text(staff.fullName)
                            .font(MedicalTypography.bodyMedium)
                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                        if !staff.isActive {
                            Text("Inactive")
                                .font(MedicalTypography.captionBold)
                                .foregroundColor(MedicalColors.Neutral.textTertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(MedicalColors.Neutral.textTertiary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Text(staff.email)
                        .font(MedicalTypography.caption)
                        .foregroundColor(MedicalColors.Neutral.textSecondary)

                    HStack(spacing: MedicalSpacing.sm) {
                        RoleBadge(role: staff.role)

                        if let lastActive = staff.lastActiveAt {
                            Text("Active \(timeAgo(from: lastActive))")
                                .font(MedicalTypography.caption)
                                .foregroundColor(MedicalColors.Neutral.textTertiary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MedicalColors.Neutral.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(MedicalSpacing.lg)
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(staff.fullName), \(staff.role.rawValue), \(staff.isActive ? "Active" : "Inactive")")
        .accessibilityHint("Double tap to view details")
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Staff Detail View

struct StaffDetailView: View {
    let staff: StaffMember
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accessControl: AccessControlManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: MedicalSpacing.lg) {
                    // Header
                    VStack(spacing: MedicalSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(MedicalColors.Brand.primary.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Text(staff.initials)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(MedicalColors.Brand.primary)
                        }

                        VStack(spacing: MedicalSpacing.xs) {
                            Text(staff.fullName)
                                .font(MedicalTypography.headlineLarge)
                                .foregroundColor(MedicalColors.Neutral.textPrimary)

                            RoleBadge(role: staff.role)

                            Text(staff.departmentName)
                                .font(MedicalTypography.bodySmall)
                                .foregroundColor(MedicalColors.Neutral.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MedicalSpacing.lg)

                    // Contact Info
                    VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                        Text("Contact Information")
                            .font(MedicalTypography.headlineSmall)

                        VStack(spacing: MedicalSpacing.sm) {
                            DetailRow(label: "Email", value: staff.email)
                            DetailRow(label: "Status", value: staff.isActive ? "Active" : "Inactive")
                        }
                    }
                    .padding(MedicalSpacing.lg)
                    .background(Color(.systemBackground))
                    .cornerRadius(MedicalCardStyle.radiusMedium)

                    // Permissions
                    VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                        Text("Permissions")
                            .font(MedicalTypography.headlineSmall)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: MedicalSpacing.sm) {
                            ForEach(Array(staff.effectivePermissions).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { permission in
                                HStack(spacing: MedicalSpacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(MedicalColors.Clinical.normal)
                                        .accessibilityHidden(true)

                                    Text(permission.rawValue)
                                        .font(MedicalTypography.caption)
                                        .foregroundColor(MedicalColors.Neutral.textPrimary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, MedicalSpacing.sm)
                                .padding(.vertical, MedicalSpacing.xs)
                                .background(MedicalColors.Clinical.normal.opacity(0.1))
                                .cornerRadius(MedicalCardStyle.radiusSmall)
                            }
                        }
                    }
                    .padding(MedicalSpacing.lg)
                    .background(Color(.systemBackground))
                    .cornerRadius(MedicalCardStyle.radiusMedium)

                    // Actions
                    if accessControl.hasPermission(.manageStaff) {
                        VStack(spacing: MedicalSpacing.md) {
                            Button(action: {}) {
                                Text("Change Role")
                                    .font(MedicalTypography.button)
                                    .foregroundColor(MedicalColors.Brand.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, MedicalSpacing.md)
                                    .background(MedicalColors.Brand.primary.opacity(0.1))
                                    .cornerRadius(MedicalCardStyle.radiusSmall)
                            }
                            .frame(minWidth: 44, minHeight: 44)

                            if staff.isActive {
                                Button(action: {}) {
                                    Text("Deactivate Staff Member")
                                        .font(MedicalTypography.button)
                                        .foregroundColor(MedicalColors.Clinical.criticalValue)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, MedicalSpacing.md)
                                        .background(MedicalColors.Clinical.criticalValue.opacity(0.1))
                                        .cornerRadius(MedicalCardStyle.radiusSmall)
                                }
                                .frame(minWidth: 44, minHeight: 44)
                            }
                        }
                        .padding(MedicalSpacing.lg)
                        .background(Color(.systemBackground))
                        .cornerRadius(MedicalCardStyle.radiusMedium)
                    }
                }
                .padding(MedicalSpacing.lg)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Staff Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Invite Staff View

struct InviteStaffView: View {
    @EnvironmentObject var accessControl: AccessControlManager
    @EnvironmentObject var departmentManager: DepartmentManager
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var selectedRole: StaffRole = .registeredNurse
    @State private var isInviting = false
    @State private var validationError: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: MedicalSpacing.lg) {
                    // Form Fields
                    VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                        Text("Basic Information")
                            .font(MedicalTypography.headlineSmall)

                        VStack(spacing: MedicalSpacing.md) {
                            VStack(alignment: .leading, spacing: MedicalSpacing.xs) {
                                Text("First Name *")
                                    .font(MedicalTypography.labelMedium)
                                    .foregroundColor(MedicalColors.Neutral.textSecondary)

                                TextField("Enter first name", text: $firstName)
                                    .font(MedicalTypography.bodyMedium)
                                    .padding(MedicalSpacing.md)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(MedicalCardStyle.radiusSmall)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MedicalCardStyle.radiusSmall)
                                            .stroke(Color(.separator), lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: MedicalSpacing.xs) {
                                Text("Last Name *")
                                    .font(MedicalTypography.labelMedium)
                                    .foregroundColor(MedicalColors.Neutral.textSecondary)

                                TextField("Enter last name", text: $lastName)
                                    .font(MedicalTypography.bodyMedium)
                                    .padding(MedicalSpacing.md)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(MedicalCardStyle.radiusSmall)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MedicalCardStyle.radiusSmall)
                                            .stroke(Color(.separator), lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: MedicalSpacing.xs) {
                                Text("Email *")
                                    .font(MedicalTypography.labelMedium)
                                    .foregroundColor(MedicalColors.Neutral.textSecondary)

                                TextField("Enter email address", text: $email)
                                    .font(MedicalTypography.bodyMedium)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(MedicalSpacing.md)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(MedicalCardStyle.radiusSmall)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MedicalCardStyle.radiusSmall)
                                            .stroke(Color(.separator), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(MedicalSpacing.lg)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(MedicalCardStyle.radiusMedium)

                    // Role Selection
                    VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                        Text("Role *")
                            .font(MedicalTypography.headlineSmall)

                        Menu {
                            ForEach(availableRoles, id: \.self) { role in
                                Button(action: { selectedRole = role }) {
                                    HStack {
                                        Text(role.rawValue)
                                        if selectedRole == role {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedRole.rawValue)
                                        .font(MedicalTypography.bodyMedium)
                                        .foregroundColor(MedicalColors.Neutral.textPrimary)

                                    Text(selectedRole.category)
                                        .font(MedicalTypography.caption)
                                        .foregroundColor(MedicalColors.Neutral.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(MedicalColors.Neutral.textTertiary)
                            }
                            .padding(MedicalSpacing.md)
                            .background(Color(.systemBackground))
                            .cornerRadius(MedicalCardStyle.radiusSmall)
                            .overlay(
                                RoundedRectangle(cornerRadius: MedicalCardStyle.radiusSmall)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                        }
                    }
                    .padding(MedicalSpacing.lg)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(MedicalCardStyle.radiusMedium)

                    // Validation Error
                    if let error = validationError {
                        HStack(spacing: MedicalSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(MedicalColors.Clinical.criticalValue)

                            Text(error)
                                .font(MedicalTypography.bodySmall)
                                .foregroundColor(MedicalColors.Clinical.criticalValue)
                        }
                        .padding(MedicalSpacing.md)
                        .background(MedicalColors.Clinical.criticalValue.opacity(0.1))
                        .cornerRadius(MedicalCardStyle.radiusSmall)
                    }

                    // Submit Button
                    Button(action: sendInvitation) {
                        Text("Send Invitation")
                            .font(MedicalTypography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MedicalSpacing.lg)
                            .background(isFormValid ? MedicalColors.Brand.primary : MedicalColors.Neutral.textTertiary)
                            .cornerRadius(MedicalCardStyle.radiusMedium)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(!isFormValid)
                }
                .padding(MedicalSpacing.lg)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Invite Staff Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var availableRoles: [StaffRole] {
        guard let session = accessControl.currentSession else {
            return StaffRole.allCases
        }

        // Can only assign roles equal to or lower than your own
        return StaffRole.allCases.filter { $0 <= session.staffMember.role }
    }

    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        email.contains("@")
    }

    // MARK: - Actions

    private func sendInvitation() {
        guard let dept = departmentManager.currentDepartment else { return }

        validationError = nil
        isInviting = true

        Task {
            do {
                try await accessControl.inviteStaffMember(
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    role: selectedRole,
                    departmentId: dept.id
                )
                isInviting = false
                dismiss()
            } catch {
                isInviting = false
                validationError = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview("Staff Management") {
    StaffManagementView()
        .environmentObject(AccessControlManager.shared)
        .environmentObject(DepartmentManager.shared)
}

#Preview("Staff Detail") {
    StaffDetailView(
        staff: StaffMember(
            id: UUID(),
            userId: "user_1",
            firstName: "Sarah",
            lastName: "Johnson",
            email: "sarah.johnson@hospital.com",
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
    )
    .environmentObject(AccessControlManager.shared)
}

#Preview("Invite Staff") {
    InviteStaffView()
        .environmentObject(AccessControlManager.shared)
        .environmentObject(DepartmentManager.shared)
}
