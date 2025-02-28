//
//  CredentialsLoginView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 20/03/25.
//


// CredentialsLoginView.swift
// SurgiTrack
// Refactored on 03/20/2025

import SwiftUI

struct CredentialsLoginView: View {
    // MARK: - Bindings
    @Binding var username: String
    @Binding var password: String
    @Binding var rememberMe: Bool
    
    // MARK: - Properties
    var onLogin: () -> Void
    
    // MARK: - UI State
    @State private var usernameFieldFocused = false
    @State private var passwordFieldFocused = false
    @State private var isPasswordVisible = false
    
    // MARK: - Environment
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 15) {
            // MARK: - Header
            AuthHeaderView(
                style: .credentials,
                title: "Welcome Back",
                subtitle: "Sign in to your account",
                iconName: "person.fill",
                animationProgress: 1.0,
                animating: true
            )
            .padding(.bottom, 10)
            
            // MARK: - Login Form
            GlassmorphicCard {
                VStack(spacing: 20) {
                    // Username field
                    inputField(
                        title: "Username",
                        text: $username,
                        iconName: "person.fill",
                        isFocused: usernameFieldFocused,
                        isSecure: false,
                        onFocusChange: { focused in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                usernameFieldFocused = focused
                                if focused {
                                    passwordFieldFocused = false
                                }
                            }
                        }
                    )
                    
                    // Password field
                    inputField(
                        title: "Password",
                        text: $password,
                        iconName: "lock.fill",
                        isFocused: passwordFieldFocused,
                        isSecure: !isPasswordVisible,
                        trailingIcon: isPasswordVisible ? "eye.slash.fill" : "eye.fill",
                        trailingAction: {
                            withAnimation {
                                isPasswordVisible.toggle()
                            }
                            HapticFeedback.buttonPress()
                        },
                        onFocusChange: { focused in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                passwordFieldFocused = focused
                                if focused {
                                    usernameFieldFocused = false
                                }
                            }
                        }
                    )
                    
                    // Remember me toggle with custom styling
                    enhancedToggle("Remember me", isOn: $rememberMe)
                        .padding(.top, 4)
                    
                    // Login button
                    Button(action: {
                        HapticFeedback.buttonPress()
                        // Dismiss keyboard
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onLogin()
                    }) {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                appState.currentTheme.primaryColor,
                                                appState.currentTheme.secondaryColor
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: appState.currentTheme.primaryColor.opacity(0.5), radius: 8, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(username.isEmpty || password.isEmpty)
                    .opacity(username.isEmpty || password.isEmpty ? 0.7 : 1)
                    
                    Divider()
                        .padding(.vertical)
                    
                    // Help options with enhanced styling
                    HStack(spacing: 20) {
                        Button(action: {
                            // Would navigate to password reset flow
                            HapticFeedback.buttonPress()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 12))
                                Text("Forgot Password?")
                            }
                            .font(.subheadline)
                            .foregroundColor(appState.currentTheme.primaryColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            // Would navigate to registration flow
                            HapticFeedback.buttonPress()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 12))
                                Text("Register")
                            }
                            .font(.subheadline)
                            .foregroundColor(appState.currentTheme.primaryColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Custom Components
    
    // Custom input field with floating label
    private func inputField(
        title: String,
        text: Binding<String>,
        iconName: String,
        isFocused: Bool,
        isSecure: Bool,
        trailingIcon: String? = nil,
        trailingAction: (() -> Void)? = nil,
        onFocusChange: @escaping (Bool) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(isFocused ? appState.currentTheme.primaryColor : .secondary)
                .opacity(text.wrappedValue.isEmpty && !isFocused ? 0 : 1)
                .offset(y: text.wrappedValue.isEmpty && !isFocused ? 20 : 0)
                .animation(.easeOut(duration: 0.2), value: isFocused)
                .animation(.easeOut(duration: 0.2), value: text.wrappedValue.isEmpty)
            
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(isFocused ? appState.currentTheme.primaryColor : .secondary)
                    .font(.system(size: 16))
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty && !isFocused {
                        Text(title)
                            .foregroundColor(.secondary)
                    }
                    
                    if isSecure {
                        SecureField("", text: text)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(.password)
                            .onTapGesture {
                                onFocusChange(true)
                            }
                    } else {
                        TextField("", text: text)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .textContentType(iconName == "person.fill" ? .username : .password)
                            .onTapGesture {
                                onFocusChange(true)
                            }
                    }
                }
                
                if let trailingIcon = trailingIcon, let trailingAction = trailingAction {
                    Button(action: trailingAction) {
                        Image(systemName: trailingIcon)
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.secondarySystemBackground))
                    .shadow(color: isFocused ? appState.currentTheme.primaryColor.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused
                        ? appState.currentTheme.primaryColor
                        : Color.gray.opacity(0.2),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
    
    // Custom toggle with better styling
    private func enhancedToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Button(action: {
            isOn.wrappedValue.toggle()
            HapticFeedback.buttonPress()
        }) {
            HStack {
                Image(systemName: isOn.wrappedValue ? "checkmark.square.fill" : "square")
                    .foregroundColor(isOn.wrappedValue ? appState.currentTheme.primaryColor : .secondary)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}