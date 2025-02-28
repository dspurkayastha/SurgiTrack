// NumpadView.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI

/// A numeric keypad view for PIN entry
struct NumpadView: View {
    // MARK: - Properties
    
    /// Action to perform when a digit is tapped
    var onDigitTapped: (Int) -> Void
    
    /// Action to perform when delete is tapped
    var onDeleteTapped: () -> Void
    
    /// Optional action for alternative button (e.g., biometric)
    var alternativeButtonAction: (() -> Void)?
    
    /// Icon name for alternative button
    var alternativeButtonIcon: String?
    
    /// Currently pressed button for animation
    var pressedButton: Int?
    
    /// Button size
    var buttonSize: CGFloat = 50
    
    /// Spacing between buttons
    var spacing: CGFloat = 23
    
    /// Current theme
    @EnvironmentObject private var appState: AppState
    
    /// Current color scheme
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: spacing) {
            // First row (1-2-3)
            HStack(spacing: spacing) {
                numpadButton(number: 1)
                numpadButton(number: 2)
                numpadButton(number: 3)
            }
            
            // Second row (4-5-6)
            HStack(spacing: spacing) {
                numpadButton(number: 4)
                numpadButton(number: 5)
                numpadButton(number: 6)
            }
            
            // Third row (7-8-9)
            HStack(spacing: spacing) {
                numpadButton(number: 7)
                numpadButton(number: 8)
                numpadButton(number: 9)
            }
            
            // Fourth row (alt-0-delete)
            HStack(spacing: spacing) {
                // Alternative button or spacer
                if let iconName = alternativeButtonIcon, let action = alternativeButtonAction {
                    Button(action: action) {
                        Image(systemName: iconName)
                            .font(.system(size: 23))
                            .foregroundColor(appState.currentTheme.primaryColor)
                            .frame(width: buttonSize, height: buttonSize)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                            .overlay(
                                Circle()
                                    .stroke(appState.currentTheme.primaryColor.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Spacer()
                        .frame(width: buttonSize, height: buttonSize)
                }
                
                // Zero button
                numpadButton(number: 0)
                
                // Delete button
                Button(action: onDeleteTapped) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 23))
                        .foregroundColor(.primary)
                        .frame(width: buttonSize, height: buttonSize)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Components
    
    /// Creates a numpad button for a specific digit
    private func numpadButton(number: Int) -> some View {
        Button(action: {
            onDigitTapped(number)
        }) {
            Text("\(number)")
                .font(.system(size: 23, weight: .medium, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    ZStack {
                        // Main background
                        Circle()
                            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        // Subtle gradient overlay
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                                        Color.white.opacity(0.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(0.85)
                    }
                )
                .overlay(
                    Circle()
                        .stroke(
                            pressedButton == number ?
                            appState.currentTheme.primaryColor.opacity(0.5) :
                                Color.gray.opacity(0.2),
                            lineWidth: pressedButton == number ? 2 : 1
                        )
                )
                .scaleEffect(pressedButton == number ? 0.9 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1), value: pressedButton == number)
        }
        .buttonStyle(PlainButtonStyle())
    }
    // MARK: - Preview
    
    struct NumpadView_Previews: PreviewProvider {
        static var previews: some View {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    NumpadView(
                        onDigitTapped: { digit in print("Tapped \(digit)") },
                        onDeleteTapped: { print("Delete tapped") },
                        alternativeButtonAction: { print("Alternative tapped") },
                        alternativeButtonIcon: "faceid",
                        pressedButton: nil
                    )
                }
                .padding()
            }
            .environmentObject(AppState())
        }
    }
}
