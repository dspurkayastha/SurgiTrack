import SwiftUI

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isShowingToast = false
    @Published var toastTitle = ""
    @Published var toastMessage: String?
    @Published var toastType: ModernToast.ToastType = .info
    
    private init() {}
    
    func showToast(
        title: String,
        message: String? = nil,
        type: ModernToast.ToastType = .info
    ) {
        toastTitle = title
        toastMessage = message
        toastType = type
        isShowingToast = true
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.isShowingToast = false
            }
        }
    }
    
    func showSuccess(_ message: String) {
        showToast(title: "Success", message: message, type: .success)
    }
    
    func showError(_ message: String) {
        showToast(title: "Error", message: message, type: .error)
    }
    
    func showWarning(_ message: String) {
        showToast(title: "Warning", message: message, type: .warning)
    }
    
    func showInfo(_ message: String) {
        showToast(title: "Info", message: message, type: .info)
    }
}

struct ToastManagerKey: EnvironmentKey {
    static let defaultValue = ToastManager.shared
}

extension EnvironmentValues {
    var toastManager: ToastManager {
        get { self[ToastManagerKey.self] }
        set { self[ToastManagerKey.self] = newValue }
    }
}

extension View {
    func withToastManager() -> some View {
        self.environment(\.toastManager, ToastManager.shared)
    }
} 
