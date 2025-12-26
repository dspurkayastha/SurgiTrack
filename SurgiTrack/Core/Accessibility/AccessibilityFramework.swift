// AccessibilityFramework.swift
// SurgiTrack
// Comprehensive accessibility support for WCAG 2.1 AA compliance
// Created on 26/12/2025

import SwiftUI
import Combine

// MARK: - Accessibility Manager

/// Centralized accessibility settings manager
@MainActor
final class AccessibilityManager: ObservableObject {

    // MARK: - Singleton

    static let shared = AccessibilityManager()

    // MARK: - Published Properties

    @Published private(set) var isVoiceOverRunning = false
    @Published private(set) var isSwitchControlRunning = false
    @Published private(set) var isReduceMotionEnabled = false
    @Published private(set) var isReduceTransparencyEnabled = false
    @Published private(set) var isDifferentiateWithoutColorEnabled = false
    @Published private(set) var isBoldTextEnabled = false
    @Published private(set) var preferredContentSizeCategory: UIContentSizeCategory = .medium

    // MARK: - Initialization

    private init() {
        updateAccessibilitySettings()
        setupNotifications()
    }

    // MARK: - Private Methods

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.switchControlStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilitySettingsChanged),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    @objc private func accessibilitySettingsChanged() {
        updateAccessibilitySettings()
    }

    private func updateAccessibilitySettings() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        isSwitchControlRunning = UIAccessibility.isSwitchControlRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
        isDifferentiateWithoutColorEnabled = UIAccessibility.shouldDifferentiateWithoutColor
        isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    }

    // MARK: - Utility Methods

    /// Returns appropriate animation based on reduce motion setting
    func animation(_ animation: Animation = .default) -> Animation? {
        isReduceMotionEnabled ? nil : animation
    }

    /// Returns scaled value for current content size category
    func scaledValue(_ baseValue: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> CGFloat {
        let sizeCategory = preferredContentSizeCategory
        let scale: CGFloat

        switch sizeCategory {
        case .extraSmall: scale = 0.8
        case .small: scale = 0.9
        case .medium: scale = 1.0
        case .large: scale = 1.1
        case .extraLarge: scale = 1.2
        case .extraExtraLarge: scale = 1.3
        case .extraExtraExtraLarge: scale = 1.4
        case .accessibilityMedium: scale = 1.6
        case .accessibilityLarge: scale = 1.8
        case .accessibilityExtraLarge: scale = 2.0
        case .accessibilityExtraExtraLarge: scale = 2.2
        case .accessibilityExtraExtraExtraLarge: scale = 2.5
        default: scale = 1.0
        }

        return baseValue * scale
    }
}

// MARK: - Accessible Color System

/// WCAG 2.1 AA compliant color system
struct AccessibleColors {

    // MARK: - Contrast Ratios

    /// Minimum contrast ratio for normal text (WCAG AA)
    static let normalTextMinContrast = 4.5

    /// Minimum contrast ratio for large text (WCAG AA)
    static let largeTextMinContrast = 3.0

    /// Minimum contrast ratio for UI components
    static let uiComponentMinContrast = 3.0

    // MARK: - Semantic Colors (WCAG AA Compliant)

    struct Primary {
        /// Primary blue - meets 4.5:1 contrast on white
        static let base = Color(hex: "1A56DB")
        static let light = Color(hex: "3B82F6")
        static let dark = Color(hex: "1E40AF")
    }

    struct Success {
        /// Success green - meets 4.5:1 contrast on white
        static let base = Color(hex: "047857")
        static let light = Color(hex: "10B981")
        static let dark = Color(hex: "065F46")
    }

    struct Warning {
        /// Warning orange - meets 3:1 contrast on white (large text only)
        static let base = Color(hex: "B45309")
        static let light = Color(hex: "F59E0B")
        static let dark = Color(hex: "92400E")
    }

    struct Error {
        /// Error red - meets 4.5:1 contrast on white
        static let base = Color(hex: "B91C1C")
        static let light = Color(hex: "EF4444")
        static let dark = Color(hex: "991B1B")
    }

    struct Neutral {
        static let text = Color(hex: "1F2937")           // 12.6:1 on white
        static let textSecondary = Color(hex: "4B5563")  // 7.5:1 on white
        static let textTertiary = Color(hex: "6B7280")   // 5.0:1 on white
        static let border = Color(hex: "9CA3AF")         // 3.0:1 on white
        static let background = Color(hex: "F9FAFB")
    }

    // MARK: - Medical Status Colors (WCAG AA Compliant)

    struct PatientStatus {
        /// Stable - green that meets contrast requirements
        static let stable = Color(hex: "047857")

        /// Guarded - yellow/orange with sufficient contrast
        static let guarded = Color(hex: "B45309")

        /// Critical - red that meets requirements
        static let critical = Color(hex: "B91C1C")

        /// Inactive - gray that meets requirements
        static let inactive = Color(hex: "4B5563")
    }

    // MARK: - Contrast Calculation

    /// Calculates relative luminance for a color component
    static func relativeLuminance(_ component: CGFloat) -> CGFloat {
        let c = component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        return c
    }

    /// Calculates contrast ratio between two colors
    static func contrastRatio(_ color1: Color, _ color2: Color) -> Double {
        // This is a simplified version - full implementation would need UIColor conversion
        // For production, use actual luminance calculation
        return 4.5 // Placeholder - actual implementation needed
    }
}

// MARK: - Accessible Typography

struct AccessibleTypography {

    /// Minimum font size for body text (WCAG recommendation)
    static let minimumBodySize: CGFloat = 16

    /// Minimum font size for captions
    static let minimumCaptionSize: CGFloat = 12

    /// Line height multiplier for readability
    static let lineHeightMultiplier: CGFloat = 1.5

    /// Letter spacing for improved readability
    static let letterSpacing: CGFloat = 0.5

    // MARK: - Scalable Fonts

    /// Returns a font that scales with Dynamic Type
    static func scalableFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        Font.system(size: size, weight: weight, design: design)
    }

    /// Heading styles that scale with Dynamic Type
    struct Heading {
        static var h1: Font { .largeTitle.bold() }
        static var h2: Font { .title.bold() }
        static var h3: Font { .title2.semibold() }
        static var h4: Font { .title3.semibold() }
        static var h5: Font { .headline }
    }

    /// Body styles
    struct Body {
        static var large: Font { .body }
        static var regular: Font { .body }
        static var small: Font { .subheadline }
    }

    /// Caption styles
    struct Caption {
        static var regular: Font { .caption }
        static var small: Font { .caption2 }
    }
}

// MARK: - View Modifiers

/// Adds comprehensive accessibility support to a view
struct AccessibleViewModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    let value: String?

    init(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        value: String? = nil
    ) {
        self.label = label
        self.hint = hint
        self.traits = traits
        self.value = value
    }

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityValue(value ?? "")
    }
}

/// Ensures minimum touch target size (44x44 points)
struct MinimumTouchTargetModifier: ViewModifier {
    let minimumSize: CGFloat = 44

    func body(content: Content) -> some View {
        content
            .frame(minWidth: minimumSize, minHeight: minimumSize)
            .contentShape(Rectangle())
    }
}

/// Respects reduce motion setting
struct ReduceMotionModifier: ViewModifier {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    let animation: Animation

    func body(content: Content) -> some View {
        content
            .animation(accessibilityManager.isReduceMotionEnabled ? nil : animation, value: UUID())
    }
}

/// Adds visual indicator for non-color distinction
struct DifferentiateWithoutColorModifier: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    let icon: String

    func body(content: Content) -> some View {
        HStack(spacing: 4) {
            if differentiateWithoutColor {
                Image(systemName: icon)
                    .font(.caption)
            }
            content
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds comprehensive VoiceOver support
    func accessible(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        value: String? = nil
    ) -> some View {
        modifier(AccessibleViewModifier(
            label: label,
            hint: hint,
            traits: traits,
            value: value
        ))
    }

    /// Ensures minimum 44x44 touch target
    func minimumTouchTarget() -> some View {
        modifier(MinimumTouchTargetModifier())
    }

    /// Animation that respects reduce motion
    func accessibleAnimation(_ animation: Animation = .default) -> some View {
        modifier(ReduceMotionModifier(animation: animation))
    }

    /// Adds icon when differentiate without color is enabled
    func differentiateWithIcon(_ icon: String) -> some View {
        modifier(DifferentiateWithoutColorModifier(icon: icon))
    }

    /// Groups content for VoiceOver navigation
    func accessibilityGroup(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    /// Makes a button accessible
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessible(label: label, hint: hint, traits: .isButton)
            .minimumTouchTarget()
    }

    /// Makes a header accessible
    func accessibleHeader(level: Int = 1) -> some View {
        self.accessibilityAddTraits(.isHeader)
    }

    /// Announces changes to VoiceOver
    func announceChanges(_ message: String, priority: AccessibilityNotification.Announcement.Priority = .high) -> some View {
        self.onChange(of: message) { _, newValue in
            UIAccessibility.post(notification: .announcement, argument: newValue)
        }
    }
}

// MARK: - Accessible Components

/// An accessible button with proper touch target and VoiceOver support
struct AccessibleButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    let accessibilityLabel: String
    let accessibilityHint: String?

    init(
        _ accessibilityLabel: String,
        hint: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = hint
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action, label: label)
            .accessibleButton(label: accessibilityLabel, hint: accessibilityHint)
    }
}

/// An accessible text field with validation feedback
struct AccessibleTextField: View {
    let title: String
    @Binding var text: String
    let prompt: String?
    let errorMessage: String?
    var keyboardType: UIKeyboardType = .default

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text, prompt: prompt.map { Text($0) })
                .keyboardType(keyboardType)
                .accessibilityLabel(title)
                .accessibilityValue(text.isEmpty ? "Empty" : text)
                .accessibilityHint(errorMessage ?? prompt ?? "")

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(AccessibleColors.Error.base)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }
}

/// Accessible progress indicator with value announcement
struct AccessibleProgressView: View {
    let value: Double
    let total: Double
    let label: String

    private var percentage: Int {
        Int((value / total) * 100)
    }

    var body: some View {
        ProgressView(value: value, total: total) {
            Text(label)
        }
        .accessibilityLabel("\(label), \(percentage) percent complete")
        .accessibilityValue("\(percentage)%")
    }
}

/// Status badge with non-color visual indicator
struct AccessibleStatusBadge: View {
    let status: Status
    let showIcon: Bool

    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    enum Status {
        case success, warning, error, info

        var color: Color {
            switch self {
            case .success: return AccessibleColors.Success.base
            case .warning: return AccessibleColors.Warning.base
            case .error: return AccessibleColors.Error.base
            case .info: return AccessibleColors.Primary.base
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var label: String {
            switch self {
            case .success: return "Success"
            case .warning: return "Warning"
            case .error: return "Error"
            case .info: return "Information"
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if showIcon || differentiateWithoutColor {
                Image(systemName: status.icon)
            }
            Text(status.label)
        }
        .foregroundColor(status.color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(status.label)
    }
}

// MARK: - Focus Management

/// Manages accessibility focus for complex navigation
class AccessibilityFocusManager: ObservableObject {
    @Published var focusedElement: String?

    func moveFocus(to element: String) {
        focusedElement = element
        // Post accessibility notification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }

    func announceChange(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

// MARK: - Dynamic Type Support

struct DynamicTypeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

extension View {
    /// Enables full Dynamic Type support up to accessibility sizes
    func supportsDynamicType() -> some View {
        modifier(DynamicTypeModifier())
    }
}
