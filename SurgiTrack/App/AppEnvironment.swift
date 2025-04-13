//
//  AppEnvironment.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 13/04/25.
//


import SwiftUI
import CoreData

class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()
    
    let persistenceController: PersistenceController
    @Published var appState: AppState
    
    private init() {
        self.persistenceController = PersistenceController.shared
        self.appState = AppState()
    }
}

struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.shared
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}