import SwiftUI

struct GlassmorphicModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.1
    var blurRadius: CGFloat = 10
    
    @Environment(\.themeColors) private var colors
    
    func body(content: Content) -> some View {
        content
            .background(
                colors.glassBackground
                    .opacity(opacity)
            )
            .background(
                .ultraThinMaterial
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(colors.glassBorder, lineWidth: 1)
            )
            .shadow(
                color: colors.shadow.opacity(0.1),
                radius: blurRadius,
                x: 0,
                y: 5
            )
    }
}

// MARK: - View Extension
extension View {
    func glassmorphic(
        cornerRadius: CGFloat = 20,
        opacity: Double = 0.1,
        blurRadius: CGFloat = 10
    ) -> some View {
        modifier(GlassmorphicModifier(
            cornerRadius: cornerRadius,
            opacity: opacity,
            blurRadius: blurRadius
        ))
    }
} 