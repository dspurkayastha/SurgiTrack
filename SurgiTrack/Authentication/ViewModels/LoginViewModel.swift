//
//  LoginViewModel.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//  Updated on 26/12/2025 - Compatible with new secure AuthManager

import SwiftUI
import Combine

@MainActor
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

        // Record activity for session timeout
        authManager.recordActivity()

        // Clerk credential login
        if authState.activeMethod == .credentials {
            Task {
                do {
                    try await authManager.authenticateWithCredentials(
                        username: authState.username,
                        password: authState.password
                    )
                    await MainActor.run {
                        handleSuccessfulAuthentication()
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        if let appError = error as? AppError {
                            displayError(appError)
                        } else {
                            displayError("Login failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
            return
        }

        // Short delay for animation
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            switch self.authState.activeMethod {
            case .pin:
                self.loginWithPin()
            case .biometric:
                self.loginWithBiometrics()
            default:
                break
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
        if method == .pin && !authManager.hasPINSet() {
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
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await MainActor.run {
                        self.login()
                    }
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
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                await MainActor.run {
                    self.login()
                }
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
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await MainActor.run {
                self.animationCoordinator.startEntryAnimations()
            }
        }
    }

    @MainActor
    func signUpWithProfile(
        profile: UserProfile,
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        clearError()

        // 1. Basic validation
        guard !email.isEmpty,
              !password.isEmpty,
              profile.isValid else {
            displayError("All fields are required")
            return
        }

        isLoading = true
        Logger.auth("Starting sign up for email: \(email)")

        Task { [weak self] in
            guard let self = self else { return }
            do {
                // 2. Sign up with Clerk
                try await authManager.registerWithCredentials(username: email, password: password)
                Logger.auth("Sign up succeeded for email: \(email)")

                // 3. Save profile (Core Data save)
                if let context = profile.managedObjectContext {
                    try context.save()
                }

                // 4. Update UI
                await MainActor.run {
                    self.isLoading = false
                    completion(.success(()))
                }
            } catch {
                Logger.auth("Sign up failed: \(error)", level: .error)
                await MainActor.run {
                    self.isLoading = false
                    if let appError = error as? AppError {
                        self.displayError(appError)
                    } else {
                        self.displayError("Sign up failed: \(error.localizedDescription)")
                    }
                    completion(.failure(error))
                }
            }
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
        authManager.clearError()
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

        // Listen for authentication errors (now AppError type)
        authManager.$authError
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.displayError(error)
            }
            .store(in: &cancellables)

        // Listen for lockout state
        authManager.$isLockedOut
            .receive(on: RunLoop.main)
            .sink { [weak self] isLockedOut in
                if isLockedOut {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
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
            Task { @MainActor in
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
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                self.shouldNavigateToMain = true
                self.isLoading = false
                UserDefaults.standard.set(true, forKey: "isAuthenticated")
            }
        }
    }

    private func handleBiometricFailure() {
        // Vibrate device for feedback
        HapticFeedback.errorPattern()

        // Fallback to PIN if available
        if authManager.hasPINSet() && authState.availableMethods.contains(.pin) {
            displayError("Biometric authentication failed. Use PIN instead.", style: .warning)

            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                await MainActor.run {
                    self.switchMethod(to: .pin)
                }
            }
        } else {
            // Otherwise fall back to credentials
            displayError("Biometric authentication failed. Use credentials instead.", style: .warning)
        }
    }

    /// Display error from AppError type
    private func displayError(_ error: AppError) {
        displayError(error.localizedDescription, style: .error)
    }

    /// Display error from string
    private func displayError(_ errorMessage: String, style: ErrorMessageView.AlertStyle = .error) {
        withAnimation {
            self.errorMessage = errorMessage
            self.errorStyle = style
            self.showingError = true
        }

        // Animate error effect
        animationCoordinator.animateError()

        // Auto-hide error after delay
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            await MainActor.run {
                withAnimation {
                    if self.errorMessage == errorMessage {
                        self.showingError = false
                    }
                }
            }
        }
    }
}
