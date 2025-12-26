import SwiftUI

struct ModernListItem: View {
    let title: String
    let subtitle: String?
    let leadingIcon: String?
    let trailingIcon: String?
    let action: () -> Void
    
    @Environment(\.themeColors) private var colors
    
    init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let leadingIcon = leadingIcon {
                    Image(systemName: leadingIcon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(colors.primary))
                        .frame(width: 24)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(colors.text)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                }

                Spacer()

                if let trailingIcon = trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 14))
                        .foregroundColor(colors.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)  // Minimum touch target
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabelText: String {
        if let subtitle = subtitle {
            return "\(title), \(subtitle)"
        }
        return title
    }
}

#Preview {
    ModernListItem(
        title: "Sample Item",
        subtitle: "This is a subtitle",
        leadingIcon: "star.fill",
        trailingIcon: "chevron.right"
    ) {}
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 