import SwiftUI

struct ModernEmptyState: View {
    let title: String
    let message: String
    let icon: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    @Environment(\.themeColors) private var colors
    @State private var isAnimating = false
    
    init(
        title: String,
        message: String,
        icon: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(colors.primary)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.5)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
            
            if let action = action, let actionTitle = actionTitle {
                ModernButton(
                    actionTitle,
                    style: .primary,
                    action: action
                )
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            }
        }
        .padding(24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    VStack {
        ModernEmptyState(
            title: "No Results Found",
            message: "Try adjusting your search or filter criteria.",
            icon: "doc.text.magnifyingglass",
            action: {},
            actionTitle: "Clear Filters"
        )
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 