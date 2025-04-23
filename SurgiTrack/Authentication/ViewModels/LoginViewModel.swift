//
//  LoginViewModel.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// LoginViewModel.swift
// SurgiTrack
// Refactored on 03/20/2025

import SwiftUI
import Combine

class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Authentication state
    @Published var authState: AuthenticationState
    
    // Loading state
    @Published var isLoading = false
    
    // Error handling
    @Published var showingError = false
    @Published var errorMessage: String?
    @Published var errorStyle: ErrorMessageView.AlertStyle = .error
    
    // Navigation
    @Published var shouldNavigateToMain = false
    @Published var showingPinCreation = false
    @Published var showingPasswordReset = false
    
    // Animation coordinator
    @Published var animationCoordinator: AnimationCoordinator
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    let authManager: AuthManager
    
    // MARK: - Initialization
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        self.authState = AuthenticationState(authManager: authManager)
        self.animationCoordinator = AnimationCoordinator()
        
        setupSubscriptions()
    }
    
    // MARK: - Authentication Methods
    
    /// Attempt login with current authentication method
    func login() {
        // Reset any existing errors
        clearError()
        
        // Start loading animation
        isLoading = true
        //animationCoordinator.animateLoginButtonPress()
        
        // Short delay for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch self.authState.activeMethod {
            case .credentials:
                self.loginWithCredentials()
            case .pin:
                self.loginWithPin()
            case .biometric:
                self.loginWithBiometrics()
            }
        }
    }
    
    /// Switch to a different authentication method
    func switchMethod(to method: AuthenticationState.AuthMethod) {
        guard authState.availableMethods.contains(method),
              method != authState.activeMethod else {
            return
        }
        
        // If switching to PIN but not set up
        if method == .pin && authManager.getPreferredAuthMethod() != .pin {
            showingPinCreation = true
            return
        }
        
        // Clear any existing errors
        clearError()
        
        // Perform coordinated transition
        animationCoordinator.transitionToNewMethod {
            self.authState.switchMethod(to: method)
            
            // Auto-trigger biometric auth if that's the selected method
            if method == .biometric {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.login()
                }
            }
        }
    }
    
    /// Clear PIN input
    func clearPin() {
        HapticFeedback.buttonPress()
        authState.pin = ""
        authState.pinCircleFills = Array(repeating: 0, count: authState.pinLength)
    }
    
    /// Handle PIN digit entry
    func enterPinDigit(_ digit: Int) {
        guard authState.pin.count < authState.pinLength else { return }
        
        HapticFeedback.pinDigitEntry()
        
        // Add digit to PIN
        authState.pin.append(String(digit))
        
        // Animate PIN circle fill
        authState.animatePinDigitEntry(digit: digit)
        
        // Auto-submit when PIN is complete
        if authState.pin.count == authState.pinLength {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.login()
            }
        }
    }
    
    /// Delete last PIN digit
    func deleteLastPinDigit() {
        guard !authState.pin.isEmpty else { return }
        
        HapticFeedback.buttonPress()
        
        // Animate clearing the last circle
        withAnimation(.easeInOut(duration: 0.2)) {
            authState.pinCircleFills[authState.pin.count - 1] = 0
        }
        
        // Remove last digit
        authState.pin.removeLast()
    }
    
    /// Reset password
    func resetPassword() {
        HapticFeedback.buttonPress()
        showingPasswordReset = true
    }
    
    /// Logout
    func logout() {
        authManager.logout()
        shouldNavigateToMain = false
        
        // Reset animation states
        animationCoordinator.resetAnimations()
        
        // Restart animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.animationCoordinator.startEntryAnimations()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Start entry animations
    func startEntryAnimations() {
        animationCoordinator.startEntryAnimations()
    }
    
    /// Clear error message
    func clearError() {
        withAnimation {
            showingError = false
            errorMessage = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Listen for authentication state changes
        authManager.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.handleSuccessfulAuthentication()
                }
            }
            .store(in: &cancellables)
        
        // Listen for authentication errors
        authManager.$authError
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.displayError(error)
            }
            .store(in: &cancellables)
    }
    
    private func loginWithCredentials() {
        guard !authState.username.isEmpty && !authState.password.isEmpty else {
            isLoading = false
            displayError("Please enter both username and password")
            return
        }
        
        isLoading = true
        authManager.authenticateWithCredentials(
            username: authState.username,
            password: authState.password
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if success {
                    if self?.authState.rememberMe == true {
                        _ = self?.authManager.saveCredentials(
                            username: self?.authState.username ?? "",
                            password: self?.authState.password ?? ""
                        )
                    }
                    self?.shouldNavigateToMain = true
                } else {
                    self?.displayError(error ?? "Login failed. Please try again.")
                }
            }
        }
    }
    
    private func loginWithPin() {
        guard authState.pin.count == authState.pinLength else {
            isLoading = false
            displayError("Please enter a \(authState.pinLength)-digit PIN")
            return
        }
        
        let success = authManager.authenticateWithPIN(authState.pin)
        
        if !success {
            isLoading = false
            authState.animatePinError()
        }
    }
    
    private func loginWithBiometrics() {
        authManager.authenticateWithBiometrics { [weak self] success in
            DispatchQueue.main.async {
                if !success {
                    self?.isLoading = false
                    self?.handleBiometricFailure()
                }
            }
        }
    }
    
    private func handleSuccessfulAuthentication() {
        // Animate success
        animationCoordinator.animateSuccess()
        HapticFeedback.successPattern()
        
        // Show success message briefly
        errorStyle = .success
        errorMessage = "Authentication successful"
        showingError = true
        
        // Navigate to main after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.shouldNavigateToMain = true
            self.isLoading = false
            UserDefaults.standard.set(true, forKey: "isAuthenticated")
        }
    }
    
    private func handleBiometricFailure() {
        // Vibrate device for feedback
        HapticFeedback.errorPattern()
        
        // Fallback to PIN if available
        if authManager.getPreferredAuthMethod() == .pin && authState.availableMethods.contains(.pin) {
            displayError("Biometric authentication failed. Use PIN instead.", style: .warning)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.switchMethod(to: .pin)
            }
        } else {
            // Otherwise fall back to credentials
            displayError("Biometric authentication failed. Use credentials instead.", style: .warning)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.switchMethod(to: .credentials)
            }
        }
    }
    
    private func displayError(_ errorMessage: String, style: ErrorMessageView.AlertStyle = .error) {
        withAnimation {
            self.errorMessage = errorMessage
            self.errorStyle = style
            self.showingError = true
        }
        
        // Animate error effect
        animationCoordinator.animateError()
        
        // Auto-hide error after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation {
                if self.errorMessage == errorMessage {
                    self.showingError = false
                }
            }
        }
    }
}
