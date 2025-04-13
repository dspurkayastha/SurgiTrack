import SwiftUI

struct ModernToast: View {
    let title: String
    let message: String?
    let type: ToastType
    let duration: TimeInterval
    
    @Environment(\.themeColors) private var colors
    @Binding var isPresented: Bool
    
    enum ToastType {
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
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 24))
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colors.text)
                
                if let message = message {
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colors.textSecondary)
            }
        }
        .padding(16)
        .background(colors.surface)
        .cornerRadius(12)
        .shadow(color: colors.shadow, radius: 10, x: 0, y: 4)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation {
                    isPresented = false
                }
            }
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let type: ModernToast.ToastType
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isPresented {
                ModernToast(
                    title: title,
                    message: message,
                    type: type,
                    duration: duration,
                    isPresented: $isPresented
                )
                .padding(.top, 16)
            }
        }
    }
}

extension View {
    func toast(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        type: ModernToast.ToastType = .info,
        duration: TimeInterval = 3
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            type: type,
            duration: duration
        ))
    }
}

#Preview {
    VStack {
        Button("Show Success Toast") {
            // In a real app, you would set a @State variable to true here
        }
        
        Button("Show Error Toast") {
            // In a real app, you would set a @State variable to true here
        }
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 