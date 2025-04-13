import SwiftUI

struct ModernCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ModernCard {
        VStack {
            Text("Card Content")
                .font(.headline)
            Text("This is a modern card component")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 