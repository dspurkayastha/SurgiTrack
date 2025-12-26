// SettingsView.swift
// SurgiTrack
// Updated on 26/12/2025 - Fixed deprecated APIs, modern SwiftUI alerts

import SwiftUI
import LocalAuthentication
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var showingLogoutAlert = false
    @State private var showingBiometricsAlert = false
    @State private var showingResetAlert = false
    @State private var showingCacheAlert = false
    @State private var showingRateAlert = false
    @State private var isResetInProgress = false

    // Access AuthManager
    @StateObject private var authManager = AuthManager()

    @State private var biometricsEnabled: Bool = false
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
                    if authManager.biometricType != .none {
                        Toggle(authManager.biometricType == .faceID ? "Face ID Login" : "Touch ID Login", isOn: $biometricsEnabled)
                            .onChange(of: biometricsEnabled) { _, newValue in
                                if newValue {
                                    authenticateBiometrics()
                                } else {
                                    authManager.enableBiometric(false)
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
                        .onChange(of: rememberLoginEnabled) { _, newValue in
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
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
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Log Out", role: .destructive) {
                    logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out of SurgiTrack?")
            }
            .alert("Reset Security Settings", isPresented: $showingResetAlert) {
                Button("Reset", role: .destructive) {
                    resetSecuritySettings()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all your security settings including PIN, biometrics, and saved credentials. You'll need to set them up again.")
            }
            .onAppear {
                biometricsEnabled = authManager.isBiometricEnabled()
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
                        authManager.enableBiometric(true)
                        Logger.auth("Biometric login enabled")
                    } else {
                        // Reset toggle if authentication fails
                        self.biometricsEnabled = false
                        self.showingBiometricsAlert = true
                        Logger.auth("Biometric enable failed: \(error?.localizedDescription ?? "unknown")", level: .warning)
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
        Logger.auth("Resetting security settings")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Clear all security settings
            authManager.clearSavedCredentials()

            // Reset state variables
            biometricsEnabled = false
            rememberLoginEnabled = false

            isResetInProgress = false
            Logger.auth("Security settings reset complete")
        }
    }

    private func logout() {
        Logger.auth("User initiated logout")

        // Log out using AuthManager
        authManager.logout()

        // Notify app to show login view
        UserDefaults.standard.set(false, forKey: "isAuthenticated")

        // Reset app state
        appState.resetUserState()

        // Dismiss settings view
        dismiss()
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
    @StateObject private var authManager = AuthManager()

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
        .alert("Remove PIN", isPresented: $showingConfirmation) {
            Button("Remove", role: .destructive) {
                // Remove PIN using KeychainManager
                do {
                    try KeychainManager.shared.delete(key: .pinHash)
                    try KeychainManager.shared.delete(key: .pinSalt)
                    Logger.auth("PIN removed")
                } catch {
                    Logger.error("Failed to remove PIN", error: error, category: .security)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove your PIN? You'll need to use your credentials to log in.")
        }
        .sheet(isPresented: $showingPINCreation) {
            PinCreationView(authManager: authManager)
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
    @State private var showingCacheAlert = false
    @State private var cacheCleared = false

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
                    showingCacheAlert = true
                }) {
                    HStack {
                        Text("Clear Cache")
                        Spacer()
                        if cacheCleared {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle("Privacy & Data")
        .alert("Clear Cache", isPresented: $showingCacheAlert) {
            Button("Clear", role: .destructive) {
                clearCache()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all temporary files and cached data. Your patient records will not be affected.")
        }
    }

    private func clearCache() {
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()

        // Clear temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) {
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
        }

        Logger.info("Cache cleared", category: .general)
        cacheCleared = true

        // Reset after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            cacheCleared = false
        }
    }
}

struct AboutView: View {
    @State private var showingRateAlert = false

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

                    Text("Version \(Configuration.App.fullVersion)")
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
                    requestAppReview()
                }) {
                    Text("Rate SurgiTrack")
                }
            }
        }
        .navigationTitle("About SurgiTrack")
    }

    private func requestAppReview() {
        // Use the modern SKStoreReviewController API
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
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
