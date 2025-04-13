import SwiftUI

// Define Shadow struct
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Theme Colors (Instance-based for Environment)
internal struct ThemeColors {
    var primary: Color
    var secondary: Color
    var accent: Color
    var background: Color
    var surface: Color
    var text: Color
    var textSecondary: Color
    
    // Semantic Colors
    var success: Color
    var warning: Color
    var error: Color
    var info: Color
    
    // Glassmorphism Colors
    var glassBackground: Color
    var glassBorder: Color
    
    var border: Color
    var shadow: Color

    // Initializer taking all parameters (inside the struct)
    init(
        primary: Color,
        secondary: Color,
        accent: Color,
        background: Color,
        surface: Color,
        text: Color,
        textSecondary: Color,
        success: Color,
        warning: Color,
        error: Color,
        info: Color,
        glassBackground: Color,
        glassBorder: Color,
        border: Color,
        shadow: Color
    ) {
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.background = background
        self.surface = surface
        self.text = text
        self.textSecondary = textSecondary
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
        self.glassBackground = glassBackground
        self.glassBorder = glassBorder
        self.border = border
        self.shadow = shadow
    }

    // Default initializer (inside the struct)
    init() {
        self.primary = Color.blue
        self.secondary = Color.gray
        self.accent = Color.purple
        self.background = Color(.systemBackground)
        self.surface = Color(.secondarySystemBackground)
        self.text = Color(.label)
        self.textSecondary = Color(.secondaryLabel)
        self.success = Color.green
        self.warning = Color.orange
        self.error = Color.red
        self.info = Color.blue
        self.glassBackground = Color(.systemGray6).opacity(0.5)
        self.glassBorder = Color(.systemGray4).opacity(0.3)
        self.border = Color(.separator)
        self.shadow = Color.black.opacity(0.1)
    }
}

// MARK: - Renamed Legacy Theme Colors (Static)
struct LegacyThemeColors { // Renamed from ThemeColors
    static let primary = Color.blue
    static let secondary = Color.gray
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let text = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    
    // Semantic Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // Glassmorphism Colors
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    
    static let border = Color(.separator)
    static let shadow = Color.black.opacity(0.1)
}

// MARK: - Theme Typography
struct ThemeTypography {
    // Headings
    static let h1 = Font.system(size: 32, weight: .bold, design: .rounded)
    static let h2 = Font.system(size: 24, weight: .bold, design: .rounded)
    static let h3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    // Body Text
    static let bodyLarge = Font.system(size: 18, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)
    
    // Special Text
    static let caption = Font.caption
    static let button = Font.system(size: 16, weight: .semibold)
}

// MARK: - Theme Spacing
struct ThemeSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 4 // Note: xs and xxs were the same, kept xs
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Theme Shadows
struct ThemeShadows {
    // Use the defined Shadow struct
    static let small = Shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    static let medium = Shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    static let large = Shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
}

// MARK: - Theme Animation
struct ThemeAnimation {
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let easeOut = Animation.easeOut(duration: 0.2)
    static let easeIn = Animation.easeIn(duration: 0.2)
    static let easeInOut = Animation.easeInOut(duration: 0.2)
}

// MARK: - Theme (Points to Legacy Static Values)
struct Theme {
    // Point to the renamed static struct
    static let colors = LegacyThemeColors.self 
    static let typography = ThemeTypography.self
    static let spacing = ThemeSpacing.self
    static let shadows = ThemeShadows.self
    static let animation = ThemeAnimation.self
}

#Preview {
    VStack(spacing: ThemeSpacing.md) { // Use ThemeSpacing directly
        Text("Primary Text")
            .foregroundColor(LegacyThemeColors.primary) // Use LegacyThemeColors directly
        
        Text("Secondary Text")
            .foregroundColor(LegacyThemeColors.secondary) // Use LegacyThemeColors directly
        
        Text("Error Text")
            .foregroundColor(LegacyThemeColors.error) // Use LegacyThemeColors directly
        
        Text("Success Text")
            .foregroundColor(LegacyThemeColors.success) // Use LegacyThemeColors directly
    }
    .padding()
    .background(LegacyThemeColors.background) // Use LegacyThemeColors directly
} 