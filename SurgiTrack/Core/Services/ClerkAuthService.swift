// ClerkAuthService.swift
// SurgiTrack
// Service wrapper for Clerk authentication
// Created by Cascade AI

import Foundation
import Clerk // This import assumes Clerk Swift SDK is added via SPM

/// A service that wraps Clerk authentication APIs for login, signup, and session management.
class ClerkAuthService {
    static let shared = ClerkAuthService()
    
    private init() {
        // Configure Clerk SDK with your publishable key
        Clerk.configure(publishableKey: "pk_test_Y3VyaW91cy1jYXR0bGUtOTUuY2xlcmsuYWNjb3VudHMuZGV2JA")
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String) async throws {
        _ = try await SignUp.create(strategy: .standard(emailAddress: email, password: password))
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        try await SignIn.create(strategy: .identifier(email, password: password))
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        try await Clerk.shared.signOut()
    }
    
    // MARK: - Session
    func isSignedIn() async -> Bool {
        return try await Clerk.shared.isUserSignedIn()
    }
    
    func getCurrentUserEmail() async -> String? {
        return try? await Clerk.shared.getCurrentUser()?.email
    }
}

// NOTE: You must add Clerk Swift SDK to your project using Swift Package Manager.
// In Xcode: File > Add Packages... > https://github.com/clerkinc/clerk-ios
// After adding the package, replace 'Clerk' with the correct module name if needed.
