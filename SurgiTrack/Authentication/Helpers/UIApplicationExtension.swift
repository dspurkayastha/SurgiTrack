//
//  UIApplicationExtension.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//

import SwiftUI

// Extension to simulate user interaction with text fields
extension UIApplication {
    static func simulateTextFieldInteraction(retryCount: Int = 0) {
        print("DEBUG: Simulating text field interaction (attempt \(retryCount+1))")
        
        // Create a hidden text field
        let textField = UITextField()
        
        // Configure to prevent keyboard from showing
        textField.autocorrectionType = .no
        textField.keyboardType = .emailAddress // Less likely to show predictive text
        textField.keyboardAppearance = .default
        textField.returnKeyType = .done
        textField.isSecureTextEntry = false // Prevents additional UI
        
        // Make it invisible
        textField.alpha = 0.0
        textField.textColor = .clear
        textField.tintColor = .clear
        textField.backgroundColor = .clear
        
        // Configure to suppress keyboard
        textField.inputView = UIView() // Empty custom input view prevents keyboard
        textField.inputAccessoryView = nil
        
        // Add it to the application's key window
        let currentWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
        currentWindow?.addSubview(textField)
        
        // Position off-screen to be extra safe
        textField.frame = CGRect(x: -100, y: -100, width: 1, height: 1)
        
        // Focus and unfocus to trigger the same rendering update as user interaction
        // WITHOUT showing keyboard
        textField.becomeFirstResponder()
        
        // Longer delay for more reliable processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            textField.resignFirstResponder()
            
            // Clean up after ourselves
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                textField.removeFromSuperview()
                print("DEBUG: Text field interaction simulation complete")
            }
        }
    }
}

