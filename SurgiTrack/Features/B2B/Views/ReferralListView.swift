// ReferralListView.swift
// SurgiTrack → MedTrack
// B2B Referral Management UI
// Created on 26/12/2025

import SwiftUI

/// Comprehensive referral list with filtering and quick actions
struct ReferralListView: View {

    @EnvironmentObject var referralManager: ReferralManager
    @EnvironmentObject var accessControl: AccessControlManager
    @State private var selectedTab: ReferralTab = .incoming
    @State private var filterStatus: ReferralStatus?
    @State private var selectedReferral: Referral?
    @State private var showingCreateReferral = false
    @State private var showingDeclineSheet = false
    @State private var referralToDecline: Referral?
    @State private var declineReason = ""
    @State private var isProcessing = false

    enum ReferralTab: String, CaseIterable {
        case incoming = "Incoming"
        case outgoing = "Outgoing"

        var icon: String {
            switch self {
            case .incoming: return "arrow.down.circle"
            case .outgoing: return "arrow.up.circle"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab Selector
                    tabSelector

                    // Filter Bar
                    filterBar
                        .padding(.horizontal, MedicalSpacing.lg)
                        .padding(.vertical, MedicalSpacing.sm)

                    // Stats Summary
                    if selectedTab == .incoming {
                        statsBar
                            .padding(.horizontal, MedicalSpacing.lg)
                            .padding(.bottom, MedicalSpacing.sm)
                    }

                    // Referral List
                    if referralList.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: MedicalSpacing.md) {
                                ForEach(referralList) { referral in
                                    ReferralCard(
                                        referral: referral,
                                        onAccept: selectedTab == .incoming ? {
                                            acceptReferral(referral)
                                        } : nil,
                                        onDecline: selectedTab == .incoming ? {
                                            showDeclineSheet(for: referral)
                                        } : nil,
                                        onView: {
                                            selectedReferral = referral
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, MedicalSpacing.lg)
                            .padding(.vertical, MedicalSpacing.md)
                        }
                    }
                }
            }
            .navigationTitle("Referrals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateReferral = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                    .accessibilityLabel("Create new referral")
                    .disableWithoutPermission(.createReferrals)
                }
            }
            .sheet(item: $selectedReferral) { referral in
                ReferralDetailView(referral: referral)
            }
            .sheet(isPresented: $showingCreateReferral) {
                CreateReferralView()
                    .environmentObject(referralManager)
            }
            .sheet(isPresented: $showingDeclineSheet) {
                declineSheet
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ReferralTab.allCases, id: \.self) { tab in
                Button(action: { withAnimation { selectedTab = tab } }) {
                    VStack(spacing: MedicalSpacing.xs) {
                        HStack(spacing: MedicalSpacing.sm) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                                .font(MedicalTypography.labelLarge)

                            // Badge count
                            if let count = badgeCount(for: tab), count > 0 {
                                Text("\(count)")
                                    .font(MedicalTypography.captionBold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(MedicalColors.Brand.primary)
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(selectedTab == tab ? MedicalColors.Brand.primary : MedicalColors.Neutral.textSecondary)

                        Rectangle()
                            .fill(selectedTab == tab ? MedicalColors.Brand.primary : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MedicalSpacing.md)
                }
                .accessibilityLabel("\(tab.rawValue) referrals")
                .accessibilityHint(selectedTab == tab ? "Selected" : "Double tap to view")
            }
        }
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MedicalSpacing.sm) {
                FilterChip(
                    title: "All",
                    isSelected: filterStatus == nil,
                    action: { filterStatus = nil }
                )

                ForEach([ReferralStatus.pending, .accepted, .declined, .completed], id: \.self) { status in
                    FilterChip(
                        title: status.rawValue,
                        count: referralCount(for: status),
                        color: status.color,
                        isSelected: filterStatus == status,
                        action: { filterStatus = status }
                    )
                }
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: MedicalSpacing.lg) {
            StatItem(
                icon: "exclamationmark.triangle.fill",
                value: "\(referralManager.urgentReferrals.count)",
                label: "Urgent",
                color: MedicalColors.Clinical.abnormal
            )

            Divider()
                .frame(height: 24)

            StatItem(
                icon: "clock.fill",
                value: "\(referralManager.overdueReferrals.count)",
                label: "Overdue",
                color: MedicalColors.Clinical.criticalValue
            )

            Divider()
                .frame(height: 24)

            StatItem(
                icon: "checkmark.circle.fill",
                value: "\(referralManager.pendingIncomingCount)",
                label: "Pending",
                color: MedicalColors.Brand.primary
            )
        }
        .padding(MedicalSpacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(MedicalCardStyle.radiusMedium)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MedicalSpacing.lg) {
            Image(systemName: selectedTab == .incoming ? "tray.fill" : "paperplane.fill")
                .font(.system(size: 64))
                .foregroundColor(MedicalColors.Neutral.textTertiary)

            VStack(spacing: MedicalSpacing.xs) {
                Text("No \(selectedTab.rawValue) Referrals")
                    .font(MedicalTypography.headlineMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                Text(selectedTab == .incoming ?
                    "You have no incoming referrals at this time" :
                    "You haven't sent any referrals yet")
                    .font(MedicalTypography.bodyMedium)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if selectedTab == .outgoing {
                Button(action: { showingCreateReferral = true }) {
                    Text("Create Referral")
                        .font(MedicalTypography.button)
                        .foregroundColor(.white)
                        .padding(.horizontal, MedicalSpacing.xl)
                        .padding(.vertical, MedicalSpacing.md)
                        .background(MedicalColors.Brand.primary)
                        .cornerRadius(MedicalCardStyle.radiusSmall)
                }
                .frame(minWidth: 44, minHeight: 44)
                .disableWithoutPermission(.createReferrals)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(MedicalSpacing.xl)
    }

    // MARK: - Decline Sheet

    private var declineSheet: some View {
        NavigationView {
            VStack(spacing: MedicalSpacing.lg) {
                if let referral = referralToDecline {
                    // Patient Info
                    VStack(alignment: .leading, spacing: MedicalSpacing.sm) {
                        Text("Declining Referral")
                            .font(MedicalTypography.headlineSmall)
                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                        HStack {
                            Text("Patient:")
                                .font(MedicalTypography.labelMedium)
                                .foregroundColor(MedicalColors.Neutral.textSecondary)
                            Text(referral.patientName)
                                .font(MedicalTypography.bodyMedium)
                                .foregroundColor(MedicalColors.Neutral.textPrimary)
                        }

                        HStack {
                            Text("Reason:")
                                .font(MedicalTypography.labelMedium)
                                .foregroundColor(MedicalColors.Neutral.textSecondary)
                            Text(referral.reason)
                                .font(MedicalTypography.bodyMedium)
                                .foregroundColor(MedicalColors.Neutral.textPrimary)
                        }
                    }
                    .padding(MedicalSpacing.lg)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(MedicalCardStyle.radiusMedium)

                    // Decline Reason
                    VStack(alignment: .leading, spacing: MedicalSpacing.sm) {
                        Text("Reason for Declining")
                            .font(MedicalTypography.labelLarge)
                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                        TextEditor(text: $declineReason)
                            .frame(minHeight: 100)
                            .padding(MedicalSpacing.sm)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(MedicalCardStyle.radiusSmall)
                            .overlay(
                                RoundedRectangle(cornerRadius: MedicalCardStyle.radiusSmall)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                            .accessibilityLabel("Decline reason text field")
                    }

                    Spacer()

                    // Decline Button
                    Button(action: confirmDecline) {
                        Text("Decline Referral")
                            .font(MedicalTypography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MedicalSpacing.md)
                            .background(MedicalColors.Clinical.criticalValue)
                            .cornerRadius(MedicalCardStyle.radiusSmall)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(declineReason.isEmpty)
                    .opacity(declineReason.isEmpty ? 0.5 : 1.0)
                    .accessibilityLabel("Confirm decline referral")
                }
            }
            .padding(MedicalSpacing.lg)
            .navigationTitle("Decline Referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingDeclineSheet = false
                        declineReason = ""
                        referralToDecline = nil
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var referralList: [Referral] {
        let list = selectedTab == .incoming ?
            referralManager.incomingReferrals :
            referralManager.outgoingReferrals

        if let status = filterStatus {
            return list.filter { $0.status == status }
        }

        return list
    }

    private func badgeCount(for tab: ReferralTab) -> Int? {
        switch tab {
        case .incoming:
            return referralManager.pendingIncomingCount > 0 ? referralManager.pendingIncomingCount : nil
        case .outgoing:
            return nil
        }
    }

    private func referralCount(for status: ReferralStatus) -> Int {
        referralList.filter { $0.status == status }.count
    }

    // MARK: - Actions

    private func acceptReferral(_ referral: Referral) {
        guard let session = accessControl.currentSession else { return }

        isProcessing = true
        Task {
            do {
                try await referralManager.acceptReferral(
                    referral.id,
                    acceptingProviderId: session.staffMember.id,
                    acceptingProviderName: session.staffMember.fullName
                )
                isProcessing = false
            } catch {
                isProcessing = false
                // Handle error
            }
        }
    }

    private func showDeclineSheet(for referral: Referral) {
        referralToDecline = referral
        declineReason = ""
        showingDeclineSheet = true
    }

    private func confirmDecline() {
        guard let referral = referralToDecline,
              let session = accessControl.currentSession else { return }

        isProcessing = true
        showingDeclineSheet = false

        Task {
            do {
                try await referralManager.declineReferral(
                    referral.id,
                    reason: declineReason,
                    declinedBy: session.staffMember.id,
                    declinedByName: session.staffMember.fullName
                )
                isProcessing = false
                referralToDecline = nil
                declineReason = ""
            } catch {
                isProcessing = false
                // Handle error
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var count: Int?
    var color: Color?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MedicalSpacing.xs) {
                Text(title)
                    .font(MedicalTypography.labelMedium)

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(MedicalTypography.captionBold)
                }
            }
            .foregroundColor(isSelected ? .white : (color ?? MedicalColors.Neutral.textPrimary))
            .padding(.horizontal, MedicalSpacing.md)
            .padding(.vertical, MedicalSpacing.sm)
            .background(
                isSelected ?
                    (color ?? MedicalColors.Brand.primary) :
                    Color(.secondarySystemBackground)
            )
            .cornerRadius(MedicalCardStyle.radiusSmall)
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("\(title) filter")
        .accessibilityHint(isSelected ? "Selected" : "Double tap to filter")
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: MedicalSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(MedicalTypography.titleMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                Text(label)
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }
}

// MARK: - Referral Detail View

struct ReferralDetailView: View {
    let referral: Referral
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: MedicalSpacing.lg) {
                    // Patient Section
                    VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                        Text("Patient Information")
                            .font(MedicalTypography.headlineSmall)

                        VStack(spacing: MedicalSpacing.sm) {
                            DetailRow(label: "Name", value: referral.patientName)
                            DetailRow(label: "MRN", value: referral.patientMRN)
                        }
                    }
                    .padding(MedicalSpacing.lg)
                    .background(Color(.systemBackground))
                    .cornerRadius(MedicalCardStyle.radiusMedium)

                    // Referral Details
                    VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                        Text("Referral Details")
                            .font(MedicalTypography.headlineSmall)

                        VStack(spacing: MedicalSpacing.sm) {
                            DetailRow(label: "From", value: referral.fromDepartmentName)
                            DetailRow(label: "To", value: referral.toDepartmentName)
                            DetailRow(label: "Priority", value: referral.priority.rawValue)
                            DetailRow(label: "Status", value: referral.status.rawValue)
                            DetailRow(label: "Referring Provider", value: referral.referringProviderName)
                        }
                    }
                    .padding(MedicalSpacing.lg)
                    .background(Color(.systemBackground))
                    .cornerRadius(MedicalCardStyle.radiusMedium)

                    // Clinical Summary
                    VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                        Text("Clinical Summary")
                            .font(MedicalTypography.headlineSmall)

                        VStack(alignment: .leading, spacing: MedicalSpacing.sm) {
                            Text("Reason:")
                                .font(MedicalTypography.labelLarge)
                                .foregroundColor(MedicalColors.Neutral.textSecondary)
                            Text(referral.reason)
                                .font(MedicalTypography.bodyMedium)

                            Text("Summary:")
                                .font(MedicalTypography.labelLarge)
                                .foregroundColor(MedicalColors.Neutral.textSecondary)
                            Text(referral.clinicalSummary)
                                .font(MedicalTypography.bodyMedium)
                        }
                    }
                    .padding(MedicalSpacing.lg)
                    .background(Color(.systemBackground))
                    .cornerRadius(MedicalCardStyle.radiusMedium)

                    // Notes
                    if !referral.notes.isEmpty {
                        VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                            Text("Notes")
                                .font(MedicalTypography.headlineSmall)

                            ForEach(referral.notes) { note in
                                VStack(alignment: .leading, spacing: MedicalSpacing.xs) {
                                    HStack {
                                        Text(note.authorName)
                                            .font(MedicalTypography.labelMedium)
                                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                                        Spacer()

                                        Text(note.createdAt, style: .relative)
                                            .font(MedicalTypography.caption)
                                            .foregroundColor(MedicalColors.Neutral.textSecondary)
                                    }

                                    Text(note.content)
                                        .font(MedicalTypography.bodySmall)
                                        .foregroundColor(MedicalColors.Neutral.textSecondary)
                                }
                                .padding(MedicalSpacing.md)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(MedicalCardStyle.radiusSmall)
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
            .navigationTitle("Referral Details")
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

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(MedicalTypography.labelMedium)
                .foregroundColor(MedicalColors.Neutral.textSecondary)
            Spacer()
            Text(value)
                .font(MedicalTypography.bodyMedium)
                .foregroundColor(MedicalColors.Neutral.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview("Referral List") {
    ReferralListView()
        .environmentObject(ReferralManager.shared)
        .environmentObject(AccessControlManager.shared)
}
