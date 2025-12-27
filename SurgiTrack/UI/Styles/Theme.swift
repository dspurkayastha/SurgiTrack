// Theme.swift
// SurgiTrack
// Legacy Theme System - DEPRECATED
//
// ⚠️ WARNING: This file is deprecated and maintained only for backward compatibility.
// All new code should use DesignSystem.swift instead.
//
// Migration Guide:
// - Theme.colors.* → DesignSystem.Colors.*
// - Theme.typography.* → DesignSystem.Typography.*
// - Theme.spacing.* → DesignSystem.Spacing.*
// - Theme.shadows.* → DesignSystem.Shadows.*
// - Theme.animation.* → DesignSystem.Animation.*
//
// See DesignSystem.swift for complete documentation and migration examples.

import SwiftUI

// MARK: - Shadow Support Struct

/// Shadow definition for legacy compatibility
/// - Note: Consider migrating to DesignSystem.Shadows
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Theme Colors (Instance-based for Environment)

/// Instance-based theme colors for environment injection
/// - Note: Now uses DesignSystem as the source of truth
/// - Usage: Inject via environment for dynamic theming
internal struct ThemeColors {
    var primary: Color
    var secondary: Color
    var accent: Color
    var background: Color
    var surface: Color
    var text: Color
    var textSecondary: Color

    // Semantic Colors
    var success: Color
    var warning: Color
    var error: Color
    var info: Color

    // Glassmorphism Colors
    var glassBackground: Color
    var glassBorder: Color

    var border: Color
    var shadow: Color

    // Initializer taking all parameters (inside the struct)
    init(
        primary: Color,
        secondary: Color,
        accent: Color,
        background: Color,
        surface: Color,
        text: Color,
        textSecondary: Color,
        success: Color,
        warning: Color,
        error: Color,
        info: Color,
        glassBackground: Color,
        glassBorder: Color,
        border: Color,
        shadow: Color
    ) {
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.background = background
        self.surface = surface
        self.text = text
        self.textSecondary = textSecondary
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
        self.glassBackground = glassBackground
        self.glassBorder = glassBorder
        self.border = border
        self.shadow = shadow
    }

    /// Default initializer - now uses DesignSystem values
    init() {
        // Use DesignSystem as the source of truth
        self.primary = DesignSystem.Colors.primary
        self.secondary = DesignSystem.Colors.secondary
        self.accent = DesignSystem.Colors.accent
        self.background = DesignSystem.Colors.Adaptive.background
        self.surface = DesignSystem.Colors.Adaptive.surface
        self.text = DesignSystem.Colors.Adaptive.textPrimary
        self.textSecondary = DesignSystem.Colors.Adaptive.textSecondary
        self.success = DesignSystem.Colors.success
        self.warning = DesignSystem.Colors.warning
        self.error = DesignSystem.Colors.error
        self.info = DesignSystem.Colors.info
        self.glassBackground = DesignSystem.Colors.glassBackground
        self.glassBorder = DesignSystem.Colors.glassBorder
        self.border = DesignSystem.Colors.Adaptive.border
        self.shadow = DesignSystem.Colors.shadow
    }
}

// MARK: - Legacy Theme Colors
// Note: LegacyThemeColors is defined in DesignSystem.swift

// MARK: - Theme Typography (DEPRECATED)

/// Legacy typography system - DEPRECATED
/// - Warning: Use `DesignSystem.Typography` instead
/// - Note: Maintained for backward compatibility only
/// - SeeAlso: `DesignSystem.Typography` for the unified typography system
@available(*, deprecated, message: "Use DesignSystem.Typography instead. See migration guide in DesignSystem.swift")
struct ThemeTypography {
    // Headings - Professional, clean design
    @available(*, deprecated, renamed: "DesignSystem.Typography.displayMedium")
    static let h1 = DesignSystem.Typography.displayMedium

    @available(*, deprecated, renamed: "DesignSystem.Typography.headlineLarge")
    static let h2 = DesignSystem.Typography.headlineLarge

    @available(*, deprecated, renamed: "DesignSystem.Typography.headlineMedium")
    static let h3 = DesignSystem.Typography.headlineMedium

    // Body Text - Optimized for readability
    @available(*, deprecated, renamed: "DesignSystem.Typography.bodyLarge")
    static let bodyLarge = DesignSystem.Typography.bodyLarge

    @available(*, deprecated, renamed: "DesignSystem.Typography.bodyMedium")
    static let bodyMedium = DesignSystem.Typography.bodyMedium

    @available(*, deprecated, renamed: "DesignSystem.Typography.bodySmall")
    static let bodySmall = DesignSystem.Typography.bodySmall

    // Special Text
    @available(*, deprecated, renamed: "DesignSystem.Typography.caption")
    static let caption = DesignSystem.Typography.caption

    @available(*, deprecated, renamed: "DesignSystem.Typography.captionBold")
    static let captionMedium = DesignSystem.Typography.captionBold

    @available(*, deprecated, renamed: "DesignSystem.Typography.button")
    static let button = DesignSystem.Typography.button

    // Titles
    @available(*, deprecated, renamed: "DesignSystem.Typography.titleLarge")
    static let titleLarge = DesignSystem.Typography.titleLarge

    @available(*, deprecated, renamed: "DesignSystem.Typography.titleMedium")
    static let titleMedium = DesignSystem.Typography.titleMedium

    // Labels
    @available(*, deprecated, renamed: "DesignSystem.Typography.labelMedium")
    static let labelMedium = DesignSystem.Typography.labelMedium

    @available(*, deprecated, renamed: "DesignSystem.Typography.labelSmall")
    static let labelSmall = DesignSystem.Typography.labelSmall

    // Numeric display - rounded for numbers only
    @available(*, deprecated, renamed: "DesignSystem.Typography.numericLarge")
    static let numericLarge = DesignSystem.Typography.numericLarge

    @available(*, deprecated, renamed: "DesignSystem.Typography.numericMedium")
    static let numericMedium = DesignSystem.Typography.numericMedium
}

// MARK: - Theme Spacing (DEPRECATED)

/// Legacy spacing system - DEPRECATED
/// - Warning: Use `DesignSystem.Spacing` instead
/// - Note: Maintained for backward compatibility only
/// - SeeAlso: `DesignSystem.Spacing` for the unified spacing system
@available(*, deprecated, message: "Use DesignSystem.Spacing instead. See migration guide in DesignSystem.swift")
struct ThemeSpacing {
    @available(*, deprecated, renamed: "DesignSystem.Spacing.xxxs")
    static let xxxs: CGFloat = DesignSystem.Spacing.xxxs

    @available(*, deprecated, renamed: "DesignSystem.Spacing.xxs")
    static let xxs: CGFloat = DesignSystem.Spacing.xxs

    @available(*, deprecated, renamed: "DesignSystem.Spacing.xs")
    static let xs: CGFloat = DesignSystem.Spacing.xs

    @available(*, deprecated, renamed: "DesignSystem.Spacing.sm")
    static let sm: CGFloat = DesignSystem.Spacing.sm

    @available(*, deprecated, renamed: "DesignSystem.Spacing.md")
    static let md: CGFloat = DesignSystem.Spacing.md

    @available(*, deprecated, renamed: "DesignSystem.Spacing.lg")
    static let lg: CGFloat = DesignSystem.Spacing.lg

    @available(*, deprecated, renamed: "DesignSystem.Spacing.xl")
    static let xl: CGFloat = DesignSystem.Spacing.xl

    @available(*, deprecated, renamed: "DesignSystem.Spacing.xxl")
    static let xxl: CGFloat = DesignSystem.Spacing.xxl

    @available(*, deprecated, renamed: "DesignSystem.Spacing.huge")
    static let xxxl: CGFloat = DesignSystem.Spacing.huge
}

// MARK: - Theme Shadows (DEPRECATED)

/// Legacy shadow system - DEPRECATED
/// - Warning: Use `DesignSystem.Shadows` instead
/// - Note: Maintained for backward compatibility only. Shadow struct format differs slightly.
/// - SeeAlso: `DesignSystem.Shadows` for the unified shadow system
@available(*, deprecated, message: "Use DesignSystem.Shadows instead. See migration guide in DesignSystem.swift")
struct ThemeShadows {
    @available(*, deprecated, message: "Use DesignSystem.Shadows.small - note: tuple format differs from Shadow struct")
    static let small = Shadow(
        color: DesignSystem.Shadows.small.color,
        radius: DesignSystem.Shadows.small.radius,
        x: DesignSystem.Shadows.small.x,
        y: DesignSystem.Shadows.small.y
    )

    @available(*, deprecated, message: "Use DesignSystem.Shadows.medium - note: tuple format differs from Shadow struct")
    static let medium = Shadow(
        color: DesignSystem.Shadows.medium.color,
        radius: DesignSystem.Shadows.medium.radius,
        x: DesignSystem.Shadows.medium.x,
        y: DesignSystem.Shadows.medium.y
    )

    @available(*, deprecated, message: "Use DesignSystem.Shadows.large - note: tuple format differs from Shadow struct")
    static let large = Shadow(
        color: DesignSystem.Shadows.large.color,
        radius: DesignSystem.Shadows.large.radius,
        x: DesignSystem.Shadows.large.x,
        y: DesignSystem.Shadows.large.y
    )
}

// MARK: - Theme Animation (DEPRECATED)

/// Legacy animation system - DEPRECATED
/// - Warning: Use `DesignSystem.Animation` instead
/// - Note: Maintained for backward compatibility only
/// - SeeAlso: `DesignSystem.Animation` for the unified animation system
@available(*, deprecated, message: "Use DesignSystem.Animation instead. See migration guide in DesignSystem.swift")
struct ThemeAnimation {
    @available(*, deprecated, renamed: "DesignSystem.Animation.spring")
    static let spring = DesignSystem.Animation.spring

    @available(*, deprecated, renamed: "DesignSystem.Animation.easeOut")
    static let easeOut = DesignSystem.Animation.easeOut

    @available(*, deprecated, renamed: "DesignSystem.Animation.easeIn")
    static let easeIn = DesignSystem.Animation.easeIn

    @available(*, deprecated, message: "Use DesignSystem.Animation.fast or DesignSystem.Animation.standard")
    static let easeInOut = DesignSystem.Animation.fast
}

// MARK: - Theme (DEPRECATED - Points to DesignSystem)

/// Legacy theme namespace - DEPRECATED
/// - Warning: Use `DesignSystem` directly instead
/// - Note: This struct exists only for backward compatibility
/// - SeeAlso: `DesignSystem` for the unified design system
///
/// # Migration Example:
/// ```swift
/// // Old (deprecated):
/// Text("Hello").foregroundColor(Theme.colors.primary)
///
/// // New (recommended):
/// Text("Hello").foregroundColor(DesignSystem.Colors.primary)
/// ```
@available(*, deprecated, message: "Use DesignSystem directly instead. Theme.colors.primary → DesignSystem.Colors.primary")
struct Theme {
    /// Legacy color access - DEPRECATED
    /// - Use `DesignSystem.Colors` instead
    @available(*, deprecated, message: "Use DesignSystem.Colors instead")
    static let colors = LegacyThemeColors.self

    /// Legacy typography access - DEPRECATED
    /// - Use `DesignSystem.Typography` instead
    @available(*, deprecated, message: "Use DesignSystem.Typography instead")
    static let typography = ThemeTypography.self

    /// Legacy spacing access - DEPRECATED
    /// - Use `DesignSystem.Spacing` instead
    @available(*, deprecated, message: "Use DesignSystem.Spacing instead")
    static let spacing = ThemeSpacing.self

    /// Legacy shadows access - DEPRECATED
    /// - Use `DesignSystem.Shadows` instead
    @available(*, deprecated, message: "Use DesignSystem.Shadows instead")
    static let shadows = ThemeShadows.self

    /// Legacy animation access - DEPRECATED
    /// - Use `DesignSystem.Animation` instead
    @available(*, deprecated, message: "Use DesignSystem.Animation instead")
    static let animation = ThemeAnimation.self
}

#Preview("Legacy Theme (Deprecated)") {
    VStack(spacing: DesignSystem.Spacing.md) {
        // Header
        Text("Theme System Comparison")
            .font(DesignSystem.Typography.headlineLarge)
            .foregroundColor(DesignSystem.Colors.Adaptive.textPrimary)

        Divider()

        // Legacy approach (still works but deprecated)
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Legacy Theme (Deprecated)")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(DesignSystem.Colors.Adaptive.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 24, height: 24)
                Text("Primary")
                    .font(DesignSystem.Typography.bodySmall)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(DesignSystem.Colors.success)
                    .frame(width: 24, height: 24)
                Text("Success")
                    .font(DesignSystem.Typography.bodySmall)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(DesignSystem.Colors.error)
                    .frame(width: 24, height: 24)
                Text("Error")
                    .font(DesignSystem.Typography.bodySmall)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.Adaptive.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.md)

        Divider()

        // New approach (recommended)
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("New DesignSystem (Recommended)")
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(DesignSystem.Colors.Adaptive.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 24, height: 24)
                Text("Primary")
                    .font(DesignSystem.Typography.bodySmall)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(DesignSystem.Colors.success)
                    .frame(width: 24, height: 24)
                Text("Success")
                    .font(DesignSystem.Typography.bodySmall)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(DesignSystem.Colors.error)
                    .frame(width: 24, height: 24)
                Text("Error")
                    .font(DesignSystem.Typography.bodySmall)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.Adaptive.surfaceElevated)
        .cornerRadius(DesignSystem.CornerRadius.md)

        // Notice
        Text("✓ Both approaches work identically\n✓ Legacy code continues to function\n✓ Migrate to DesignSystem for new code")
            .font(DesignSystem.Typography.caption)
            .foregroundColor(DesignSystem.Colors.Adaptive.textSecondary)
            .multilineTextAlignment(.center)
    }
    .padding(DesignSystem.Spacing.xl)
    .background(DesignSystem.Colors.Adaptive.background)
} 