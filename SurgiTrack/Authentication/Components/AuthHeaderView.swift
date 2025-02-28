//
//  AuthHeaderView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// AuthHeaderView.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI

/// A shared header view for authentication screens
struct AuthHeaderView: View {
    // MARK: - Properties
    
    /// Style of header to display
    var style: Style
    
    /// Title text
    var title: String
    
    /// Optional subtitle text
    var subtitle: String?
    
    /// Icon name (SF Symbols)
    var iconName: String
    
    /// Animation progress (0-1)
    var animationProgress: CGFloat
    
    /// Ongoing animation (e.g., pulsing)
    var animating: Bool = false
    
    /// Current theme
    @EnvironmentObject private var appState: AppState
    
    /// Current color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Style Enum
    
    /// Header style options
    enum Style {
        case credentials
        case pin
        case biometric
        
        /// Icon size for this style
        var iconSize: CGFloat {
            switch self {
            case .credentials: return 45
            case .pin: return 40
            case .biometric: return 50
            }
        }
        
        /// Circle size for this style
        var circleSize: CGFloat {
            switch self {
            case .credentials: return 90
            case .pin: return 80
            case .biometric: return 100
            }
        }
        
        /// Outer ring count
        var ringCount: Int {
            switch self {
            case .credentials: return 1
            case .pin: return 1
            case .biometric: return 3
            }
        }
    }
    
    // MARK: - Animation States
    
    /// Scale animation for pulsing effect
    @State private var pulseScale: CGFloat = 1.0
    
    /// Rotation animation for icon
    @State private var iconRotation: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 15) {
            // Icon with container
            ZStack {
                // Outer rings with pulsing animation
                ForEach(0..<style.ringCount, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    appState.currentTheme.primaryColor.opacity(0.3 - Double(i) * 0.1),
                                    appState.currentTheme.secondaryColor.opacity(0.2 - Double(i) * 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2 - CGFloat(i) * 0.5
                        )
                        .frame(
                            width: style.circleSize + CGFloat(i * 20),
                            height: style.circleSize + CGFloat(i * 20)
                        )
                        .scaleEffect(animating ? pulseScale : 0.95)
                }
                
                // Main circle background
                Circle()
                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                    .frame(width: style.circleSize, height: style.circleSize)
                    .overlay(
                        Circle()
                            .fill(appState.currentTheme.primaryColor.opacity(0.1))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        appState.currentTheme.primaryColor.opacity(0.7),
                                        appState.currentTheme.secondaryColor.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: appState.currentTheme.primaryColor.opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 3
                    )
                
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: style.iconSize, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                appState.currentTheme.primaryColor,
                                appState.currentTheme.secondaryColor
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .rotationEffect(.degrees(iconRotation))
            }
            .opacity(animationProgress)
            .scaleEffect(animationProgress)
            
            // Title text
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(appState.currentTheme.primaryColor)
                .opacity(animationProgress)
            
            // Optional subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(animationProgress)
            }
        }
        .onAppear {
            if animating {
                startAnimations()
            }
        }
        .onChange(of: animating) { isAnimating in
            if isAnimating {
                startAnimations()
            }
        }
    }
    
    // MARK: - Animation Methods
    
    /// Start all animations for the header
    private func startAnimations() {
        // Start pulse animation
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.05
        }
        
        // Start icon rotation for specific styles
        if style == .biometric {
            withAnimation(
                Animation.linear(duration: 20)
                    .repeatForever(autoreverses: false)
            ) {
                iconRotation = 360
            }
        }
    }
}

// MARK: - Preview
struct AuthHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AuthHeaderView(
                style: .biometric,
                title: "Face ID Login",
                subtitle: "Login with Face ID for quick and secure access",
                iconName: "faceid",
                animationProgress: 1.0,
                animating: true
            )
            
            AuthHeaderView(
                style: .credentials,
                title: "Welcome Back",
                subtitle: "Sign in to your account",
                iconName: "person.fill",
                animationProgress: 1.0,
                animating: true
            )
            
            AuthHeaderView(
                style: .pin,
                title: "Enter PIN",
                subtitle: "Enter your 6-digit PIN",
                iconName: "lock.fill",
                animationProgress: 1.0,
                animating: true
            )
        }
        .padding()
        .environmentObject(AppState())
    }
}