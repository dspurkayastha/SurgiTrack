//
//  PinLoginView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// PinLoginView.swift
// SurgiTrack
// Refactored on 03/20/2025

import SwiftUI

struct PinLoginView: View {
    // MARK: - Bindings
    @Binding var pin: String
    @Binding var pinCircleFills: [CGFloat]
    @Binding var pressedButton: Int?
    
    // MARK: - Properties
    var onDigitTapped: (Int) -> Void
    var onDeleteTapped: () -> Void
    var onClearTapped: () -> Void
    var onLogin: () -> Void
    
    // MARK: - Environment
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 25) {
            // MARK: - Header
            AuthHeaderView(
                style: .pin,
                title: "Enter PIN",
                subtitle: "Enter your 6-digit PIN to access your account",
                iconName: "lock.fill",
                animationProgress: 1.0,
                animating: true
            )
            
            // MARK: - PIN Content
            GlassmorphicCard {
                VStack(spacing: 25) {
                    // PIN circles
                    PinCircleView(
                        pinLength: 6,
                        filledCount: pin.count,
                        fillProgress: pinCircleFills
                    )
                    .padding(.vertical, 10)
                    
                    // Numpad
                    NumpadView(
                        onDigitTapped: onDigitTapped,
                        onDeleteTapped: onDeleteTapped,
                        alternativeButtonAction: nil,
                        alternativeButtonIcon: nil,
                        pressedButton: pressedButton
                    )
                    .padding(.top, 10)
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: onClearTapped) {
                            Text("Clear")
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .withHapticFeedback()
                        
                        Button(action: onLogin) {
                            Text("Login")
                                .fontWeight(.semibold)
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
                        .disabled(pin.count < 6)
                        .opacity(pin.count < 6 ? 0.7 : 1)
                    }
                    
                    // PIN management options
                    Button(action: {
                        HapticFeedback.buttonPress()
                        // Would implement PIN reset flow
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle")
                                .font(.caption)
                            Text("Forgot PIN?")
                                .font(.caption)
                        }
                        .foregroundColor(appState.currentTheme.primaryColor.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 10)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}