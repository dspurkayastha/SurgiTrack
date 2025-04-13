import SwiftUI

struct ModernList<Content: View>: View {
    let content: Content
    let style: ListStyle
    
    @Environment(\.themeColors) private var colors
    
    enum ListStyle {
        case plain
        case grouped
        case inset
        case insetGrouped
        
        var cornerRadius: CGFloat {
            switch self {
            case .plain, .grouped: return 0
            case .inset, .insetGrouped: return 12
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .plain: return EdgeInsets()
            case .grouped: return EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            case .inset: return EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            case .insetGrouped: return EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            }
        }
    }
    
    init(style: ListStyle = .plain, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                content
            }
            .padding(style.padding)
        }
        .background(colors.background)
    }
}

struct ModernListSection<Header: View, Content: View, Footer: View>: View {
    let header: Header
    let content: Content
    let footer: Footer
    let style: ModernList<ListContent>.ListStyle
    
    @Environment(\.themeColors) private var colors
    
    init(
        style: ModernList<ListContent>.ListStyle = .plain,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.style = style
        self.header = header()
        self.content = content()
        self.footer = footer()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !(header is EmptyView) {
                header
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            
            VStack(spacing: 0) {
                content
            }
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(colors.border, lineWidth: 1)
            )
            
            if !(footer is EmptyView) {
                footer
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
        }
    }
}

struct ListContent: View {
    var body: some View {
        EmptyView()
    }
}

extension ModernListSection where Header == EmptyView, Footer == EmptyView {
    init(
        style: ModernList<ListContent>.ListStyle = .plain,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            style: style,
            header: { EmptyView() },
            content: content,
            footer: { EmptyView() }
        )
    }
}

extension ModernListSection where Footer == EmptyView {
    init(
        style: ModernList<ListContent>.ListStyle = .plain,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            style: style,
            header: header,
            content: content,
            footer: { EmptyView() }
        )
    }
}

extension ModernListSection where Header == EmptyView {
    init(
        style: ModernList<ListContent>.ListStyle = .plain,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.init(
            style: style,
            header: { EmptyView() },
            content: content,
            footer: footer
        )
    }
}

#Preview {
    ModernList(style: .insetGrouped) {
        ModernListSection(
            style: .insetGrouped,
            header: {
                Text("Section 1")
                    .font(.headline)
                    .foregroundColor(.secondary)
            },
            content: {
                ModernListItem(
                    title: "Item 1",
                    subtitle: "Subtitle 1",
                    leadingIcon: "star.fill",
                    trailingIcon: "chevron.right"
                ) {}
                
                ModernListItem(
                    title: "Item 2",
                    subtitle: "Subtitle 2",
                    leadingIcon: "heart.fill",
                    trailingIcon: "chevron.right"
                ) {}
            },
            footer: { EmptyView() }
        )
        
        ModernListSection(
            style: .insetGrouped,
            header: {
                Text("Section 2")
                    .font(.headline)
                    .foregroundColor(.secondary)
            },
            content: {
                ModernListItem(
                    title: "Item 3",
                    subtitle: "Subtitle 3",
                    leadingIcon: "bell.fill",
                    trailingIcon: "chevron.right"
                ) {}
                
                ModernListItem(
                    title: "Item 4",
                    subtitle: "Subtitle 4",
                    leadingIcon: "gear",
                    trailingIcon: "chevron.right"
                ) {}
            },
            footer: {
                Text("Footer text")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        )
    }
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 
