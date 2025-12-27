// DepartmentSelectorView.swift
// SurgiTrack → MedTrack
// B2B Multi-Department Switching UI
// Created on 26/12/2025

import SwiftUI

/// Comprehensive department selector with stats and quick switching
struct DepartmentSelectorView: View {

    @EnvironmentObject var departmentManager: DepartmentManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedFacility: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Current Department Header
                    if let current = departmentManager.currentDepartment {
                        currentDepartmentHeader(current)
                            .padding(.horizontal, MedicalSpacing.lg)
                            .padding(.vertical, MedicalSpacing.md)
                            .background(Color(.systemBackground))
                    }

                    // Search Bar
                    searchBar
                        .padding(.horizontal, MedicalSpacing.lg)
                        .padding(.vertical, MedicalSpacing.md)

                    // Department List
                    ScrollView {
                        LazyVStack(spacing: MedicalSpacing.lg, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedDepartments.keys.sorted(), id: \.self) { facility in
                                Section {
                                    ForEach(filteredDepartments(for: facility)) { department in
                                        DepartmentCard(
                                            department: department,
                                            isSelected: department.id == departmentManager.currentDepartment?.id,
                                            onSelect: {
                                                withAnimation(MedicalAnimation.spring) {
                                                    departmentManager.switchDepartment(to: department)
                                                    dismiss()
                                                }
                                            }
                                        )
                                    }
                                } header: {
                                    facilityHeader(facility)
                                }
                            }
                        }
                        .padding(.horizontal, MedicalSpacing.lg)
                        .padding(.bottom, MedicalSpacing.xl)
                    }
                }
            }
            .navigationTitle("Select Department")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Close department selector")
                }
            }
        }
    }

    // MARK: - Current Department Header

    private func currentDepartmentHeader(_ department: DepartmentInfo) -> some View {
        VStack(alignment: .leading, spacing: MedicalSpacing.sm) {
            Text("Current Department")
                .font(MedicalTypography.caption)
                .foregroundColor(MedicalColors.Neutral.textSecondary)
                .accessibilityLabel("Current department section")

            HStack(spacing: MedicalSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(department.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: department.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(department.color)
                }
                .accessibilityHidden(true)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(department.name)
                        .font(MedicalTypography.titleLarge)
                        .foregroundColor(MedicalColors.Neutral.textPrimary)

                    Text(department.facilityName)
                        .font(MedicalTypography.bodySmall)
                        .foregroundColor(MedicalColors.Neutral.textSecondary)

                    // Stats
                    HStack(spacing: MedicalSpacing.lg) {
                        Label("\(department.staffCount)", systemImage: "person.2")
                        Label("\(department.activePatients)", systemImage: "bed.double")
                    }
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textTertiary)
                }

                Spacer()

                // Checkmark
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(MedicalColors.Brand.primary)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Currently in \(department.name), \(department.facilityName), \(department.staffCount) staff, \(department.activePatients) active patients")
        }
        .padding(MedicalSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                .fill(department.color.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                        .stroke(department.color.opacity(0.2), lineWidth: 2)
                )
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: MedicalSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MedicalColors.Neutral.textTertiary)
                .accessibilityHidden(true)

            TextField("Search departments...", text: $searchText)
                .textFieldStyle(.plain)
                .font(MedicalTypography.bodyMedium)
                .accessibilityLabel("Search departments")
                .accessibilityHint("Enter text to filter departments")

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

    // MARK: - Facility Header

    private func facilityHeader(_ facility: String) -> some View {
        let departmentCount = filteredDepartments(for: facility).count
        return HStack {
            Image(systemName: "building.2.fill")
                .font(.system(size: 14))
                .foregroundColor(MedicalColors.Neutral.textSecondary)
                .accessibilityHidden(true)

            Text(facility)
                .font(MedicalTypography.labelLarge)
                .foregroundColor(MedicalColors.Neutral.textSecondary)

            Spacer()

            Text("\(departmentCount) dept\(departmentCount == 1 ? "" : "s")")
                .font(MedicalTypography.caption)
                .foregroundColor(MedicalColors.Neutral.textTertiary)
        }
        .padding(.horizontal, MedicalSpacing.md)
        .padding(.vertical, MedicalSpacing.sm)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(facility) facility, \(departmentCount) departments")
    }

    // MARK: - Computed Properties

    private var groupedDepartments: [String: [DepartmentInfo]] {
        Dictionary(grouping: departmentManager.availableDepartments) { $0.facilityName }
    }

    private func filteredDepartments(for facility: String) -> [DepartmentInfo] {
        let departments = groupedDepartments[facility] ?? []

        if searchText.isEmpty {
            return departments
        }

        return departments.filter { dept in
            dept.name.localizedCaseInsensitiveContains(searchText) ||
            dept.type.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Department Card

struct DepartmentCard: View {
    let department: DepartmentInfo
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: MedicalSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(department.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: department.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(department.color)
                }
                .accessibilityHidden(true)

                // Department Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(department.name)
                        .font(MedicalTypography.titleMedium)
                        .foregroundColor(MedicalColors.Neutral.textPrimary)
                        .multilineTextAlignment(.leading)

                    // Department Stats
                    HStack(spacing: MedicalSpacing.lg) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.system(size: 11))
                            Text("\(department.staffCount)")
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "bed.double")
                                .font(.system(size: 11))
                            Text("\(department.activePatients)")
                        }

                        // Status indicator
                        if department.activePatients > 20 {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(MedicalColors.Clinical.abnormal)
                                    .frame(width: 6, height: 6)
                                Text("Busy")
                                    .font(MedicalTypography.captionBold)
                                    .foregroundColor(MedicalColors.Clinical.abnormal)
                            }
                        }
                    }
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
                }

                Spacer()

                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(MedicalColors.Brand.primary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                }
            }
            .padding(MedicalSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                    .fill(isSelected ? department.color.opacity(0.05) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                            .stroke(
                                isSelected ? department.color.opacity(0.3) : Color(.separator),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(department.name) department, \(department.staffCount) staff, \(department.activePatients) active patients")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to this department")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview("Department Selector") {
    DepartmentSelectorView()
        .environmentObject(DepartmentManager.shared)
}

#Preview("Department Card") {
    VStack(spacing: MedicalSpacing.md) {
        DepartmentCard(
            department: DepartmentInfo(
                id: UUID(),
                name: "General Surgery",
                type: .generalSurgery,
                facilityName: "Main Hospital",
                staffCount: 24,
                activePatients: 18
            ),
            isSelected: true,
            onSelect: {}
        )

        DepartmentCard(
            department: DepartmentInfo(
                id: UUID(),
                name: "Emergency Department",
                type: .emergencyMedicine,
                facilityName: "Main Hospital",
                staffCount: 45,
                activePatients: 32
            ),
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
