// ClerkAuthService.swift
// SurgiTrack
// Service wrapper for Clerk authentication
// Created by Cascade AI

import Foundation
import ClerkSDK // This import assumes Clerk Swift SDK is added via SPM

/// A service that wraps Clerk authentication APIs for login, signup, and session management.
class ClerkAuthService {
    static let shared = ClerkAuthService()
    
    private init() {
        // Configure Clerk SDK with your publishable key
        Clerk.configure(publishableKey: "pk_test_Y3VyaW91cy1jYXR0bGUtOTUuY2xlcmsuYWNjb3VudHMuZGV2JA")
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Clerk.shared.signUp(email: email, password: password) { result in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Clerk.shared.signIn(email: email, password: password) { result in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        Clerk.shared.signOut { result in
            switch result {
            case .success(_):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Session
    func isSignedIn() -> Bool {
        return Clerk.shared.isSignedIn
    }
    
    func getCurrentUserEmail() -> String? {
        return Clerk.shared.currentUser?.email
    }
}

// NOTE: You must add Clerk Swift SDK to your project using Swift Package Manager.
// In Xcode: File > Add Packages... > https://github.com/clerkinc/clerk-ios
// After adding the package, replace 'ClerkSDK' with the correct module name if needed.
