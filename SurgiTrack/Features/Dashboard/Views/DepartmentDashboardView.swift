// DepartmentDashboardView.swift
// SurgiTrack → MedTrack
// Department-specific dashboard with contextual metrics
// Created on 26/12/2025

import SwiftUI

struct DepartmentDashboardView: View {

    @EnvironmentObject var departmentManager: DepartmentManager
    @EnvironmentObject var accessControl: AccessControlManager
    @EnvironmentObject var referralManager: ReferralManager

    @State private var showingDepartmentSelector = false
    @State private var selectedTab: DashboardTab = .overview

    enum DashboardTab: String, CaseIterable {
        case overview = "Overview"
        case patients = "Patients"
        case referrals = "Referrals"
        case assessments = "Assessments"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: MedicalSpacing.lg) {
                    // Department Header
                    departmentHeader

                    // Quick Stats
                    quickStatsSection

                    // Tab Picker
                    tabPicker

                    // Tab Content
                    tabContent
                }
                .padding(MedicalSpacing.lg)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DepartmentHeaderView()
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: MedicalSpacing.sm) {
                        // Referral notifications
                        if referralManager.pendingIncomingCount > 0 {
                            Button(action: { selectedTab = .referrals }) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 18))

                                    Text("\(referralManager.pendingIncomingCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(MedicalColors.Clinical.criticalValue)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }

                        // User menu
                        Menu {
                            Button(action: {}) {
                                Label("Profile", systemImage: "person.circle")
                            }
                            Button(action: {}) {
                                Label("Settings", systemImage: "gear")
                            }
                            Divider()
                            Button(role: .destructive, action: {
                                accessControl.endSession()
                            }) {
                                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            UserAvatarButton()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Department Header

    private var departmentHeader: some View {
        Group {
            if let department = departmentManager.currentDepartment {
                HStack(spacing: MedicalSpacing.lg) {
                    // Department icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(department.color.opacity(0.15))
                            .frame(width: 60, height: 60)

                        Image(systemName: department.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(department.color)
                    }

                    VStack(alignment: .leading, spacing: MedicalSpacing.xxs) {
                        Text(department.name)
                            .font(MedicalTypography.headlineMedium)
                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                        Text(department.facilityName)
                            .font(MedicalTypography.bodySmall)
                            .foregroundColor(MedicalColors.Neutral.textSecondary)

                        HStack(spacing: MedicalSpacing.md) {
                            Label("\(department.activePatients) Active", systemImage: "person.2.fill")
                            Label("\(department.staffCount) Staff", systemImage: "stethoscope")
                        }
                        .font(MedicalTypography.caption)
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                    }

                    Spacer()
                }
                .padding(MedicalSpacing.lg)
                .background(Color(.systemBackground))
                .cornerRadius(MedicalCardStyle.radiusLarge)
                .subtleElevation()
            }
        }
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: MedicalSpacing.md) {
            QuickStatsCard(
                title: "Today's Patients",
                value: "12",
                icon: "person.2.fill",
                trend: "+3",
                trendPositive: true
            )

            QuickStatsCard(
                title: "Pending Referrals",
                value: "\(referralManager.pendingIncomingCount)",
                icon: "arrow.left.arrow.right",
                accentColor: referralManager.pendingIncomingCount > 0 ? MedicalColors.Clinical.abnormal : MedicalColors.Brand.primary
            )

            QuickStatsCard(
                title: "Assessments Due",
                value: "5",
                icon: "checklist",
                accentColor: Color(hex: "8B5CF6")
            )

            QuickStatsCard(
                title: "Bed Occupancy",
                value: "85%",
                icon: "bed.double.fill",
                trend: "-2%",
                trendPositive: true,
                accentColor: Color(hex: "0EA5E9")
            )
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MedicalSpacing.sm) {
                ForEach(DashboardTab.allCases, id: \.rawValue) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(MedicalTypography.labelMedium)
                            .foregroundColor(selectedTab == tab ? .white : MedicalColors.Neutral.textSecondary)
                            .padding(.horizontal, MedicalSpacing.lg)
                            .padding(.vertical, MedicalSpacing.sm)
                            .background(
                                selectedTab == tab
                                    ? MedicalColors.Brand.primary
                                    : Color(.secondarySystemBackground)
                            )
                            .cornerRadius(MedicalCardStyle.radiusSmall)
                    }
                }
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewTab
        case .patients:
            patientsTab
        case .referrals:
            referralsTab
        case .assessments:
            assessmentsTab
        }
    }

    private var overviewTab: some View {
        VStack(spacing: MedicalSpacing.lg) {
            // Recent Activity
            ActivityTimelineCard(
                title: "Recent Activity",
                activities: [
                    .init(title: "New patient admitted", time: "10 min ago", icon: "person.badge.plus"),
                    .init(title: "Surgery completed", time: "45 min ago", icon: "checkmark.circle.fill", color: MedicalColors.Surgery.completed),
                    .init(title: "Lab results received", time: "2 hours ago", icon: "doc.text.fill", color: MedicalColors.Clinical.verified),
                    .init(title: "Referral accepted", time: "3 hours ago", icon: "arrow.left.arrow.right", color: MedicalColors.Brand.primary)
                ]
            )

            // Department-specific content
            if let department = departmentManager.currentDepartment {
                departmentSpecificContent(for: department.type)
            }
        }
    }

    @ViewBuilder
    private func departmentSpecificContent(for type: DepartmentType) -> some View {
        switch type.category {
        case .surgical:
            SurgicalOverviewCard(
                scheduledToday: 8,
                inProgress: 2,
                completed: 4,
                cancelled: 0
            )

        case .criticalCare:
            VStack(spacing: MedicalSpacing.md) {
                SectionHeader(title: "ED Status", subtitle: "Current census")

                HStack(spacing: MedicalSpacing.md) {
                    CensusCard(title: "Waiting", count: 12, color: MedicalColors.Clinical.abnormal)
                    CensusCard(title: "In Treatment", count: 18, color: MedicalColors.Surgery.inProgress)
                    CensusCard(title: "Pending Admit", count: 5, color: Color(hex: "8B5CF6"))
                }
            }

        default:
            StatsSummaryCard(
                title: "Department Overview",
                icon: type.icon,
                stats: [
                    .init(label: "Scheduled", value: "15"),
                    .init(label: "In Progress", value: "8"),
                    .init(label: "Completed", value: "22"),
                    .init(label: "Pending", value: "3")
                ]
            )
        }
    }

    private var patientsTab: some View {
        VStack(spacing: MedicalSpacing.md) {
            SectionHeader(title: "Active Patients", actionTitle: "See All") {}

            PatientQuickViewCard(
                patientName: "John Smith",
                patientId: "MRN-2024-00123",
                status: .preOperative,
                lastUpdated: "2h ago",
                upcomingSurgery: "Cholecystectomy - Tomorrow 9:00 AM"
            )

            PatientQuickViewCard(
                patientName: "Sarah Johnson",
                patientId: "MRN-2024-00456",
                status: .postOperative,
                lastUpdated: "30m ago"
            )

            PatientQuickViewCard(
                patientName: "Michael Brown",
                patientId: "MRN-2024-00789",
                status: .active,
                lastUpdated: "1h ago"
            )
        }
    }

    private var referralsTab: some View {
        VStack(spacing: MedicalSpacing.md) {
            if referralManager.urgentReferrals.isEmpty && referralManager.incomingReferrals.isEmpty {
                EmptyStateCard(
                    icon: "arrow.left.arrow.right",
                    title: "No Pending Referrals",
                    message: "You have no incoming referrals at this time."
                )
            } else {
                // Urgent referrals
                if !referralManager.urgentReferrals.isEmpty {
                    SectionHeader(title: "Urgent", subtitle: "\(referralManager.urgentReferrals.count) requiring attention")

                    ForEach(referralManager.urgentReferrals) { referral in
                        ReferralCard(
                            referral: referral,
                            onAccept: {},
                            onDecline: {}
                        )
                    }
                }

                // All incoming
                SectionHeader(title: "All Incoming", actionTitle: "View All") {}

                ForEach(referralManager.incomingReferrals.prefix(3)) { referral in
                    ReferralCard(
                        referral: referral,
                        onAccept: {},
                        onDecline: {}
                    )
                }
            }
        }
    }

    private var assessmentsTab: some View {
        VStack(spacing: MedicalSpacing.md) {
            SectionHeader(title: "Available Assessments")

            if let department = departmentManager.currentDepartment {
                ForEach(department.type.availableAssessments.prefix(5), id: \.rawValue) { assessment in
                    AssessmentRow(assessment: assessment)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct UserAvatarButton: View {
    @EnvironmentObject var accessControl: AccessControlManager

    var body: some View {
        if let session = accessControl.currentSession {
            ZStack {
                Circle()
                    .fill(MedicalColors.Brand.primary.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text(session.staffMember.initials)
                    .font(MedicalTypography.captionBold)
                    .foregroundColor(MedicalColors.Brand.primary)
            }
        }
    }
}

struct CensusCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: MedicalSpacing.xs) {
            Text("\(count)")
                .font(MedicalTypography.numericMedium)
                .foregroundColor(color)

            Text(title)
                .font(MedicalTypography.caption)
                .foregroundColor(MedicalColors.Neutral.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MedicalSpacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(MedicalCardStyle.radiusMedium)
        .subtleElevation()
    }
}

struct AssessmentRow: View {
    let assessment: AssessmentType

    var body: some View {
        HStack(spacing: MedicalSpacing.md) {
            Image(systemName: "checklist")
                .font(.system(size: 20))
                .foregroundColor(MedicalColors.Brand.primary)
                .frame(width: 40, height: 40)
                .background(MedicalColors.Brand.primary.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(assessment.rawValue)
                    .font(MedicalTypography.titleMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                Text(assessment.fullName)
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MedicalColors.Neutral.textTertiary)
        }
        .padding(MedicalSpacing.md)
        .background(Color(.systemBackground))
        .cornerRadius(MedicalCardStyle.radiusMedium)
        .subtleElevation()
    }
}

// MARK: - Preview

#Preview("Department Dashboard") {
    DepartmentDashboardView()
        .environmentObject(DepartmentManager.shared)
        .environmentObject(AccessControlManager.shared)
        .environmentObject(ReferralManager.shared)
}
