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
            Logger.debug("NavigationState: showingAnalysisButton changed to \(showingAnalysisButton)", category: .ui)
        }
    }

    func ensureButtonVisibility() {
        Logger.debug("NavigationState: ensureButtonVisibility called, current value: \(showingAnalysisButton)", category: .ui)
        if !showingAnalysisButton {
            showingAnalysisButton = true
            Logger.debug("NavigationState: set showingAnalysisButton to true", category: .ui)
        }
    }
}
