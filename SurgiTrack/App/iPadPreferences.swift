import SwiftUI

/// iPad-specific user preferences
class iPadPreferences: ObservableObject {
    static let shared = iPadPreferences()

    // Column visibility preference
    @AppStorage("iPad.columnVisibility") private var columnVisibilityRaw: String = "all"

    var columnVisibility: NavigationSplitViewVisibility {
        get {
            switch columnVisibilityRaw {
            case "all":
                return .all
            case "doubleColumn":
                return .doubleColumn
            case "detailOnly":
                return .detailOnly
            default:
                return .all
            }
        }
        set {
            switch newValue {
            case .all:
                columnVisibilityRaw = "all"
            case .doubleColumn:
                columnVisibilityRaw = "doubleColumn"
            case .detailOnly:
                columnVisibilityRaw = "detailOnly"
            default:
                columnVisibilityRaw = "all"
            }
        }
    }

    // Preferred sidebar width
    @AppStorage("iPad.sidebarWidth") var preferredSidebarWidth: Double = 320

    // Preferred content width
    @AppStorage("iPad.contentWidth") var preferredContentWidth: Double = 400

    // Auto-hide sidebar in landscape
    @AppStorage("iPad.autoHideSidebar") var autoHideSidebarInLandscape: Bool = false

    // Remember last selected section
    @AppStorage("iPad.lastSection") var lastSelectedSection: String = "dashboard"

    // Show section icons in toolbar
    @AppStorage("iPad.showSectionIcons") var showSectionIconsInToolbar: Bool = true

    // Compact sidebar mode
    @AppStorage("iPad.compactSidebar") var useCompactSidebar: Bool = false

    // Quick actions in toolbar
    @AppStorage("iPad.quickActionsToolbar") var showQuickActionsInToolbar: Bool = true

    private init() {
        Logger.info("iPadPreferences initialized", category: .ui)
    }

    /// Reset all preferences to defaults
    func resetToDefaults() {
        columnVisibilityRaw = "all"
        preferredSidebarWidth = 320
        preferredContentWidth = 400
        autoHideSidebarInLandscape = false
        lastSelectedSection = "dashboard"
        showSectionIconsInToolbar = true
        useCompactSidebar = false
        showQuickActionsInToolbar = true

        Logger.info("iPad preferences reset to defaults", category: .ui)
    }

    /// Get NavigationSection from stored preference
    func getLastSection() -> NavigationSection? {
        NavigationSection(rawValue: lastSelectedSection)
    }

    /// Save current section
    func saveSection(_ section: NavigationSection?) {
        if let section = section {
            lastSelectedSection = section.rawValue
        }
    }
}

/// iPad-specific settings view
struct iPadSettingsView: View {
    @ObservedObject var preferences = iPadPreferences.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Form {
            Section {
                Toggle("Auto-hide Sidebar in Landscape", isOn: $preferences.autoHideSidebarInLandscape)
                Toggle("Use Compact Sidebar", isOn: $preferences.useCompactSidebar)
            } header: {
                Text("Layout")
            } footer: {
                Text("Customize how the iPad interface appears")
            }

            Section {
                Toggle("Show Section Icons in Toolbar", isOn: $preferences.showSectionIconsInToolbar)
                Toggle("Show Quick Actions in Toolbar", isOn: $preferences.showQuickActionsInToolbar)
            } header: {
                Text("Toolbar")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sidebar Width: \(Int(preferences.preferredSidebarWidth))pt")
                        .font(.subheadline)
                    Slider(value: $preferences.preferredSidebarWidth, in: 280...400, step: 10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Content Width: \(Int(preferences.preferredContentWidth))pt")
                        .font(.subheadline)
                    Slider(value: $preferences.preferredContentWidth, in: 350...500, step: 10)
                }
            } header: {
                Text("Column Widths")
            } footer: {
                Text("Adjust the preferred width for sidebar and content columns")
            }

            Section {
                Button("Reset to Defaults") {
                    preferences.resetToDefaults()
                    Haptics.shared.notify(.success)
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("iPad Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        iPadSettingsView()
    }
}
