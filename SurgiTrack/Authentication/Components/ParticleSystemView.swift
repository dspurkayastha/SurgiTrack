//
//  ParticleSystemView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// ParticleSystemView.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI

/// A particle system view for authentication screens
struct ParticleSystemView: View {
    // MARK: - Properties
    
    /// Style of particles to display
    var style: Style
    
    /// Whether to show particles
    var showParticles: Bool
    
    
    /// Number of particles to display
    var particleCount: Int = 20
    
    /// Current theme
    @EnvironmentObject private var appState: AppState
    
    /// Local state for particles
    @State private var particles: [Particle] = []
    @State private var particleOpacity: CGFloat
    
    // MARK: - Initialization
    init(style: Style, showParticles: Bool, opacity: CGFloat, particleCount: Int = 20) {
            self.style = style
            self.showParticles = showParticles
            _particleOpacity = State(initialValue: opacity) // Initialize @State property
            self.particleCount = particleCount
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    if particle.isIcon {
                        // Icon particles
                        Image(systemName: particle.content)
                            .font(.system(size: particle.size))
                            .foregroundColor(particle.color)
                            .opacity(showParticles ? particle.opacity : 0)
                            .scaleEffect(particle.scale)
                            .position(particle.position)
                            .rotationEffect(.degrees(particle.rotation))
                            .animation(
                                Animation.easeInOut(duration: particle.duration)
                                    .repeatForever(autoreverses: true)
                                    .delay(particle.delay),
                                value: showParticles
                            )
                    } else {
                        // Text/number particles
                        Text(particle.content)
                            .font(.system(size: particle.size, weight: .medium, design: .rounded))
                            .foregroundColor(particle.color)
                            .opacity(showParticles ? particle.opacity : 0)
                            .scaleEffect(particle.scale)
                            .position(particle.position)
                            .rotationEffect(.degrees(particle.rotation))
                            .animation(
                                Animation.easeInOut(duration: particle.duration)
                                    .repeatForever(autoreverses: true)
                                    .delay(particle.delay),
                                value: showParticles
                            )
                    }
                }
            }
            .opacity(particleOpacity)
            .onAppear {
                generateParticles(in: geometry.size)
            }
            .onChange(of: style) { newStyle in
                regenerateParticles(in: geometry.size)
            }
        }
    }
    
    // MARK: - Style Enum
    
    /// Particle system style options
    enum Style {
        case credentials
        case pin
        case biometric
        
        /// Gets appropriate content generators for this style
        var contentGenerators: [() -> (String, Bool)] {
            switch self {
            case .credentials:
                return [
                    { ("@", false) },
                    { ("#", false) },
                    { ("*", false) },
                    { ("&", false) },
                    { ("person.fill", true) },
                    { ("lock.fill", true) },
                    { ("key.fill", true) },
                    { ("checkmark.shield", true) }
                ]
            case .pin:
                return [
                    { (String(Int.random(in: 0...9)), false) },
                    { (String(Int.random(in: 0...9)), false) },
                    { (String(Int.random(in: 0...9)), false) },
                    { (String(Int.random(in: 0...9)), false) },
                    { ("lock.fill", true) },
                    { ("key.fill", true) }
                ]
            case .biometric:
                return [
                    { ("faceid", true) },
                    { ("touchid", true) },
                    { ("lock.shield.fill", true) },
                    { ("checkmark.shield.fill", true) },
                    { ("key.fill", true) },
                    { ("lock.fill", true) }
                ]
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Generate particles based on current style
    private func generateParticles(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Create array of content generators based on style
        let generators = style.contentGenerators
        
        // Generate particles
        particles = (0..<particleCount).map { _ in
            // Create particles distributed around the center
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = Double.random(in: 80..<min(size.width, size.height) * 0.4)
            let x = centerX + CGFloat(cos(angle) * distance)
            let y = centerY + CGFloat(sin(angle) * distance)
            
            // Get random content and isIcon flag
            let (content, isIcon) = generators.randomElement()!()
            
            return Particle(
                id: UUID(),
                position: CGPoint(x: x, y: y),
                content: content,
                isIcon: isIcon,
                color: [
                    appState.currentTheme.primaryColor,
                    appState.currentTheme.secondaryColor,
                    Color.gray
                ].randomElement()!,
                size: CGFloat.random(in: isIcon ? 14...24 : 16...30),
                opacity: Double.random(in: 0.1...0.4),
                scale: Double.random(in: 0.8...1.2),
                rotation: Double.random(in: -10...10),
                duration: Double.random(in: 3...6),
                delay: Double.random(in: 0...2)
            )
        }
        
        // Start animating particles
        animateParticles(in: size)
    }
    
    /// Regenerate particles when style changes
    private func regenerateParticles(in size: CGSize) {
            withAnimation(.easeOut(duration: 0.3)) {
                particleOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.generateParticles(in: size)
                
                withAnimation(.easeIn(duration: 0.5)) {
                    self.particleOpacity = 1
                }
            }
    }
    
    /// Animate particles
    private func animateParticles(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        for (index, _) in particles.enumerated() {
            animateParticle(index: index, centerX: centerX, centerY: centerY)
        }
    }
    
    /// Animate a single particle
    private func animateParticle(index: Int, centerX: CGFloat, centerY: CGFloat) {
        guard index < particles.count else { return }
        
        // Animate to a new position
        withAnimation(
            Animation.easeInOut(duration: Double.random(in: 4...8))
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...2))
        ) {
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = Double.random(in: 100...220)
            let newX = centerX + CGFloat(cos(angle) * distance)
            let newY = centerY + CGFloat(sin(angle) * distance)
            
            particles[index].position = CGPoint(x: newX, y: newY)
            particles[index].opacity = Double.random(in: 0.1...0.4)
            particles[index].scale = Double.random(in: 0.8...1.2)
            particles[index].rotation = Double.random(in: -45...45)
        }
    }
}

// MARK: - Particle Model

/// Represents a single particle in the particle system
struct Particle: Identifiable {
    var id: UUID
    var position: CGPoint
    var content: String
    var isIcon: Bool
    var color: Color
    var size: CGFloat
    var opacity: Double
    var scale: Double
    var rotation: Double
    var duration: Double
    var delay: Double
}

// MARK: - Preview
struct ParticleSystemView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            
            ParticleSystemView(
                style: .credentials,
                showParticles: true,
                opacity: 1.0
            )
        }
        .environmentObject(AppState())
    }
}
