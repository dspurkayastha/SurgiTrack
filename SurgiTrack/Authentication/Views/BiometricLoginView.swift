//
//  BiometricLoginView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// BiometricLoginView.swift
// SurgiTrack
// Refactored on 03/20/2025

import SwiftUI
import LocalAuthentication

struct BiometricLoginView: View {
    // MARK: - Properties
    var biometricType: BiometricType
    var onAuthenticate: () -> Void
    
    // MARK: - State
    @State private var authenticating = false
    @State private var authRays: [AuthRay] = []
    @State private var rayAnimation = false
    
    // MARK: - Environment
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Types
    enum BiometricType {
        case faceID
        case touchID
        
        var iconName: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            }
        }
        
        var displayName: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 30) {
            // MARK: - Header
            AuthHeaderView(
                style: .biometric,
                title: "\(biometricType.displayName) Login",
                subtitle: "Login with \(biometricType.displayName) for quick and secure access",
                iconName: biometricType.iconName,
                animationProgress: 1.0,
                animating: true
            )
            
            // MARK: - Biometric Content
            GlassmorphicCard {
                VStack(spacing: 24) {
                    // Biometric icon with animation
                    ZStack {
                        // Authentication rays that appear during authentication
                        ForEach(authRays) { ray in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(appState.currentTheme.primaryColor.opacity(ray.opacity))
                                .frame(width: ray.length, height: 2)
                                .offset(x: ray.distance)
                                .rotationEffect(.degrees(ray.angle))
                                .opacity(authenticating ? 1 : 0)
                                .animation(
                                    Animation.easeInOut(duration: Double.random(in: 1.0...2.0))
                                        .repeatForever(autoreverses: true),
                                    value: rayAnimation
                                )
                        }
                        
                        // Center circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (colorScheme == .dark ? Color.black : Color.white).opacity(0.7),
                                        (colorScheme == .dark ? Color.black : Color.white).opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: appState.currentTheme.primaryColor.opacity(0.5), radius: 15, x: 0, y: 4)
                        
                        // Biometric icon
                        Image(systemName: biometricType.iconName)
                            .font(.system(size: 60, weight: .light))
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
                            .shadow(color: appState.currentTheme.primaryColor.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                    .frame(height: 180)
                    
                    // Description
                    Text("Authenticate with \(biometricType.displayName) for quick and secure access to your account.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    // Authenticate button
                    Button(action: {
                        HapticFeedback.buttonPress()
                        startAuthenticationAnimation()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onAuthenticate()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: biometricType.iconName)
                                .font(.system(size: 18))
                            
                            Text("Authenticate with \(biometricType.displayName)")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            appState.currentTheme.primaryColor,
                                            appState.currentTheme.secondaryColor
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: appState.currentTheme.primaryColor.opacity(0.5), radius: 8, x: 0, y: 4)
                        )
                    }
                    .withHapticFeedback()
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Alternative login options
                    VStack(spacing: 8) {
                        Text("Having trouble?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            HapticFeedback.buttonPress()
                            // Would switch to credentials login
                        }) {
                            Text("Use account credentials instead")
                                .font(.subheadline)
                                .foregroundColor(appState.currentTheme.primaryColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            generateAuthRays()
        }
    }
    
    // MARK: - Animations
    
    private func startAuthenticationAnimation() {
        authenticating = true
        
        // Animate rays
        withAnimation {
            rayAnimation.toggle()
        }
        
        // Return to normal after authentication attempt completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            authenticating = false
        }
    }
    
    private func generateAuthRays() {
        // Create rays that will emanate from the center during authentication
        let count = 12
        
        authRays = (0..<count).map { i in
            let angle = (Double(i) / Double(count)) * 360
            
            return AuthRay(
                id: UUID(),
                angle: angle,
                length: CGFloat.random(in: 80...120),
                distance: CGFloat.random(in: 60...90),
                opacity: Double.random(in: 0.3...0.6)
            )
        }
    }
}

// MARK: - Supporting Types

/// Authentication ray animation model
struct AuthRay: Identifiable {
    var id: UUID
    var angle: Double
    var length: CGFloat
    var distance: CGFloat
    var opacity: Double
}