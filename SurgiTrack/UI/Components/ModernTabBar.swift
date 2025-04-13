import SwiftUI

struct ModernTabBar: View {
    @Binding var selectedTab: Int
    let items: [TabItem]
    
    @Environment(\.themeColors) private var colors
    
    struct TabItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let selectedIcon: String
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == index ? item.selectedIcon : item.icon)
                            .font(.system(size: 24, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? colors.primary : colors.textSecondary)
                        
                        Text(item.title)
                            .font(.system(size: 12, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? colors.primary : colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colors.primary.opacity(0.1))
                                    .matchedGeometryEffect(id: "TAB", in: namespace)
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(colors.surface)
                .shadow(color: colors.shadow.opacity(0.1), radius: 8, x: 0, y: -4)
        )
    }
    
    @Namespace private var namespace
}

#Preview {
    VStack {
        Spacer()
        
        ModernTabBar(
            selectedTab: .constant(0),
            items: [
                .init(title: "Home", icon: "house", selectedIcon: "house.fill"),
                .init(title: "Patients", icon: "person.2", selectedIcon: "person.2.fill"),
                .init(title: "Calendar", icon: "calendar", selectedIcon: "calendar.fill"),
                .init(title: "Settings", icon: "gear", selectedIcon: "gear.fill")
            ]
        )
    }
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 