//
//  UIApplicationExtension.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//  Updated on 26/12/2025 - Fixed deprecated APIs for iOS 17+

import SwiftUI

// Extension to simulate user interaction with text fields
extension UIApplication {

    /// Gets the key window using the modern scene-based approach
    static var keyWindow: UIWindow? {
        // Use the modern scene-based approach for iOS 15+
        return UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    /// Gets the root view controller from the key window
    static var rootViewController: UIViewController? {
        return keyWindow?.rootViewController
    }

    static func simulateTextFieldInteraction(retryCount: Int = 0) {
        Logger.debug("Simulating text field interaction (attempt \(retryCount+1))", category: .ui)

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

        // Add it to the application's key window using modern approach
        guard let currentWindow = UIApplication.keyWindow else {
            Logger.warning("No key window available for text field simulation", category: .ui)
            return
        }
        currentWindow.addSubview(textField)

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
                Logger.debug("Text field interaction simulation complete", category: .ui)
            }
        }
    }
}
