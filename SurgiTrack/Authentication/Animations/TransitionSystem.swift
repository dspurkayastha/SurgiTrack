import SwiftUI
import Combine

/// Manages transitions between authentication views
struct TransitionSystem: ViewModifier {
    // MARK: - Properties
    
    /// Current transition state
    @Binding var transitionState: AuthenticationState.TransitionState
    
    /// Transition animation duration
    var duration: Double
    
    // MARK: - Initializer
    
    init(transitionState: Binding<AuthenticationState.TransitionState>, duration: Double = 0.3) {
        self._transitionState = transitionState
        self.duration = duration
    }
    
    // MARK: - ViewModifier Protocol Requirements
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(y: offset)
            .animation(.easeInOut(duration: duration), value: transitionState)
    }
    
    // MARK: - Transition Calculations
    
    private var opacity: Double {
        switch transitionState {
        case .idle, .active:
            return 1.0
        case .fadeOut:
            return 0.0
        case .switching:
            return 0.0
        case .fadeIn:
            return 1.0
        }
    }
    
    private var scale: CGFloat {
        switch transitionState {
        case .idle, .active:
            return 1.0
        case .fadeOut:
            return 0.95
        case .switching:
            return 0.95
        case .fadeIn:
            return 1.0
        }
    }
    
    private var offset: CGFloat {
        switch transitionState {
        case .idle, .active:
            return 0
        case .fadeOut:
            return 10
        case .switching:
            return -10
        case .fadeIn:
            return 0
        }
    }
}

/// View extension for easy application of transitions
extension View {
    func withTransition(
        state: Binding<AuthenticationState.TransitionState>,
        duration: Double = 0.3
    ) -> some View {
        modifier(TransitionSystem(transitionState: state, duration: duration))
    }
}

/// Container view that handles transitions between child views
struct TransitionContainer<Content: View>: View {
    // MARK: - Properties
    
    /// Current transition state
    @Binding var transitionState: AuthenticationState.TransitionState
    
    /// Content to display
    @ViewBuilder var content: () -> Content
    
    // MARK: - Body
    
    var body: some View {
        content()
            .withTransition(state: $transitionState)
    }
}

// MARK: - Preview
struct TransitionSystem_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State private var transitionState: AuthenticationState.TransitionState = .idle
            @State private var showingSecondView = false
            
            var body: some View {
                VStack {
                    TransitionContainer(transitionState: $transitionState) {
                        if showingSecondView {
                            VStack {
                                Text("Second View")
                                    .font(.title)
                                
                                Button("Switch to First View") {
                                    switchViews()
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.green.opacity(0.2))
                        } else {
                            VStack {
                                Text("First View")
                                    .font(.title)
                                
                                Button("Switch to Second View") {
                                    switchViews()
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.blue.opacity(0.2))
                        }
                    }
                    
                    // Controls for testing
                    VStack {
                        Text("Current state: \(stateDescription)")
                            .padding()
                        
                        HStack {
                            ForEach(["Idle", "FadeOut", "Switching", "FadeIn", "Active"], id: \.self) { state in
                                Button(state) {
                                    setTransitionState(state)
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            private var stateDescription: String {
                switch transitionState {
                case .idle: return "Idle"
                case .fadeOut: return "FadeOut"
                case .switching: return "Switching"
                case .fadeIn: return "FadeIn"
                case .active: return "Active"
                }
            }
            
            private func setTransitionState(_ state: String) {
                switch state {
                case "Idle": transitionState = .idle
                case "FadeOut": transitionState = .fadeOut
                case "Switching": transitionState = .switching
                case "FadeIn": transitionState = .fadeIn
                case "Active": transitionState = .active
                default: break
                }
            }
            
            private func switchViews() {
                // 1. Fade out
                transitionState = .fadeOut
                
                // 2. Switch content
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    transitionState = .switching
                    showingSecondView.toggle()
                    
                    // 3. Fade in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        transitionState = .fadeIn
                        
                        // 4. Set to active
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            transitionState = .active
                            
                            // 5. Return to idle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                transitionState = .idle
                            }
                        }
                    }
                }
            }
        }
        
        return PreviewWrapper()
    }
}
