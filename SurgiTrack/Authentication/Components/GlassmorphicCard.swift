//
//  GlassmorphicCard.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// GlassmorphicCard.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI

/// A card with glassmorphic effect for authentication screens
struct GlassmorphicCard<Content: View>: View {
    // MARK: - Properties
    
    /// Corner radius of the card
    var cornerRadius: CGFloat = 24
    
    /// Background opacity (0-1)
    var backgroundOpacity: CGFloat = 0.7
    
    /// Show gradient border
    var showGradientBorder: Bool = true
    
    /// Shadow intensity (0-1)
    var shadowIntensity: CGFloat = 0.15
    
    /// Card content
    @ViewBuilder var content: () -> Content
    
    /// Current theme
    @EnvironmentObject private var appState: AppState
    
    /// Current color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        content()
            .padding(24)
            .background(
                ZStack {
                    // Base fill based on color scheme
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(colorScheme == .dark ?
                              Color.black.opacity(backgroundOpacity) :
                              Color.white.opacity(backgroundOpacity))
                    
                    // Glassmorphic effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Material.ultraThinMaterial)
                }
            )
            .overlay(
                showGradientBorder ?
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                appState.currentTheme.primaryColor.opacity(0.3),
                                appState.currentTheme.secondaryColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                : nil
            )
            .shadow(
                color: Color.black.opacity(shadowIntensity),
                radius: 15,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Preview
struct GlassmorphicCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Default card
                GlassmorphicCard {
                    VStack(spacing: 16) {
                        Text("Default Card")
                            .font(.headline)
                        
                        Text("This is a glassmorphic card component with default settings")
                            .font(.body)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {}) {
                            Text("Button")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                
                // Custom card
                GlassmorphicCard(
                    cornerRadius: 16,
                    backgroundOpacity: 0.5,
                    showGradientBorder: false,
                    shadowIntensity: 0.25
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Card")
                            .font(.headline)
                        
                        Text("This card has custom properties")
                            .font(.body)
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {}) {
                                Text("Action")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .environmentObject(AppState())
    }
}