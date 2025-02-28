//
//  PinCreationView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// PinCreationView.swift
// SurgiTrack
// Refactored on 03/20/2025

import SwiftUI

struct PinCreationView: View {
    // MARK: - View Model and State
    @StateObject private var viewModel: PinCreationViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    // Initialize
    init(authManager: AuthManager) {
        self._viewModel = StateObject(wrappedValue: PinCreationViewModel(authManager: authManager))
    }

    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: - Background Layer
                BackgroundView(
                    style: .pin,
                    animationProgress: viewModel.animationCoordinator.backgroundOpacity,
                    rotationDegrees: viewModel.animationCoordinator.backgroundRotation
                )
                
                // MARK: - Particle Layer
                ParticleSystemView(
                    style: .pin,
                    showParticles: viewModel.animationCoordinator.showParticles,
                    opacity: viewModel.animationCoordinator.particleOpacity
                )
                
                // MARK: - Main Content
                ScrollView {
                    VStack(spacing: 25) {
                        // MARK: - Header
                        headerSection
                        
                        // MARK: - PIN Display
                        pinDisplaySection
                            .rotation3DEffect(
                                .degrees(viewModel.stepChangeAnimation ? 180 : 0),
                                axis: (x: 0, y: 1, z: 0),
                                anchor: .center,
                                anchorZ: 0.0,
                                perspective: 0.5
                            )
                        
                        // MARK: - PIN Strength (only in first step)
                        if viewModel.currentStep == .enterPin {
                            pinStrengthSection
                        }
                        
                        // MARK: - Numpad and Actions
                        GlassmorphicCard {
                            VStack(spacing: 20) {
                                // Numpad
                                NumpadView(
                                    onDigitTapped: { viewModel.addDigit(String($0)) },
                                    onDeleteTapped: { viewModel.deleteLastDigit() },
                                    pressedButton: viewModel.pressedButton
                                )
                                
                                // Action buttons
                                HStack(spacing: 15) {
                                    Button(action: { viewModel.clearPin() }) {
                                        Text("Clear")
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                    .withHapticFeedback()
                                    
                                    Button(action: { viewModel.handleContinue() }) {
                                        Text(viewModel.currentStep == .enterPin ? "Continue" : "Create PIN")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
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
                                    .disabled(viewModel.getCurrentInputLength() < viewModel.pinLength)
                                    .opacity(viewModel.getCurrentInputLength() < viewModel.pinLength ? 0.7 : 1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(appState.currentTheme.primaryColor)
                }
            )
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if viewModel.isSuccess {
                            // Dismiss and return to PIN login after success
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                )
            }
            .onAppear {
                viewModel.startEntryAnimations()
            }
        }
    }
    
    // MARK: - Component Views
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            // Step indicator
            StepIndicator(currentStep: viewModel.currentStep == .enterPin ? 1 : 2, totalSteps: 2)
                .padding(.top, 8)
            
            AuthHeaderView(
                style: .pin,
                title: viewModel.currentStep == .enterPin ? "Create PIN" : "Confirm PIN",
                subtitle: viewModel.currentStep == .enterPin ?
                    "Create a secure \(viewModel.pinLength)-digit PIN for quick access" :
                    "Enter your PIN again to confirm",
                iconName: "lock.shield",
                animationProgress: 1.0,
                animating: true
            )
        }
    }
    
    private var pinDisplaySection: some View {
        PinCircleView(
            pinLength: viewModel.pinLength,
            filledCount: viewModel.getCurrentInputLength(),
            fillProgress: viewModel.pinCircleFills,
            isError: viewModel.wrongPinAttempt
        )
        .scaleEffect(viewModel.pinDisplayScale)
        .offset(x: viewModel.animationCoordinator.errorShakeOffset)
        .padding(.vertical, 10)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.7))
                .background(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    viewModel.wrongPinAttempt ?
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red.opacity(0.5), Color.red.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [
                            appState.currentTheme.primaryColor.opacity(0.3),
                            appState.currentTheme.secondaryColor.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private var pinStrengthSection: some View {
        VStack(alignment: .center, spacing: 8) {
            // Strength text and progress bar
            HStack(spacing: 15) {
                Text("PIN Strength")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(viewModel.pinStrengthText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.pinStrengthColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(viewModel.pinStrengthColor.opacity(0.1))
                    )
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                // Progress fill
                if !viewModel.pin.isEmpty {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    viewModel.pinStrengthColor.opacity(0.8),
                                    viewModel.pinStrengthColor
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(viewModel.pinStrengthRingProgress * UIScreen.main.bounds.width * 0.7, UIScreen.main.bounds.width * 0.7), height: 8)
                }
            }
            
            // Feedback criteria with icons
            VStack(spacing: 10) {
                ForEach(viewModel.pinFeedback, id: \.self) { feedback in
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.hasPinIssue(feedback) ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.hasPinIssue(feedback) ? .red : .green)
                        
                        Text(feedback)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.7))
                .background(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.pinStrengthColor.opacity(0.3), lineWidth: 1)
        )
        .opacity(viewModel.pin.isEmpty ? 0.3 : 1.0)
    }
}

// MARK: - Step Indicator
struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 5)
            }
        }
        .padding(8)
    }
}
