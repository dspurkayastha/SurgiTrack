//
//  ErrorMessageView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// ErrorMessageView.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI

/// Displays error messages with animation
struct ErrorMessageView: View {
    // MARK: - Properties
    
    /// Error message to display
    var message: String?
    
    /// Show error animation
    var isShowing: Bool
    
    /// Alert style
    var style: AlertStyle = .error
    
    /// Offset for shake animation
    var shakeOffset: CGFloat = 0
    
    /// Auto-dismiss after time interval
    var autoDismiss: Bool = true
    
    /// Auto-dismiss delay
    var dismissDelay: Double = 5.0
    
    /// Optional dismiss action
    var onDismiss: (() -> Void)?
    
    /// Current theme
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Alert Styles
    
    /// Alert style options
    enum AlertStyle {
        case error
        case warning
        case info
        case success
        
        /// Background color for this style
        var backgroundColor: Color {
            switch self {
            case .error: return Color.red.opacity(0.1)
            case .warning: return Color.orange.opacity(0.1)
            case .info: return Color.blue.opacity(0.1)
            case .success: return Color.green.opacity(0.1)
            }
        }
        
        /// Border color for this style
        var borderColor: Color {
            switch self {
            case .error: return Color.red.opacity(0.3)
            case .warning: return Color.orange.opacity(0.3)
            case .info: return Color.blue.opacity(0.3)
            case .success: return Color.green.opacity(0.3)
            }
        }
        
        /// Icon name for this style
        var iconName: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
        
        /// Text color for this style
        var textColor: Color {
            switch self {
            case .error: return Color.red
            case .warning: return Color.orange
            case .info: return Color.blue
            case .success: return Color.green
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        if isShowing, let message = message {
            VStack {
                HStack {
                    // Icon
                    Image(systemName: style.iconName)
                        .foregroundColor(style.textColor)
                    
                    // Message
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(style.textColor)
                    
                    Spacer()
                    
                    // Dismiss button
                    Button(action: {
                        onDismiss?()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(style.textColor.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(style.backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style.borderColor, lineWidth: 1)
                        )
                )
                .offset(x: shakeOffset)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                if autoDismiss {
                    DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
                        onDismiss?()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct ErrorMessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Error
            ErrorMessageView(
                message: "Invalid username or password",
                isShowing: true,
                style: .error,
                autoDismiss: false
            )
            .previewDisplayName("Error")
            
            // Warning
            ErrorMessageView(
                message: "Your session will expire soon",
                isShowing: true,
                style: .warning,
                autoDismiss: false
            )
            .previewDisplayName("Warning")
            
            // Info
            ErrorMessageView(
                message: "Biometric authentication is available",
                isShowing: true,
                style: .info,
                autoDismiss: false
            )
            .previewDisplayName("Info")
            
            // Success
            ErrorMessageView(
                message: "Successfully authenticated",
                isShowing: true,
                style: .success,
                autoDismiss: false
            )
            .previewDisplayName("Success")
        }
        .padding()
        .environmentObject(AppState())
    }
}