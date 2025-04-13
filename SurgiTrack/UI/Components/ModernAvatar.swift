import SwiftUI

struct ModernAvatar: View {
    let image: Image?
    let initials: String?
    let size: AvatarSize
    let style: AvatarStyle
    
    @Environment(\.themeColors) private var colors
    
    enum AvatarSize {
        case small
        case medium
        case large
        case extraLarge
        
        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 40
            case .large: return 56
            case .extraLarge: return 72
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 20
            case .extraLarge: return 24
            }
        }
    }
    
    enum AvatarStyle {
        case circle
        case rounded
        case square
        
        var cornerRadius: CGFloat {
            switch self {
            case .circle: return 999
            case .rounded: return 12
            case .square: return 0
            }
        }
    }
    
    init(
        image: Image? = nil,
        initials: String? = nil,
        size: AvatarSize = .medium,
        style: AvatarStyle = .circle
    ) {
        self.image = image
        self.initials = initials
        self.size = size
        self.style = style
    }
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
            } else if let initials = initials {
                Text(initials)
                    .font(.system(size: size.fontSize, weight: .semibold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size.fontSize))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        .background(
            Group {
                if image == nil {
                    LinearGradient(
                        colors: [colors.primary, colors.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .stroke(colors.border, lineWidth: 1)
        )
    }
}

// Convenience initializer for system images
extension ModernAvatar {
    init(
        systemImage: String,
        size: AvatarSize = .medium,
        style: AvatarStyle = .circle
    ) {
        self.init(
            image: Image(systemName: systemImage),
            size: size,
            style: style
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            ModernAvatar(
                image: Image(systemName: "person.crop.circle.fill"),
                size: .small
            )
            
            ModernAvatar(
                initials: "JD",
                size: .medium
            )
            
            ModernAvatar(
                systemImage: "person.fill",
                size: .large
            )
            
            ModernAvatar(
                initials: "AB",
                size: .extraLarge
            )
        }
        
        HStack(spacing: 16) {
            ModernAvatar(
                image: Image(systemName: "person.crop.circle.fill"),
                size: .medium,
                style: .rounded
            )
            
            ModernAvatar(
                initials: "MS",
                size: .medium,
                style: .square
            )
        }
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 