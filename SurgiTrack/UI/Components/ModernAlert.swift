import SwiftUI

struct ModernAlert: View {
    let title: String
    let message: String
    let type: AlertType
    let primaryButton: AlertButton
    let secondaryButton: AlertButton?
    
    @Environment(\.themeColors) private var colors
    @Environment(\.dismiss) private var dismiss
    
    struct AlertButton {
        let title: String
        let action: () -> Void
        let style: ButtonStyle
        
        enum ButtonStyle {
            case primary
            case secondary
            case destructive
        }
    }
    
    enum AlertType {
        case success
        case warning
        case error
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: type.icon)
                .font(.system(size: 48))
                .foregroundColor(type.color)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    primaryButton.action()
                    dismiss()
                }) {
                    Text(primaryButton.title)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(backgroundForStyle(primaryButton.style))
                        .foregroundColor(foregroundForStyle(primaryButton.style))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if let secondaryButton = secondaryButton {
                    Button(action: {
                        secondaryButton.action()
                        dismiss()
                    }) {
                        Text(secondaryButton.title)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(backgroundForStyle(secondaryButton.style))
                            .foregroundColor(foregroundForStyle(secondaryButton.style))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colors.surface)
                .shadow(color: colors.shadow.opacity(0.2), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, 24)
    }
    
    private func backgroundForStyle(_ style: AlertButton.ButtonStyle) -> some View {
        Group {
            switch style {
            case .primary:
                LinearGradient(
                    colors: [colors.primary, colors.primary.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .secondary:
                colors.surface
            case .destructive:
                LinearGradient(
                    colors: [.red, .red.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    private func foregroundForStyle(_ style: AlertButton.ButtonStyle) -> Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return colors.text
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        ModernAlert(
            title: "Success",
            message: "Your changes have been saved successfully.",
            type: .success,
            primaryButton: .init(
                title: "Done",
                action: {},
                style: .primary
            ),
            secondaryButton: .init(
                title: "Cancel",
                action: {},
                style: .secondary
            )
        )
    }
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 