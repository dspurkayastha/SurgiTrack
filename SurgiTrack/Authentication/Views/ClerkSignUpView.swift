// ClerkSignUpView.swift
// SurgiTrack
// Native SwiftUI Clerk sign-up logic
// Created by Cascade AI

import SwiftUI
import Clerk

/// A SwiftUI view that presents Clerk's hosted sign-up page for user registration.
struct ClerkSignUpView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            // App Title as Text Logo
            Text("SurgiTrack")
                .font(.largeTitle.bold())
                .foregroundColor(appState.currentTheme.primaryColor)
                .padding(.top, 32)

            Text("Create your SurgiTrack account")
                .font(.title2)
                .foregroundColor(.secondary)

            // Clerk's prebuilt sign-up view (2025 SDK)
            SignUpView(
                appearance: .init(
                    primaryColor: appState.currentTheme.primaryColor,
                    backgroundColor: colorScheme == .dark ? .black : .white,
                    cornerRadius: 14
                ),
                showSocialButtons: true,
                onSignUp: { session in
                    // Optionally handle successful sign-up
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

// Usage: Present ClerkSignUpView() in a sheet or navigation stack from your SwiftUI view.
