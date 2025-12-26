// MedicalStatusComponents.swift
// SurgiTrack
// Professional medical status indicators and badges
// Created on 26/12/2025

import SwiftUI

// MARK: - Patient Status Badge

/// Professional status badge for patient care status
struct PatientStatusBadge: View {

    enum Status: String, CaseIterable {
        case active = "Active"
        case preOperative = "Pre-Op"
        case inSurgery = "In Surgery"
        case postOperative = "Post-Op"
        case recovery = "Recovery"
        case readyForDischarge = "Ready for Discharge"
        case discharged = "Discharged"
        case followUp = "Follow-Up"
        case critical = "Critical"

        var color: Color {
            switch self {
            case .active: return MedicalColors.PatientStatus.active
            case .preOperative: return MedicalColors.PatientStatus.preOperative
            case .inSurgery: return MedicalColors.PatientStatus.inSurgery
            case .postOperative: return MedicalColors.PatientStatus.postOperative
            case .recovery: return Color(hex: "F59E0B")
            case .readyForDischarge: return MedicalColors.PatientStatus.readyForDischarge
            case .discharged: return MedicalColors.PatientStatus.discharged
            case .followUp: return MedicalColors.PatientStatus.followUp
            case .critical: return MedicalColors.PatientStatus.critical
            }
        }

        var icon: String {
            switch self {
            case .active: return "person.fill"
            case .preOperative: return "clock.fill"
            case .inSurgery: return "cross.case.fill"
            case .postOperative: return "bed.double.fill"
            case .recovery: return "heart.fill"
            case .readyForDischarge: return "checkmark.circle.fill"
            case .discharged: return "arrow.right.circle.fill"
            case .followUp: return "calendar.badge.clock"
            case .critical: return "exclamationmark.triangle.fill"
            }
        }

        var isPulsing: Bool {
            self == .inSurgery || self == .critical
        }
    }

    let status: Status
    var size: Size = .medium
    var showIcon: Bool = true

    enum Size {
        case small, medium, large

        var fontSize: Font {
            switch self {
            case .small: return MedicalTypography.captionBold
            case .medium: return MedicalTypography.labelMedium
            case .large: return MedicalTypography.labelLarge
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 5) {
            if showIcon {
                Image(systemName: status.icon)
                    .font(.system(size: size.iconSize, weight: .semibold))
                    .scaleEffect(status.isPulsing && isPulsing ? 1.1 : 1.0)
            }

            Text(status.rawValue)
                .font(size.fontSize)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(status.color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(status.color.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            if status.isPulsing {
                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .accessibilityLabel("Patient status: \(status.rawValue)")
    }
}

// MARK: - Risk Score Indicator

/// Visual indicator for surgical risk assessment scores
struct RiskScoreIndicator: View {

    let score: Double
    let maxScore: Double
    let label: String
    var size: Size = .medium

    enum Size {
        case small, medium, large

        var diameter: CGFloat {
            switch self {
            case .small: return 48
            case .medium: return 64
            case .large: return 80
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }

        var scoreFont: Font {
            switch self {
            case .small: return MedicalTypography.numericSmall
            case .medium: return MedicalTypography.numericMedium
            case .large: return MedicalTypography.numericLarge
            }
        }
    }

    private var percentage: Double {
        min(max(score / maxScore, 0), 1)
    }

    private var riskColor: Color {
        MedicalColors.RiskLevel.color(for: percentage * 100)
    }

    var body: some View {
        VStack(spacing: MedicalSpacing.xs) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: size.lineWidth)

                // Progress arc
                Circle()
                    .trim(from: 0, to: percentage)
                    .stroke(
                        riskColor,
                        style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: percentage)

                // Score text
                Text(String(format: "%.0f", score))
                    .font(size.scoreFont)
                    .foregroundColor(riskColor)
            }
            .frame(width: size.diameter, height: size.diameter)

            Text(label)
                .font(MedicalTypography.caption)
                .foregroundColor(MedicalColors.Neutral.textSecondary)
        }
        .accessibilityLabel("\(label): \(Int(score)) out of \(Int(maxScore))")
    }
}

// MARK: - Vital Sign Display

/// Professional vital sign display component
struct VitalSignDisplay: View {

    let title: String
    let value: String
    let unit: String
    var status: ValueStatus = .normal
    var trend: Trend? = nil

    enum ValueStatus {
        case normal, warning, critical

        var color: Color {
            switch self {
            case .normal: return MedicalColors.Clinical.normal
            case .warning: return MedicalColors.Clinical.abnormal
            case .critical: return MedicalColors.Clinical.criticalValue
            }
        }
    }

    enum Trend {
        case increasing, decreasing, stable

        var icon: String {
            switch self {
            case .increasing: return "arrow.up"
            case .decreasing: return "arrow.down"
            case .stable: return "arrow.forward"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MedicalSpacing.xxs) {
            Text(title)
                .font(MedicalTypography.caption)
                .foregroundColor(MedicalColors.Neutral.textSecondary)

            HStack(alignment: .lastTextBaseline, spacing: MedicalSpacing.xxs) {
                Text(value)
                    .font(MedicalTypography.numericMedium)
                    .foregroundColor(status.color)

                Text(unit)
                    .font(MedicalTypography.labelSmall)
                    .foregroundColor(MedicalColors.Neutral.textTertiary)

                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(status.color)
                }
            }
        }
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}

// MARK: - Surgery Status Card

/// Compact surgery status indicator
struct SurgeryStatusCard: View {

    let surgeryName: String
    let status: Status
    let date: Date
    var duration: TimeInterval? = nil

    enum Status: String {
        case scheduled = "Scheduled"
        case preparing = "Preparing"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"

        var color: Color {
            switch self {
            case .scheduled: return MedicalColors.Surgery.scheduled
            case .preparing: return MedicalColors.Surgery.preparing
            case .inProgress: return MedicalColors.Surgery.inProgress
            case .completed: return MedicalColors.Surgery.completed
            case .cancelled: return MedicalColors.Surgery.cancelled
            }
        }

        var icon: String {
            switch self {
            case .scheduled: return "calendar"
            case .preparing: return "clock.fill"
            case .inProgress: return "waveform.path.ecg"
            case .completed: return "checkmark.circle.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private var durationText: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        HStack(spacing: MedicalSpacing.md) {
            // Status icon
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: status.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(status.color)
            }

            // Content
            VStack(alignment: .leading, spacing: MedicalSpacing.xxs) {
                Text(surgeryName)
                    .font(MedicalTypography.titleMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                HStack(spacing: MedicalSpacing.sm) {
                    Text(status.rawValue)
                        .font(MedicalTypography.captionBold)
                        .foregroundColor(status.color)

                    Text("•")
                        .foregroundColor(MedicalColors.Neutral.textTertiary)

                    Text(dateFormatter.string(from: date))
                        .font(MedicalTypography.caption)
                        .foregroundColor(MedicalColors.Neutral.textSecondary)

                    if let durationText = durationText {
                        Text("•")
                            .foregroundColor(MedicalColors.Neutral.textTertiary)

                        Text(durationText)
                            .font(MedicalTypography.caption)
                            .foregroundColor(MedicalColors.Neutral.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MedicalColors.Neutral.textTertiary)
        }
        .padding(MedicalSpacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(MedicalCardStyle.radiusMedium)
        .subtleElevation()
    }
}

// MARK: - Lab Result Row

/// Professional lab result display
struct LabResultRow: View {

    let testName: String
    let value: String
    let unit: String
    let referenceRange: String
    var status: ResultStatus = .normal

    enum ResultStatus {
        case normal, low, high, critical

        var color: Color {
            switch self {
            case .normal: return MedicalColors.Clinical.normal
            case .low: return Color(hex: "3B82F6") // Blue for low
            case .high: return MedicalColors.Clinical.abnormal
            case .critical: return MedicalColors.Clinical.criticalValue
            }
        }

        var icon: String? {
            switch self {
            case .normal: return nil
            case .low: return "arrow.down"
            case .high: return "arrow.up"
            case .critical: return "exclamationmark.triangle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: MedicalSpacing.md) {
            // Test name
            VStack(alignment: .leading, spacing: 2) {
                Text(testName)
                    .font(MedicalTypography.bodyMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                Text("Ref: \(referenceRange)")
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textTertiary)
            }

            Spacer()

            // Value with status
            HStack(spacing: MedicalSpacing.xs) {
                if let icon = status.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(status.color)
                }

                Text(value)
                    .font(MedicalTypography.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(status.color)

                Text(unit)
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
            }
        }
        .padding(.vertical, MedicalSpacing.sm)
        .accessibilityLabel("\(testName): \(value) \(unit), Reference range: \(referenceRange)")
    }
}

// MARK: - Quick Stats Card

/// Compact statistics display for dashboards
struct QuickStatsCard: View {

    let title: String
    let value: String
    let icon: String
    var trend: String? = nil
    var trendPositive: Bool = true
    var accentColor: Color = MedicalColors.Brand.primary

    var body: some View {
        VStack(alignment: .leading, spacing: MedicalSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)

                Spacer()

                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trendPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(trend)
                            .font(MedicalTypography.captionBold)
                    }
                    .foregroundColor(trendPositive ? MedicalColors.Clinical.normal : MedicalColors.Clinical.abnormal)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(MedicalTypography.displaySmall)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                Text(title)
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
            }
        }
        .padding(MedicalSpacing.lg)
        .background(Color(.systemBackground))
        .cornerRadius(MedicalCardStyle.radiusMedium)
        .subtleElevation()
    }
}

// MARK: - Previews

#Preview("Patient Status Badges") {
    VStack(spacing: MedicalSpacing.lg) {
        ForEach(PatientStatusBadge.Status.allCases, id: \.rawValue) { status in
            PatientStatusBadge(status: status, size: .medium)
        }
    }
    .padding()
}

#Preview("Medical Components") {
    ScrollView {
        VStack(spacing: MedicalSpacing.xl) {
            // Risk Score
            HStack(spacing: MedicalSpacing.xl) {
                RiskScoreIndicator(score: 3, maxScore: 10, label: "RCRI Score", size: .medium)
                RiskScoreIndicator(score: 7, maxScore: 10, label: "Apgar Score", size: .medium)
                RiskScoreIndicator(score: 45, maxScore: 100, label: "Risk %", size: .medium)
            }

            Divider()

            // Vital Signs
            HStack(spacing: MedicalSpacing.xl) {
                VitalSignDisplay(title: "Heart Rate", value: "72", unit: "bpm", status: .normal)
                VitalSignDisplay(title: "Blood Pressure", value: "145/92", unit: "mmHg", status: .warning, trend: .increasing)
                VitalSignDisplay(title: "Temperature", value: "39.2", unit: "°C", status: .critical)
            }

            Divider()

            // Surgery Status
            SurgeryStatusCard(
                surgeryName: "Laparoscopic Cholecystectomy",
                status: .inProgress,
                date: Date(),
                duration: 3600
            )

            // Lab Results
            VStack(spacing: 0) {
                LabResultRow(testName: "Hemoglobin", value: "14.2", unit: "g/dL", referenceRange: "12.0-16.0", status: .normal)
                Divider()
                LabResultRow(testName: "WBC Count", value: "12.5", unit: "K/uL", referenceRange: "4.5-11.0", status: .high)
                Divider()
                LabResultRow(testName: "Platelets", value: "85", unit: "K/uL", referenceRange: "150-400", status: .critical)
            }
            .padding(MedicalSpacing.md)
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
            .subtleElevation()

            // Quick Stats
            HStack(spacing: MedicalSpacing.md) {
                QuickStatsCard(title: "Patients", value: "24", icon: "person.2.fill", trend: "+3", trendPositive: true)
                QuickStatsCard(title: "Surgeries", value: "8", icon: "cross.case.fill", trend: "-1", trendPositive: false, accentColor: MedicalColors.Surgery.scheduled)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
