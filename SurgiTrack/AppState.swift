//
//  AppState.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 06/03/25.
//


// AppState.swift
// SurgiTrack
// Created on 06/03/2025

import SwiftUI

// Central app state management
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var colorScheme: ColorScheme? = nil
    @Published var currentTheme: AppTheme = .teal
    @Published var notifications: [AppNotification] = []
    
    // Initialize with stored preferences
    init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
        
        // Load dark/light mode preference
        if let savedMode = UserDefaults.standard.string(forKey: "colorScheme") {
            if savedMode == "dark" {
                colorScheme = .dark
            } else if savedMode == "light" {
                colorScheme = .light
            } else {
                colorScheme = nil // System
            }
        }
        
        // Check if onboarding was completed
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    // Set and persist theme
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
    }
    
    // Set and persist color scheme
    func setColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
        let value = scheme == .dark ? "dark" : (scheme == .light ? "light" : "system")
        UserDefaults.standard.set(value, forKey: "colorScheme")
    }
    
    // Set onboarding completion
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    // Clear all user data (for logout)
    func resetUserState() {
        // Keep theme and appearance preferences
    }
    func showAlert(title: String, message: String) {
            // Your alert implementation
            // This could set some @Published properties that trigger an alert overlay
            // For example:
            
        }
        
        func presentSheet<Content: View>(view: Content) {
            // Your sheet presentation implementation
            // This could store the view and set a flag to show it
        }
}

// App Theme options
enum AppTheme: String, CaseIterable, Identifiable {
    case teal = "teal"
    case blue = "blue"
    case indigo = "indigo"
    case purple = "purple"
    case orange = "orange"
    case pink = "pink"
    
    var id: String { self.rawValue }
    
    var primaryColor: Color {
        switch self {
        case .teal: return Color("TealPrimary")
        case .blue: return Color("BluePrimary")
        case .indigo: return Color("IndigoPrimary")
        case .purple: return Color("PurplePrimary")
        case .orange: return Color("OrangePrimary")
        case .pink: return Color("PinkPrimary")
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .teal: return Color("TealSecondary")
        case .blue: return Color("BlueSecondary")
        case .indigo: return Color("IndigoSecondary")
        case .purple: return Color("PurpleSecondary")
        case .orange: return Color("OrangeSecondary")
        case .pink: return Color("PinkSecondary")
        }
    }
}

// Notification model for in-app notifications
struct AppNotification: Identifiable {
    let id = UUID()
    let message: String
    let type: NotificationType
    let date: Date
    var isRead: Bool = false
    
    enum NotificationType {
        case info, success, warning, error
    }
}
