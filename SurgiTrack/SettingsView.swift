// Updated SettingsView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState
    @State private var showingLogoutAlert = false
    @State private var showingBiometricsAlert = false
    @State private var showingResetAlert = false
    @State private var isResetInProgress = false
    
    // Access AuthManager settings indirectly through UserDefaults
    private var authManager: AuthManager {
        return AuthManager()
    }
    
    private var biometricsType: AuthManager.BiometricType {
        return authManager.biometricType
    }
    
    @State private var biometricsEnabled: Bool = UserDefaults.standard.string(forKey: "authMethod") == AuthManager.AuthMethod.biometric.rawValue
    
    @State private var rememberLoginEnabled: Bool = UserDefaults.standard.bool(forKey: "rememberMe")
    
    var body: some View {
        NavigationView {
            List {
                // Appearance settings
                Section(header: Text("Appearance")) {
                    // Theme picker
                    NavigationLink(destination: ThemeSettingsView()) {
                        HStack {
                            Label("Theme", systemImage: "paintpalette")
                            
                            Spacer()
                            
                            Circle()
                                .fill(appState.currentTheme.primaryColor)
                                .frame(width: 20, height: 20)
                        }
                    }
                    
                    // Dark mode toggle
                    Picker("Appearance", selection: $appState.colorScheme.animation()) {
                        Text("System").tag(nil as ColorScheme?)
                        Text("Light").tag(ColorScheme.light as ColorScheme?)
                        Text("Dark").tag(ColorScheme.dark as ColorScheme?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Authentication settings
                Section(header: Text("Authentication")) {
                    // Biometric login
                    if biometricsType != .none {
                        Toggle(biometricsType == .faceID ? "Face ID Login" : "Touch ID Login", isOn: $biometricsEnabled)
                            .onChange(of: biometricsEnabled) { newValue in
                                if newValue {
                                    authenticateBiometrics()
                                } else {
                                    UserDefaults.standard.set(AuthManager.AuthMethod.credentials.rawValue, forKey: "authMethod")
                                }
                            }
                    }
                    
                    // PIN management
                    NavigationLink(destination: PINManagementView()) {
                        Label("PIN Settings", systemImage: "lock.shield")
                    }
                }
                
                // Security settings
                Section(header: Text("Security")) {
                    Toggle("Remember Login", isOn: $rememberLoginEnabled)
                        .onChange(of: rememberLoginEnabled) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "rememberMe")
                        }
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Label("Reset Security Settings", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.red)
                    }
                }
                
                // Application settings
                Section(header: Text("Application")) {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink(destination: DataPrivacyView()) {
                        Label("Privacy & Data", systemImage: "hand.raised")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Label("About SurgiTrack", systemImage: "info.circle")
                    }
                }
                
                // Logout section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .overlay(
                Group {
                    if isResetInProgress {
                        ProgressView("Resetting settings...")
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 10)
                            )
                    }
                }
            )
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out of SurgiTrack?"),
                    primaryButton: .destructive(Text("Log Out")) {
                        logout()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Reset Security Settings"),
                    message: Text("This will clear all your security settings including PIN, biometrics, and saved credentials. You'll need to set them up again."),
                    primaryButton: .destructive(Text("Reset")) {
                        resetSecuritySettings()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // MARK: - Methods
    
    private func authenticateBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Confirm to enable biometric login"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        UserDefaults.standard.set(AuthManager.AuthMethod.biometric.rawValue, forKey: "authMethod")
                    } else {
                        // Reset toggle if authentication fails
                        self.biometricsEnabled = false
                        self.showingBiometricsAlert = true
                    }
                }
            }
        } else {
            biometricsEnabled = false
            showingBiometricsAlert = true
        }
    }
    
    private func resetSecuritySettings() {
        isResetInProgress = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Clear all security settings
            authManager.clearSavedCredentials()
            
            // Reset state variables
            biometricsEnabled = false
            rememberLoginEnabled = false
            
            isResetInProgress = false
        }
    }
    
    private func logout() {
        // Log out using AuthManager
        authManager.logout()
        
        // Notify app to show login view
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        
        // Reset app state
        appState.resetUserState()
        
        // Dismiss settings view
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Views

struct ThemeSettingsView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        List {
            ForEach(AppTheme.allCases) { theme in
                Button(action: {
                    appState.setTheme(theme)
                }) {
                    HStack {
                        Circle()
                            .fill(theme.primaryColor)
                            .frame(width: 24, height: 24)
                        
                        Text(theme.rawValue.capitalized)
                            .padding(.leading, 8)
                        
                        Spacer()
                        
                        if appState.currentTheme == theme {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Theme")
    }
}

struct PINManagementView: View {
    @State private var showingPINCreation = false
    @State private var showingConfirmation = false
    
    var body: some View {
        List {
            Button(action: {
                showingPINCreation = true
            }) {
                Label("Change PIN", systemImage: "key")
            }
            
            Button(action: {
                showingConfirmation = true
            }) {
                Label("Remove PIN", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("PIN Settings")
        .alert(isPresented: $showingConfirmation) {
            Alert(
                title: Text("Remove PIN"),
                message: Text("Are you sure you want to remove your PIN? You'll need to use your credentials to log in."),
                primaryButton: .destructive(Text("Remove")) {
                    // Remove PIN logic
                    UserDefaults.standard.removeObject(forKey: "pinHash")
                    UserDefaults.standard.set(AuthManager.AuthMethod.credentials.rawValue, forKey: "authMethod")
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingPINCreation) {
            PinCreationView(authManager: AuthManager())
                .environmentObject(AppState())
        }
    }
}

struct NotificationSettingsView: View {
    @State private var appointmentReminders = true
    @State private var surgeryAlerts = true
    @State private var patientUpdates = true
    @State private var systemNotifications = true
    
    var body: some View {
        List {
            Section(header: Text("Alerts")) {
                Toggle("Appointment Reminders", isOn: $appointmentReminders)
                Toggle("Surgery Alerts", isOn: $surgeryAlerts)
                Toggle("Patient Updates", isOn: $patientUpdates)
                Toggle("System Notifications", isOn: $systemNotifications)
            }
            
            Section(header: Text("Timing")) {
                NavigationLink(destination: NotificationScheduleView()) {
                    Text("Notification Schedule")
                }
                
                NavigationLink(destination: QuietHoursView()) {
                    Text("Quiet Hours")
                }
            }
        }
        .navigationTitle("Notifications")
    }
}

struct DataPrivacyView: View {
    var body: some View {
        List {
            Section(header: Text("Data Collection")) {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Text("Privacy Policy")
                }
                
                NavigationLink(destination: DataUsageView()) {
                    Text("Data Usage")
                }
            }
            
            Section(header: Text("Data Management")) {
                NavigationLink(destination: ExportDataView()) {
                    Text("Export Your Data")
                }
                
                Button(action: {
                    // Clear cache logic
                    let alert = UIAlertController(title: "Clear Cache", message: "This will remove all temporary files and cached data. Your patient records will not be affected.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
                        // Simulate clearing cache
                        // In a real app, this would clear the actual cache
                    })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    
                    // Present the alert
                    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
                }) {
                    Text("Clear Cache")
                }
            }
        }
        .navigationTitle("Privacy & Data")
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: "stethoscope.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("SurgiTrack")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0 (Build 25)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Section(header: Text("Information")) {
                NavigationLink(destination: TermsOfServiceView()) {
                    Text("Terms of Service")
                }
                
                NavigationLink(destination: LicenseAgreementView()) {
                    Text("License Agreement")
                }
                
                NavigationLink(destination: ThirdPartySoftwareView()) {
                    Text("Third-Party Software")
                }
            }
            
            Section(header: Text("Support")) {
                NavigationLink(destination: ContactSupportView()) {
                    Text("Contact Support")
                }
                
                NavigationLink(destination: ReportBugView()) {
                    Text("Report a Bug")
                }
                
                Button(action: {
                    // Rate app logic
                    // In a real app, this would open the App Store rating page
                    let alert = UIAlertController(title: "App Store Rating", message: "This would normally open the App Store for you to rate the app.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    
                    // Present the alert
                    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
                }) {
                    Text("Rate SurgiTrack")
                }
            }
        }
        .navigationTitle("About SurgiTrack")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
                .environmentObject(AppState())
            
            SettingsView()
                .environmentObject(AppState())
                .preferredColorScheme(.dark)
        }
    }
}
