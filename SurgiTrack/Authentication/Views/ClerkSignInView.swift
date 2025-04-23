// ClerkSignInView.swift
// SurgiTrack
// Native SwiftUI Clerk sign-in view
// Created by Cascade AI

import SwiftUI
import Clerk

/// A SwiftUI view that presents Clerk's sign-in page for user login.
struct ClerkSignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var error: String? = nil
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign In")
                .font(.title.bold())
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
            }
            Button(action: {
                Task { await signIn() }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Continue")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(isLoading)
        }
        .padding()
    }

    func signIn() async {
        isLoading = true
        do {
            try await SignIn.create(strategy: .identifier(email, password: password))
            error = nil
        } catch {
            self.error = "Sign in failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// Usage: Present ClerkSignInView() in a sheet or navigation stack from your SwiftUI view.
