import SwiftUI

// MARK: - Enums

/// Defines the size variations for the Floating Action Button.
enum FABSize {
    case small, medium, large

    var dimension: CGFloat {
        switch self {
        case .small: return 44
        case .medium: return 56
        case .large: return 68
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 18
        case .medium: return 24
        case .large: return 30
        }
    }
}

/// Defines the style variations for the Floating Action Button, affecting its color.
enum FABStyle {
    case primary, secondary, destructive

    // Updated function to accept ThemeColors
    func backgroundColor(themeColors: ThemeColors) -> Color {
        switch self {
        case .primary: return themeColors.accent // Use accent color for primary FAB
        case .secondary: return themeColors.secondary
        case .destructive: return themeColors.error // Use error color for destructive
        }
    }

    // Updated function to accept ThemeColors
    func foregroundColor(themeColors: ThemeColors) -> Color {
        switch self {
        case .primary, .destructive: return .white // Keep white for contrast
        case .secondary: return themeColors.text // Use standard text color
        }
    }
}

// MARK: - ModernFloatingActionButton Component

/// A reusable Floating Action Button (FAB) component with customizable style, size, and action.
struct ModernFloatingActionButton: View {
    // Use themeColors from the environment
    @Environment(\.themeColors) var themeColors

    let icon: String
    let action: () -> Void
    var size: FABSize = .medium
    var style: FABStyle = .primary
    var animation: Animation? = .spring(response: 0.4, dampingFraction: 0.6) // Default subtle spring

    @State private var isPressed: Bool = false // For press animation

    var body: some View {
        // Use themeColors directly
        let backgroundColor = style.backgroundColor(themeColors: themeColors)
        let foregroundColor = style.foregroundColor(themeColors: themeColors)
        let dimension = size.dimension
        let iconSize = size.iconSize

        Button(action: {
            // Haptic feedback on tap
            Haptics.shared.play(.soft)
            action()
        }) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(foregroundColor)
                .padding() // Padding inside the circle
        }
        .frame(width: dimension, height: dimension)
        .background(backgroundColor)
        .clipShape(Circle())
        // Use themeColors.shadow
        .shadow(color: themeColors.shadow.opacity(0.3), radius: 8, x: 0, y: 4) // Floating effect
        .shadow(color: backgroundColor.opacity(0.4), radius: isPressed ? 4 : 12, x: 0, y: isPressed ? 2 : 6) // Interactive shadow
        .scaleEffect(isPressed ? 0.95 : 1.0) // Scale effect on press
        .animation(animation, value: isPressed) // Apply animation to press effect
        .pressAction { 
            withAnimation(animation) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(animation) {
                isPressed = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    // Use a container view to set up the environment correctly
    struct PreviewWrapper: View {
        @StateObject var appState = AppState() // Still need AppState for the bridge
        @Environment(\.colorScheme) var colorScheme // Detect dark/light mode

        var body: some View {
            // Access themeColors AFTER applying the bridge
            @Environment(\.themeColors) var themeColors

             ZStack(alignment: .bottomTrailing) {
                // Use themeColors from the environment
                themeColors.background.ignoresSafeArea()

                VStack(spacing: 20) {
                     Text("Floating Action Buttons")
                        .font(.largeTitle)
                        // Use themeColors from the environment
                        .foregroundColor(themeColors.text)

                     Spacer() // Push FABs down

                     HStack(spacing: 20) {
                         ModernFloatingActionButton(icon: "plus", action: { print("Small Primary Tapped") }, size: .small, style: .primary)
                         ModernFloatingActionButton(icon: "pencil", action: { print("Medium Secondary Tapped") }, size: .medium, style: .secondary)
                         ModernFloatingActionButton(icon: "trash", action: { print("Large Destructive Tapped") }, size: .large, style: .destructive)
                     }
                     .padding()
                  }
                  .padding() // Padding for the VStack content
             }
             // Apply the theme bridge to inject themeColors into the environment
             .withThemeBridge(appState: appState, colorScheme: colorScheme)
             // Pass AppState down if needed by other bridged components (FAB doesn't need it directly anymore)
             .environmentObject(appState)
        }
    }

    return PreviewWrapper()
}

// MARK: - Helper for Press Events (Removed - Defined in InteractiveCard.swift)
// struct PressActions: ViewModifier { ... }
// extension View { func pressEvents(...) -> some View { ... } }

// Assume Haptics Utility exists (replace with your implementation if different)
// Example Haptics Utility
class Haptics {
    static let shared = Haptics()
    private init() {}

    func play(_ feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: feedbackStyle).impactOccurred()
    }

    func notify(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(feedbackType)
    }
} 
