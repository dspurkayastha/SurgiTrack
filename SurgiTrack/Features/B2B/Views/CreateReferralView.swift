// CreateReferralView.swift
// SurgiTrack → MedTrack
// B2B Referral Creation UI
// Created on 26/12/2025

import SwiftUI

/// Comprehensive form for creating inter-department referrals
struct CreateReferralView: View {

    @EnvironmentObject var referralManager: ReferralManager
    @EnvironmentObject var departmentManager: DepartmentManager
    @EnvironmentObject var accessControl: AccessControlManager
    @Environment(\.dismiss) var dismiss

    // Form Fields
    @State private var selectedDepartment: DepartmentInfo?
    @State private var selectedPatient: MockPatient?
    @State private var priority: ReferralPriority = .routine
    @State private var reason = ""
    @State private var clinicalSummary = ""
    @State private var requestedDate: Date?
    @State private var includeRequestedDate = false

    // UI State
    @State private var showingDepartmentPicker = false
    @State private var showingPatientPicker = false
    @State private var isSubmitting = false
    @State private var validationError: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MedicalSpacing.lg) {
                        // Patient Selection
                        sectionHeader("Patient", required: true)
                        patientSelector

                        // Department Selection
                        sectionHeader("Target Department", required: true)
                        departmentSelector

                        // Priority Selection
                        sectionHeader("Priority", required: true)
                        prioritySelector

                        // Reason
                        sectionHeader("Reason for Referral", required: true)
                        reasonField

                        // Clinical Summary
                        sectionHeader("Clinical Summary", required: true)
                        clinicalSummaryField

                        // Requested Date
                        sectionHeader("Requested Appointment Date", required: false)
                        requestedDateSection

                        // Validation Error
                        if let error = validationError {
                            errorBanner(error)
                        }

                        // Submit Button
                        submitButton
                            .padding(.top, MedicalSpacing.md)
                    }
                    .padding(MedicalSpacing.lg)
                }
            }
            .navigationTitle("Create Referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel referral creation")
                }
            }
            .sheet(isPresented: $showingDepartmentPicker) {
                DepartmentPickerSheet(
                    departments: availableDepartments,
                    selectedDepartment: $selectedDepartment
                )
            }
            .sheet(isPresented: $showingPatientPicker) {
                PatientPickerSheet(
                    patients: mockPatients,
                    selectedPatient: $selectedPatient
                )
            }
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: MedicalSpacing.md) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Creating Referral...")
                                .font(MedicalTypography.bodyMedium)
                                .foregroundColor(MedicalColors.Neutral.textPrimary)
                        }
                        .padding(MedicalSpacing.xl)
                        .background(Color(.systemBackground))
                        .cornerRadius(MedicalCardStyle.radiusMedium)
                    }
                }
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, required: Bool) -> some View {
        HStack(spacing: MedicalSpacing.xs) {
            Text(title)
                .font(MedicalTypography.labelLarge)
                .foregroundColor(MedicalColors.Neutral.textPrimary)

            if required {
                Text("*")
                    .font(MedicalTypography.labelLarge)
                    .foregroundColor(MedicalColors.Clinical.criticalValue)
            }

            Spacer()
        }
    }

    // MARK: - Patient Selector

    private var patientSelector: some View {
        Button(action: { showingPatientPicker = true }) {
            HStack(spacing: MedicalSpacing.md) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(selectedPatient != nil ? MedicalColors.Brand.primary : MedicalColors.Neutral.textTertiary)
                    .accessibilityHidden(true)

                if let patient = selectedPatient {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(patient.name)
                            .font(MedicalTypography.bodyMedium)
                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                        Text(patient.mrn)
                            .font(MedicalTypography.monoSmall)
                            .foregroundColor(MedicalColors.Neutral.textSecondary)
                    }
                } else {
                    Text("Select Patient")
                        .font(MedicalTypography.bodyMedium)
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(MedicalColors.Neutral.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(MedicalSpacing.lg)
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(selectedPatient != nil ? "Patient: \(selectedPatient!.name)" : "Select patient")
        .accessibilityHint("Double tap to choose a patient")
    }

    // MARK: - Department Selector

    private var departmentSelector: some View {
        Button(action: { showingDepartmentPicker = true }) {
            HStack(spacing: MedicalSpacing.md) {
                if let dept = selectedDepartment {
                    Image(systemName: dept.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(dept.color)
                        .frame(width: 40, height: 40)
                        .background(dept.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                        .frame(width: 40, height: 40)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let dept = selectedDepartment {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dept.name)
                            .font(MedicalTypography.bodyMedium)
                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                        Text(dept.facilityName)
                            .font(MedicalTypography.caption)
                            .foregroundColor(MedicalColors.Neutral.textSecondary)
                    }
                } else {
                    Text("Select Department")
                        .font(MedicalTypography.bodyMedium)
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(MedicalColors.Neutral.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(MedicalSpacing.lg)
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(selectedDepartment != nil ? "Department: \(selectedDepartment!.name)" : "Select department")
        .accessibilityHint("Double tap to choose a department")
    }

    // MARK: - Priority Selector

    private var prioritySelector: some View {
        VStack(spacing: MedicalSpacing.sm) {
            ForEach(ReferralPriority.allCases, id: \.self) { priorityLevel in
                Button(action: { priority = priorityLevel }) {
                    HStack(spacing: MedicalSpacing.md) {
                        Circle()
                            .fill(priorityLevel.color)
                            .frame(width: 12, height: 12)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(priorityLevel.rawValue)
                                .font(MedicalTypography.bodyMedium)
                                .foregroundColor(MedicalColors.Neutral.textPrimary)

                            Text("Response time: \(priorityLevel.responseTimeHours)h")
                                .font(MedicalTypography.caption)
                                .foregroundColor(MedicalColors.Neutral.textSecondary)
                        }

                        Spacer()

                        if priority == priorityLevel {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(MedicalColors.Brand.primary)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(MedicalSpacing.md)
                    .background(
                        priority == priorityLevel ?
                            priorityLevel.color.opacity(0.1) :
                            Color(.systemBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MedicalCardStyle.radiusSmall)
                            .stroke(
                                priority == priorityLevel ? priorityLevel.color : Color(.separator),
                                lineWidth: priority == priorityLevel ? 2 : 1
                            )
                    )
                    .cornerRadius(MedicalCardStyle.radiusSmall)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("\(priorityLevel.rawValue) priority, \(priorityLevel.responseTimeHours) hour response time")
                .accessibilityHint(priority == priorityLevel ? "Selected" : "Double tap to select")
            }
        }
    }

    // MARK: - Reason Field

    private var reasonField: some View {
        TextField("Brief description of referral reason", text: $reason)
            .font(MedicalTypography.bodyMedium)
            .padding(MedicalSpacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: MedicalCardStyle.radiusSmall)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .accessibilityLabel("Reason for referral")
            .accessibilityHint("Enter a brief description")
    }

    // MARK: - Clinical Summary Field

    private var clinicalSummaryField: some View {
        VStack(alignment: .leading, spacing: MedicalSpacing.xs) {
            TextEditor(text: $clinicalSummary)
                .font(MedicalTypography.bodyMedium)
                .frame(minHeight: 120)
                .padding(MedicalSpacing.sm)
                .background(Color(.systemBackground))
                .cornerRadius(MedicalCardStyle.radiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: MedicalCardStyle.radiusSmall)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .accessibilityLabel("Clinical summary")
                .accessibilityHint("Enter detailed clinical information")

            Text("Include relevant clinical history, symptoms, test results, and specific consultation questions.")
                .font(MedicalTypography.caption)
                .foregroundColor(MedicalColors.Neutral.textSecondary)
        }
    }

    // MARK: - Requested Date Section

    private var requestedDateSection: some View {
        VStack(spacing: MedicalSpacing.md) {
            Toggle(isOn: $includeRequestedDate) {
                Text("Request Specific Date")
                    .font(MedicalTypography.bodyMedium)
            }
            .tint(MedicalColors.Brand.primary)
            .padding(MedicalSpacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusSmall)

            if includeRequestedDate {
                DatePicker(
                    "Preferred Date",
                    selection: Binding(
                        get: { requestedDate ?? Date().addingTimeInterval(86400) },
                        set: { requestedDate = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding(MedicalSpacing.md)
                .background(Color(.systemBackground))
                .cornerRadius(MedicalCardStyle.radiusMedium)
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: MedicalSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(MedicalColors.Clinical.criticalValue)
                .accessibilityHidden(true)

            Text(message)
                .font(MedicalTypography.bodySmall)
                .foregroundColor(MedicalColors.Clinical.criticalValue)

            Spacer()
        }
        .padding(MedicalSpacing.md)
        .background(MedicalColors.Clinical.criticalValue.opacity(0.1))
        .cornerRadius(MedicalCardStyle.radiusSmall)
        .accessibilityLabel("Error: \(message)")
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: submitReferral) {
            Text("Create Referral")
                .font(MedicalTypography.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MedicalSpacing.lg)
                .background(isFormValid ? MedicalColors.Brand.primary : MedicalColors.Neutral.textTertiary)
                .cornerRadius(MedicalCardStyle.radiusMedium)
        }
        .frame(minWidth: 44, minHeight: 44)
        .disabled(!isFormValid)
        .accessibilityLabel("Create referral")
        .accessibilityHint(isFormValid ? "Double tap to submit" : "Complete required fields to enable")
    }

    // MARK: - Computed Properties

    private var availableDepartments: [DepartmentInfo] {
        // Exclude current department
        departmentManager.availableDepartments.filter {
            $0.id != departmentManager.currentDepartment?.id
        }
    }

    private var isFormValid: Bool {
        selectedPatient != nil &&
        selectedDepartment != nil &&
        !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !clinicalSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    private func submitReferral() {
        guard let patient = selectedPatient,
              let department = selectedDepartment,
              let currentDept = departmentManager.currentDepartment,
              let session = accessControl.currentSession else {
            validationError = "Missing required information"
            return
        }

        validationError = nil
        isSubmitting = true

        let referral = Referral(
            patientId: patient.id,
            patientName: patient.name,
            patientMRN: patient.mrn,
            fromDepartmentId: currentDept.id,
            fromDepartmentName: currentDept.name,
            fromDepartmentType: currentDept.type,
            toDepartmentId: department.id,
            toDepartmentName: department.name,
            toDepartmentType: department.type,
            referringProviderId: session.staffMember.id,
            referringProviderName: session.staffMember.fullName,
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
            clinicalSummary: clinicalSummary.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            requestedDate: includeRequestedDate ? requestedDate : nil
        )

        Task {
            do {
                try await referralManager.createReferral(referral)
                isSubmitting = false
                dismiss()
            } catch {
                isSubmitting = false
                validationError = "Failed to create referral: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Mock Patient Model

struct MockPatient: Identifiable {
    let id: UUID
    let name: String
    let mrn: String
    let age: Int
    let gender: String
}

// Sample patients for development
private let mockPatients: [MockPatient] = [
    MockPatient(id: UUID(), name: "John Smith", mrn: "MRN-2024-00123", age: 45, gender: "M"),
    MockPatient(id: UUID(), name: "Mary Williams", mrn: "MRN-2024-00456", age: 68, gender: "F"),
    MockPatient(id: UUID(), name: "Robert Brown", mrn: "MRN-2024-00789", age: 52, gender: "M"),
    MockPatient(id: UUID(), name: "Jennifer Davis", mrn: "MRN-2024-01012", age: 34, gender: "F"),
    MockPatient(id: UUID(), name: "Michael Johnson", mrn: "MRN-2024-01234", age: 61, gender: "M")
]

// MARK: - Department Picker Sheet

struct DepartmentPickerSheet: View {
    let departments: [DepartmentInfo]
    @Binding var selectedDepartment: DepartmentInfo?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(groupedDepartments.keys.sorted(), id: \.self) { facility in
                    Section(header: Text(facility)) {
                        ForEach(groupedDepartments[facility] ?? []) { dept in
                            Button(action: {
                                selectedDepartment = dept
                                dismiss()
                            }) {
                                HStack(spacing: MedicalSpacing.md) {
                                    Image(systemName: dept.icon)
                                        .foregroundColor(dept.color)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(dept.name)
                                            .font(MedicalTypography.bodyMedium)
                                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                                        Text("\(dept.staffCount) staff, \(dept.activePatients) patients")
                                            .font(MedicalTypography.caption)
                                            .foregroundColor(MedicalColors.Neutral.textSecondary)
                                    }

                                    Spacer()

                                    if selectedDepartment?.id == dept.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(MedicalColors.Brand.primary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Department")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var groupedDepartments: [String: [DepartmentInfo]] {
        Dictionary(grouping: departments) { $0.facilityName }
    }
}

// MARK: - Patient Picker Sheet

struct PatientPickerSheet: View {
    let patients: [MockPatient]
    @Binding var selectedPatient: MockPatient?
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: MedicalSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MedicalColors.Neutral.textTertiary)

                    TextField("Search patients...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(MedicalTypography.bodyMedium)
                }
                .padding(MedicalSpacing.md)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(MedicalCardStyle.radiusSmall)
                .padding()

                // Patient List
                List(filteredPatients) { patient in
                    Button(action: {
                        selectedPatient = patient
                        dismiss()
                    }) {
                        HStack(spacing: MedicalSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(MedicalColors.Brand.primary.opacity(0.15))
                                    .frame(width: 44, height: 44)

                                Text(patient.name.prefix(2).uppercased())
                                    .font(MedicalTypography.titleMedium)
                                    .foregroundColor(MedicalColors.Brand.primary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(patient.name)
                                    .font(MedicalTypography.bodyMedium)
                                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                                HStack(spacing: MedicalSpacing.md) {
                                    Text(patient.mrn)
                                        .font(MedicalTypography.monoSmall)
                                        .foregroundColor(MedicalColors.Neutral.textSecondary)

                                    Text("\(patient.age)y \(patient.gender)")
                                        .font(MedicalTypography.caption)
                                        .foregroundColor(MedicalColors.Neutral.textSecondary)
                                }
                            }

                            Spacer()

                            if selectedPatient?.id == patient.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(MedicalColors.Brand.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var filteredPatients: [MockPatient] {
        if searchText.isEmpty {
            return patients
        }
        return patients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.mrn.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Preview

#Preview("Create Referral") {
    CreateReferralView()
        .environmentObject(ReferralManager.shared)
        .environmentObject(DepartmentManager.shared)
        .environmentObject(AccessControlManager.shared)
}
