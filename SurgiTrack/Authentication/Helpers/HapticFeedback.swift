//
//  HapticFeedback.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// HapticFeedback.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI
import CoreHaptics

/// Provides haptic feedback utilities
class HapticFeedback {
    // MARK: - Standard Haptic Feedback
    
    /// Provides impact feedback
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Provides selection feedback
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Provides notification feedback
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // MARK: - Custom Haptic Patterns
    
    /// Plays success haptic pattern
    static func successPattern() {
        // Simple success pattern
        impact(style: .light)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            notification(type: .success)
        }
    }
    
    /// Plays error haptic pattern
    static func errorPattern() {
        // Error pattern with multiple impacts
        impact(style: .medium)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            notification(type: .error)
        }
    }
    
    /// Plays button press haptic
    static func buttonPress() {
        impact(style: .light)
    }
    
    /// Plays PIN entry haptic
    static func pinDigitEntry() {
        impact(style: .rigid)
    }
    
    /// Plays method switch haptic
    static func methodSwitch() {
        selection()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impact(style: .light)
        }
    }
}

// MARK: - Haptic Button Styles

/// Button style that provides haptic feedback
struct HapticButtonStyle: ButtonStyle {
    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    HapticFeedback.impact(style: feedbackStyle)
                }
            }
    }
}

extension View {
    /// Adds haptic feedback to a button
    func withHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        buttonStyle(HapticButtonStyle(feedbackStyle: style))
    }
}