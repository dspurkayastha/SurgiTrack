import SwiftUI

struct InteractiveCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    let isSelected: Bool
    
    @Environment(\.themeColors) private var colors
    @State private var isPressed: Bool = false
    
    init(
        isSelected: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .padding()
                .frame(maxWidth: .infinity)
                .background(isSelected ? colors.primary.opacity(0.1) : colors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? colors.primary : colors.border, lineWidth: isSelected ? 2 : 1)
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .shadow(color: isSelected ? colors.primary.opacity(0.1) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .pressAction(onPress: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
        }, onRelease: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        })
    }
}

// Helper for press action
struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        onPress()
                    })
                    .onEnded({ _ in
                        onRelease()
                    })
            )
    }
}

extension View {
    func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: { onPress() }, onRelease: { onRelease() }))
    }
}

// MARK: - Preview
struct InteractiveCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.colors.background
                .ignoresSafeArea()
            
            InteractiveCard(action: {}) {
                VStack(alignment: .leading, spacing: Theme.spacing.sm) {
                    Text("Interactive Card")
                        .font(Theme.typography.h3)
                        .foregroundColor(Theme.colors.text)
                    
                    Text("This is a modern interactive card with glassmorphic effect and spring animations.")
                        .font(Theme.typography.bodyMedium)
                        .foregroundColor(Theme.colors.textSecondary)
                }
            }
            .padding()
        }
    }
} 