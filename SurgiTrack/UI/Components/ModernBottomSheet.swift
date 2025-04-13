import SwiftUI

struct ModernBottomSheet<Content: View>: View {
    let title: String
    let content: Content
    @Binding var isPresented: Bool
    
    @Environment(\.themeColors) private var colors
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    
    init(
        title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPresented = false
                        }
                    }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Handle
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(colors.textSecondary.opacity(0.3))
                            .frame(width: 36, height: 5)
                            .padding(.top, 16)
                        
                        // Title
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(colors.text)
                            .padding(.top, 16)
                        
                        // Content
                        content
                            .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colors.surface)
                            .shadow(color: colors.shadow.opacity(0.2), radius: 16, x: 0, y: -8)
                    )
                    .offset(y: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let translation = value.translation.height
                                offset = lastOffset + translation
                            }
                            .onEnded { value in
                                let velocity = value.predictedEndLocation.y - value.location.y
                                let shouldDismiss = offset > 100 || velocity > 500
                                
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if shouldDismiss {
                                        isPresented = false
                                    } else {
                                        offset = 0
                                        lastOffset = 0
                                    }
                                }
                            }
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: isPresented) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    lastOffset = 0
                }
            }
        }
    }
}

struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let content: () -> SheetContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            ModernBottomSheet(
                title: title,
                isPresented: $isPresented,
                content: self.content
            )
        }
    }
}

extension View {
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(BottomSheetModifier(
            isPresented: isPresented,
            title: title,
            content: content
        ))
    }
}

#Preview {
    VStack {
        Button("Show Bottom Sheet") {
            // In a real app, you would set a @State variable to true here
        }
    }
    .padding()
    .withThemeBridge(appState: AppState(), colorScheme: .light)
} 