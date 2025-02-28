//
//  PinCreationViewModel.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// PinCreationViewModel.swift
// SurgiTrack
// Created for refactoring on 03/20/2025

import SwiftUI
import Combine

class PinCreationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // PIN states
    @Published var pin = ""
    @Published var confirmPin = ""
    @Published var pinCircleFills: [CGFloat] = Array(repeating: 0, count: 6)
    @Published var pinLength = 6
    @Published var currentStep: CreationStep = .enterPin
    
    // Animation states
    @Published var animationCoordinator = AnimationCoordinator()
    @Published var wrongPinAttempt = false
    @Published var pinStrengthRingProgress: CGFloat = 0
    @Published var pinDisplayScale = 0.95
    @Published var stepChangeAnimation = false
    @Published var pressedButton: Int? = nil
    
    // Alert states
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isSuccess = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let authManager: AuthManager
    
    // MARK: - Creation Steps
    
    enum CreationStep {
        case enterPin
        case confirmPin
    }
    
    // MARK: - Initialization
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Start entry animations
    func startEntryAnimations() {
        animationCoordinator.startEntryAnimations()
    }
    
    /// Handle digit entry
    func addDigit(_ digit: String) {
        // Track pressed button for animation
        if let digitInt = Int(digit) {
            pressedButton = digitInt
            
            // Clear pressed state after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.pressedButton = nil
            }
        }
        
        HapticFeedback.pinDigitEntry()
        
        if currentStep == .enterPin {
            handleEnterPinDigit(digit)
        } else {
            handleConfirmPinDigit(digit)
        }
    }
    
    /// Delete last entered digit
    func deleteLastDigit() {
        guard getCurrentInput().isEmpty == false else { return }
        
        HapticFeedback.buttonPress()
        
        if currentStep == .enterPin {
            // Animate clearing the last circle
            withAnimation(.easeInOut(duration: 0.2)) {
                pinCircleFills[pin.count - 1] = 0
            }
            pin.removeLast()
            
            // Update strength visualization
            updatePinStrengthProgress()
        } else {
            // Animate clearing the last circle
            withAnimation(.easeInOut(duration: 0.2)) {
                pinCircleFills[confirmPin.count - 1] = 0
            }
            confirmPin.removeLast()
        }
    }
    
    /// Clear current PIN input
    func clearPin() {
        HapticFeedback.buttonPress()
        
        // Animate clearing the circles
        withAnimation(.easeInOut(duration: 0.2)) {
            for i in 0..<pinCircleFills.count {
                if i < getCurrentInputLength() {
                    pinCircleFills[i] = 0
                }
            }
        }
        
        if currentStep == .enterPin {
            pin = ""
            // Update strength visualization
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                pinStrengthRingProgress = 0
            }
        } else {
            confirmPin = ""
        }
    }
    
    /// Handle continue/submit action
    func handleContinue() {
        HapticFeedback.buttonPress()
        
        if currentStep == .enterPin {
            validateFirstPin()
        } else {
            confirmAndSavePin()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe PIN changes for strength calculation
        $pin
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updatePinStrengthProgress()
            }
            .store(in: &cancellables)
    }
    
    private func handleEnterPinDigit(_ digit: String) {
        if pin.count < pinLength {
            pin.append(digit)
            
            // Animate filling the circle
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3)) {
                pinCircleFills[pin.count-1] = 1.0
            }
            
            // Update PIN strength visualization
            updatePinStrengthProgress()
            
            // Auto-continue when PIN is complete and strong enough
            if pin.count == pinLength && pinStrength >= 2 {
                // Provide a slight delay to show the PIN before moving to confirmation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.transitionToConfirmStep()
                }
            }
        }
    }
    
    private func handleConfirmPinDigit(_ digit: String) {
        if confirmPin.count < pinLength {
            confirmPin.append(digit)
            
            // Animate filling the circle
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.3)) {
                pinCircleFills[confirmPin.count-1] = 1.0
            }
            
            // Auto-complete when confirmPin is filled
            if confirmPin.count == pinLength {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.confirmAndSavePin()
                }
            }
        }
    }
    
    private func validateFirstPin() {
        if pin.count < pinLength {
            showAlert(title: "Incomplete PIN", message: "Please enter a \(pinLength)-digit PIN", isSuccess: false)
            return
        }
        
        if pinStrength < 2 {
            showAlert(title: "Weak PIN", message: "Please choose a stronger PIN. Avoid sequential or repeated digits.", isSuccess: false)
            return
        }
        
        transitionToConfirmStep()
    }
    
    private func confirmAndSavePin() {
        if confirmPin != pin {
            // Show error animation
            HapticFeedback.errorPattern()
            
            // Flash red and shake
            withAnimation(.easeInOut(duration: 0.2)) {
                for i in 0..<pinCircleFills.count {
                    pinCircleFills[i] = 1.2 // Slightly enlarge for emphasis
                }
                pinDisplayScale = 1.05
                wrongPinAttempt = true
            }
            
            // Shake animation
            let shakeSequence = [10, -10, 8, -8, 5, -5, 0]
            for (index, offset) in shakeSequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(index)) {
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.3, blendDuration: 0.1)) {
                        self.animationCoordinator.errorShakeOffset = CGFloat(offset)
                    }
                }
            }
            
            // Reset animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.pinDisplayScale = 1.0
                    self.animationCoordinator.errorShakeOffset = 0
                    self.wrongPinAttempt = false
                    
                    // Clear circles
                    for i in 0..<self.pinCircleFills.count {
                        self.pinCircleFills[i] = 0
                    }
                }
                
                // Reset and go back to first step
                self.confirmPin = ""
                self.showAlert(title: "PIN Mismatch", message: "PINs don't match. Please try again.", isSuccess: false)
                self.currentStep = .enterPin
            }
            
            return
        }
        
        // Attempt to save PIN
        let successfulSave = authManager.setPIN(pin)
        
        if successfulSave {
            // Success animation
            HapticFeedback.successPattern()
            
            // Pulse animation for circles
            withAnimation(.easeInOut(duration: 0.2).repeatCount(3, autoreverses: true)) {
                pinDisplayScale = 1.05
            }
            
            showAlert(title: "Success", message: "PIN successfully created!", isSuccess: true)
        } else {
            showAlert(title: "Error", message: "Failed to save PIN. Please try again.", isSuccess: false)
        }
    }
    
    private func transitionToConfirmStep() {
        // Create a 3D flip animation for the PIN circles
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            stepChangeAnimation = true
            // Clear fill animations
            for i in 0..<pinCircleFills.count {
                pinCircleFills[i] = 0
            }
        }
        
        // Change step after animation midpoint
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.currentStep = .confirmPin
        }
        
        // Complete the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                self.stepChangeAnimation = false
            }
        }
    }
    
    private func updatePinStrengthProgress() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            pinStrengthRingProgress = CGFloat(pinStrength) / 3.0
        }
    }
    
    private func showAlert(title: String, message: String, isSuccess: Bool) {
        self.alertTitle = title
        self.alertMessage = message
        self.isSuccess = isSuccess
        self.showAlert = true
    }
    
    // MARK: - Helper Functions
    
    /// Get current input value based on step
    private func getCurrentInput() -> String {
        return currentStep == .enterPin ? pin : confirmPin
    }
    
    /// Get current input length based on step
    func getCurrentInputLength() -> Int {
        return currentStep == .enterPin ? pin.count : confirmPin.count
    }
    
    // MARK: - PIN Strength Calculation
    
    /// Calculate PIN strength (0-3)
    private var pinStrength: Int {
        if pin.isEmpty {
            return 0
        }
        
        var strength = 0
        
        // Basic checks
        if pin.count >= pinLength { strength += 1 }
        
        // Check for sequential digits (e.g., 1234, 4321)
        if !hasSequentialDigits(pin) { strength += 1 }
        
        // Check for repeated digits (e.g., 1111, 2222)
        if !hasRepeatedDigits(pin) { strength += 1 }
        
        return strength
    }
    
    /// Pin strength text
    var pinStrengthText: String {
        if pin.isEmpty {
            return "Empty"
        }
        
        switch pinStrength {
        case 0, 1: return "Weak"
        case 2: return "Moderate"
        case 3: return "Strong"
        default: return "Weak"
        }
    }
    
    /// Pin strength color
    var pinStrengthColor: Color {
        if pin.isEmpty {
            return .gray
        }
        
        switch pinStrength {
        case 0, 1: return .red
        case 2: return .orange
        case 3: return .green
        default: return .red
        }
    }
    
    /// Feedback criteria for PIN
    var pinFeedback: [String] {
        var feedback = ["\(pinLength) digits minimum"]
        
        if pin.count >= 3 {
            feedback.append("No sequential digits")
            feedback.append("No repeated digits")
        }
        
        return feedback
    }
    
    /// Check if PIN criteria has issue
    func hasPinIssue(_ feedback: String) -> Bool {
        switch feedback {
        case "\(pinLength) digits minimum":
            return pin.count < pinLength
        case "No sequential digits":
            return hasSequentialDigits(pin)
        case "No repeated digits":
            return hasRepeatedDigits(pin)
        default:
            return false
        }
    }
    
    // MARK: - PIN Validation Methods
    
    private func hasSequentialDigits(_ pin: String) -> Bool {
        guard pin.count >= 3 else { return false }
        
        let digits = pin.compactMap { Int(String($0)) }
        
        for i in 0..<(digits.count - 2) {
            // Check for ascending sequence
            if digits[i] + 1 == digits[i+1] && digits[i+1] + 1 == digits[i+2] {
                return true
            }
            
            // Check for descending sequence
            if digits[i] - 1 == digits[i+1] && digits[i+1] - 1 == digits[i+2] {
                return true
            }
        }
        
        return false
    }
    
    private func hasRepeatedDigits(_ pin: String) -> Bool {
        guard pin.count >= 2 else { return false }
        
        let digits = pin.compactMap { Int(String($0)) }
        
        // Check for 3 or more repeated digits
        for i in 0..<(digits.count - 2) {
            if digits[i] == digits[i+1] && digits[i+1] == digits[i+2] {
                return true
            }
        }
        
        // Check if all digits are the same
        if Set(digits).count == 1 {
            return true
        }
        
        return false
    }
}
