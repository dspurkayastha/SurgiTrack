import SwiftUI

struct ModernTabView<Content: View>: View {
    @Binding var selectedIndex: Int
    let tabs: [ModernTabBar.TabItem]
    let content: (Int) -> Content // Closure to provide content for a given index

    @Environment(\.themeColors) private var colors

    init(
        selectedIndex: Binding<Int>,
        tabs: [ModernTabBar.TabItem],
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self._selectedIndex = selectedIndex
        self.tabs = tabs
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            // Display the content for the selected tab
            content(selectedIndex)
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure content fills space

            // Display the tab bar at the bottom
            ModernTabBar(selectedTab: $selectedIndex, items: tabs)
        }
        .background(colors.background.ignoresSafeArea()) // Set background
        .ignoresSafeArea(.keyboard) // Prevent keyboard overlap
    }
}

// MARK: - Preview
#Preview {
    // Example State for Preview
    struct ModernTabViewPreviewWrapper: View {
        @State private var selectedTab = 0
        let sampleTabs: [ModernTabBar.TabItem] = [
            .init(title: "Home", icon: "house", selectedIcon: "house.fill"),
            .init(title: "Patients", icon: "person.2", selectedIcon: "person.2.fill"),
            .init(title: "Calendar", icon: "calendar", selectedIcon: "calendar"), // Use same icon for simplicity
            .init(title: "Settings", icon: "gear", selectedIcon: "gearshape.fill")
        ]

        var body: some View {
            ModernTabView(selectedIndex: $selectedTab, tabs: sampleTabs) { index in
                // Provide different content views based on the index
                switch index {
                case 0:
                    Text("Home Content").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.cyan.opacity(0.2))
                case 1:
                    Text("Patients Content").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.orange.opacity(0.2))
                case 2:
                    Text("Calendar Content").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.green.opacity(0.2))
                case 3:
                    Text("Settings Content").frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.purple.opacity(0.2))
                default:
                    Text("Unknown Content")
                }
            }
            .withThemeBridge(appState: AppState(), colorScheme: .light)
        }
    }

    return ModernTabViewPreviewWrapper()
} 