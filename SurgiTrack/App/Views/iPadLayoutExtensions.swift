import SwiftUI

// MARK: - iPad Layout Extensions

extension View {
    /// Conditionally applies iPad-specific styling
    @ViewBuilder
    func iPadStyle<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            transform(self)
        } else {
            self
        }
    }

    /// Apply different styles for iPad and iPhone
    @ViewBuilder
    func adaptiveStyle<iPadContent: View, iPhoneContent: View>(
        iPad: (Self) -> iPadContent,
        iPhone: (Self) -> iPhoneContent
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPad(self)
        } else {
            iPhone(self)
        }
    }
}

// MARK: - Navigation Split View Column Preferences

struct NavigationColumnPreference {
    static let sidebarMin: CGFloat = 280
    static let sidebarIdeal: CGFloat = 320
    static let sidebarMax: CGFloat = 400

    static let contentMin: CGFloat = 350
    static let contentIdeal: CGFloat = 400
    static let contentMax: CGFloat = 500

    static let detailMin: CGFloat = 500
    static let detailIdeal: CGFloat = 700
}

// MARK: - iPad Toolbar Configuration

extension ToolbarItemPlacement {
    /// Returns the appropriate placement for iPad vs iPhone
    static var adaptiveLeading: ToolbarItemPlacement {
        UIDevice.current.userInterfaceIdiom == .pad ? .navigationBarLeading : .navigationBarLeading
    }

    static var adaptiveTrailing: ToolbarItemPlacement {
        UIDevice.current.userInterfaceIdiom == .pad ? .navigationBarTrailing : .navigationBarTrailing
    }

    static var adaptivePrincipal: ToolbarItemPlacement {
        UIDevice.current.userInterfaceIdiom == .pad ? .principal : .principal
    }
}

// MARK: - Device Detection Helpers

struct DeviceType {
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    static var isLandscape: Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return false
        }
        return window.frame.width > window.frame.height
    }
}
