// ClerkSignInView.swift
// SurgiTrack
// Native SwiftUI Clerk sign-in view
// Created by Cascade AI

import SwiftUI
import Clerk

/// A SwiftUI view that presents Clerk's sign-in page for user login.
struct ClerkSignInView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            // App Title as Text Logo
            Text("SurgiTrack")
                .font(.largeTitle.bold())
                .foregroundColor(appState.currentTheme.primaryColor)
                .padding(.top, 32)

            Text("Sign in to your account")
                .font(.title2)
                .foregroundColor(.secondary)

            // Clerk's prebuilt sign-in view (2025 SDK)
            SignInView(
                appearance: .init(
                    primaryColor: appState.currentTheme.primaryColor,
                    backgroundColor: colorScheme == .dark ? .black : .white,
                    cornerRadius: 14
                ),
                showSocialButtons: true,
                onSignIn: { session in
                    // Optionally handle successful sign-in
                },
                onError: { error in
                    // Optionally handle error
                }
            )
            .frame(maxWidth: 400)
            .padding()

            Spacer()
        }
        .background(
            (colorScheme == .dark ? Color.black : Color(.systemGroupedBackground)).ignoresSafeArea()
        )
    }
}

// Usage: Present ClerkSignInView() in a sheet or navigation stack from your SwiftUI view.
