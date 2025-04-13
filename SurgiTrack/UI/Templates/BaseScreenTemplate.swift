import SwiftUI

struct BaseScreenTemplate<Content: View>: View {
    let title: String
    let subtitle: String?
    let showBackButton: Bool
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.content = content()
    }
    
    var body: some View {
        ModernNavigationView {
            VStack(spacing: 0) {
                ModernNavigationBar(
                    title: title,
                    subtitle: subtitle,
                    showBackButton: showBackButton
                )
                
                content
            }
        }
    }
}

struct DetailScreenTemplate<Content: View>: View {
    let title: String
    let content: Content
    
    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        BaseScreenTemplate(
            title: title,
            showBackButton: true
        ) {
            ScrollView {
                VStack(spacing: 16) {
                    content
                }
                .padding()
            }
        }
    }
}

struct ListScreenTemplate<Content: View>: View {
    let title: String
    let content: Content
    
    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        BaseScreenTemplate(
            title: title,
            showBackButton: true
        ) {
            content
        }
    }
}

#Preview {
    DetailScreenTemplate(title: "Patient Details") {
        VStack(spacing: 16) {
            ModernCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Patient Information")
                        .font(.headline)
                    Text("Sample patient details here")
                        .foregroundColor(.secondary)
                }
            }
            
            ModernButton(
                "Save Changes", 
                style: .primary
            ) {
                // Action
            }
        }
    }
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 