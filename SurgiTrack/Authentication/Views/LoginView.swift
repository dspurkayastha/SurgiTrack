import SwiftUI

// Modified LoginView to ensure all content is visible
struct LoginView: View {
    // MARK: - View Model and State
    @StateObject private var viewModel: LoginViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    // Simplified state management - controlled by ContentView
    @State private var contentOpacity: Double = 1.0
    @State private var animationsInitiated: Bool = false
    
    // Initialize with dependencies
    init(authManager: AuthManager) {
        self._viewModel = StateObject(wrappedValue: LoginViewModel(authManager: authManager))
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            ZStack {
                // Background and particle layers remain the same
                BackgroundView(
                    style: backgroundStyle,
                    animationProgress: viewModel.animationCoordinator.backgroundOpacity,
                    rotationDegrees: viewModel.animationCoordinator.backgroundRotation
                )
                
                ParticleSystemView(
                    style: particleStyle,
                    showParticles: viewModel.animationCoordinator.showParticles,
                    opacity: viewModel.animationCoordinator.particleOpacity
                )
                
                // Main content with explicit opacity animation
                VStack(spacing: 20) {
                    // MARK: - Method Picker
                    LoginMethodPicker(
                        selectedMethod: $viewModel.authState.activeMethod,
                        availableMethods: viewModel.authState.availableMethods,
                        onMethodChange: { method in
                            viewModel.switchMethod(to: method)
                        }
                    )
                    .padding(.top, 60)
                    
                    // MARK: - Authentication Content
                    // Use an explicit ZStack to ensure proper rendering
                    ZStack {
                        // Only show one at a time to prevent rendering conflicts
                        if viewModel.authState.activeMethod == .credentials {
                            CredentialsLoginView(
                                username: $viewModel.authState.username,
                                password: $viewModel.authState.password,
                                rememberMe: $viewModel.authState.rememberMe,
                                onLogin: { viewModel.login() },
                                viewModel: viewModel
                            )
                            .transition(.opacity)
                            .zIndex(1)
                        } else if viewModel.authState.activeMethod == .pin {
                            pinView
                                .transition(.opacity)
                                .zIndex(1)
                        } else if viewModel.authState.activeMethod == .biometric {
                            biometricView
                                .transition(.opacity)
                                .zIndex(1)
                        }
                    }
                    .animation(.easeInOut, value: viewModel.authState.activeMethod)
                    
                    // MARK: - Error Message
                    ErrorMessageView(
                        message: viewModel.errorMessage,
                        isShowing: viewModel.showingError,
                        style: viewModel.errorStyle,
                        shakeOffset: viewModel.animationCoordinator.errorShakeOffset,
                        onDismiss: {
                            viewModel.clearError()
                        }
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // MARK: - App Info
                    appInfoView
                }
                .padding(.horizontal, 20)
                .frame(minHeight: size.height)
                .opacity(contentOpacity)
                
                // MARK: - Loading Overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .onAppear {
                print("DEBUG: LoginView appeared - waiting for animation signal")
                
                // Listen for animation notification from ContentView
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("StartLoginAnimations"),
                    object: nil,
                    queue: .main
                ) { _ in
                    if !animationsInitiated {
                        animationsInitiated = true
                        startAnimationsWithFallback()
                    }
                }
            }
        }
    }
    
    // MARK: - Animation Control
    
    private func startAnimationsWithFallback() {
        print("DEBUG: Starting LoginView animations via notification")
        
        // Ensure UI is ready for animation
        viewModel.animationCoordinator.forceUIUpdate()
        
        // Give a moment for UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Start animations
            viewModel.startEntryAnimations()
            
            // Second simulation after animations start to ensure updates propagate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIApplication.simulateTextFieldInteraction(retryCount: 1)
                
                // Verify animation state and force if needed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if viewModel.animationCoordinator.backgroundOpacity < 0.5 {
                        print("DEBUG: Background opacity still low, forcing update")
                        viewModel.animationCoordinator.forceUIUpdate()
                        viewModel.animationCoordinator.backgroundOpacity = 1.0
                        viewModel.animationCoordinator.particleOpacity = 1.0
                        
                        // Final simulation attempt
                        UIApplication.simulateTextFieldInteraction(retryCount: 2)
                    }
                }
            }
        }
    }

    // Rest of your code remains the same...
    private var backgroundStyle: BackgroundView.Style {
        switch viewModel.authState.activeMethod {
        case .credentials:
            return .credentials
        case .pin:
            return .pin
        case .biometric:
            return .biometric
        }
    }
    
    private var particleStyle: ParticleSystemView.Style {
        switch viewModel.authState.activeMethod {
        case .credentials:
            return .credentials
        case .pin:
            return .pin
        case .biometric:
            return .biometric
        }
    }
    
    // Your view components remain the same
    private var credentialsView: some View {
        CredentialsLoginView(
            username: $viewModel.authState.username,
            password: $viewModel.authState.password,
            rememberMe: $viewModel.authState.rememberMe,
            onLogin: viewModel.login,
            viewModel: viewModel
        )
    }
    
    private var pinView: some View {
        PinLoginView(
            pin: $viewModel.authState.pin,
            pinCircleFills: $viewModel.authState.pinCircleFills,
            pressedButton: $viewModel.authState.pressedButton,
            onDigitTapped: viewModel.enterPinDigit,
            onDeleteTapped: viewModel.deleteLastPinDigit,
            onClearTapped: viewModel.clearPin,
            onLogin: viewModel.login
        )
    }
    
    private var biometricView: some View {
        BiometricLoginView(
            biometricType: viewModel.authManager.biometricType == .faceID ? .faceID : .touchID,
            onAuthenticate: viewModel.login
        )
    }
    
    private var appInfoView: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.currentTheme.primaryColor)
                .frame(width: 8, height: 8)
            
            Text("SurgiTrack")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("•")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
                .transition(.opacity)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground).opacity(0.85))
                .frame(width: 100, height: 100)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Authenticating")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .transition(.opacity)
    }
}
