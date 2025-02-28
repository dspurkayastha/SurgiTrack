//
//  ContactSupportView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// ContactSupportView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct ContactSupportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var issueCategory: IssueCategory = .technicalIssue
    @State private var issueTitle = ""
    @State private var issueDescription = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var preferredContactMethod: ContactMethod = .email
    @State private var includeSystemInfo = true
    @State private var includeScreenshot = false
    @State private var includeLogFiles = true
    @State private var screenshot: UIImage? = nil
    @State private var isShowingImagePicker = false
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    @State private var showingValidationError = false
    @State private var validationErrorMessage = ""
    
    var body: some View {
        Form {
            // Issue details
            Section(header: Text("Issue Details")) {
                Picker("Category", selection: $issueCategory) {
                    ForEach(IssueCategory.allCases, id: \.self) { category in
                        Text(category.description).tag(category)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                
                TextField("Title", text: $issueTitle)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if issueDescription.isEmpty {
                            Text("Please describe the issue in detail...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $issueDescription)
                            .frame(minHeight: 150)
                            .background(Color.clear)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Contact information
            Section(header: Text("Contact Information")) {
                Picker("Preferred Contact Method", selection: $preferredContactMethod) {
                    ForEach(ContactMethod.allCases, id: \.self) { method in
                        Text(method.description).tag(method)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if preferredContactMethod == .email || preferredContactMethod == .both {
                    TextField("Email", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                if preferredContactMethod == .phone || preferredContactMethod == .both {
                    TextField("Phone", text: $contactPhone)
                        .keyboardType(.phonePad)
                }
            }
            
            // Additional information
            Section(header: Text("Additional Information")) {
                Toggle("Include System Information", isOn: $includeSystemInfo)
                Toggle("Include Log Files", isOn: $includeLogFiles)
                
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
                                    Text("Add Screenshot")
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                
                if includeSystemInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Device: iPhone 13 Pro")
                                .font(.caption)
                            Text("iOS Version: 15.4.1")
                                .font(.caption)
                            Text("App Version: 1.0.0 (Build 25)")
                                .font(.caption)
                            Text("Available Storage: 34.5 GB")
                                .font(.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Submit button
            Section {
                Button(action: {
                    submitIssue()
                }) {
                    HStack {
                        Spacer()
                        
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 10)
                        }
                        
                        Text(isSubmitting ? "Submitting..." : "Submit Support Request")
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                }
                .disabled(isSubmitting || !isFormValid)
            }
            
            // Help information
            Section(header: Text("Help & Information")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Our support team will respond to your request as soon as possible, usually within 24 business hours.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("For urgent matters, please contact:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.blue)
                        
                        Text("Support Hotline: 1-800-SURGITRACK")
                            .font(.caption)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        
                        Text("support@surgitrack.com")
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Contact Support")
        .alert(isPresented: $showingSuccessAlert) {
            Alert(
                title: Text("Request Submitted"),
                message: Text("Your support request has been submitted successfully. We'll contact you as soon as possible."),
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
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        // Basic validation
        if issueTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        
        if issueDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        
        // Contact validation
        if preferredContactMethod == .email || preferredContactMethod == .both {
            if contactEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isValidEmail(contactEmail) {
                return false
            }
        }
        
        if preferredContactMethod == .phone || preferredContactMethod == .both {
            if contactPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }
        
        // Ensure we have a screenshot if selected
        if includeScreenshot && screenshot == nil {
            return false
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    
    private func submitIssue() {
        // Validate form
        if issueTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showValidationError("Please enter a title for your issue.")
            return
        }
        
        if issueDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showValidationError("Please describe your issue.")
            return
        }
        
        if preferredContactMethod == .email || preferredContactMethod == .both {
            if contactEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showValidationError("Please enter your email address.")
                return
            }
            
            if !isValidEmail(contactEmail) {
                showValidationError("Please enter a valid email address.")
                return
            }
        }
        
        if (preferredContactMethod == .phone || preferredContactMethod == .both) && contactPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showValidationError("Please enter your phone number.")
            return
        }
        
        if includeScreenshot && screenshot == nil {
            showValidationError("Please add a screenshot or disable the screenshot option.")
            return
        }
        
        // Submit the issue
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

// MARK: - Supporting Types

enum IssueCategory: String, CaseIterable {
    case technicalIssue = "technical"
    case accountAccess = "account"
    case dataSync = "dataSync"
    case appPerformance = "performance"
    case featureRequest = "feature"
    case dataPrivacy = "privacy"
    case billing = "billing"
    case other = "other"
    
    var description: String {
        switch self {
        case .technicalIssue: return "Technical Issue"
        case .accountAccess: return "Account Access"
        case .dataSync: return "Data Synchronization"
        case .appPerformance: return "App Performance"
        case .featureRequest: return "Feature Request"
        case .dataPrivacy: return "Data & Privacy"
        case .billing: return "Billing"
        case .other: return "Other"
        }
    }
}

enum ContactMethod: String, CaseIterable {
    case email
    case phone
    case both
    
    var description: String {
        switch self {
        case .email: return "Email"
        case .phone: return "Phone"
        case .both: return "Both"
        }
    }
}


struct ContactSupportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContactSupportView()
        }
    }
}
