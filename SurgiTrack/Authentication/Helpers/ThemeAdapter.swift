//
//  ThemeAdapter.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// ThemeAdapter.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI

/// Adapts colors and styling based on the current theme and color scheme
struct ThemeAdapter {
    // MARK: - Properties
    
    /// App state reference
    private let appState: AppState
    
    /// Current color scheme
    private let colorScheme: ColorScheme
    
    // MARK: - Initialization
    
    init(appState: AppState, colorScheme: ColorScheme) {
        self.appState = appState
        self.colorScheme = colorScheme
    }
    
    // MARK: - Color Adaptations
    
    /// Primary background color
    var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    /// Secondary background color
    var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.secondarySystemBackground)
    }
    
    /// Card background color
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.7)
    }
    
    /// Foreground color for primary text
    var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    /// Foreground color for secondary text
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.gray
    }
    
    /// Primary theme color (from current theme)
    var primaryThemeColor: Color {
        appState.currentTheme.primaryColor
    }
    
    /// Secondary theme color (from current theme)
    var secondaryThemeColor: Color {
        appState.currentTheme.secondaryColor
    }
    
    // MARK: - Gradient Builders
    
    /// Primary theme gradient
    var primaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                primaryThemeColor,
                secondaryThemeColor
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Subtle background gradient
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                primaryThemeColor.opacity(0.1),
                secondaryThemeColor.opacity(0.05)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Shadow Builders
    
    // MARK: - Shadow Builders
    
    /// Theme shadow modifier
    func themeShadow(radius: CGFloat = 10, opacity: Double = 0.3) -> some ViewModifier {
        return ShadowModifier(color: primaryThemeColor.opacity(opacity), radius: radius, x: 0, y: 4)
    }
    
    /// Standard shadow modifier
    func standardShadow(radius: CGFloat = 5, opacity: Double = 0.1) -> some ViewModifier {
        return ShadowModifier(color: Color.black.opacity(opacity), radius: radius, x: 0, y: 2)
    }
    
    // Shadow modifier struct
struct ShadowModifier: ViewModifier {
        var color: Color
        var radius: CGFloat
        var x: CGFloat
        var y: CGFloat
        
        func body(content: Content) -> some View {
            content.shadow(color: color, radius: radius, x: x, y: y)
        }
    }
}

// MARK: - Environment Value Extension

private struct ThemeAdapterKey: EnvironmentKey {
    static let defaultValue: ThemeAdapter? = nil
}

extension EnvironmentValues {
    var themeAdapter: ThemeAdapter? {
        get { self[ThemeAdapterKey.self] }
        set { self[ThemeAdapterKey.self] = newValue }
    }
}

extension View {
    /// Injects theme adapter into the environment
    func withThemeAdapter(appState: AppState, colorScheme: ColorScheme) -> some View {
        let adapter = ThemeAdapter(appState: appState, colorScheme: colorScheme)
        return self.environment(\.themeAdapter, adapter)
    }
}
