//
//  ReportsNavigation.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 14/03/25.
//

import SwiftUI

// MARK: - ReportsNavigation Class
class ReportsNavigationState: ObservableObject {
    @Published var showingAnalysisButton: Bool = true {
        didSet {
            print("🔍 NavigationState: showingAnalysisButton changed to \(showingAnalysisButton)")
        }
    }
    
    func ensureButtonVisibility() {
        print("🔍 NavigationState: ensureButtonVisibility called, current value: \(showingAnalysisButton)")
        if !showingAnalysisButton {
            showingAnalysisButton = true
            print("🔍 NavigationState: set showingAnalysisButton to true")
        }
    }
}
