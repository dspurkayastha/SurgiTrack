import SwiftUI

struct ModernProgressIndicator: View {
    let progress: Double
    let style: ProgressStyle
    let size: ProgressSize
    let showPercentage: Bool
    
    @Environment(\.themeColors) private var colors
    
    enum ProgressStyle {
        case linear
        case circular
        case circularWithPercentage
    }
    
    enum ProgressSize {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 8
            case .large: return 12
            }
        }
        
        var circleSize: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 80
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .small: return 3
            case .medium: return 5
            case .large: return 7
            }
        }
    }
    
    init(
        progress: Double,
        style: ProgressStyle = .linear,
        size: ProgressSize = .medium,
        showPercentage: Bool = false
    ) {
        self.progress = max(0, min(progress, 1))
        self.style = style
        self.size = size
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        Group {
            switch style {
            case .linear:
                LinearProgressView(progress: progress, size: size, showPercentage: showPercentage)
            case .circular, .circularWithPercentage:
                CircularProgressView(progress: progress, size: size, showPercentage: style == .circularWithPercentage || showPercentage)
            }
        }
    }
    
    private struct LinearProgressView: View {
        let progress: Double
        let size: ProgressSize
        let showPercentage: Bool
        
        @Environment(\.themeColors) private var colors
        
        var body: some View {
            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(colors.primary.opacity(0.2))
                    
                    Rectangle()
                        .fill(colors.primary)
                        .frame(width: progress * size.height, height: size.height)
                }
                .frame(height: size.height)
                .cornerRadius(size.height / 2)
                .overlay(
                    GeometryReader { geometry in
                         Rectangle()
                            .fill(colors.primary)
                            .frame(width: geometry.size.width * CGFloat(progress), height: geometry.size.height)
                            .cornerRadius(geometry.size.height / 2)
                            .animation(.spring(), value: progress)
                    }
                 )
                 
                if showPercentage {
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
        }
    }
    
    private struct CircularProgressView: View {
        let progress: Double
        let size: ProgressSize
        let showPercentage: Bool
        
        @Environment(\.themeColors) private var colors
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(colors.primary.opacity(0.2), lineWidth: size.lineWidth)
                
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(colors.primary, style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)
                
                if showPercentage {
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(size == .large ? .title3 : .caption)
                        .fontWeight(.medium)
                        .foregroundColor(colors.textSecondary)
                }
            }
            .frame(width: size.circleSize, height: size.circleSize)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        Text("Linear")
        ModernProgressIndicator(progress: 0.75, size: .small)
        ModernProgressIndicator(progress: 0.5, size: .medium)
        ModernProgressIndicator(progress: 0.25, size: .large, showPercentage: true)
        
        Text("Circular")
        HStack(spacing: 24) {
            ModernProgressIndicator(progress: 0.75, style: .circular, size: .small)
            ModernProgressIndicator(progress: 0.5, style: .circular, size: .medium)
            ModernProgressIndicator(progress: 0.25, style: .circular, size: .large)
        }
        
        Text("Circular with Percentage")
        HStack(spacing: 24) {
            ModernProgressIndicator(progress: 0.75, style: .circularWithPercentage, size: .small)
            ModernProgressIndicator(progress: 0.5, style: .circularWithPercentage, size: .medium)
            ModernProgressIndicator(progress: 0.25, style: .circularWithPercentage, size: .large)
        }
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 