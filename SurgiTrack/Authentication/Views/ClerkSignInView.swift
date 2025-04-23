// ClerkSignInView.swift
// SurgiTrack
// SwiftUI wrapper for Clerk's SignInViewController
// Created by Cascade AI

import SwiftUI
import ClerkSDK

/// A SwiftUI view that presents Clerk's prebuilt SignInViewController for user login.
struct ClerkSignInView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        // Create Clerk's SignInViewController
        let signInVC = SignInViewController()
        // Add a text logo at the top using a UILabel overlay
        let logoLabel = UILabel()
        logoLabel.text = "SurgiTrack™"
        logoLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        logoLabel.textAlignment = .center
        logoLabel.textColor = UIColor.systemBlue
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        signInVC.view.addSubview(logoLabel)
        NSLayoutConstraint.activate([
            logoLabel.topAnchor.constraint(equalTo: signInVC.view.safeAreaLayoutGuide.topAnchor, constant: 28),
            logoLabel.centerXAnchor.constraint(equalTo: signInVC.view.centerXAnchor)
        ])
        return signInVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No-op
    }
}

// Usage: Present ClerkSignInView() in a sheet or navigation stack from your SwiftUI view.
