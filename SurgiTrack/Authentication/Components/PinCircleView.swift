//
//  PinCircleView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// PinCircleView.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI

/// A group of circles for PIN input visualization
struct PinCircleView: View {
    // MARK: - Properties
    
    /// Total number of digits in PIN
    var pinLength: Int = 6
    
    /// Current number of filled digits
    var filledCount: Int
    
    /// Fill progress for each digit (0-1)
    var fillProgress: [CGFloat]
    
    /// Whether to show error state
    var isError: Bool = false
    
    /// Circle size
    var circleSize: CGFloat = 18
    
    /// Spacing between circles
    var spacing: CGFloat = 18
    
    /// Current theme
    @EnvironmentObject private var appState: AppState
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<pinLength, id: \.self) { index in
                PinCircle(
                    isFilled: index < filledCount,
                    fillProgress: fillProgress[index],
                    isError: isError,
                    color: appState.currentTheme.primaryColor,
                    size: circleSize
                )
            }
        }
    }
}

/// Individual PIN circle with fill animation
struct PinCircle: View {
    // MARK: - Properties
    
    /// Whether the circle is filled
    var isFilled: Bool
    
    /// Fill progress (0-1)
    var fillProgress: CGFloat
    
    /// Whether to show error state
    var isError: Bool
    
    /// Circle color
    var color: Color
    
    /// Circle size
    var size: CGFloat = 18
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .strokeBorder(
                    isError ? Color.red.opacity(0.8) : color.opacity(0.6),
                    lineWidth: isError ? 1.5 : 1
                )
                .frame(width: size, height: size)
            
            // Fill with animated progress
            Circle()
                .fill(isError ? Color.red.opacity(0.8) : color)
                .scaleEffect(fillProgress)
                .opacity(isFilled ? 1 : 0)
                .frame(width: size, height: size)
        }
        // Add subtle glow when filled
        .shadow(
            color: (isError ? Color.red : color).opacity(isFilled ? 0.6 : 0),
            radius: 4,
            x: 0,
            y: 0
        )
    }
}

// MARK: - Preview
struct PinCircleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Empty PIN
            PinCircleView(
                filledCount: 0,
                fillProgress: Array(repeating: 0, count: 6)
            )
            
            // Partially filled PIN
            PinCircleView(
                filledCount: 3,
                fillProgress: [1, 1, 1, 0, 0, 0]
            )
            
            // Filled PIN
            PinCircleView(
                filledCount: 6,
                fillProgress: Array(repeating: 1, count: 6)
            )
            
            // Error state
            PinCircleView(
                filledCount: 6,
                fillProgress: Array(repeating: 1, count: 6),
                isError: true
            )
        }
        .padding()
        .environmentObject(AppState())
    }
}