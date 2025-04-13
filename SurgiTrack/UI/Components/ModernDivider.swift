import SwiftUI

struct ModernDivider: View {
    let style: DividerStyle
    let color: Color?
    
    @Environment(\.themeColors) private var colors
    
    enum DividerStyle {
        case solid
        case dashed
        case dotted
        case gradient
        
        var dashPattern: [CGFloat] {
            switch self {
            case .solid: return []
            case .dashed: return [6, 3]
            case .dotted: return [1, 3]
            case .gradient: return []
            }
        }
    }
    
    init(style: DividerStyle = .solid, color: Color? = nil) {
        self.style = style
        self.color = color
    }
    
    var body: some View {
        Group {
            switch style {
            case .gradient:
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colors.border.opacity(0),
                                colors.border,
                                colors.border.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            default:
                Rectangle()
                    .fill(color ?? colors.border)
                    .frame(height: 1)
                    .overlay(
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: style.dashPattern))
                            .foregroundColor(color ?? colors.border)
                    )
            }
        }
    }
}

struct VerticalDivider: View {
    let style: ModernDivider.DividerStyle
    let color: Color?
    
    @Environment(\.themeColors) private var colors
    
    init(style: ModernDivider.DividerStyle = .solid, color: Color? = nil) {
        self.style = style
        self.color = color
    }
    
    var body: some View {
        Group {
            switch style {
            case .gradient:
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                colors.border.opacity(0),
                                colors.border,
                                colors.border.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
            default:
                Rectangle()
                    .fill(color ?? colors.border)
                    .frame(width: 1)
                    .overlay(
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: style.dashPattern))
                            .foregroundColor(color ?? colors.border)
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        VStack(spacing: 16) {
            Text("Solid Divider")
            ModernDivider()
            Text("Dashed Divider")
            ModernDivider(style: .dashed)
            Text("Dotted Divider")
            ModernDivider(style: .dotted)
            Text("Gradient Divider")
            ModernDivider(style: .gradient)
        }
        
        HStack(spacing: 16) {
            Text("Left")
            VerticalDivider()
            Text("Right")
        }
        
        HStack(spacing: 16) {
            Text("Left")
            VerticalDivider(style: .dashed)
            Text("Right")
        }
        
        HStack(spacing: 16) {
            Text("Left")
            VerticalDivider(style: .gradient)
            Text("Right")
        }
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 
