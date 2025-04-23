// ClerkSignUpView.swift
// SurgiTrack
// SwiftUI wrapper for Clerk's hosted sign-up page
// Created by Cascade AI

import SwiftUI
import WebKit

/// A SwiftUI view that presents Clerk's hosted sign-up page for user registration.
struct ClerkSignUpView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let url = URL(string: "https://YOUR-CLERK-SUBDOMAIN.clerk.accounts.dev/sign-up")!
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op
    }
}

// Usage: Present ClerkSignUpView() in a sheet or navigation stack from your SwiftUI view.
