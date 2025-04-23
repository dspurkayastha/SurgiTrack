// ClerkSignUpView.swift
// SurgiTrack
// Native SwiftUI Clerk sign-up logic
// Created by Cascade AI

import SwiftUI
import Clerk

/// A SwiftUI view that presents Clerk's hosted sign-up page for user registration.
struct ClerkSignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var code = ""
    @State private var isVerifying = false
    @State private var error: String? = nil
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Sign Up")
                .font(.title.bold())
            if isVerifying {
                TextField("Verification Code", text: $code)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                Button("Verify") {
                    Task { await verify(code: code) }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
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
                Button("Continue") {
                    Task { await signUp(email: email, password: password) }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            if let error = error {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        do {
            let signUp = try await SignUp.create(strategy: .standard(emailAddress: email, password: password))
            isVerifying = true
            error = nil
        } catch {
            self.error = "Sign up failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func verify(code: String) async {
        isLoading = true
        do {
            guard let signUp = Clerk.shared.client?.signUp else {
                error = "Sign up session not found."
                isVerifying = false
                isLoading = false
                return
            }
            try await signUp.attemptVerification(strategy: .emailCode(code: code))
            error = nil
        } catch {
            self.error = "Verification failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// Usage: Present ClerkSignUpView() in a sheet or navigation stack from your SwiftUI view.
