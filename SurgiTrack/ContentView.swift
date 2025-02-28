import SwiftUI

struct ContentView: View {
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isShowingSplash = true
    @State private var loginViewReady = false
    @EnvironmentObject private var appState: AppState
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashView()
                    .onAppear {
                        print("DEBUG: SplashView appeared")
                    }
            } else if !hasCompletedOnboarding {
                OnboardingView()
            } else if !isAuthenticated {
                // Add a stable container with smooth transitions
                ZStack {
                    // Black background to prevent flicker during transition
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                        .opacity(loginViewReady ? 0 : 1)
                        .animation(.easeOut(duration: 0.3), value: loginViewReady)
                        
                    LoginView(authManager: authManager)
                        .environmentObject(authManager)
                        .transition(.identity)
                        .opacity(1) // Ensure view is fully opaque even before animations
                        .onAppear {
                            // First, just mount the view without animations
                            print("DEBUG: LoginView mounted in ContentView")
                                
                            // Delay startup sequence to ensure view is fully in hierarchy
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                loginViewReady = true
                                
                                // Start animations with additional delay after view is stable
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    print("DEBUG: Triggering LoginView animations from ContentView")
                                    // Synchronize these operations
                                    UIApplication.simulateTextFieldInteraction()
                                    
                                    // Use main thread for view model animations
                                    DispatchQueue.main.async {
                                        if let loginViewModel = (authManager as? LoginViewModel) {
                                            loginViewModel.animationCoordinator.forceUIUpdate()
                                            loginViewModel.startEntryAnimations()
                                        } else {
                                            NotificationCenter.default.post(
                                                name: Notification.Name("StartLoginAnimations"),
                                                object: nil
                                            )
                                        }
                                    }
                                }
                            }
                        }
                }
            } else {
                MainPageView()
            }
        }
        .onAppear {
            // FOR TESTING: Uncomment this line to force logout
            UserDefaults.standard.set(false, forKey: "isAuthenticated")
        }
        .onChange(of: authManager.isAuthenticated) { newValue in
            if newValue {
                isAuthenticated = true
            }
        }
        .onReceive(authManager.$isAuthenticated) { authenticated in
            if authenticated {
                isAuthenticated = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SplashAnimationComplete"))) { _ in
            print("DEBUG: SplashAnimationComplete notification received")
            // Use a more direct transition without competing animations
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowingSplash = false
                // Reset login view ready state for next appearance
                loginViewReady = false
            }
        }
    }
}
