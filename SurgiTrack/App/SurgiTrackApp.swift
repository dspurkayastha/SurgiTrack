import SwiftUI
import Clerk

@main
struct SurgiTrackApp: App {
    @StateObject private var environment = AppEnvironment.shared
    @Environment(\.colorScheme) private var colorScheme

    init() {
        // Validate configuration on startup
        if !AppConfiguration.validate() {
            Logger.fault("Configuration validation failed", category: .general)
        }

        // Log app startup
        Logger.info("SurgiTrack \(AppConfiguration.App.fullVersion) starting in \(AppConfiguration.environment.rawValue) mode", category: .general)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, environment.persistenceController.container.viewContext)
                .environmentObject(environment)
                .environmentObject(environment.appState)
                .environmentObject(AccessibilityManager.shared)
                .withThemeBridge(appState: environment.appState, colorScheme: colorScheme)
                .applyAccessibility()
                .overlay(
                    Group {
                        if environment.appState.isShowingToast {
                            ModernToast(
                                title: environment.appState.toastTitle,
                                message: environment.appState.toastMessage,
                                type: environment.appState.toastType,
                                duration: AppConfiguration.UI.toastDuration,
                                isPresented: Binding(
                                    get: { environment.appState.isShowingToast },
                                    set: { environment.appState.isShowingToast = $0 }
                                )
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                )
                .task {
                    // Configure Clerk with environment-based key
                    let clerkKey = AppConfiguration.ClerkAPI.publishableKey
                    guard !clerkKey.isEmpty else {
                        Logger.error("Clerk API key not configured", category: .authentication)
                        return
                    }
                    await Clerk.shared.configure(publishableKey: clerkKey)
                    Logger.info("Clerk configured successfully", category: .authentication)
                }
        }
    }
}
