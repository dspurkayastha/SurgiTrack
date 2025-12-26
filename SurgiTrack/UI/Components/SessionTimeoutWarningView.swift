// SessionTimeoutWarningView.swift
// SurgiTrack
// Session timeout warning overlay for HIPAA compliance
// Created on 26/12/2025

import SwiftUI

/// Displays a warning when the user's session is about to expire
struct SessionTimeoutWarningView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            // Warning icon with animation
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
            }

            // Title
            Text("Session Expiring Soon")
                .font(.title2)
                .fontWeight(.bold)

            // Countdown
            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(timeColor)

            // Description
            Text("Your session will expire due to inactivity.\nAny unsaved changes may be lost.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    authManager.extendSession()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Continue Session")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                Button(action: {
                    authManager.logout()
                }) {
                    Text("Logout Now")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)

            // HIPAA notice
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                Text("Session timeout protects patient data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
        .padding(.horizontal, 24)
        .onAppear {
            isAnimating = true
        }
    }

    private var formattedTime: String {
        let minutes = authManager.sessionWarningSeconds / 60
        let seconds = authManager.sessionWarningSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var timeColor: Color {
        if authManager.sessionWarningSeconds <= 60 {
            return .red
        } else if authManager.sessionWarningSeconds <= 120 {
            return .orange
        }
        return .primary
    }
}

/// View modifier to add session timeout warning overlay
struct SessionTimeoutOverlayModifier: ViewModifier {
    @EnvironmentObject private var authManager: AuthManager

    func body(content: Content) -> some View {
        ZStack {
            content

            if authManager.showSessionWarning {
                // Dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // Warning dialog
                SessionTimeoutWarningView()
                    .environmentObject(authManager)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: authManager.showSessionWarning)
    }
}

extension View {
    /// Adds session timeout warning overlay to the view
    func sessionTimeoutWarning() -> some View {
        modifier(SessionTimeoutOverlayModifier())
    }
}

// MARK: - Preview

struct SessionTimeoutWarningView_Previews: PreviewProvider {
    static var previews: some View {
        SessionTimeoutWarningView()
            .environmentObject(AuthManager())
    }
}
