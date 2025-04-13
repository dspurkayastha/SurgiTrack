//
//  ReportBugView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// ReportBugView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct ReportBugView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var bugTitle = ""
    @State private var bugDescription = ""
    @State private var stepsToReproduce = ""
    @State private var severity: BugSeverity = .minor
    @State private var reproducibility: Reproducibility = .sometimes
    @State private var includeSystemInfo = true
    @State private var includeScreenshot = false
    @State private var includeDiagnosticLogs = true
    @State private var screenshot: UIImage? = nil
    @State private var isShowingImagePicker = false
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    @State private var diagnosticInfo = DiagnosticInfo(
        appVersion: "1.0.0 (Build 25)",
        osVersion: "iOS 15.4.1",
        deviceModel: "iPhone 13 Pro",
        memoryUsage: "412 MB",
        storageAvailable: "34.5 GB"
    )
    
    var body: some View {
        Form {
            // Bug details
            Section(header: Text("Bug Details")) {
                TextField("Title", text: $bugTitle)
                    .onChange(of: bugTitle) { _ in validateForm() }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if bugDescription.isEmpty {
                            Text("Please describe what happened...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $bugDescription)
                            .frame(minHeight: 100)
                            .background(Color.clear)
                    }
                    .padding(1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .onChange(of: bugDescription) { _ in validateForm() }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Steps to Reproduce")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if stepsToReproduce.isEmpty {
                            Text("1. First step\n2. Second step\n3. ...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $stepsToReproduce)
                            .frame(minHeight: 100)
                            .background(Color.clear)
                    }
                    .padding(1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Bug classification
            Section(header: Text("Classification")) {
                Picker("Severity", selection: $severity) {
                    ForEach(BugSeverity.allCases, id: \.self) { severity in
                        Text(severity.description).tag(severity)
                    }
                }
                
                Picker("Reproducibility", selection: $reproducibility) {
                    ForEach(Reproducibility.allCases, id: \.self) { reproducibility in
                        Text(reproducibility.description).tag(reproducibility)
                    }
                }
            }
            
            // Evidence collection
            Section(header: Text("Evidence")) {
                Toggle("Include Screenshot", isOn: $includeScreenshot)
                
                if includeScreenshot {
                    HStack {
                        if let image = screenshot {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .cornerRadius(8)
                                .padding(.vertical, 4)
                            
                            Button(action: {
                                screenshot = nil
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        } else {
                            Button(action: {
                                isShowingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Take Screenshot")
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                
                Toggle("Include System Information", isOn: $includeSystemInfo)
                Toggle("Include Diagnostic Logs", isOn: $includeDiagnosticLogs)
            }
            
            // System information
            if includeSystemInfo {
                Section(header: Text("System Information")) {
                    diagnosticInfoView(diagnosticInfo)
                }
            }
            
            // Additional notes
            Section(header: Text("Additional Notes")) {
                Text("Our team will investigate this bug and work to resolve it as soon as possible. Thank you for helping improve SurgiTrack.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Submit button
            Section {
                Button(action: {
                    submitBugReport()
                }) {
                    HStack {
                        Spacer()
                        
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 10)
                        }
                        
                        Text(isSubmitting ? "Submitting..." : "Submit Bug Report")
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                }
                .disabled(isSubmitting || !isFormValid)
            }
        }
        .navigationTitle("Report a Bug")
        .alert(isPresented: $showingSuccessAlert) {
            Alert(
                title: Text("Bug Report Submitted"),
                message: Text("Thank you for your report. Our development team will investigate the issue."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert(isPresented: $showingValidationError) {
            Alert(
                title: Text("Error"),
                message: Text(validationErrorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $screenshot)
        }
    }
    
    // MARK: - Helper Views
    
    private func diagnosticInfoView(_ info: DiagnosticInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("App Version:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(info.appVersion)
                    .font(.caption)
            }
            
            HStack {
                Text("OS Version:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(info.osVersion)
                    .font(.caption)
            }
            
            HStack {
                Text("Device Model:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(info.deviceModel)
                    .font(.caption)
            }
            
            HStack {
                Text("Memory Usage:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(info.memoryUsage)
                    .font(.caption)
            }
            
            HStack {
                Text("Storage Available:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(info.storageAvailable)
                    .font(.caption)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        // Simple validation checks
        bugTitle.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5 &&
        bugDescription.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 &&
        (!includeScreenshot || screenshot != nil)
    }
    
    // MARK: - Helper Methods
    
    private func validateForm() {
        // This is called when input fields change to update the form validity
        // The actual validation logic is in the isFormValid computed property
    }
    
    private func submitBugReport() {
        // Validate form
        if bugTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showValidationError("Please enter a title for the bug report.")
            return
        }
        
        if bugDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showValidationError("Please describe the bug.")
            return
        }
        
        if includeScreenshot && screenshot == nil {
            showValidationError("Please add a screenshot or disable the screenshot option.")
            return
        }
        
        // Submit the bug report
        isSubmitting = true
        
        // Simulate a network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSubmitting = false
            showingSuccessAlert = true
        }
    }
    
    private func showValidationError(_ message: String) {
        validationErrorMessage = message
        showingValidationError = true
    }
}

// MARK: - Supporting Types

enum BugSeverity: String, CaseIterable {
    case critical
    case major
    case minor
    case cosmetic
    
    var description: String {
        switch self {
        case .critical: return "Critical - App Crashes/Data Loss"
        case .major: return "Major - Feature Unusable"
        case .minor: return "Minor - Issue with Workaround"
        case .cosmetic: return "Cosmetic - Visual Issue Only"
        }
    }
}

enum Reproducibility: String, CaseIterable {
    case always
    case sometimes
    case rarely
    case once
    
    var description: String {
        switch self {
        case .always: return "Always"
        case .sometimes: return "Sometimes"
        case .rarely: return "Rarely"
        case .once: return "Happened Once"
        }
    }
}

struct DiagnosticInfo {
    let appVersion: String
    let osVersion: String
    let deviceModel: String
    let memoryUsage: String
    let storageAvailable: String
}


struct ReportBugView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportBugView()
        }
    }
}
