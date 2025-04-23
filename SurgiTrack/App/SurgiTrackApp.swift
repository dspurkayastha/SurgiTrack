import SwiftUI
import Clerk

@main
struct SurgiTrackApp: App {
    @StateObject private var environment = AppEnvironment.shared
    @Environment(\.colorScheme) private var colorScheme
    
    init() {
        Clerk.shared.configure(publishableKey: "pk_test_Y3VyaW91cy1jYXR0bGUtOTUuY2xlcmsuYWNjb3VudHMuZGV2JA")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, environment.persistenceController.container.viewContext)
                .environmentObject(environment)
                .environmentObject(environment.appState)
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
