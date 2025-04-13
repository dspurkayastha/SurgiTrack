import SwiftUI

// ThemeColors is defined in Theme.swift

/// Bridges the new UI components with the existing AppTheme system
struct ThemeBridge {
    static func adaptTheme(_ appTheme: AppTheme, colorScheme: ColorScheme) -> ThemeColors {
        // This call refers to ThemeColors defined in Theme.swift
        return ThemeColors(
            primary: appTheme.primaryColor,
            secondary: appTheme.secondaryColor,
            accent: appTheme.primaryColor.opacity(0.8),
            background: colorScheme == .dark ? Color.black : Color.white,
            surface: colorScheme == .dark ? Color.black.opacity(0.3) : Color.white,
            text: colorScheme == .dark ? Color.white : Color.primary,
            textSecondary: colorScheme == .dark ? Color.white.opacity(0.7) : Color.gray,
            success: Color.green,
            warning: Color.orange,
            error: Color.red,
            info: Color.blue,
            glassBackground: Color.white.opacity(0.1),
            glassBorder: Color.white.opacity(0.2),
            border: Color(.separator),
            shadow: Color.black.opacity(0.1)
        )
    }
}

// MARK: - View Extension
extension View {
    func withThemeBridge(appState: AppState, colorScheme: ColorScheme) -> some View {
        // Remove the guard let as appState.currentTheme is not optional
        let currentTheme = appState.currentTheme
        let adaptedColors = ThemeBridge.adaptTheme(currentTheme, colorScheme: colorScheme)
        return self.environment(\.themeColors, adaptedColors)
    }
}

// MARK: - Environment Key
private struct ThemeColorsKey: EnvironmentKey {
    // Uses ThemeColors defined in Theme.swift
    typealias Value = ThemeColors
    static let defaultValue = ThemeColors()
}

extension EnvironmentValues {
    // Uses ThemeColors defined in Theme.swift
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        // The KeyPath should now resolve correctly
        set { self[ThemeColorsKey.self] = newValue }
    }
} 