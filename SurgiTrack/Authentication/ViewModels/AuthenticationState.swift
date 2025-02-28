//
//  AuthenticationState.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// AuthenticationState.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI
import Combine

/// Manages UI state for the authentication flow
class AuthenticationState: ObservableObject {
    // MARK: - Authentication Method
    
    /// Currently active authentication method
    @Published var activeMethod: AuthMethod = .credentials
    
    /// Available authentication methods based on device capabilities
    @Published var availableMethods: [AuthMethod] = [.credentials]
    
    /// Authentication methods enum
    enum AuthMethod: String, CaseIterable, Identifiable {
        case credentials
        case pin
        case biometric
        
        var id: String { self.rawValue }
        
        var title: String {
            switch self {
            case .credentials: return "Credentials"
            case .pin: return "PIN"
            case .biometric: return "Biometric"
            }
        }
        
        var iconName: String {
            switch self {
            case .credentials: return "person.fill"
            case .pin: return "lock.fill"
            case .biometric: return "faceid" // or touchid
            }
        }
    }
    
    // MARK: - Form Input States
    
    // Credentials
    @Published var username = ""
    @Published var password = ""
    @Published var rememberMe = false
    
    // PIN
    @Published var pin = ""
    @Published var pinCircleFills: [CGFloat] = Array(repeating: 0, count: 6)
    @Published var pinLength = 6
    
    // MARK: - Animation States
    
    // Global animations
    @Published var backgroundRotation = 0.0
    @Published var backgroundOpacity = 0.0
    @Published var contentOpacity = 0.0
    
    // Method-specific animations
    @Published var methodTransitioning = false
    @Published var cardOffset: CGFloat = 20
    @Published var cardOpacity = 0.0
    @Published var headerScale = 0.95
    @Published var showParticles = false
    @Published var particleOpacity = 0.0
    
    // Interactive elements
    @Published var pressedButton: Int? = nil
    @Published var loginButtonScale: CGFloat = 1.0
    
    // Error states
    @Published var errorShakeOffset: CGFloat = 0
    @Published var wrongAttemptAnimation = false
    @Published var displayScale: CGFloat = 1.0
    
    // MARK: - View States
    
    /// Current transition state for view switching
    @Published var transitionState: TransitionState = .idle
    
    /// States for view transitions
    enum TransitionState {
        case idle
        case fadeOut
        case switching
        case fadeIn
        case active
    }
    
    // MARK: - Particle System State
    
    /// Particle system configuration for current authentication method
    @Published var particleStyle: ParticleStyle = .credentials
    
    /// Particle system styles
    enum ParticleStyle {
        case credentials
        case pin
        case biometric
        case transitioning
    }
    
    // MARK: - Lifecycle

    private var cancellables = Set<AnyCancellable>()
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        
        // Initialize available methods
        determineAvailableMethods()
        
        // Set initial method based on user preferences
        initializePreferredMethod()
        
        // Subscribe to auth manager's authentication state
        authManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.handleSuccessfulAuthentication()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to auth manager's error state
        authManager.$authError
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.handleAuthenticationError()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Switch to a different authentication method with coordinated animations
    func switchMethod(to newMethod: AuthMethod) {
        guard availableMethods.contains(newMethod), 
              newMethod != activeMethod,
              transitionState == .idle else {
            return
        }
        
        // Begin transition sequence
        startMethodTransition(to: newMethod)
    }
    
    /// Start animations when view appears
    func startEntryAnimations() {
        // Implement coordinated entry animations
        withAnimation(.easeOut(duration: 0.8)) {
            backgroundOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            cardOpacity = 1.0
            cardOffset = 0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
            headerScale = 1.0
            contentOpacity = 1.0
        }
        
        // Start continuous animations
        withAnimation(
            Animation.linear(duration: 20)
                .repeatForever(autoreverses: false)
        ) {
            backgroundRotation = 360
        }
        
        // Start particles with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.5)) {
                self.showParticles = true
                self.particleOpacity = 1.0
            }
        }
    }
    
    /// Trigger login button press animation
    func animateLoginButtonPress() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            loginButtonScale = 0.98
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.loginButtonScale = 1.0
            }
        }
    }
    
    /// Animate adding a digit to PIN
    func animatePinDigitEntry(digit: Int) {
        // Track pressed button for animation
        pressedButton = digit
        
        let currentIndex = pin.count - 1
        print("DEBUG: Animating PIN fill for digit \(digit) at index \(currentIndex)")
        
        // IMPORTANT: Use DispatchQueue to force separate animation transaction
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                // Only animate the current index
                self.pinCircleFills[currentIndex] = 1.0
            }
        }
        
        // Clear pressed state after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.pressedButton = nil
        }
    }
    
    /// Animate PIN error state
    func animatePinError() {
        wrongAttemptAnimation = true
        
        // Shake animation
        let shakeSequence = [12, -12, 8, -8, 5, -5, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(index)) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                    self.errorShakeOffset = CGFloat(offset)
                }
            }
        }
        
        // Visual feedback
        withAnimation(.easeInOut(duration: 0.3)) {
            for i in 0..<pinCircleFills.count {
                if i < pin.count {
                    pinCircleFills[i] = 1.2
                }
            }
        }
        
        // Reset animation state after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.wrongAttemptAnimation = false
                self.errorShakeOffset = 0
                for i in 0..<self.pinCircleFills.count {
                    self.pinCircleFills[i] = 0
                }
            }
            self.pin = ""  // Clear PIN
        }
    }
    
    // MARK: - Private Methods
    
    private func determineAvailableMethods() {
        // Always have credentials
        availableMethods = [.credentials]
        
        // Check PIN availability
        if authManager.getPreferredAuthMethod() == .pin {
            availableMethods.append(.pin)
        }
        
        // Check biometric availability
        if authManager.biometricsAvailable {
            availableMethods.append(.biometric)
        }
    }
    
    private func initializePreferredMethod() {
        // Set initial method based on user preference
        let preferredMethod = authManager.getPreferredAuthMethod()
        
        if preferredMethod == .biometric, availableMethods.contains(.biometric) {
                activeMethod = .biometric
            } else {
                // Force credentials otherwise
                activeMethod = .credentials
            }
        
        // Set initial particle style
        updateParticleStyle()
    }
    
    private func updateParticleStyle() {
        switch activeMethod {
        case .credentials:
            particleStyle = .credentials
        case .pin:
            particleStyle = .pin
        case .biometric:
            particleStyle = .biometric
        }
    }
    
    private func startMethodTransition(to newMethod: AuthMethod) {
        // Start transition sequence
        transitionState = .fadeOut
        methodTransitioning = true
        
        // 1. Fade out current view
        withAnimation(.easeInOut(duration: 0.3)) {
            cardOpacity = 0.0
            particleOpacity = 0.0
        }
        
        // 2. Switch particle style during transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.particleStyle = .transitioning
        }
        
        // 3. Switch view content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.transitionState = .switching
            self.activeMethod = newMethod
            self.updateParticleStyle()
            
            // 4. Begin fade in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.transitionState = .fadeIn
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.cardOpacity = 1.0
                }
                
                withAnimation(.easeInOut(duration: 0.5).delay(0.1)) {
                    self.particleOpacity = 1.0
                }
                
                // 5. Complete transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.transitionState = .active
                    self.methodTransitioning = false
                    
                    // After short delay, set to idle state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.transitionState = .idle
                    }
                }
            }
        }
    }
    
    private func handleSuccessfulAuthentication() {
        // Animate success
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            displayScale = 1.1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.displayScale = 1.0
            }
        }
    }
    
    private func handleAuthenticationError() {
        // Animate error
        withAnimation(.easeInOut(duration: 0.1)) {
            errorShakeOffset = 10
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.errorShakeOffset = -10
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.errorShakeOffset = 5
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.1)) {
                self.errorShakeOffset = 0
            }
        }
    }
}
