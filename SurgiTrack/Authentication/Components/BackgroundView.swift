//
//  BackgroundView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// BackgroundView.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI

/// A shared background view with animated gradients for authentication screens
struct BackgroundView: View {
    // MARK: - Properties
    
    /// Style of background to display
    var style: Style
    
    /// Animation progress (0-1)
    var animationProgress: CGFloat
    
    /// Rotation degrees for animation
    var rotationDegrees: Double
    
    /// Current theme
    @EnvironmentObject private var appState: AppState
    
    /// Current color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Style Enum
    
    /// Background style options
    enum Style {
        case credentials
        case pin
        case biometric
        case general
        
        /// Primary gradient color intensity
        var primaryIntensity: Double {
            switch self {
            case .credentials: return 0.3
            case .pin: return 0.3
            case .biometric: return 0.35
            case .general: return 0.25
            }
        }
        
        /// Secondary gradient color intensity
        var secondaryIntensity: Double {
            switch self {
            case .credentials: return 0.3
            case .pin: return 0.25
            case .biometric: return 0.3
            case .general: return 0.2
            }
        }
        
        /// Grid pattern opacity
        var gridOpacity: Double {
            switch self {
            case .credentials: return 0.5
            case .pin: return 0.6
            case .biometric: return 0.4
            case .general: return 0.5
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Base color
            baseColor
            
            // Animated gradient circles
            gradientCircles
            
            // Subtle grid pattern
            gridPattern
        }
    }
    
    // MARK: - Computed Views
    
    /// Base background color
    private var baseColor: some View {
        Color(colorScheme == .dark ? .black : .white)
            .edgesIgnoringSafeArea(.all)
    }
    
    /// Animated gradient circles
    private var gradientCircles: some View {
        GeometryReader { geometry in
            ZStack {
                // Primary gradient circle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                appState.currentTheme.primaryColor.opacity(style.primaryIntensity),
                                appState.currentTheme.primaryColor.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 1,
                            endRadius: geometry.size.width
                        )
                    )
                    .scaleEffect(1.5)
                    .offset(x: -geometry.size.width/4, y: -geometry.size.height/4)
                    .opacity(animationProgress)
                    .rotationEffect(.degrees(rotationDegrees))
                
                // Secondary gradient circle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                appState.currentTheme.secondaryColor.opacity(style.secondaryIntensity),
                                appState.currentTheme.secondaryColor.opacity(0.0)
                            ]),
                            center: .center,
                            startRadius: 1,
                            endRadius: geometry.size.width
                        )
                    )
                    .scaleEffect(1.5)
                    .offset(x: geometry.size.width/4, y: geometry.size.height/4)
                    .opacity(animationProgress)
                    .rotationEffect(.degrees(-rotationDegrees))
            }
        }
    }
    
    /// Grid pattern overlay
    private var gridPattern: some View {
        GridPatternView(
            spacing: 20,
            lineWidth: 0.5,
            lineColor: appState.currentTheme.primaryColor.opacity(0.1)
        )
        .opacity(animationProgress * style.gridOpacity)
    }
}

/// Grid pattern view for background
struct GridPatternView: View {
    var spacing: CGFloat
    var lineWidth: CGFloat
    var lineColor: Color
    
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

// MARK: - Preview
struct BackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundView(
            style: .credentials,
            animationProgress: 1.0,
            rotationDegrees: 45
        )
        .environmentObject(AppState())
    }
}