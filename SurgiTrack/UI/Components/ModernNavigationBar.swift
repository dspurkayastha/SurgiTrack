import SwiftUI

struct ModernNavigationBar: View {
    let title: String
    let subtitle: String?
    let showBackButton: Bool
    let leading: AnyView?
    let trailing: AnyView?
    
    @Environment(\.themeColors) private var colors
    @Environment(\.dismiss) private var dismiss
    
    // Main initializer
    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = true,
        leading: AnyView? = nil,
        trailing: AnyView? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.leading = leading
        self.trailing = trailing
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                if showBackButton {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(colors.text)
                    }
                } else if let leading = leading {
                    leading
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(colors.text)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if let trailing = trailing {
                    trailing
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colors.surface)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(colors.border),
                alignment: .bottom
            )
        }
    }
}

// Convenience initializers
extension ModernNavigationBar {
    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = true,
        @ViewBuilder leading: () -> some View
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            showBackButton: showBackButton,
            leading: AnyView(leading()),
            trailing: nil
        )
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = true,
        @ViewBuilder trailing: () -> some View
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            showBackButton: showBackButton,
            leading: nil,
            trailing: AnyView(trailing())
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Basic
        ModernNavigationBar(
            title: "Title Only",
            showBackButton: false
        )
        
        // With Subtitle and Back Button
        ModernNavigationBar(
            title: "Appointments",
            subtitle: "Dr. Smith - Today"
        )
        
        // With Leading View
        ModernNavigationBar(
            title: "Settings",
            leading: { 
                Image(systemName: "gear")
                    .foregroundColor(.blue)
            }
        )
        
        // With Trailing View
        ModernNavigationBar(
            title: "Patients",
            trailing: { 
                Button("Add") {}
                    .buttonStyle(.borderedProminent)
            }
        )
        
        // With Leading and Trailing
        ModernNavigationBar(
            title: "Profile",
            leading: AnyView(Image(systemName: "person.crop.circle")),
            trailing: AnyView(Button("Save") {})
        )
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 