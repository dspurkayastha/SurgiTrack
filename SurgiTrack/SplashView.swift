// SplashView.swift
// SurgiTrack
// Created on 15/03/2025

import SwiftUI

struct SplashView: View {
    // MARK: - Animation States
    @State private var backgroundOpacity = 0.0
    @State private var backgroundRotation = 0.0
    @State private var logoScale = 0.0
    @State private var logoOpacity = 0.0
    @State private var logoPulse = false
    @State private var titleOpacity = 0.0
    @State private var subtitleCharacters = Array<(offset: Int, opacity: Double)>()
    @State private var showParticles = false
    @State private var particles = [Particle]()
    @State private var iconParticles = [IconParticle]()
    @State private var burstParticles = [BurstParticle]()
    @State private var showBurst = false
    @State private var progressValue = 0.0
    @State private var showProgress = false
    @State private var exitScale = 1.0
    @State private var exitOpacity = 1.0
    
    // MARK: - Constants - Animation Timing
    private let subtitleText = "Precision Monitoring, Intelligent Care"
    private let particleCount = 20
    private let iconParticleCount = 12
    private let burstParticleCount = 15
    
    // Animation segments (well-paced over ~5 seconds)
    private let logoAnimationDelay = 0.3
    private let titleAnimationDelay = 0.8
    private let subtitleAnimationDelay = 1.2
    private let subtitleAnimationDuration = 0.04  // Per character
    private let firstBurstDelay = 1.6
    private let secondBurstDelay = 2.5
    private let progressDelay = 3.0
    private let progressDuration = 1.3
    private let exitAnimationDelay = 4.3
    private let exitDuration = 0.7
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Fonts
    private let titleFont = Font.custom("Avenir-Heavy", size: 42, relativeTo: .largeTitle)
    private let subtitleFont = Font.custom("Avenir-Medium", size: 16, relativeTo: .subheadline)
    
    // MARK: - Computed Properties
    private var primaryColor: Color {
        appState.currentTheme.primaryColor
    }
    
    private var secondaryColor: Color {
        appState.currentTheme.secondaryColor
    }
    
    private var accentColor: Color {
        primaryColor.opacity(0.8)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic Background
                backgroundLayer(in: geometry)
                
                // Particles
                particleLayer
                
                // Content
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Logo
                    logoLayer
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .scaleEffect(exitScale)
                        .opacity(exitOpacity)
                    
                    // Title + Subtitle
                    VStack(spacing: 10) {
                        // Title
                        Text("SurgiTrack")
                            .font(titleFont)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        primaryColor,
                                        secondaryColor
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: primaryColor.opacity(0.3), radius: 2, x: 0, y: 2)
                            .opacity(titleOpacity)
                            .scaleEffect(exitScale)
                        
                        // Subtitle with character animation
                        HStack(spacing: 0) {
                            ForEach(subtitleCharacters, id: \.offset) { char in
                                Text(String(subtitleText[char.offset]))
                                    .font(subtitleFont)
                                    .foregroundColor(.secondary)
                                    .opacity(char.opacity)
                            }
                        }
                        .opacity(exitOpacity)
                    }
                    
                    Spacer()
                    
                    // Progress Indicator
                    if showProgress {
                        ProgressRing(
                            progress: progressValue,
                            ringWidth: 4,
                            foregroundColor: primaryColor,
                            backgroundColor: primaryColor.opacity(0.2)
                        )
                        .frame(width: 40, height: 40)
                        .opacity(exitOpacity)
                        .padding(.bottom, 40)
                    }
                }
                .padding()
            }
            .onAppear {
                setupAnimations(in: geometry)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(colorScheme)
    }
    
    // MARK: - View Components
    
    // Background with animated gradient
    private func backgroundLayer(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Base color
            backgroundColor
            
            // Animated gradient circles
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            primaryColor.opacity(0.3),
                            primaryColor.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 1,
                        endRadius: geometry.size.width
                    )
                )
                .scaleEffect(1.5)
                .offset(x: -geometry.size.width/4, y: -geometry.size.height/4)
                .opacity(backgroundOpacity)
                .rotationEffect(.degrees(backgroundRotation))
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            secondaryColor.opacity(0.3),
                            secondaryColor.opacity(0.0)
                        ]),
                        center: .center,
                        startRadius: 1,
                        endRadius: geometry.size.width
                    )
                )
                .scaleEffect(1.5)
                .offset(x: geometry.size.width/4, y: geometry.size.height/4)
                .opacity(backgroundOpacity)
                .rotationEffect(.degrees(-backgroundRotation))
            
            // Subtle grid pattern
            GridPattern(spacing: 20, lineWidth: 0.5, lineColor: primaryColor.opacity(0.1))
                .opacity(backgroundOpacity * 0.5)
            
            // Noise texture
            Color.clear
                .overlay(
                    Image("noise-texture")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blendMode(.overlay)
                )
                .opacity(0.05)
        }
    }
    
    // Logo with animation
    private var logoLayer: some View {
        ZStack {
            // Outer ring glow
            ForEach(0..<3) { i in
                Circle()
                    .stroke(
                        primaryColor.opacity(0.2 - Double(i) * 0.05),
                        lineWidth: 2 - Double(i) * 0.5
                    )
                    .frame(width: 140 + CGFloat(i * 30), height: 140 + CGFloat(i * 30))
                    .scaleEffect(logoPulse ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(0.2 * Double(i)),
                        value: logoPulse
                    )
            }
            
            // Main logo background with glassmorphic effect
            Circle()
                .fill(backgroundColor)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .fill(primaryColor.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    primaryColor.opacity(0.8),
                                    secondaryColor.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: primaryColor.opacity(0.5), radius: 15, x: 0, y: 5)
            
            // Logo icon
            Image(systemName: "stethoscope")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            primaryColor,
                            secondaryColor
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Subtle shine animation
            Circle()
                .trim(from: 0.3, to: 0.5)
                .stroke(
                    Color.white.opacity(0.6),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
                .frame(width: 115, height: 115)
                .rotationEffect(.degrees(backgroundRotation * 2))
        }
        .drawingGroup() // Optimize rendering with Metal
    }
    
    // Enhanced particle system with multiple particle types
    private var particleLayer: some View {
        ZStack {
            // Standard particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .scaleEffect(particle.scale)
                    .position(particle.position)
                    .opacity(showParticles ? particle.opacity : 0)
                    .blur(radius: 0.3)
            }
            
            // Medical icon particles
            ForEach(iconParticles) { particle in
                Image(systemName: particle.iconName)
                    .font(.system(size: particle.size))
                    .foregroundColor(particle.color)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(particle.position)
                    .opacity(showParticles ? particle.opacity : 0)
                    .shadow(color: particle.color.opacity(0.5), radius: 2, x: 0, y: 0)
            }
            
            // Burst particles for special effects
            ForEach(burstParticles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [particle.color, particle.color.opacity(0)]),
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size/2
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .scaleEffect(particle.scale)
                    .position(particle.position)
                    .opacity(particle.isVisible && showBurst ? particle.opacity : 0)
                    .blur(radius: 0.5)
            }
        }
        .opacity(exitOpacity)
        .drawingGroup() // Use Metal for better performance
    }
    
    // MARK: - Animation Setup
    
    private func setupAnimations(in geometry: GeometryProxy) {
        // Initialize subtitle characters
        subtitleCharacters = Array(subtitleText).enumerated().map { (offset, _) in
            (offset: offset, opacity: 0.0)
        }
        
        // Generate particles
        generateParticles(in: geometry)
        
        // Start animation sequence
        startAnimations(in: geometry)
    }
    
    private func startAnimations(in geometry: GeometryProxy) {
        // Background animation
        withAnimation(.easeOut(duration: 0.8)) {
            backgroundOpacity = 1.0
        }
        
        withAnimation(
            Animation.linear(duration: 20)
                .repeatForever(autoreverses: false)
        ) {
            backgroundRotation = 360
        }
        
        // Logo animations
        DispatchQueue.main.asyncAfter(deadline: .now() + logoAnimationDelay) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.logoPulse = true
            }
        }
        
        // Title animation
        DispatchQueue.main.asyncAfter(deadline: .now() + titleAnimationDelay) {
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1.0
            }
        }
        
        // Subtitle character-by-character animation
        DispatchQueue.main.asyncAfter(deadline: .now() + subtitleAnimationDelay) {
            for (index, _) in self.subtitleCharacters.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + subtitleAnimationDuration * Double(index)) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.subtitleCharacters[index].opacity = 1.0
                    }
                }
            }
        }
        
        // Start particle effects with subtitle
        DispatchQueue.main.asyncAfter(deadline: .now() + subtitleAnimationDelay) {
            withAnimation(.easeOut(duration: 0.8)) {
                showParticles = true
            }
            
            // Animate standard particles
            for i in 0..<self.particles.count {
                self.animateParticle(index: i, in: geometry)
            }
            
            // Animate icon particles
            for i in 0..<self.iconParticles.count {
                self.animateIconParticle(index: i, in: geometry)
            }
        }
        
        // First burst particles
        DispatchQueue.main.asyncAfter(deadline: .now() + firstBurstDelay) {
            self.showBurst = true
            self.animateBurstParticles(in: geometry)
        }
        
        // Second burst during the enjoyment period
        DispatchQueue.main.asyncAfter(deadline: .now() + secondBurstDelay) {
            self.animateBurstParticles(in: geometry)
        }
        
        // Progress animation
        DispatchQueue.main.asyncAfter(deadline: .now() + progressDelay) {
            self.showProgress = true
            
            withAnimation(.easeInOut(duration: self.progressDuration)) {
                self.progressValue = 1.0
            }
        }
        
        // Exit animation and notification
        DispatchQueue.main.asyncAfter(deadline: .now() + exitAnimationDelay) {
            self.startExitAnimation()
            
            // Notify when all animations are complete
            DispatchQueue.main.asyncAfter(deadline: .now() + exitDuration) {
                // Send notification that splash animation is complete
                NotificationCenter.default.post(
                    name: Notification.Name("SplashAnimationComplete"),
                    object: nil
                )
            }
        }
    }
    
    // MARK: - Enhanced Particle Systems
    
    private func generateParticles(in geometry: GeometryProxy) {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2

        // Standard particles
        particles = (0..<particleCount).map { _ in
            // Create particles in a circle around the center
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = Double.random(in: 100..<250)
            let x = centerX + CGFloat(cos(angle) * distance)
            let y = centerY + CGFloat(sin(angle) * distance)
            
            return Particle(
                id: UUID(),
                position: CGPoint(x: x, y: y),
                content: "•", // Simple circle character as content
                isIcon: false, // These are standard particles, not icons
                color: [primaryColor, secondaryColor, .white].randomElement()!,
                size: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.3...0.7),
                scale: 0.1,
                rotation: Double.random(in: 0...360), // Random rotation
                duration: Double.random(in: 3...6), // Animation duration
                delay: Double.random(in: 0...2) // Animation delay
            )
        }
        
        // Medical icon particles - distributed in an oval around the screen
        let medicalIcons = ["heart.fill", "lungs.fill", "cross.case.fill", "pill.fill",
                            "waveform.path.ecg", "stethoscope", "bandage.fill", "brain",
                            "ear", "eye.fill", "hand.raised.fill", "cellularbars"]
        
        iconParticles = (0..<iconParticleCount).map { i in
            // Create icon particles in an oval pattern with some randomization
            let baseAngle = (Double(i) / Double(iconParticleCount)) * 2 * .pi
            let angleVariation = Double.random(in: -0.2...0.2)
            let angle = baseAngle + angleVariation
            
            // Oval parameters (wider than tall)
            let horizontalRadius = Double.random(in: 220...350)
            let verticalRadius = Double.random(in: 180...280)
            
            let x = centerX + CGFloat(cos(angle) * horizontalRadius)
            let y = centerY + CGFloat(sin(angle) * verticalRadius)
            
            return IconParticle(
                id: UUID(),
                position: CGPoint(x: x, y: y),
                iconName: medicalIcons.randomElement()!,
                color: [primaryColor, secondaryColor, accentColor].randomElement()!,
                size: CGFloat.random(in: 14...22),
                opacity: Double.random(in: 0.3...0.5),
                rotation: Double.random(in: 0...360),
                scale: 0.1
            )
        }
        
        // Burst particles (initially invisible)
        burstParticles = (0..<burstParticleCount).map { _ in
            // Create burst particles emanating from center
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = Double.random(in: 20...40) // Initial distance
            let x = centerX + CGFloat(cos(angle) * distance)
            let y = centerY + CGFloat(sin(angle) * distance)
            
            return BurstParticle(
                id: UUID(),
                position: CGPoint(x: x, y: y),
                color: [primaryColor, secondaryColor, .white].randomElement()!,
                size: CGFloat.random(in: 4...10),
                opacity: 1.0,
                scale: 0.1,
                angle: angle,
                distance: distance,
                isVisible: false
            )
        }
    }
    
    private func animateParticle(index: Int, in geometry: GeometryProxy) {
        guard index < particles.count else { return }
        
        // Animate particles with varying durations
        let duration = Double.random(in: 2.0...5.0)
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        // Animate to a new position
        withAnimation(
            Animation.easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...2))
        ) {
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = Double.random(in: 130...280)
            let newX = centerX + CGFloat(cos(angle) * distance)
            let newY = centerY + CGFloat(sin(angle) * distance)
            
            particles[index].position = CGPoint(x: newX, y: newY)
            particles[index].opacity = Double.random(in: 0.2...0.7)
            particles[index].scale = Double.random(in: 0.8...1.2)
        }
    }
    
    private func animateIconParticle(index: Int, in geometry: GeometryProxy) {
        guard index < iconParticles.count else { return }
        
        // Animate icon particles with slower, more deliberate movements
        let duration = Double.random(in: 4.0...8.0)
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        // Slower, orbital-like animation
        withAnimation(
            Animation.easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...3))
        ) {
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = Double.random(in: 180...320)
            let newX = centerX + CGFloat(cos(angle) * distance)
            let newY = centerY + CGFloat(sin(angle) * distance)
            
            iconParticles[index].position = CGPoint(x: newX, y: newY)
            iconParticles[index].opacity = Double.random(in: 0.3...0.6)
            iconParticles[index].scale = Double.random(in: 0.9...1.3)
            iconParticles[index].rotation = Double.random(in: 0...360)
        }
    }
    
    private func animateBurstParticles(in geometry: GeometryProxy) {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        // Make all particles visible
        for index in 0..<burstParticles.count {
            burstParticles[index].isVisible = true
            
            // Animate each particle outward along its angle
            withAnimation(
                Animation.easeOut(duration: Double.random(in: 1.0...2.0))
            ) {
                let finalDistance = Double.random(in: 150...300)
                let angle = burstParticles[index].angle
                
                // Calculate new position
                let newX = centerX + CGFloat(cos(angle) * finalDistance)
                let newY = centerY + CGFloat(sin(angle) * finalDistance)
                
                burstParticles[index].position = CGPoint(x: newX, y: newY)
                burstParticles[index].scale = Double.random(in: 0.8...1.5)
                
                // Fade out at the end of trajectory
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        if index < self.burstParticles.count {
                            self.burstParticles[index].opacity = 0
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Exit Animation
    
    private func startExitAnimation() {
        // Notify we're about to exit to prepare the next view
        NotificationCenter.default.post(
            name: Notification.Name("SplashPreExitNotification"),
            object: nil
        )
        
        // Zoom in slightly and fade out
        withAnimation(.easeIn(duration: exitDuration)) {
            exitScale = 1.1
            exitOpacity = 0
        }
    }
}

// MARK: - Supporting Types and Views

// Particle models for sophisticated particle systems


// Medical icon particles
struct IconParticle: Identifiable {
    var id: UUID
    var position: CGPoint
    var iconName: String
    var color: Color
    var size: CGFloat
    var opacity: Double
    var rotation: Double
    var scale: Double
}

// Burst particles for special effects
struct BurstParticle: Identifiable {
    var id: UUID
    var position: CGPoint
    var color: Color
    var size: CGFloat
    var opacity: Double
    var scale: Double
    var angle: Double
    var distance: Double
    var isVisible: Bool
}

struct GridPattern: View {
    let spacing: CGFloat
    let lineWidth: CGFloat
    let lineColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                // Vertical lines
                for x in stride(from: 0, to: geometry.size.width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, to: geometry.size.height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(lineColor, lineWidth: lineWidth)
        }
    }
}
// Custom Progress Ring
struct ProgressRing: View {
    var progress: Double
    var ringWidth: CGFloat
    var foregroundColor: Color
    var backgroundColor: Color
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: ringWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }
}

// MARK: - String Extension for Indexing
extension String {
    subscript(offset: Int) -> Character {
        self[self.index(self.startIndex, offsetBy: offset)]
    }
}

// MARK: - Preview
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SplashView()
                .environmentObject(AppState())
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            SplashView()
                .environmentObject(AppState())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
