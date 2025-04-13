import SwiftUI

struct ModernSegmentedControl<T: Hashable>: View {
    let items: [T]
    @Binding var selection: T
    let itemTitle: (T) -> String
    
    @Environment(\.themeColors) private var colors
    @Namespace private var namespace
    
    init(
        items: [T],
        selection: Binding<T>,
        itemTitle: @escaping (T) -> String
    ) {
        self.items = items
        self._selection = selection
        self.itemTitle = itemTitle
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = item
                    }
                }) {
                    Text(itemTitle(item))
                        .font(.system(size: 16, weight: selection == item ? .semibold : .regular))
                        .foregroundColor(selection == item ? colors.primary : colors.textSecondary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            ZStack {
                                if selection == item {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colors.primary.opacity(0.1))
                                        .matchedGeometryEffect(id: "TAB", in: namespace)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .shadow(color: colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// Convenience initializer for string-based segments
extension ModernSegmentedControl where T == String {
    init(
        items: [String],
        selection: Binding<String>
    ) {
        self.init(
            items: items,
            selection: selection,
            itemTitle: { $0 }
        )
    }
}

#Preview {
    VStack(spacing: 32) {
        ModernSegmentedControl(
            items: ["All", "Active", "Completed"],
            selection: .constant("All")
        )
        
        ModernSegmentedControl(
            items: ["Day", "Week", "Month", "Year"],
            selection: .constant("Week")
        )
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 