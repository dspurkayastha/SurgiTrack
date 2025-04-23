// ClerkSignInView.swift
// SurgiTrack
// SwiftUI wrapper for Clerk's hosted sign-in page
// Created by Cascade AI

import SwiftUI
import WebKit

/// A SwiftUI view that presents Clerk's hosted sign-in page for user login.
struct ClerkSignInView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let url = URL(string: "https://YOUR-CLERK-SUBDOMAIN.clerk.accounts.dev/sign-in")!
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op
    }
}

// Usage: Present ClerkSignInView() in a sheet or navigation stack from your SwiftUI view.
