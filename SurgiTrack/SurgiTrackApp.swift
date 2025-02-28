// SurgiTrackApp.swift
// SurgiTrack
// Created on 06/03/2025

import SwiftUI
import CoreData

@main
struct SurgiTrackApp: App {
    @StateObject private var appState = AppState()
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appState)
                .preferredColorScheme(appState.colorScheme)
                .animation(.default, value: appState.colorScheme)
                .tint(Color("AccentColor"))
        }
    }
}
