import SwiftUI

struct ModernNavigationView<Content: View>: View {
    let content: Content
    
    @Environment(\.themeColors) private var colors
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    ModernNavigationView {
        VStack {
            ModernNavigationBar(
                title: "Sample Title",
                subtitle: "Sample Subtitle",
                showBackButton: true,
                trailing: { Text("Edit") }
            )
            Spacer()
            Text("Main Content Area")
            Spacer()
        }
        .withThemeBridge(appState: AppState(), colorScheme: .light)
    }
} 