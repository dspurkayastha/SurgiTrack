import SwiftUI
import Combine

/// Coordinates animations across authentication views
class AnimationCoordinator: ObservableObject {
    // MARK: - Animation State
    
    /// Background animation properties
    @Published var backgroundRotation = 0.0
    @Published var backgroundOpacity: Double = 0.0 {
        didSet {
            Logger.debug("backgroundOpacity changed to \(backgroundOpacity)", category: .ui)
        }
    }

    /// Content animation properties
    @Published var headerScale = 0.95
    @Published var headerOpacity = 0.0
    @Published var contentScale = 0.98
    @Published var contentOpacity = 0.0
    
    /// Card animation properties
    @Published var cardOffset: CGFloat = 20
    @Published var cardOpacity = 0.0
    
    /// Particle animation properties
    @Published var showParticles = false
    @Published var particleOpacity: Double = 0.0 {
        didSet {
            Logger.debug("particleOpacity changed to \(particleOpacity)", category: .ui)
        }
    }
    
    /// Error animation properties
    @Published var errorShakeOffset: CGFloat = 0
    @Published var errorPulse: CGFloat = 1.0
    
    /// Success animation properties
    @Published var successPulse: CGFloat = 1.0
    
    /// Transition animation properties
    @Published var isTransitioning = false
    @Published var transitionProgress: CGFloat = 0.0
    
    // Track animation initialization
    private var animationsInitialized = false
    
    // MARK: - Animation Settings
    
    /// Timing for entry animations
    private let entryTiming = EntryAnimationTiming()
    
    /// Timing for transition animations
    private let transitionTiming = TransitionAnimationTiming()
    
    // Debug flag to track animation flow
    private let enableDebugging = true
    
    // MARK: - Initialization
    
    init() {
        if enableDebugging {
            Logger.debug("AnimationCoordinator initialized", category: .ui)
            Logger.debug("Initial backgroundOpacity = \(backgroundOpacity)", category: .ui)
        }
    }
    
    // MARK: - Public Methods
    
    /// Start entry animations with improved reliability
    func startEntryAnimations() {
        if enableDebugging {
            Logger.debug("startEntryAnimations() called. Initial states:", category: .ui)
            Logger.debug("   backgroundOpacity = \(backgroundOpacity)", category: .ui)
            Logger.debug("   particleOpacity = \(particleOpacity)", category: .ui)
        }
        
        // Start with a clean slate
        resetAnimations()
        
        // Set the initialized flag to prevent unnecessary resets
        animationsInitialized = true
        
        // Force an immediate update cycle before starting animations
        forceUIUpdate()
        
        // Use main thread to ensure UI updates are immediately processed
        DispatchQueue.main.async {
            if self.enableDebugging { Logger.debug("Starting background animation", category: .ui) }
            // Background fade in - use a longer duration for more reliability
            withAnimation(.easeOut(duration: self.entryTiming.backgroundFadeIn * 1.5)) {
                self.backgroundOpacity = 1.0
            }


            // Card fade in
            if self.enableDebugging { Logger.debug("Starting card animation with delay: \(self.entryTiming.cardDelay)", category: .ui) }
            withAnimation(.spring(response: self.entryTiming.cardSpringResponse,
                                dampingFraction: self.entryTiming.cardSpringDamping)
                .delay(self.entryTiming.cardDelay)) {
                    self.cardOpacity = 1.0
                    self.cardOffset = 0
                }
            
            // Header fade in and scale
            if self.enableDebugging { print("DEBUG: Starting header animation with delay: \(self.entryTiming.headerDelay)") }
            withAnimation(.spring(response: self.entryTiming.headerSpringResponse,
                                dampingFraction: self.entryTiming.headerSpringDamping)
                .delay(self.entryTiming.headerDelay)) {
                    self.headerOpacity = 1.0
                    self.headerScale = 1.0
                }
            
            // Content fade in
            if self.enableDebugging { print("DEBUG: Starting content animation with delay: \(self.entryTiming.contentDelay)") }
            withAnimation(.spring(response: self.entryTiming.contentSpringResponse,
                                dampingFraction: self.entryTiming.contentSpringDamping)
                .delay(self.entryTiming.contentDelay)) {
                    self.contentOpacity = 1.0
                    self.contentScale = 1.0
                }
            
            // Start background rotation
            if self.enableDebugging { print("DEBUG: Starting rotation animation") }
            withAnimation(Animation.linear(duration: self.entryTiming.backgroundRotationDuration)
                .repeatForever(autoreverses: false)) {
                    self.backgroundRotation = 360
                }
            
            // Start particles with delay
            if self.enableDebugging { print("DEBUG: Scheduling particles with delay: \(self.entryTiming.particlesDelay)") }
            DispatchQueue.main.asyncAfter(deadline: .now() + self.entryTiming.particlesDelay) {
                if self.enableDebugging { print("DEBUG: Starting particles animation") }
                withAnimation(.easeIn(duration: self.entryTiming.particlesFadeIn)) {
                    self.showParticles = true
                    self.particleOpacity = 1.0
                }
                
                // Schedule more UI updates to ensure animations complete
                self.scheduleAnimationVerification()
            }
        }
    }
    
    /// Coordinate transition between authentication methods
    func transitionToNewMethod(completion: @escaping () -> Void) {
        isTransitioning = true

        if enableDebugging {
            Logger.debug("transitionToNewMethod called", category: .ui)
        }
        
        // Force UI update before transitioning
        forceUIUpdate()
        
        // 1. Fade out content
        withAnimation(.easeInOut(duration: transitionTiming.fadeOutDuration)) {
            contentOpacity = 0
            cardOpacity = 0
            particleOpacity = 0
        }
        
        // 2. Update transition progress for visual indicators
        withAnimation(.easeInOut(duration: transitionTiming.totalDuration)) {
            transitionProgress = 1.0
        }
        
        // 3. Wait for fade out, then invoke the completion handler to update content
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionTiming.contentSwitchDelay) {
            // Let the caller update content before we fade back in
            completion()
            
            // 4. Fade in new content
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: self.transitionTiming.fadeInDuration)) {
                    self.contentOpacity = 1
                    self.cardOpacity = 1
                }
                
                // 5. Fade in particles with a slight delay
                DispatchQueue.main.asyncAfter(deadline: .now() + self.transitionTiming.particlesDelay) {
                    withAnimation(.easeInOut(duration: self.transitionTiming.particlesFadeInDuration)) {
                        self.particleOpacity = 1
                    }
                    
                    // 6. Reset transition state
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.transitionTiming.completionDelay) {
                        self.isTransitioning = false
                        self.transitionProgress = 0
                    }
                }
            }
        }
    }
    
    /// Animate error state
    func animateError() {
        // Shake animation
        let shakeSequence = [10, -10, 8, -8, 5, -5, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(index)) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.3, blendDuration: 0.1)) {
                    self.errorShakeOffset = CGFloat(offset)
                }
            }
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 0.2)) {
            errorPulse = 1.05
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.errorPulse = 1.0
            }
        }
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Animate success state
    func animateSuccess() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            successPulse = 1.1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.successPulse = 1.0
            }
        }
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Reset all animations to initial state
    func resetAnimations() {
        if enableDebugging { print("DEBUG: Resetting all animations to initial state") }
        
        // Reset in main thread to ensure UI updates
        DispatchQueue.main.async {
            self.backgroundOpacity = 0
            self.headerScale = 0.95
            self.headerOpacity = 0.0
            self.contentScale = 0.98
            self.contentOpacity = 0
            self.cardOffset = 20
            self.cardOpacity = 0
            self.showParticles = false
            self.particleOpacity = 0
        }
    }
    
    /// Force a UI update to ensure animations are visible
    func forceUIUpdate() {
        Logger.debug("Forcing UI update", category: .ui)
        
        // Store current values
        let currentBgOpacity = self.backgroundOpacity
        let currentParticleOpacity = self.particleOpacity
        
        // Make a small change to trigger updates
        self.backgroundOpacity = 0.01
        self.particleOpacity = 0.01
        
        // ONLY restore values if they weren't zero before,
        // otherwise let animations take control
        DispatchQueue.main.async {
            // IMPORTANT: Don't restore zero values! Let animations work instead
            if currentBgOpacity > 0.01 {
                self.backgroundOpacity = currentBgOpacity
                Logger.debug("Restored background opacity to \(currentBgOpacity)", category: .ui)
            }

            if currentParticleOpacity > 0.01 {
                self.particleOpacity = currentParticleOpacity
                Logger.debug("Restored particle opacity to \(currentParticleOpacity)", category: .ui)
            }

            Logger.debug("UI update completed without restoring zero values", category: .ui)
        }
    }
    
    /// Schedule verification of animation states
    private func scheduleAnimationVerification() {
        // Verify animation states at multiple points to ensure consistency
        let checkPoints = [0.5, 1.0, 2.0, 3.0]
        
        for (index, delay) in checkPoints.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if self.enableDebugging {
                    Logger.debug("Animation verification #\(index + 1) after \(delay) seconds:", category: .ui)
                    Logger.debug("   backgroundOpacity = \(self.backgroundOpacity)", category: .ui)
                    Logger.debug("   particleOpacity = \(self.particleOpacity)", category: .ui)
                    Logger.debug("   contentOpacity = \(self.contentOpacity)", category: .ui)
                    Logger.debug("   showParticles = \(self.showParticles)", category: .ui)
                }

                // Check for stalled animations and fix them
                if self.backgroundOpacity < 0.5 && delay > 1.0 {
                    Logger.debug("Animation appears stalled - forcing background opacity", category: .ui)
                    self.backgroundOpacity = 1.0
                }

                if self.particleOpacity < 0.5 && delay > 2.0 && self.showParticles {
                    Logger.debug("Animation appears stalled - forcing particle opacity", category: .ui)
                    self.particleOpacity = 1.0
                }
            }
        }
    }
}


// MARK: - Animation Timing Structures

/// Timing for entry animations
struct EntryAnimationTiming {
    let backgroundFadeIn: Double = 0.8
    let backgroundRotationDuration: Double = 20
    
    let headerDelay: Double = 0.3
    let headerSpringResponse: Double = 0.6
    let headerSpringDamping: Double = 0.7
    
    let cardDelay: Double = 0.3
    let cardSpringResponse: Double = 0.6
    let cardSpringDamping: Double = 0.7
    
    let contentDelay: Double = 0.5
    let contentSpringResponse: Double = 0.6
    let contentSpringDamping: Double = 0.7
    
    let particlesDelay: Double = 0.8
    let particlesFadeIn: Double = 0.5
}

/// Timing for transitions between authentication methods
struct TransitionAnimationTiming {
    let fadeOutDuration: Double = 0.3
    let contentSwitchDelay: Double = 0.3
    let fadeInDuration: Double = 0.3
    let particlesDelay: Double = 0.1
    let particlesFadeInDuration: Double = 0.5
    let completionDelay: Double = 0.3
    
    // Total duration of the transition
    var totalDuration: Double {
        return fadeOutDuration + contentSwitchDelay + fadeInDuration + particlesDelay + 0.2
    }
}
