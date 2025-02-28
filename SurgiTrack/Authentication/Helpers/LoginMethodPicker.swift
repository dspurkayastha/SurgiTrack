//
//  LoginMethodPicker.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// LoginMethodPicker.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI

/// A custom segmented picker for authentication methods
struct LoginMethodPicker: View {
    // MARK: - Properties
    
    /// Selected authentication method
    @Binding var selectedMethod: AuthenticationState.AuthMethod
    
    /// Available authentication methods
    var availableMethods: [AuthenticationState.AuthMethod]
    
    /// Action to perform when method changes
    var onMethodChange: ((AuthenticationState.AuthMethod) -> Void)?
    
    /// Appearance configuration
    var appearance: Appearance = .standard
    
    /// Current theme
    @EnvironmentObject private var appState: AppState
    
    /// Current color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Appearance Settings
    
    /// Appearance options for the picker
    enum Appearance {
        case standard
        case compact
        case minimal
        
        var horizontalPadding: CGFloat {
            switch self {
            case .standard: return 30
            case .compact: return 20
            case .minimal: return 16
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .standard: return 10
            case .compact: return 8
            case .minimal: return 6
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .standard: return 12
            case .compact, .minimal: return 8
            }
        }
        
        var showBackground: Bool {
            switch self {
            case .standard, .compact: return true
            case .minimal: return false
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .standard: return 16
            case .compact, .minimal: return 14
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(availableMethods) { method in
                methodButton(method)
            }
        }
        .padding(.horizontal, appearance.horizontalPadding)
        .padding(.vertical, appearance.verticalPadding)
        .background(
            appearance.showBackground ?
            RoundedRectangle(cornerRadius: appearance.cornerRadius)
                .fill(Color(.secondarySystemBackground).opacity(0.7))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            : nil
        )
    }
    
    // MARK: - Components
    
    /// Creates a button for an authentication method
    private func methodButton(_ method: AuthenticationState.AuthMethod) -> some View {
        Button(action: {
            if selectedMethod != method {
                HapticFeedback.methodSwitch()
                selectedMethod = method
                onMethodChange?(method)
            }
        }) {
            HStack(spacing: 5) {
                if appearance != .minimal {
                    Image(systemName: method.iconName)
                        .font(.system(size: appearance.fontSize * 0.8))
                }
                
                Text(method.title)
                    .font(.system(size: appearance.fontSize, weight: selectedMethod == method ? .semibold : .regular))
                    .minimumScaleFactor(0.8)          // <-- Add this
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedMethod == method ?
                Capsule()
                    .fill(appState.currentTheme.primaryColor.opacity(0.2)) :
                Capsule()
                    .fill(Color.clear)
            )
            .foregroundColor(
                selectedMethod == method ?
                appState.currentTheme.primaryColor :
                Color.gray
            )
            .animation(.easeInOut(duration: 0.2), value: selectedMethod)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct LoginMethodPicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Standard
            LoginMethodPicker(
                selectedMethod: .constant(.credentials),
                availableMethods: [.credentials, .pin, .biometric],
                appearance: .standard
            )
            .previewDisplayName("Standard")
            
            // Compact
            LoginMethodPicker(
                selectedMethod: .constant(.pin),
                availableMethods: [.credentials, .pin, .biometric],
                appearance: .compact
            )
            .previewDisplayName("Compact")
            
            // Minimal
            LoginMethodPicker(
                selectedMethod: .constant(.biometric),
                availableMethods: [.credentials, .pin, .biometric],
                appearance: .minimal
            )
            .previewDisplayName("Minimal")
        }
        .padding()
        .environmentObject(AppState())
    }
}
