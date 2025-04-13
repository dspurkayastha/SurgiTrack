import SwiftUI

struct ModernBadge: View {
    let text: String
    let style: BadgeStyle
    let size: BadgeSize
    
    @Environment(\.themeColors) private var colors
    
    enum BadgeStyle {
        case primary
        case secondary
        case success
        case warning
        case error
        case info
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return .gray
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .success, .warning, .error, .info:
                return .white
            }
        }
    }
    
    enum BadgeSize {
        case small
        case medium
        case large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 14
            case .large: return 16
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
    
    init(
        text: String,
        style: BadgeStyle = .primary,
        size: BadgeSize = .medium
    ) {
        self.text = text
        self.style = style
        self.size = size
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: size.fontSize, weight: .medium))
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, size.padding)
            .padding(.vertical, size.padding / 2)
            .background(
                Capsule()
                    .fill(style.backgroundColor)
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            ModernBadge(text: "New", style: .primary)
            ModernBadge(text: "Completed", style: .success)
            ModernBadge(text: "Pending", style: .warning)
            ModernBadge(text: "Error", style: .error)
        }
        
        HStack(spacing: 8) {
            ModernBadge(text: "Small", size: .small)
            ModernBadge(text: "Medium", size: .medium)
            ModernBadge(text: "Large", size: .large)
        }
        
        HStack(spacing: 8) {
            ModernBadge(text: "Info", style: .info)
            ModernBadge(text: "Secondary", style: .secondary)
        }
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 