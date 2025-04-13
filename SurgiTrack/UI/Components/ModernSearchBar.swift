import SwiftUI

struct ModernSearchBar: View {
    let placeholder: String
    @Binding var text: String
    var onCancel: (() -> Void)?
    
    @Environment(\.themeColors) private var colors
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isFocused ? colors.primary : colors.textSecondary)
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundColor(colors.text)
                    .focused($isFocused)
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? colors.primary : colors.border, lineWidth: 1)
                    )
            )
            
            if isFocused {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                    onCancel?()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(colors.primary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: text)
    }
}

#Preview {
    VStack {
        ModernSearchBar(
            placeholder: "Search patients...",
            text: .constant("")
        )
        
        ModernSearchBar(
            placeholder: "Search appointments...",
            text: .constant("John"),
            onCancel: {}
        )
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 