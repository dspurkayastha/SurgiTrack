// AccessibleComponents.swift
// SurgiTrack
// Accessibility-enhanced UI components for medical app
// Created on 26/12/2025

import SwiftUI

// MARK: - Accessible List Row

/// A list row with proper accessibility support
struct AccessibleListRow<Leading: View, Trailing: View>: View {

    let title: String
    var subtitle: String? = nil
    var leading: (() -> Leading)? = nil
    var trailing: (() -> Trailing)? = nil
    var action: (() -> Void)? = nil

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: MedicalSpacing.md) {
                if let leading = leading {
                    leading()
                }

                VStack(alignment: .leading, spacing: MedicalSpacing.xxs) {
                    Text(title)
                        .font(MedicalTypography.bodyMedium)
                        .foregroundColor(MedicalColors.Neutral.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(MedicalTypography.caption)
                            .foregroundColor(MedicalColors.Neutral.textSecondary)
                    }
                }

                Spacer()

                if let trailing = trailing {
                    trailing()
                }

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                }
            }
            .padding(.vertical, MedicalSpacing.md)
            .padding(.horizontal, MedicalSpacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(action != nil ? .isButton : [])
    }

    private var accessibilityDescription: String {
        var description = title
        if let subtitle = subtitle {
            description += ", \(subtitle)"
        }
        return description
    }
}

// Convenience initializer without leading/trailing
extension AccessibleListRow where Leading == EmptyView, Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = nil
        self.trailing = nil
        self.action = action
    }
}

// MARK: - Accessible Icon Button

/// Icon button with proper accessibility
struct AccessibleIconButton: View {

    let icon: String
    let label: String
    var hint: String? = nil
    var color: Color = MedicalColors.Brand.primary
    var size: CGFloat = 44
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(color.opacity(isPressed ? 0.2 : 0.1))
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(label)
        .accessibilityHint(hint ?? "")
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
    }
}

// MARK: - Accessible Toggle Row

/// Toggle with proper accessibility labeling
struct AccessibleToggleRow: View {

    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var icon: String? = nil

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: MedicalSpacing.md) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(MedicalColors.Brand.primary)
                        .frame(width: 28)
                }

                VStack(alignment: .leading, spacing: MedicalSpacing.xxs) {
                    Text(title)
                        .font(MedicalTypography.bodyMedium)
                        .foregroundColor(MedicalColors.Neutral.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(MedicalTypography.caption)
                            .foregroundColor(MedicalColors.Neutral.textSecondary)
                    }
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: MedicalColors.Brand.primary))
        .padding(.vertical, MedicalSpacing.sm)
        .padding(.horizontal, MedicalSpacing.lg)
        .accessibilityLabel("\(title), \(isOn ? "enabled" : "disabled")")
        .accessibilityHint("Double tap to toggle")
    }
}

// MARK: - Accessible Stepper Row

/// Stepper with accessibility support for incrementing values
struct AccessibleStepperRow: View {

    let title: String
    let unit: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...100
    var step: Int = 1

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: MedicalSpacing.xxs) {
                Text(title)
                    .font(MedicalTypography.bodyMedium)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                Text("\(value) \(unit)")
                    .font(MedicalTypography.numericMedium)
                    .foregroundColor(MedicalColors.Brand.primary)
            }

            Spacer()

            HStack(spacing: 0) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= step
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(value > range.lowerBound ? MedicalColors.Brand.primary : MedicalColors.Neutral.textTertiary)
                        .frame(width: 44, height: 36)
                }
                .disabled(value <= range.lowerBound)
                .accessibilityLabel("Decrease \(title)")

                Divider()
                    .frame(height: 20)

                Button(action: {
                    if value < range.upperBound {
                        value += step
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(value < range.upperBound ? MedicalColors.Brand.primary : MedicalColors.Neutral.textTertiary)
                        .frame(width: 44, height: 36)
                }
                .disabled(value >= range.upperBound)
                .accessibilityLabel("Increase \(title)")
            }
            .background(Color(.tertiarySystemFill))
            .cornerRadius(8)
        }
        .padding(.vertical, MedicalSpacing.sm)
        .padding(.horizontal, MedicalSpacing.lg)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}

// MARK: - Accessible Progress Bar

/// Progress indicator with VoiceOver support
struct AccessibleProgressBar: View {

    let value: Double
    let total: Double
    let label: String
    var showPercentage: Bool = true
    var color: Color = MedicalColors.Brand.primary

    private var percentage: Double {
        total > 0 ? (value / total) * 100 : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MedicalSpacing.xs) {
            HStack {
                Text(label)
                    .font(MedicalTypography.labelMedium)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)

                Spacer()

                if showPercentage {
                    Text("\(Int(percentage))%")
                        .font(MedicalTypography.labelMedium)
                        .foregroundColor(color)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(value / total, 1.0)), height: 8)
                        .animation(.easeOut(duration: 0.3), value: value)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(Int(percentage)) percent complete")
        .accessibilityValue("\(Int(value)) of \(Int(total))")
    }
}

// MARK: - Accessible Data Point

/// Data display with proper semantic labeling
struct AccessibleDataPoint: View {

    let label: String
    let value: String
    var unit: String? = nil
    var icon: String? = nil
    var valueColor: Color = MedicalColors.Neutral.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: MedicalSpacing.xxs) {
            if let icon = icon {
                HStack(spacing: MedicalSpacing.xxs) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(MedicalColors.Neutral.textTertiary)

                    Text(label)
                        .font(MedicalTypography.caption)
                        .foregroundColor(MedicalColors.Neutral.textSecondary)
                }
            } else {
                Text(label)
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: MedicalSpacing.xxs) {
                Text(value)
                    .font(MedicalTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(valueColor)

                if let unit = unit {
                    Text(unit)
                        .font(MedicalTypography.caption)
                        .foregroundColor(MedicalColors.Neutral.textTertiary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value) \(unit ?? "")")
    }
}

// MARK: - Skip to Content Button

/// Accessibility skip link for keyboard navigation
struct SkipToContentButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Skip to main content")
                .font(MedicalTypography.labelMedium)
                .foregroundColor(.white)
                .padding(.horizontal, MedicalSpacing.lg)
                .padding(.vertical, MedicalSpacing.sm)
                .background(MedicalColors.Brand.primary)
                .cornerRadius(8)
        }
        .accessibilityLabel("Skip to main content")
        .accessibilityHint("Activate to skip navigation and jump to main content")
        .opacity(0) // Hidden visually but accessible
        .accessibilityHidden(false)
    }
}

// MARK: - Semantic Heading

/// Proper heading structure for VoiceOver
struct SemanticHeading: View {

    let text: String
    var level: HeadingLevel = .h2

    enum HeadingLevel {
        case h1, h2, h3

        var font: Font {
            switch self {
            case .h1: return MedicalTypography.headlineLarge
            case .h2: return MedicalTypography.headlineMedium
            case .h3: return MedicalTypography.headlineSmall
            }
        }
    }

    var body: some View {
        Text(text)
            .font(level.font)
            .foregroundColor(MedicalColors.Neutral.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Previews

#Preview("Accessible Components") {
    ScrollView {
        VStack(spacing: MedicalSpacing.lg) {
            SemanticHeading(text: "Patient Information", level: .h1)
                .padding(.horizontal)

            VStack(spacing: 0) {
                AccessibleListRow(
                    title: "John Smith",
                    subtitle: "MRN: 2024-00123",
                    leading: {
                        Circle()
                            .fill(MedicalColors.PatientStatus.active)
                            .frame(width: 10, height: 10)
                    },
                    trailing: {
                        PatientStatusBadge(status: .active, size: .small)
                    }
                ) {}

                Divider().padding(.leading, 60)

                AccessibleListRow(
                    title: "Sarah Johnson",
                    subtitle: "MRN: 2024-00456",
                    leading: {
                        Circle()
                            .fill(MedicalColors.PatientStatus.postOperative)
                            .frame(width: 10, height: 10)
                    },
                    trailing: {
                        PatientStatusBadge(status: .postOperative, size: .small)
                    }
                ) {}
            }
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
            .padding(.horizontal)

            VStack(spacing: 0) {
                AccessibleToggleRow(
                    title: "Notifications",
                    subtitle: "Receive alerts for patient updates",
                    isOn: .constant(true),
                    icon: "bell.fill"
                )

                Divider().padding(.leading, 60)

                AccessibleToggleRow(
                    title: "Biometric Login",
                    subtitle: "Use Face ID or Touch ID",
                    isOn: .constant(false),
                    icon: "faceid"
                )
            }
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
            .padding(.horizontal)

            AccessibleProgressBar(
                value: 7,
                total: 10,
                label: "Recovery Progress"
            )
            .padding(.horizontal)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
            .padding(.horizontal)

            HStack(spacing: MedicalSpacing.xl) {
                AccessibleDataPoint(
                    label: "Heart Rate",
                    value: "72",
                    unit: "bpm",
                    icon: "heart.fill",
                    valueColor: MedicalColors.Clinical.normal
                )

                AccessibleDataPoint(
                    label: "Blood Pressure",
                    value: "120/80",
                    unit: "mmHg",
                    icon: "waveform.path.ecg"
                )

                AccessibleDataPoint(
                    label: "Temperature",
                    value: "37.2",
                    unit: "°C",
                    icon: "thermometer"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(MedicalCardStyle.radiusMedium)
            .padding(.horizontal)

            HStack(spacing: MedicalSpacing.lg) {
                AccessibleIconButton(icon: "plus", label: "Add Patient") {}
                AccessibleIconButton(icon: "calendar", label: "Schedule") {}
                AccessibleIconButton(icon: "doc.text", label: "Reports") {}
                AccessibleIconButton(icon: "gear", label: "Settings") {}
            }
            .padding()
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
