// MedicalDesignSystem.swift
// SurgiTrack
// Professional medical design tokens and components
// Created on 26/12/2025
//
// ⚠️ DEPRECATED: This file has been consolidated into DesignSystem.swift
// All medical colors, typography, and spacing are now available via:
// - DesignSystem.Colors.PatientStatus.*
// - DesignSystem.Colors.RiskLevel.*
// - DesignSystem.Colors.Clinical.*
// - DesignSystem.Typography.*
// - DesignSystem.Spacing.*
//
// This file is kept for reference only. New code should use DesignSystem.swift.
// See DESIGN_SYSTEM_MIGRATION.md for migration guide.

import SwiftUI

// MARK: - Medical Color Semantics

/// Healthcare-specific semantic colors for medical status, risk levels, and clinical indicators
struct MedicalColors {

    // MARK: - Patient Status Colors
    struct PatientStatus {
        /// Active patient in current care
        static let active = Color(hex: "2563EB")      // Professional blue
        /// Patient scheduled for surgery
        static let preOperative = Color(hex: "7C3AED") // Purple
        /// Patient currently in surgery
        static let inSurgery = Color(hex: "DC2626")    // Alert red
        /// Patient in recovery/post-op
        static let postOperative = Color(hex: "F59E0B") // Amber
        /// Patient ready for discharge
        static let readyForDischarge = Color(hex: "10B981") // Emerald
        /// Patient discharged
        static let discharged = Color(hex: "6B7280")   // Gray
        /// Follow-up required
        static let followUp = Color(hex: "0891B2")     // Cyan
        /// Critical/urgent attention
        static let critical = Color(hex: "BE123C")     // Rose red
    }

    // MARK: - Risk Level Colors (WCAG AA Compliant)
    struct RiskLevel {
        /// Minimal risk (0-10%)
        static let minimal = Color(hex: "22C55E")      // Green-500
        /// Low risk (10-25%)
        static let low = Color(hex: "84CC16")          // Lime-500
        /// Moderate risk (25-50%)
        static let moderate = Color(hex: "F59E0B")     // Amber-500
        /// High risk (50-75%)
        static let high = Color(hex: "F97316")         // Orange-500
        /// Very high risk (75-90%)
        static let veryHigh = Color(hex: "EF4444")     // Red-500
        /// Critical risk (90%+)
        static let critical = Color(hex: "DC2626")     // Red-600

        static func color(for percentage: Double) -> Color {
            switch percentage {
            case 0..<10: return minimal
            case 10..<25: return low
            case 25..<50: return moderate
            case 50..<75: return high
            case 75..<90: return veryHigh
            default: return critical
            }
        }
    }

    // MARK: - Clinical Indicators
    struct Clinical {
        /// Normal lab values
        static let normal = Color(hex: "22C55E")
        /// Abnormal - slightly out of range
        static let abnormal = Color(hex: "F59E0B")
        /// Critical - significantly out of range
        static let criticalValue = Color(hex: "DC2626")
        /// Pending results
        static let pending = Color(hex: "6B7280")
        /// Verified/confirmed
        static let verified = Color(hex: "2563EB")
    }

    // MARK: - Surgery Status
    struct Surgery {
        /// Scheduled for future
        static let scheduled = Color(hex: "3B82F6")
        /// In preparation
        static let preparing = Color(hex: "8B5CF6")
        /// Currently in progress
        static let inProgress = Color(hex: "EF4444")
        /// Successfully completed
        static let completed = Color(hex: "22C55E")
        /// Cancelled
        static let cancelled = Color(hex: "6B7280")
        /// Rescheduled
        static let rescheduled = Color(hex: "F59E0B")
    }

    // MARK: - Professional Neutrals
    struct Neutral {
        static let background = Color(hex: "F8FAFC")
        static let backgroundDark = Color(hex: "0F172A")
        static let surface = Color(hex: "FFFFFF")
        static let surfaceDark = Color(hex: "1E293B")
        static let surfaceElevated = Color(hex: "F1F5F9")
        static let surfaceElevatedDark = Color(hex: "334155")
        static let border = Color(hex: "E2E8F0")
        static let borderDark = Color(hex: "475569")
        static let textPrimary = Color(hex: "0F172A")
        static let textPrimaryDark = Color(hex: "F8FAFC")
        static let textSecondary = Color(hex: "64748B")
        static let textSecondaryDark = Color(hex: "94A3B8")
        static let textTertiary = Color(hex: "94A3B8")
        static let textTertiaryDark = Color(hex: "64748B")
    }

    // MARK: - Professional Brand Colors
    struct Brand {
        static let primary = Color(hex: "0F766E")      // Teal-700 - Professional, calming
        static let primaryLight = Color(hex: "14B8A6") // Teal-500
        static let primaryDark = Color(hex: "0D9488")  // Teal-600
        static let secondary = Color(hex: "1E40AF")    // Blue-800
        static let secondaryLight = Color(hex: "3B82F6") // Blue-500
        static let accent = Color(hex: "7C3AED")       // Violet-600
    }
}

// MARK: - Professional Typography

/// Medical-appropriate typography with improved readability
struct MedicalTypography {

    // MARK: - Display (For dashboards, large numbers)
    static let displayLarge = Font.system(size: 48, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 36, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 28, weight: .semibold, design: .default)

    // MARK: - Headlines (Professional, no rounded design)
    static let headlineLarge = Font.system(size: 24, weight: .bold, design: .default)
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .default)

    // MARK: - Titles
    static let titleLarge = Font.system(size: 17, weight: .semibold, design: .default)
    static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
    static let titleSmall = Font.system(size: 15, weight: .medium, design: .default)

    // MARK: - Body Text (Optimized for medical data readability)
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

    // MARK: - Labels (For form fields, data labels)
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)

    // MARK: - Captions
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)

    // MARK: - Monospace (For medical IDs, codes)
    static let monoLarge = Font.system(size: 16, weight: .medium, design: .monospaced)
    static let monoMedium = Font.system(size: 14, weight: .medium, design: .monospaced)
    static let monoSmall = Font.system(size: 12, weight: .medium, design: .monospaced)

    // MARK: - Numeric (For vital signs, lab values)
    static let numericLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let numericMedium = Font.system(size: 24, weight: .bold, design: .rounded)
    static let numericSmall = Font.system(size: 18, weight: .semibold, design: .rounded)
}

// MARK: - Refined Spacing System

struct MedicalSpacing {
    /// 2pt - Minimal spacing
    static let xxxs: CGFloat = 2
    /// 4pt - Icon padding, badge internal
    static let xxs: CGFloat = 4
    /// 6pt - Tight grouping
    static let xs: CGFloat = 6
    /// 8pt - Related elements
    static let sm: CGFloat = 8
    /// 12pt - Standard internal padding
    static let md: CGFloat = 12
    /// 16pt - Section separation
    static let lg: CGFloat = 16
    /// 20pt - Card padding
    static let xl: CGFloat = 20
    /// 24pt - Major section gaps
    static let xxl: CGFloat = 24
    /// 32pt - Screen edge padding
    static let xxxl: CGFloat = 32
    /// 48pt - Large section gaps
    static let huge: CGFloat = 48
}

// MARK: - Professional Card Styles

struct MedicalCardStyle {

    // MARK: - Card Configurations
    enum Style {
        case elevated       // Raised with shadow
        case outlined       // Border only
        case filled         // Solid background
        case interactive    // Pressable with feedback
    }

    // MARK: - Corner Radii
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXL: CGFloat = 20

    // MARK: - Shadows
    struct Shadows {
        static let subtle = (color: Color.black.opacity(0.04), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let small = (color: Color.black.opacity(0.06), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
}

// MARK: - Icon Sizes

struct MedicalIconSize {
    static let xs: CGFloat = 12
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Animation Timing

struct MedicalAnimation {
    static let microInteraction = Animation.easeOut(duration: 0.15)
    static let fast = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let smooth = Animation.easeInOut(duration: 0.4)
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
}

// MARK: - View Modifiers

extension View {
    /// Applies a professional medical card style
    func medicalCard(style: MedicalCardStyle.Style = .elevated, padding: CGFloat = MedicalSpacing.xl) -> some View {
        self
            .padding(padding)
            .background(
                Group {
                    switch style {
                    case .elevated:
                        RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                            .fill(Color(.systemBackground))
                            .shadow(
                                color: MedicalCardStyle.Shadows.small.color,
                                radius: MedicalCardStyle.Shadows.small.radius,
                                x: MedicalCardStyle.Shadows.small.x,
                                y: MedicalCardStyle.Shadows.small.y
                            )
                    case .outlined:
                        RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                            .stroke(Color(.separator), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                                    .fill(Color(.systemBackground))
                            )
                    case .filled:
                        RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                            .fill(Color(.secondarySystemBackground))
                    case .interactive:
                        RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                            .fill(Color(.systemBackground))
                            .shadow(
                                color: MedicalCardStyle.Shadows.medium.color,
                                radius: MedicalCardStyle.Shadows.medium.radius,
                                x: MedicalCardStyle.Shadows.medium.x,
                                y: MedicalCardStyle.Shadows.medium.y
                            )
                    }
                }
            )
    }

    /// Applies a subtle elevation effect
    func subtleElevation() -> some View {
        self.shadow(
            color: Color.black.opacity(0.04),
            radius: 3,
            x: 0,
            y: 1
        )
    }

    /// Applies medical-appropriate border
    func medicalBorder(color: Color = Color(.separator)) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: MedicalCardStyle.radiusMedium)
                    .stroke(color, lineWidth: 1)
            )
    }
}

// MARK: - Accessibility Helpers

extension View {
    /// Adds proper accessibility for medical status indicators
    func medicalAccessibility(
        label: String,
        value: String? = nil,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
    }

    // Note: accessibleButton is defined in AccessibilityFramework.swift
}

// MARK: - Preview

#Preview("Medical Design System") {
    ScrollView {
        VStack(alignment: .leading, spacing: MedicalSpacing.xxl) {
            // Typography Preview
            Group {
                Text("Typography")
                    .font(MedicalTypography.headlineLarge)
                    .foregroundColor(MedicalColors.Neutral.textPrimary)

                Text("Display Large")
                    .font(MedicalTypography.displayLarge)
                Text("Headline Medium")
                    .font(MedicalTypography.headlineMedium)
                Text("Body Text")
                    .font(MedicalTypography.bodyMedium)
                Text("Caption Text")
                    .font(MedicalTypography.caption)
                    .foregroundColor(MedicalColors.Neutral.textSecondary)
                Text("MRN-2024-00123")
                    .font(MedicalTypography.monoMedium)
            }

            Divider()

            // Status Colors Preview
            Group {
                Text("Patient Status")
                    .font(MedicalTypography.headlineMedium)

                HStack(spacing: MedicalSpacing.sm) {
                    Circle().fill(MedicalColors.PatientStatus.active).frame(width: 20, height: 20)
                    Circle().fill(MedicalColors.PatientStatus.inSurgery).frame(width: 20, height: 20)
                    Circle().fill(MedicalColors.PatientStatus.postOperative).frame(width: 20, height: 20)
                    Circle().fill(MedicalColors.PatientStatus.discharged).frame(width: 20, height: 20)
                }
            }

            Divider()

            // Risk Colors Preview
            Group {
                Text("Risk Levels")
                    .font(MedicalTypography.headlineMedium)

                HStack(spacing: MedicalSpacing.xxs) {
                    ForEach([5.0, 20.0, 40.0, 60.0, 80.0, 95.0], id: \.self) { risk in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MedicalColors.RiskLevel.color(for: risk))
                            .frame(width: 40, height: 24)
                            .overlay(
                                Text("\(Int(risk))%")
                                    .font(MedicalTypography.captionBold)
                                    .foregroundColor(.white)
                            )
                    }
                }
            }

            Divider()

            // Card Styles Preview
            Group {
                Text("Card Styles")
                    .font(MedicalTypography.headlineMedium)

                Text("Elevated Card")
                    .font(MedicalTypography.bodyMedium)
                    .medicalCard(style: .elevated)

                Text("Outlined Card")
                    .font(MedicalTypography.bodyMedium)
                    .medicalCard(style: .outlined)

                Text("Filled Card")
                    .font(MedicalTypography.bodyMedium)
                    .medicalCard(style: .filled)
            }
        }
        .padding(MedicalSpacing.xl)
    }
    .background(Color(.systemGroupedBackground))
}
