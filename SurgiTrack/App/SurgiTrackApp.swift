import SwiftUI
import Clerk

@main
struct SurgiTrackApp: App {
    @StateObject private var environment = AppEnvironment.shared
    @Environment(\.colorScheme) private var colorScheme
    
    init() {
        Clerk.configure { error in
             if let error = error {
                print("🚨 Clerk configuration failed: \(error)")
             } else {
                print("✅ Clerk configured successfully.")
             }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, environment.persistenceController.container.viewContext)
                .environmentObject(environment)
                .environmentObject(environment.appState)
                .environmentObject(environment.authManager)
                .withThemeBridge(appState: environment.appState, colorScheme: colorScheme)
                .overlay(
                    Group {
                        if environment.appState.isShowingToast {
                            ModernToast(
                                title: environment.appState.toastTitle,
                                message: environment.appState.toastMessage,
                                type: environment.appState.toastType,
                                duration: 3,
                                isPresented: Binding(
                                    get: { environment.appState.isShowingToast },
                                    set: { environment.appState.isShowingToast = $0 }
                                )
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                )
        }
    }
}
