// DesignSystem.swift
// SurgiTrack
// Unified Design System - Single Source of Truth for All Design Tokens
// Created on 26/12/2025
//
// This file consolidates all design tokens (colors, typography, spacing, etc.)
// into a single, authoritative source. It supersedes individual theme files
// while maintaining backward compatibility.

import SwiftUI

// MARK: - Design System

/// Central design system providing all design tokens for the SurgiTrack application.
/// This is the single source of truth for colors, typography, spacing, and other design elements.
public struct DesignSystem {

    // MARK: - Color System

    /// All application colors organized by semantic meaning
    public struct Colors {

        // MARK: - Primary Brand Colors

        /// Primary brand color - Professional teal, optimized for medical contexts
        /// - Usage: Primary actions, key UI elements, brand identity
        /// - Accessibility: WCAG AA compliant with white text
        public static let primary = Color(hex: "0F766E")  // Teal-700

        /// Lighter variant of primary color
        /// - Usage: Hover states, lighter backgrounds, secondary emphasis
        public static let primaryLight = Color(hex: "14B8A6")  // Teal-500

        /// Darker variant of primary color
        /// - Usage: Active/pressed states, stronger emphasis
        public static let primaryDark = Color(hex: "0D9488")  // Teal-600

        /// Secondary brand color - Professional blue
        /// - Usage: Secondary actions, complementary UI elements
        /// - Accessibility: WCAG AA compliant with white text
        public static let secondary = Color(hex: "1E40AF")  // Blue-800

        /// Lighter variant of secondary color
        public static let secondaryLight = Color(hex: "3B82F6")  // Blue-500

        /// Accent color for highlights and special emphasis
        /// - Usage: Call-to-action elements, important highlights
        public static let accent = Color(hex: "7C3AED")  // Violet-600

        // MARK: - Semantic Colors (System States)

        /// Success state color
        /// - Usage: Success messages, positive confirmations, completed states
        /// - Accessibility: WCAG AA compliant
        public static let success = Color(hex: "22C55E")  // Green-500

        /// Warning state color
        /// - Usage: Warning messages, cautionary states, needs attention
        /// - Accessibility: WCAG AA compliant
        public static let warning = Color(hex: "F59E0B")  // Amber-500

        /// Error state color
        /// - Usage: Error messages, destructive actions, critical alerts
        /// - Accessibility: WCAG AA compliant
        public static let error = Color(hex: "DC2626")  // Red-600

        /// Informational state color
        /// - Usage: Info messages, helpful tips, neutral notifications
        /// - Accessibility: WCAG AA compliant
        public static let info = Color(hex: "2563EB")  // Blue-600

        // MARK: - Medical-Specific Colors

        /// Colors for patient status indicators
        public struct PatientStatus {
            /// Active patient in current care
            public static let active = Color(hex: "2563EB")  // Professional blue

            /// Patient scheduled for surgery
            public static let preOperative = Color(hex: "7C3AED")  // Purple

            /// Patient currently in surgery (high visibility)
            public static let inSurgery = Color(hex: "DC2626")  // Alert red

            /// Patient in recovery/post-operative care
            public static let postOperative = Color(hex: "F59E0B")  // Amber

            /// Patient ready for discharge
            public static let readyForDischarge = Color(hex: "10B981")  // Emerald

            /// Patient discharged
            public static let discharged = Color(hex: "6B7280")  // Gray

            /// Follow-up appointment required
            public static let followUp = Color(hex: "0891B2")  // Cyan

            /// Critical/urgent attention needed
            public static let critical = Color(hex: "BE123C")  // Rose red
        }

        /// Risk level indicators (WCAG AA compliant)
        public struct RiskLevel {
            /// Minimal risk (0-10%)
            public static let minimal = Color(hex: "22C55E")  // Green-500

            /// Low risk (10-25%)
            public static let low = Color(hex: "84CC16")  // Lime-500

            /// Moderate risk (25-50%)
            public static let moderate = Color(hex: "F59E0B")  // Amber-500

            /// High risk (50-75%)
            public static let high = Color(hex: "F97316")  // Orange-500

            /// Very high risk (75-90%)
            public static let veryHigh = Color(hex: "EF4444")  // Red-500

            /// Critical risk (90%+)
            public static let critical = Color(hex: "DC2626")  // Red-600

            /// Returns appropriate risk color for a given percentage
            /// - Parameter percentage: Risk percentage (0-100)
            /// - Returns: Color corresponding to the risk level
            public static func color(for percentage: Double) -> Color {
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

        /// Clinical indicator colors
        public struct Clinical {
            /// Normal lab values/readings
            public static let normal = Color(hex: "22C55E")  // Green-500

            /// Abnormal - slightly out of normal range
            public static let abnormal = Color(hex: "F59E0B")  // Amber-500

            /// Critical - significantly out of range
            public static let criticalValue = Color(hex: "DC2626")  // Red-600

            /// Pending results/awaiting data
            public static let pending = Color(hex: "6B7280")  // Gray-500

            /// Verified/confirmed results
            public static let verified = Color(hex: "2563EB")  // Blue-600
        }

        /// Surgery status indicators
        public struct Surgery {
            /// Scheduled for future date
            public static let scheduled = Color(hex: "3B82F6")  // Blue-500

            /// In preparation phase
            public static let preparing = Color(hex: "8B5CF6")  // Violet-500

            /// Currently in progress
            public static let inProgress = Color(hex: "EF4444")  // Red-500

            /// Successfully completed
            public static let completed = Color(hex: "22C55E")  // Green-500

            /// Cancelled
            public static let cancelled = Color(hex: "6B7280")  // Gray-500

            /// Rescheduled
            public static let rescheduled = Color(hex: "F59E0B")  // Amber-500
        }

        // MARK: - Background & Surface Colors

        /// Main application background
        /// - Note: Adapts to light/dark mode automatically
        public static let background = Color(hex: "F8FAFC")  // Slate-50 (light mode)

        /// Background for dark mode
        public static let backgroundDark = Color(hex: "0F172A")  // Slate-900

        /// Surface color for cards and containers
        public static let surface = Color(hex: "FFFFFF")  // White

        /// Surface color for dark mode
        public static let surfaceDark = Color(hex: "1E293B")  // Slate-800

        /// Elevated surface (slightly lighter than background)
        public static let surfaceElevated = Color(hex: "F1F5F9")  // Slate-100

        /// Elevated surface for dark mode
        public static let surfaceElevatedDark = Color(hex: "334155")  // Slate-700

        // MARK: - Text Colors

        /// Primary text color - highest emphasis
        /// - Usage: Main content, headings, important text
        /// - Accessibility: WCAG AAA compliant on white background
        public static let textPrimary = Color(hex: "0F172A")  // Slate-900

        /// Primary text color for dark mode
        public static let textPrimaryDark = Color(hex: "F8FAFC")  // Slate-50

        /// Secondary text color - medium emphasis
        /// - Usage: Supporting text, descriptions, labels
        /// - Accessibility: WCAG AA compliant
        public static let textSecondary = Color(hex: "64748B")  // Slate-500

        /// Secondary text color for dark mode
        public static let textSecondaryDark = Color(hex: "94A3B8")  // Slate-400

        /// Tertiary text color - low emphasis
        /// - Usage: Disabled text, placeholder text, subtle hints
        public static let textTertiary = Color(hex: "94A3B8")  // Slate-400

        /// Tertiary text color for dark mode
        public static let textTertiaryDark = Color(hex: "64748B")  // Slate-500

        // MARK: - Border & Divider Colors

        /// Standard border color
        /// - Usage: Input borders, card outlines, dividers
        public static let border = Color(hex: "E2E8F0")  // Slate-200

        /// Border color for dark mode
        public static let borderDark = Color(hex: "475569")  // Slate-600

        /// Divider/separator color (lighter than border)
        public static let divider = Color(hex: "F1F5F9")  // Slate-100

        /// Divider color for dark mode
        public static let dividerDark = Color(hex: "334155")  // Slate-700

        // MARK: - Special Effect Colors

        /// Shadow color for elevation effects
        public static let shadow = Color.black.opacity(0.1)

        /// Shadow color for dark mode
        public static let shadowDark = Color.black.opacity(0.4)

        /// Glass morphism background
        /// - Usage: Overlay panels, modal backgrounds
        public static let glassBackground = Color.white.opacity(0.1)

        /// Glass morphism border
        public static let glassBorder = Color.white.opacity(0.2)

        // MARK: - System Adaptive Colors

        /// Adaptive color that adjusts to system light/dark mode
        public struct Adaptive {
            /// Adapts between background and backgroundDark
            public static var background: Color {
                Color(.systemBackground)
            }

            /// Adapts between surface and surfaceDark
            public static var surface: Color {
                Color(.secondarySystemBackground)
            }

            /// Adapts between surfaceElevated and surfaceElevatedDark
            public static var surfaceElevated: Color {
                Color(.tertiarySystemBackground)
            }

            /// Adapts between textPrimary and textPrimaryDark
            public static var textPrimary: Color {
                Color(.label)
            }

            /// Adapts between textSecondary and textSecondaryDark
            public static var textSecondary: Color {
                Color(.secondaryLabel)
            }

            /// Adapts between border and borderDark
            public static var border: Color {
                Color(.separator)
            }
        }
    }

    // MARK: - Typography System

    /// Typography scale optimized for medical applications
    public struct Typography {

        // MARK: - Display Sizes (Large Numbers, Dashboard Headers)

        /// Extra large display text
        /// - Usage: Dashboard numbers, hero content
        public static let displayLarge = Font.system(size: 48, weight: .bold, design: .default)

        /// Medium display text
        public static let displayMedium = Font.system(size: 36, weight: .bold, design: .default)

        /// Small display text
        public static let displaySmall = Font.system(size: 28, weight: .semibold, design: .default)

        // MARK: - Headlines (Section Headers, Page Titles)

        /// Large headline
        /// - Usage: Page titles, major section headers
        public static let headlineLarge = Font.system(size: 24, weight: .bold, design: .default)

        /// Medium headline
        public static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)

        /// Small headline
        public static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .default)

        // MARK: - Titles (Subsection Headers, Card Titles)

        /// Large title
        public static let titleLarge = Font.system(size: 17, weight: .semibold, design: .default)

        /// Medium title
        public static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)

        /// Small title
        public static let titleSmall = Font.system(size: 15, weight: .medium, design: .default)

        // MARK: - Body Text (Content, Descriptions)

        /// Large body text
        /// - Usage: Main content, important descriptions
        public static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)

        /// Standard body text
        /// - Usage: Default content text
        public static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)

        /// Small body text
        public static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

        // MARK: - Labels (Form Fields, Data Labels)

        /// Large label
        public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)

        /// Medium label
        public static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)

        /// Small label
        public static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)

        // MARK: - Captions (Footnotes, Timestamps)

        /// Regular caption
        /// - Usage: Timestamps, helper text, footnotes
        public static let caption = Font.system(size: 12, weight: .regular, design: .default)

        /// Bold caption
        public static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)

        // MARK: - Button Text

        /// Standard button text
        public static let button = Font.system(size: 16, weight: .semibold, design: .default)

        /// Small button text
        public static let buttonSmall = Font.system(size: 14, weight: .semibold, design: .default)

        // MARK: - Monospace (Medical IDs, Codes, Technical Data)

        /// Large monospace text
        /// - Usage: Patient IDs, medical record numbers
        public static let monoLarge = Font.system(size: 16, weight: .medium, design: .monospaced)

        /// Medium monospace text
        public static let monoMedium = Font.system(size: 14, weight: .medium, design: .monospaced)

        /// Small monospace text
        public static let monoSmall = Font.system(size: 12, weight: .medium, design: .monospaced)

        // MARK: - Numeric (Vital Signs, Lab Values, Measurements)

        /// Large numeric display
        /// - Usage: Vital signs, key metrics
        /// - Note: Uses rounded design for better number readability
        public static let numericLarge = Font.system(size: 32, weight: .bold, design: .rounded)

        /// Medium numeric display
        public static let numericMedium = Font.system(size: 24, weight: .bold, design: .rounded)

        /// Small numeric display
        public static let numericSmall = Font.system(size: 18, weight: .semibold, design: .rounded)
    }

    // MARK: - Spacing System

    /// Consistent spacing scale for layouts
    public struct Spacing {
        /// 2pt - Minimal spacing (icon padding, badge internal)
        public static let xxxs: CGFloat = 2

        /// 4pt - Extra extra small (tight grouping)
        public static let xxs: CGFloat = 4

        /// 6pt - Extra small (related elements)
        public static let xs: CGFloat = 6

        /// 8pt - Small (standard gap between related items)
        public static let sm: CGFloat = 8

        /// 12pt - Medium (internal padding, section separation)
        public static let md: CGFloat = 12

        /// 16pt - Large (card padding, standard margins)
        public static let lg: CGFloat = 16

        /// 20pt - Extra large (generous padding)
        public static let xl: CGFloat = 20

        /// 24pt - Extra extra large (major section gaps)
        public static let xxl: CGFloat = 24

        /// 32pt - Extra extra extra large (screen edge padding)
        public static let xxxl: CGFloat = 32

        /// 48pt - Huge (large section separation)
        public static let huge: CGFloat = 48
    }

    // MARK: - Corner Radius

    /// Corner radius values for rounded elements
    public struct CornerRadius {
        /// 4pt - Minimal rounding
        public static let xs: CGFloat = 4

        /// 8pt - Small rounding (buttons, chips)
        public static let sm: CGFloat = 8

        /// 12pt - Medium rounding (cards, standard containers)
        public static let md: CGFloat = 12

        /// 16pt - Large rounding (prominent cards)
        public static let lg: CGFloat = 16

        /// 20pt - Extra large rounding
        public static let xl: CGFloat = 20

        /// 24pt - Very large rounding (modal sheets)
        public static let xxl: CGFloat = 24
    }

    // MARK: - Shadows

    /// Shadow definitions for elevation
    public struct Shadows {
        /// Subtle shadow - minimal elevation
        /// - Usage: Slight depth, hover states
        public static let subtle = (
            color: Color.black.opacity(0.04),
            radius: CGFloat(2),
            x: CGFloat(0),
            y: CGFloat(1)
        )

        /// Small shadow - low elevation
        /// - Usage: Cards, buttons
        public static let small = (
            color: Color.black.opacity(0.06),
            radius: CGFloat(4),
            x: CGFloat(0),
            y: CGFloat(2)
        )

        /// Medium shadow - medium elevation
        /// - Usage: Elevated cards, dropdowns
        public static let medium = (
            color: Color.black.opacity(0.08),
            radius: CGFloat(8),
            x: CGFloat(0),
            y: CGFloat(4)
        )

        /// Large shadow - high elevation
        /// - Usage: Modals, floating panels
        public static let large = (
            color: Color.black.opacity(0.12),
            radius: CGFloat(16),
            x: CGFloat(0),
            y: CGFloat(8)
        )
    }

    // MARK: - Icon Sizes

    /// Standard icon sizes
    public struct IconSize {
        /// 12pt - Extra small icons
        public static let xs: CGFloat = 12

        /// 16pt - Small icons (inline with text)
        public static let sm: CGFloat = 16

        /// 20pt - Medium icons (standard UI icons)
        public static let md: CGFloat = 20

        /// 24pt - Large icons (prominent UI elements)
        public static let lg: CGFloat = 24

        /// 32pt - Extra large icons
        public static let xl: CGFloat = 32

        /// 48pt - Very large icons (empty states, features)
        public static let xxl: CGFloat = 48
    }

    // MARK: - Animation

    /// Animation timing and curves
    public struct Animation {
        /// Micro interaction - very fast (hover, focus)
        public static let microInteraction = SwiftUI.Animation.easeOut(duration: 0.15)

        /// Fast - quick transitions
        public static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)

        /// Standard - default transitions
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)

        /// Smooth - gentle transitions
        public static let smooth = SwiftUI.Animation.easeInOut(duration: 0.4)

        /// Spring - bouncy, natural feel
        public static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.7)

        /// Bouncy spring - more pronounced bounce
        public static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)

        /// Ease out - decelerating
        public static let easeOut = SwiftUI.Animation.easeOut(duration: 0.2)

        /// Ease in - accelerating
        public static let easeIn = SwiftUI.Animation.easeIn(duration: 0.2)
    }
}

// MARK: - Deprecated Legacy Support

/// Legacy theme colors - DEPRECATED
/// - Warning: Use `DesignSystem.Colors` instead for new code
/// - Note: Maintained for backward compatibility only
@available(*, deprecated, message: "Use DesignSystem.Colors instead. Migration path: LegacyThemeColors.primary → DesignSystem.Colors.primary")
public struct LegacyThemeColors {
    @available(*, deprecated, renamed: "DesignSystem.Colors.primary")
    public static let primary = Color.blue

    @available(*, deprecated, renamed: "DesignSystem.Colors.secondary")
    public static let secondary = Color.gray

    @available(*, deprecated, renamed: "DesignSystem.Colors.Adaptive.background")
    public static let background = Color(.systemBackground)

    @available(*, deprecated, renamed: "DesignSystem.Colors.Adaptive.surface")
    public static let surface = Color(.secondarySystemBackground)

    @available(*, deprecated, renamed: "DesignSystem.Colors.Adaptive.textPrimary")
    public static let text = Color(.label)

    @available(*, deprecated, renamed: "DesignSystem.Colors.Adaptive.textSecondary")
    public static let textSecondary = Color(.secondaryLabel)

    @available(*, deprecated, renamed: "DesignSystem.Colors.success")
    public static let success = Color.green

    @available(*, deprecated, renamed: "DesignSystem.Colors.warning")
    public static let warning = Color.orange

    @available(*, deprecated, renamed: "DesignSystem.Colors.error")
    public static let error = Color.red

    @available(*, deprecated, renamed: "DesignSystem.Colors.info")
    public static let info = Color.blue

    @available(*, deprecated, renamed: "DesignSystem.Colors.glassBackground")
    public static let glassBackground = Color.white.opacity(0.1)

    @available(*, deprecated, renamed: "DesignSystem.Colors.glassBorder")
    public static let glassBorder = Color.white.opacity(0.2)

    @available(*, deprecated, renamed: "DesignSystem.Colors.Adaptive.border")
    public static let border = Color(.separator)

    @available(*, deprecated, renamed: "DesignSystem.Colors.shadow")
    public static let shadow = Color.black.opacity(0.1)
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (e.g., "FF0000" or "#FF0000")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Migration Guide
/*

 MIGRATION GUIDE: Moving from Legacy Theme to DesignSystem
 ============================================================

 ### Color Migrations:

 Old (Legacy)                          →  New (DesignSystem)
 ─────────────────────────────────────────────────────────────
 LegacyThemeColors.primary            →  DesignSystem.Colors.primary
 LegacyThemeColors.secondary          →  DesignSystem.Colors.secondary
 LegacyThemeColors.background         →  DesignSystem.Colors.Adaptive.background
 LegacyThemeColors.surface            →  DesignSystem.Colors.Adaptive.surface
 LegacyThemeColors.text               →  DesignSystem.Colors.Adaptive.textPrimary
 LegacyThemeColors.textSecondary      →  DesignSystem.Colors.Adaptive.textSecondary
 LegacyThemeColors.success            →  DesignSystem.Colors.success
 LegacyThemeColors.warning            →  DesignSystem.Colors.warning
 LegacyThemeColors.error              →  DesignSystem.Colors.error
 LegacyThemeColors.info               →  DesignSystem.Colors.info
 LegacyThemeColors.border             →  DesignSystem.Colors.Adaptive.border
 LegacyThemeColors.shadow             →  DesignSystem.Colors.shadow

 MedicalColors.*                      →  DesignSystem.Colors.* (use appropriate nested struct)

 ### Typography Migrations:

 Old (Legacy)                          →  New (DesignSystem)
 ─────────────────────────────────────────────────────────────
 ThemeTypography.h1                   →  DesignSystem.Typography.displayMedium
 ThemeTypography.h2                   →  DesignSystem.Typography.headlineLarge
 ThemeTypography.h3                   →  DesignSystem.Typography.headlineMedium
 ThemeTypography.bodyLarge            →  DesignSystem.Typography.bodyLarge
 ThemeTypography.bodyMedium           →  DesignSystem.Typography.bodyMedium
 ThemeTypography.bodySmall            →  DesignSystem.Typography.bodySmall
 ThemeTypography.caption              →  DesignSystem.Typography.caption
 ThemeTypography.button               →  DesignSystem.Typography.button
 ThemeTypography.numericLarge         →  DesignSystem.Typography.numericLarge

 MedicalTypography.*                  →  DesignSystem.Typography.*

 ### Spacing Migrations:

 Old (Legacy)                          →  New (DesignSystem)
 ─────────────────────────────────────────────────────────────
 ThemeSpacing.xxxs                    →  DesignSystem.Spacing.xxxs
 ThemeSpacing.md                      →  DesignSystem.Spacing.md
 ThemeSpacing.xl                      →  DesignSystem.Spacing.xl

 MedicalSpacing.*                     →  DesignSystem.Spacing.*

 ### Animation Migrations:

 Old (Legacy)                          →  New (DesignSystem)
 ─────────────────────────────────────────────────────────────
 ThemeAnimation.spring                →  DesignSystem.Animation.spring
 ThemeAnimation.easeOut               →  DesignSystem.Animation.easeOut

 MedicalAnimation.*                   →  DesignSystem.Animation.*

 ### Benefits of Migration:

 ✓ WCAG AA compliant colors throughout
 ✓ Single source of truth - no conflicting definitions
 ✓ Better documentation and semantic naming
 ✓ Medical-specific color palettes properly organized
 ✓ Consistent spacing and typography scales
 ✓ Improved dark mode support
 ✓ Future-proof architecture

 */
