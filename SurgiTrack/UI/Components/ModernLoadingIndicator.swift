import SwiftUI

struct ModernLoadingIndicator: View {
    let style: LoadingStyle
    let size: LoadingSize
    
    @Environment(\.themeColors) private var colors
    
    enum LoadingStyle {
        case circular
        case dots
        case pulse
    }
    
    enum LoadingSize {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 48
            }
        }
    }
    
    init(style: LoadingStyle = .circular, size: LoadingSize = .small) {
        self.style = style
        self.size = size
    }
    
    var body: some View {
        Group {
            switch style {
            case .circular:
                CircularLoadingIndicator(size: size)
            case .dots:
                DotsLoadingIndicator(size: size)
            case .pulse:
                PulseLoadingIndicator(size: size)
            }
        }
    }
    
    private struct CircularLoadingIndicator: View {
        let size: LoadingSize
        @Environment(\.themeColors) private var colors
        @State private var isAnimating = false
        
        var body: some View {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(LinearGradient(colors: [colors.primary, colors.primary.opacity(0.5)], startPoint: .top, endPoint: .bottom), 
                        style: StrokeStyle(lineWidth: size == .large ? 4 : (size == .medium ? 3 : 2), lineCap: .round))
                .frame(width: size.dimension, height: size.dimension)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
        }
    }
    
    private struct DotsLoadingIndicator: View {
        let size: LoadingSize
        @Environment(\.themeColors) private var colors
        @State private var scale: CGFloat = 0.5
        let dotCount = 3
        let animationDelay = 0.1

        var body: some View {
            HStack(spacing: size.dimension / 4) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(colors.primary)
                        .frame(width: size.dimension / 3, height: size.dimension / 3)
                        .scaleEffect(scale)
                        .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(index) * animationDelay), value: scale)
                }
            }
            .onAppear {
                scale = 1.0
            }
        }
    }
    
    private struct PulseLoadingIndicator: View {
        let size: LoadingSize
        @Environment(\.themeColors) private var colors
        @State private var scale: CGFloat = 0.8

        var body: some View {
            Circle()
                .fill(colors.primary)
                .frame(width: size.dimension, height: size.dimension)
                .scaleEffect(scale)
                .opacity(Double(2.0) - (Double(scale) * 1.5))
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                        scale = 1.2
                    }
                }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        Text("Circular")
        HStack(spacing: 20) {
            ModernLoadingIndicator(style: .circular, size: .small)
            ModernLoadingIndicator(style: .circular, size: .medium)
            ModernLoadingIndicator(style: .circular, size: .large)
        }
        
        Text("Dots")
        HStack(spacing: 20) {
            ModernLoadingIndicator(style: .dots, size: .small)
            ModernLoadingIndicator(style: .dots, size: .medium)
            ModernLoadingIndicator(style: .dots, size: .large)
        }
        
        Text("Pulse")
        HStack(spacing: 20) {
            ModernLoadingIndicator(style: .pulse, size: .small)
            ModernLoadingIndicator(style: .pulse, size: .medium)
            ModernLoadingIndicator(style: .pulse, size: .large)
        }
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 