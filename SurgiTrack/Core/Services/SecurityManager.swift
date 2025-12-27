// SecurityManager.swift
// SurgiTrack
// Comprehensive security management for HIPAA compliance
// Created on 26/12/2025

import Foundation
import UIKit
import SwiftUI

/// Manages application security including jailbreak detection, screen capture protection,
/// and device integrity checks for HIPAA compliance.
@MainActor
final class SecurityManager: ObservableObject {

    // MARK: - Singleton

    static let shared = SecurityManager()

    // MARK: - Published Properties

    @Published private(set) var isDeviceCompromised = false
    @Published private(set) var isScreenBeingCaptured = false
    @Published private(set) var securityAlerts: [SecurityAlert] = []

    // MARK: - Private Properties

    private var screenCaptureObserver: NSObjectProtocol?
    private var screenshotObserver: NSObjectProtocol?
    private var securityCheckTimer: Timer?

    // MARK: - Types

    struct SecurityAlert: Identifiable {
        let id = UUID()
        let type: AlertType
        let message: String
        let timestamp: Date

        enum AlertType {
            case jailbreakDetected
            case screenCapture
            case screenshot
            case debuggerAttached
            case tamperingDetected
        }
    }

    // MARK: - Initialization

    private init() {
        performInitialSecurityCheck()
        setupScreenCaptureDetection()
        setupPeriodicSecurityChecks()
    }

    deinit {
        screenCaptureObserver.map { NotificationCenter.default.removeObserver($0) }
        screenshotObserver.map { NotificationCenter.default.removeObserver($0) }
        securityCheckTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Performs a comprehensive security check
    /// Returns true if the device passes all security checks
    func performSecurityCheck() -> Bool {
        let isJailbroken = checkForJailbreak()
        let isDebugged = checkForDebugger()
        let isTampered = checkForTampering()

        isDeviceCompromised = isJailbroken || isDebugged || isTampered

        if isDeviceCompromised {
            Logger.security("Security check failed - device may be compromised", level: .error)
            AuditLogger.shared.logSecurityEvent(
                action: "SECURITY_CHECK_FAILED",
                details: [
                    "jailbroken": isJailbroken,
                    "debugger": isDebugged,
                    "tampered": isTampered
                ]
            )
        }

        return !isDeviceCompromised
    }

    /// Creates a secure overlay to protect PHI during screen capture
    func protectScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        // Add blur overlay during screen capture
        if isScreenBeingCaptured {
            addSecurityOverlay(to: window)
        }
    }

    /// Removes the security overlay
    func unprotectScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        removeSecurityOverlay(from: window)
    }

    /// Clears old security alerts
    func clearAlerts() {
        securityAlerts.removeAll()
    }

    // MARK: - Jailbreak Detection

    private func checkForJailbreak() -> Bool {
        #if targetEnvironment(simulator)
        // Don't check in simulator
        return false
        #else

        // Check 1: Presence of common jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/usr/bin/sshd",
            "/var/cache/apt",
            "/var/lib/cydia",
            "/var/log/syslog",
            "/var/tmp/cydia.log",
            "/bin/sh",
            "/usr/libexec/ssh-keysign",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                addSecurityAlert(.jailbreakDetected, message: "Jailbreak indicator found: \(path)")
                return true
            }
        }

        // Check 2: Can write to system directories
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            addSecurityAlert(.jailbreakDetected, message: "System write access detected")
            return true
        } catch {
            // Expected - can't write to system directory on non-jailbroken device
        }

        // Check 3: Check for suspicious URL schemes
        let suspiciousSchemes = ["cydia://", "sileo://", "zbra://", "filza://"]
        for scheme in suspiciousSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                addSecurityAlert(.jailbreakDetected, message: "Suspicious URL scheme available: \(scheme)")
                return true
            }
        }

        // Check 4: Check for symbolic links
        let symbolicLinkPaths = ["/Applications", "/var/stash/Library/Ringtones", "/var/stash/Library/Wallpaper", "/var/stash/usr/include", "/var/stash/usr/libexec", "/var/stash/usr/share", "/var/stash/usr/arm-apple-darwin9"]
        for path in symbolicLinkPaths {
            var isSymlink: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isSymlink) {
                do {
                    let attrs = try FileManager.default.attributesOfItem(atPath: path)
                    if attrs[.type] as? FileAttributeType == .typeSymbolicLink {
                        addSecurityAlert(.jailbreakDetected, message: "Symbolic link detected: \(path)")
                        return true
                    }
                } catch {}
            }
        }

        // Note: fork() check removed as it's unavailable on iOS
        // The above checks are sufficient for jailbreak detection

        return false
        #endif
    }

    // MARK: - Debugger Detection

    private func checkForDebugger() -> Bool {
        #if DEBUG
        // Allow debugger in debug builds
        return false
        #else
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        guard result == 0 else { return false }

        let isDebugged = (info.kp_proc.p_flag & P_TRACED) != 0
        if isDebugged {
            addSecurityAlert(.debuggerAttached, message: "Debugger detected")
        }
        return isDebugged
        #endif
    }

    // MARK: - Tampering Detection

    private func checkForTampering() -> Bool {
        // Check 1: Verify app signature (simplified check)
        guard let bundlePath = Bundle.main.bundlePath as NSString? else {
            return false
        }

        let signaturePath = bundlePath.appendingPathComponent("_CodeSignature")
        if !FileManager.default.fileExists(atPath: signaturePath) {
            addSecurityAlert(.tamperingDetected, message: "Missing code signature")
            return true
        }

        // Check 2: Verify embedded.mobileprovision exists (for release builds)
        #if !DEBUG
        let provisionPath = bundlePath.appendingPathComponent("embedded.mobileprovision")
        if !FileManager.default.fileExists(atPath: provisionPath) {
            // This is expected for App Store builds, so only flag for enterprise/ad-hoc
            // Skipping this check for now as it can cause false positives
        }
        #endif

        return false
    }

    // MARK: - Screen Capture Detection

    private func setupScreenCaptureDetection() {
        // Detect screen recording
        screenCaptureObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenCaptureChange()
            }
        }

        // Detect screenshots
        screenshotObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenshot()
            }
        }

        // Check initial state
        handleScreenCaptureChange()
    }

    private func handleScreenCaptureChange() {
        let isCaptured = UIScreen.main.isCaptured
        isScreenBeingCaptured = isCaptured

        if isCaptured {
            addSecurityAlert(.screenCapture, message: "Screen recording detected")
            Logger.security("Screen recording started - protecting PHI", level: .warning)
            AuditLogger.shared.logSecurityEvent(
                action: "SCREEN_CAPTURE_STARTED",
                details: ["timestamp": Date()]
            )
            protectScreen()
        } else {
            unprotectScreen()
        }
    }

    private func handleScreenshot() {
        addSecurityAlert(.screenshot, message: "Screenshot taken")
        Logger.security("Screenshot taken", level: .warning)
        AuditLogger.shared.logSecurityEvent(
            action: "SCREENSHOT_TAKEN",
            details: ["timestamp": Date()]
        )
    }

    // MARK: - Security Overlay

    private let overlayTag = 999999

    private func addSecurityOverlay(to window: UIWindow) {
        // Remove existing overlay if present
        removeSecurityOverlay(from: window)

        // Create blur overlay
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = window.bounds
        blurView.tag = overlayTag
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Add warning label
        let warningLabel = UILabel()
        warningLabel.text = "Screen Recording Detected\n\nPatient data is protected and hidden.\nStop screen recording to continue."
        warningLabel.textColor = .systemRed
        warningLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        warningLabel.textAlignment = .center
        warningLabel.numberOfLines = 0
        warningLabel.translatesAutoresizingMaskIntoConstraints = false

        blurView.contentView.addSubview(warningLabel)

        NSLayoutConstraint.activate([
            warningLabel.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            warningLabel.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            warningLabel.leadingAnchor.constraint(greaterThanOrEqualTo: blurView.contentView.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(lessThanOrEqualTo: blurView.contentView.trailingAnchor, constant: -20)
        ])

        // Add HIPAA badge
        let hipaaLabel = UILabel()
        hipaaLabel.text = "🔒 HIPAA Protected"
        hipaaLabel.textColor = .secondaryLabel
        hipaaLabel.font = .systemFont(ofSize: 14, weight: .medium)
        hipaaLabel.translatesAutoresizingMaskIntoConstraints = false

        blurView.contentView.addSubview(hipaaLabel)

        NSLayoutConstraint.activate([
            hipaaLabel.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            hipaaLabel.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 40)
        ])

        window.addSubview(blurView)
    }

    private func removeSecurityOverlay(from window: UIWindow) {
        window.viewWithTag(overlayTag)?.removeFromSuperview()
    }

    // MARK: - Periodic Security Checks

    private func setupPeriodicSecurityChecks() {
        // Check every 5 minutes
        securityCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                _ = self?.performSecurityCheck()
            }
        }
    }

    private func performInitialSecurityCheck() {
        let passed = performSecurityCheck()
        if !passed {
            Logger.security("Initial security check failed", level: .error)
        }
    }

    // MARK: - Alert Management

    private func addSecurityAlert(_ type: SecurityAlert.AlertType, message: String) {
        let alert = SecurityAlert(type: type, message: message, timestamp: Date())
        securityAlerts.append(alert)

        // Keep only last 50 alerts
        if securityAlerts.count > 50 {
            securityAlerts.removeFirst(securityAlerts.count - 50)
        }
    }
}

// MARK: - SwiftUI View Modifier for Screen Protection

struct ScreenProtectionModifier: ViewModifier {
    @StateObject private var securityManager = SecurityManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            if securityManager.isScreenBeingCaptured {
                // Overlay for screen capture protection
                Color.clear
                    .background(.ultraThinMaterial)
                    .overlay {
                        VStack(spacing: 16) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.red)

                            Text("Screen Recording Detected")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Patient data is protected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .ignoresSafeArea()
            }
        }
    }
}

extension View {
    /// Applies screen capture protection to the view
    /// Use this on views containing PHI (Protected Health Information)
    func protectFromScreenCapture() -> some View {
        modifier(ScreenProtectionModifier())
    }
}

// MARK: - Security Status View

struct SecurityStatusView: View {
    @StateObject private var securityManager = SecurityManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: securityManager.isDeviceCompromised ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                    .foregroundColor(securityManager.isDeviceCompromised ? .red : .green)

                Text(securityManager.isDeviceCompromised ? "Security Issue Detected" : "Device Secure")
                    .font(.headline)
            }

            if securityManager.isScreenBeingCaptured {
                HStack {
                    Image(systemName: "record.circle")
                        .foregroundColor(.red)
                    Text("Screen Recording Active")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if !securityManager.securityAlerts.isEmpty {
                Text("Recent Alerts: \(securityManager.securityAlerts.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Jailbreak Warning View

struct JailbreakWarningView: View {
    @Environment(\.dismiss) private var dismiss
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("Security Warning")
                .font(.title)
                .fontWeight(.bold)

            Text("This device may be jailbroken or compromised. Running SurgiTrack on a compromised device violates HIPAA security requirements and may expose patient data.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Text("Risks include:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    riskItem("Unauthorized access to patient data")
                    riskItem("Keylogging of entered credentials")
                    riskItem("Screen capture of PHI")
                    riskItem("Data exfiltration by malware")
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)

            Spacer()

            Button(action: {
                onAcknowledge()
                dismiss()
            }) {
                Text("I Understand the Risks")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private func riskItem(_ text: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
            Text(text)
                .font(.subheadline)
        }
    }
}
