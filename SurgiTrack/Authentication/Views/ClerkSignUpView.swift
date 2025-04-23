// ClerkSignUpView.swift
// SurgiTrack
// SwiftUI wrapper for Clerk's SignUpViewController
// Created by Cascade AI

import SwiftUI
import ClerkSDK

/// A SwiftUI view that presents Clerk's prebuilt SignUpViewController for user registration.
struct ClerkSignUpView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        // Create Clerk's SignUpViewController
        let signUpVC = SignUpViewController()
        // Add a text logo at the top using a UILabel overlay
        let logoLabel = UILabel()
        logoLabel.text = "SurgiTrack™"
        logoLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        logoLabel.textAlignment = .center
        logoLabel.textColor = UIColor.systemBlue
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        signUpVC.view.addSubview(logoLabel)
        NSLayoutConstraint.activate([
            logoLabel.topAnchor.constraint(equalTo: signUpVC.view.safeAreaLayoutGuide.topAnchor, constant: 28),
            logoLabel.centerXAnchor.constraint(equalTo: signUpVC.view.centerXAnchor)
        ])
        return signUpVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No-op
    }
}

// Usage: Present ClerkSignUpView() in a sheet or navigation stack from your SwiftUI view.
