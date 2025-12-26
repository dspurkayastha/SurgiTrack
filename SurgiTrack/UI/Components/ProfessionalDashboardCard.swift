// ProfessionalDashboardCard.swift
// SurgiTrack
// Clean, professional dashboard cards for medical data display
// Created on 26/12/2025

import SwiftUI

// MARK: - Professional Dashboard Card

/// A clean, professional card for dashboard displays
struct ProfessionalDashboardCard<Content: View>: View {

    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconColor: Color = MedicalColors.Brand.primary
    var showChevron: Bool = false
    var action: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(alignment: .leading, spacing: MedicalSpacing.md) {
                // Header
                HStack(spacing: MedicalSpacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(iconColor)
                            .frame(width: 36, height: 36)
                            .background(iconColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(MedicalTypography.titleMedium)
                            .foregroundColor(MedicalColors.Neutral.textPrimary)

                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(MedicalTypography.caption)
                                .foregroundColor(MedicalColors.Neutral.textSecondary)
                        }
                    }

                    Spacer()

                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MedicalColors.Neutral.textTertiary)
                            .accessibilityHidden(true)
                    }
                }

                // Divider
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(height: 1)
                    .accessibilityHidden(true)

                // Content
                content()
            }
            .padding(MedicalSpacing.lg)
            .frame(minHeight: 44)  // Minimum touch target
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusLarge)
            .shadow(
                color: Color.black.opacity(isPressed ? 0.08 : 0.05),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(action != nil ? "Double tap to view details" : "")
        .accessibilityAddTraits(action != nil ? .isButton : .isStaticText)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(MedicalAnimation.microInteraction) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(MedicalAnimation.spring) {
                        isPressed = false
                    }
                }
        )
        .disabled(action == nil)
    }

    private var accessibilityLabelText: String {
        if let subtitle = subtitle {
            return "\(title), \(subtitle)"
        }
        return title
    }
}

// MARK: - Stats Summary Card

/// Compact summary card for key metrics
struct StatsSummaryCard: View {

    struct Stat: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        var color: Color = MedicalColors.Neutral.textPrimary
    }

    let title: String
    let icon: String
    let stats: [Stat]
    var action: (() -> Void)? = nil

    var body: some View {
        ProfessionalDashboardCard(
            title: title,
            icon: icon,
            showChevron: action != nil,
            action: action
        ) {
            HStack(spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                    VStack(spacing: MedicalSpacing.xxs) {
                        Text(stat.value)
                            .font(MedicalTypography.numericMedium)
                            .foregroundColor(stat.color)

                        Text(stat.label)
                            .font(MedicalTypography.caption)
                            .foregroundColor(MedicalColors.Neutral.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(stat.label)")
                    .accessibilityValue(stat.value)

                    if index < stats.count - 1 {
                        Rectangle()
                            .fill(Color(.separator).opacity(0.3))
                            .frame(width: 1, height: 40)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }
}

// MARK: - Activity Timeline Card

/// Card showing recent activity with timeline
struct ActivityTimelineCard: View {

    struct Activity: Identifiable {
        let id = UUID()
        let title: String
        let time: String
        let icon: String
        var color: Color = MedicalColors.Brand.primary
    }

    let title: String
    let activities: [Activity]
    var action: (() -> Void)? = nil

    var body: some View {
        ProfessionalDashboardCard(
            title: title,
            subtitle: "Last 24 hours",
            icon: "clock.arrow.circlepath",
            showChevron: action != nil,
            action: action
        ) {
            VStack(spacing: 0) {
                ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                    HStack(spacing: MedicalSpacing.md) {
                        // Timeline indicator
                        VStack(spacing: 0) {
                            Circle()
                                .fill(activity.color)
                                .frame(width: 8, height: 8)

                            if index < activities.count - 1 {
                                Rectangle()
                                    .fill(Color(.separator).opacity(0.3))
                                    .frame(width: 2, height: 28)
                            }
                        }
                        .accessibilityHidden(true)

                        // Icon
                        Image(systemName: activity.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(activity.color)
                            .frame(width: 28, height: 28)
                            .background(activity.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .accessibilityHidden(true)

                        // Content
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.title)
                                .font(MedicalTypography.bodySmall)
                                .foregroundColor(MedicalColors.Neutral.textPrimary)

                            Text(activity.time)
                                .font(MedicalTypography.caption)
                                .foregroundColor(MedicalColors.Neutral.textTertiary)
                        }

                        Spacer()
                    }
                    .padding(.bottom, index < activities.count - 1 ? MedicalSpacing.sm : 0)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(activity.title), \(activity.time)")
                }
            }
        }
    }
}

// MARK: - Patient Quick View Card

/// Quick patient overview card for dashboard
struct PatientQuickViewCard: View {

    let patientName: String
    let patientId: String
    let status: PatientStatusBadge.Status
    let lastUpdated: String
    var upcomingSurgery: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: MedicalSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(status.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Text(patientName.prefix(2).uppercased())
                        .font(MedicalTypography.titleMedium)
                        .foregroundColor(status.color)
                }
                .accessibilityHidden(true)

                // Info
                VStack(alignment: .leading, spacing: MedicalSpacing.xxs) {
                    Text(patientName)
                        .font(MedicalTypography.titleMedium)
                        .foregroundColor(MedicalColors.Neutral.textPrimary)

                    Text(patientId)
                        .font(MedicalTypography.monoSmall)
                        .foregroundColor(MedicalColors.Neutral.textSecondary)

                    if let surgery = upcomingSurgery {
                        Text(surgery)
                            .font(MedicalTypography.caption)
                            .foregroundColor(MedicalColors.Surgery.scheduled)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: MedicalSpacing.xs) {
                    PatientStatusBadge(status: status, size: .small)

                    Text(lastUpdated)
                        .font(MedicalTypography.caption)
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                }
            }
            .padding(MedicalSpacing.lg)
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
            .subtleElevation()
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(patientName), \(patientId)")
        .accessibilityValue("Status: \(status.rawValue), Last updated: \(lastUpdated)\(upcomingSurgery.map { ", Upcoming: \($0)" } ?? "")")
        .accessibilityHint(action != nil ? "Double tap to view patient details" : "")
    }
}

// MARK: - Surgical Overview Card

/// Overview card for surgical department metrics
struct SurgicalOverviewCard: View {

    let scheduledToday: Int
    let inProgress: Int
    let completed: Int
    let cancelled: Int
    var action: (() -> Void)? = nil

    var body: some View {
        ProfessionalDashboardCard(
            title: "Surgical Overview",
            subtitle: "Today's Schedule",
            icon: "cross.case.fill",
            iconColor: MedicalColors.Surgery.scheduled,
            showChevron: action != nil,
            action: action
        ) {
            HStack(spacing: MedicalSpacing.md) {
                SurgeryMetricView(
                    value: "\(scheduledToday)",
                    label: "Scheduled",
                    color: MedicalColors.Surgery.scheduled
                )

                Divider()
                    .frame(height: 40)

                SurgeryMetricView(
                    value: "\(inProgress)",
                    label: "In Progress",
                    color: MedicalColors.Surgery.inProgress
                )

                Divider()
                    .frame(height: 40)

                SurgeryMetricView(
                    value: "\(completed)",
                    label: "Completed",
                    color: MedicalColors.Surgery.completed
                )

                Divider()
                    .frame(height: 40)

                SurgeryMetricView(
                    value: "\(cancelled)",
                    label: "Cancelled",
                    color: MedicalColors.Surgery.cancelled
                )
            }
        }
    }
}

private struct SurgeryMetricView: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: MedicalSpacing.xxs) {
            Text(value)
                .font(MedicalTypography.numericMedium)
                .foregroundColor(color)

            Text(label)
                .font(MedicalTypography.caption)
                .foregroundColor(MedicalColors.Neutral.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label)")
        .accessibilityValue(value)
    }
}

// MARK: - Empty State Card

/// Professional empty state for when no data is available
struct EmptyStateCard: View {

    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: MedicalSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(MedicalColors.Neutral.textTertiary)
                .accessibilityHidden(true)

            VStack(spacing: MedicalSpacing.xs) {
                Text(title)
                    .font(MedicalTypography.headlineSmall)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(message)
                    .font(MedicalTypography.bodySmall)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(MedicalTypography.labelLarge)
                        .foregroundColor(.white)
                        .padding(.horizontal, MedicalSpacing.xl)
                        .padding(.vertical, MedicalSpacing.sm)
                        .background(MedicalColors.Brand.primary)
                        .cornerRadius(8)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(actionTitle)
                .accessibilityHint("Double tap to \(actionTitle.lowercased())")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MedicalSpacing.xxl)
        .background(Color(.systemBackground))
        .cornerRadius(MedicalCardStyle.radiusLarge)
        .subtleElevation()
    }
}

// MARK: - Section Header

/// Professional section header for grouping content
struct SectionHeader: View {

    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MedicalTypography.headlineSmall)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(MedicalTypography.caption)
                        .foregroundColor(MedicalColors.Neutral.textSecondary)
                }
            }

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                        Image(systemName: "arrow.right")
                    }
                    .font(MedicalTypography.labelMedium)
                    .foregroundColor(MedicalColors.Brand.primary)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(actionTitle)
                .accessibilityHint("Double tap to \(actionTitle.lowercased())")
            }
        }
        .padding(.horizontal, MedicalSpacing.lg)
        .padding(.vertical, MedicalSpacing.sm)
    }
}

// MARK: - Previews

#Preview("Professional Dashboard Cards") {
    ScrollView {
        VStack(spacing: MedicalSpacing.lg) {
            // Stats Summary
            StatsSummaryCard(
                title: "Patient Overview",
                icon: "person.2.fill",
                stats: [
                    .init(label: "Active", value: "24", color: MedicalColors.PatientStatus.active),
                    .init(label: "Pre-Op", value: "8", color: MedicalColors.PatientStatus.preOperative),
                    .init(label: "Post-Op", value: "12", color: MedicalColors.PatientStatus.postOperative),
                    .init(label: "Discharged", value: "156", color: MedicalColors.PatientStatus.discharged)
                ]
            )

            // Surgical Overview
            SurgicalOverviewCard(
                scheduledToday: 12,
                inProgress: 2,
                completed: 5,
                cancelled: 1
            )

            // Activity Timeline
            ActivityTimelineCard(
                title: "Recent Activity",
                activities: [
                    .init(title: "New patient admitted", time: "10 min ago", icon: "person.badge.plus"),
                    .init(title: "Surgery completed", time: "45 min ago", icon: "checkmark.circle.fill", color: MedicalColors.Surgery.completed),
                    .init(title: "Lab results received", time: "2 hours ago", icon: "doc.text.fill", color: MedicalColors.Clinical.verified)
                ]
            )

            // Patient Quick Views
            SectionHeader(title: "Recent Patients", actionTitle: "See All") {}

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

            // Empty State
            EmptyStateCard(
                icon: "calendar.badge.exclamationmark",
                title: "No Appointments Today",
                message: "You have no scheduled appointments for today. Tap below to add a new one.",
                actionTitle: "Add Appointment"
            ) {}
        }
        .padding(MedicalSpacing.lg)
    }
    .background(Color(.systemGroupedBackground))
}
