import SwiftUI

struct ModernButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    let style: ButtonStyle
    let size: ButtonSize
    let isEnabled: Bool
    let isLoading: Bool
    
    @Environment(\.themeColors) private var colors
    
    init(
        action: @escaping () -> Void,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.label = label()
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                }
                
                label
                    .font(size.font)
                    .foregroundColor(style.foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(style.backgroundColor)
            .cornerRadius(size.cornerRadius)
            .opacity(isEnabled ? 1 : 0.5)
        }
        .disabled(!isEnabled || isLoading)
    }
}

extension ModernButton {
    enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return .accentColor
            case .secondary:
                return .secondary.opacity(0.1)
            case .tertiary:
                return .clear
            case .destructive:
                return .red
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary:
                return .accentColor
            case .tertiary:
                return .accentColor
            case .destructive:
                return .white
            }
        }
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small:
                return 32
            case .medium:
                return 44
            case .large:
                return 56
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small:
                return 8
            case .medium:
                return 12
            case .large:
                return 16
            }
        }
        
        var font: Font {
            switch self {
            case .small:
                return .subheadline
            case .medium:
                return .body
            case .large:
                return .title3
            }
        }
    }
}

extension ModernButton where Label == Text {
    init(
        _ title: String,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(
            action: action,
            style: style,
            size: size,
            isEnabled: isEnabled,
            isLoading: isLoading
        ) {
            Text(title)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ModernButton("Primary Button") {}
        
        ModernButton("Secondary Button", style: .secondary) {}
        
        ModernButton("Tertiary Button", style: .tertiary) {}
        
        ModernButton("Destructive Button", style: .destructive) {}
        
        ModernButton("Loading Button", isLoading: true) {}
        
        ModernButton("Disabled Button", isEnabled: false) {}
        
        ModernButton("Small Button", size: .small) {}
        
        ModernButton("Large Button", size: .large) {}
        
        ModernButton(action: {}) {
            HStack {
                Image(systemName: "star.fill")
                Text("Custom Label")
            }
        }
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 