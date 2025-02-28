//
//  PrivacyPolicyView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// PrivacyPolicyView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var acceptedPolicy = false
    
    private let policyUpdateDate = "March 1, 2025"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Privacy Policy")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Last updated: \(policyUpdateDate)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                
                Divider()
                
                Group {
                    sectionHeader("Introduction")
                    Text("SurgiTrack is committed to protecting the privacy and security of your personal and medical information. This Privacy Policy explains how we collect, use, store, and share your information when you use our application.")
                    
                    sectionHeader("Information We Collect")
                    Text("1. Personal Information: Name, contact details, demographic information, and identification numbers.")
                    Text("2. Medical Information: Health records, treatment history, surgical data, test results, and appointment details.")
                    Text("3. Technical Information: Device information, IP address, usage data, and application interactions.")
                    
                    sectionHeader("How We Use Your Information")
                    Text("• To provide and maintain our services")
                    Text("• To improve and personalize your experience")
                    Text("• To facilitate communication between healthcare providers")
                    Text("• For administrative and operational purposes")
                    Text("• To comply with legal and regulatory requirements")
                    
                    sectionHeader("Data Storage and Security")
                    Text("All data in SurgiTrack is stored securely using industry-standard encryption protocols. We implement appropriate technical and organizational measures to protect against unauthorized access, alteration, disclosure, or destruction of your personal information.")
                    
                    Text("Your information is stored locally on the device and may be synchronized with secure servers depending on your organization's configuration. All transmissions between the application and servers are encrypted using TLS.")
                }
                
                Group {
                    sectionHeader("Sharing Your Information")
                    Text("We may share your information with:")
                    Text("• Healthcare providers involved in your care")
                    Text("• Third-party service providers who assist in operating our application")
                    Text("• Legal and regulatory authorities when required by law")
                    
                    Text("We do not sell your personal information to third parties under any circumstances.")
                    
                    sectionHeader("Your Rights")
                    Text("Depending on your jurisdiction, you may have the right to:")
                    Text("• Access your personal information")
                    Text("• Correct inaccurate or incomplete information")
                    Text("• Delete your information (subject to legal obligations)")
                    Text("• Restrict or object to certain processing activities")
                    Text("• Request a copy of your data in a portable format")
                    
                    sectionHeader("Changes to This Policy")
                    Text("We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the \"Last updated\" date.")
                    
                    sectionHeader("Contact Us")
                    Text("If you have any questions about this Privacy Policy, please contact us at:")
                    Text("privacy@surgitrack.com")
                    Text("Memorial General Hospital")
                    Text("123 Medical Center Blvd")
                    Text("Metropolis, CA 90210")
                }
                
                // Acceptance toggle
                Toggle("I have read and understood the Privacy Policy", isOn: $acceptedPolicy)
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.top, 20)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        .navigationTitle("Privacy Policy")
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }
}


struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacyPolicyView()
        }
    }
}
