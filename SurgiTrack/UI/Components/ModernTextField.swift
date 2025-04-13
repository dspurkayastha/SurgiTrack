import SwiftUI

struct ModernTextField: View {
    let title: String
    let placeholder: String
    let text: Binding<String>
    let icon: String?
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let isRequired: Bool
    let errorMessage: String?
    
    @Environment(\.themeColors) private var colors
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        placeholder: String = "",
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        isRequired: Bool = false,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self.text = text
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.isRequired = isRequired
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(colors.text)
                
                if isRequired {
                    Text("*")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isFocused ? colors.primary : colors.textSecondary)
                }
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: text)
                    } else {
                        TextField(placeholder, text: text)
                    }
                }
                .foregroundColor(colors.text)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .focused($isFocused)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(colors.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var borderColor: Color {
        if let _ = errorMessage {
            return .red
        }
        return isFocused ? colors.primary : colors.border
    }
}

#Preview {
    VStack(spacing: 16) {
        ModernTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant(""),
            icon: "envelope",
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            isRequired: true
        )
        
        ModernTextField(
            title: "Password",
            placeholder: "Enter your password",
            text: .constant(""),
            icon: "lock",
            isSecure: true,
            textContentType: .password,
            isRequired: true
        )
        
        ModernTextField(
            title: "Phone",
            placeholder: "Enter your phone number",
            text: .constant(""),
            icon: "phone",
            keyboardType: .phonePad,
            textContentType: .telephoneNumber,
            errorMessage: "Please enter a valid phone number"
        )
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 