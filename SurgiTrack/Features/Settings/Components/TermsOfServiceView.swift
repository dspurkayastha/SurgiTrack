//
//  TermsOfServiceView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// TermsOfServiceView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var acceptedTerms = false
    
    private let termsUpdateDate = "March 1, 2025"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Terms of Service")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Last updated: \(termsUpdateDate)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                
                Divider()
                
                Group {
                    sectionHeader("1. Introduction")
                    Text("Welcome to SurgiTrack, a medical application designed for healthcare professionals. By accessing or using our services, you agree to be bound by these Terms of Service. Please read them carefully.")
                    
                    Text("SurgiTrack provides tools for managing surgical and patient data for healthcare providers. These Terms constitute a legally binding agreement between you and Memorial General Hospital regarding your use of the Application.")
                    
                    sectionHeader("2. Definitions")
                    definitionItem("Application", "refers to the SurgiTrack software, including all features, functionalities, and user interfaces.")
                    definitionItem("User", "refers to the individual or entity that has been authorized to access and use the Application.")
                    definitionItem("Content", "refers to all information entered, uploaded, or stored in the Application, including patient data, medical records, images, documents, and other materials.")
                    
                    sectionHeader("3. User Accounts")
                    Text("3.1. To use the Application, you must be registered and authorized by your healthcare institution.")
                    Text("3.2. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.")
                    Text("3.3. You agree to immediately notify Memorial General Hospital of any unauthorized use of your account or any other breach of security.")
                    
                    sectionHeader("4. Acceptable Use")
                    Text("4.1. You agree to use the Application only for legitimate medical and healthcare purposes.")
                    Text("4.2. You will not use the Application to violate any applicable laws, regulations, or professional standards.")
                    Text("4.3. You will not attempt to access, modify, or disrupt parts of the Application that you are not authorized to use.")
                }
                
                Group {
                    sectionHeader("5. Data and Privacy")
                    Text("5.1. You must comply with all applicable privacy laws and regulations when using the Application.")
                    Text("5.2. You are responsible for obtaining patient consent, where required, for storing their information in the Application.")
                    Text("5.3. Memorial General Hospital handles personal data in accordance with its Privacy Policy, which is incorporated into these Terms by reference.")
                    
                    sectionHeader("6. Intellectual Property")
                    Text("6.1. The Application and all related content and materials are protected by intellectual property rights owned by or licensed to Memorial General Hospital.")
                    Text("6.2. You may not reproduce, modify, distribute, or create derivative works based on the Application without express authorization.")
                    
                    sectionHeader("7. Disclaimers and Limitations")
                    Text("7.1. The Application is provided \"as is\" without any warranties, express or implied.")
                    Text("7.2. Memorial General Hospital does not guarantee that the Application will be error-free or uninterrupted.")
                    Text("7.3. The Application is a tool to support healthcare professionals and is not a replacement for professional medical judgment.")

                    sectionHeader("8. Termination")
                    Text("8.1. Memorial General Hospital reserves the right to suspend or terminate your access to the Application for violations of these Terms.")
                    Text("8.2. Upon termination, your right to use the Application will immediately cease.")
                    
                    sectionHeader("9. Changes to Terms")
                    Text("9.1. Memorial General Hospital may modify these Terms at any time by posting the revised terms on the Application.")
                    Text("9.2. Your continued use of the Application after such changes constitutes acceptance of the modified Terms.")
                }
                
                Group {
                    sectionHeader("10. Governing Law")
                    Text("10.1. These Terms shall be governed by and construed in accordance with the laws of the State of California, without regard to its conflict of law provisions.")
                    Text("10.2. Any disputes arising under these Terms shall be resolved in the courts located in Los Angeles County, California.")
                    
                    sectionHeader("11. Contact Information")
                    Text("For questions about these Terms, please contact:")
                    Text("Legal Department")
                    Text("Memorial General Hospital")
                    Text("123 Medical Center Blvd")
                    Text("Metropolis, CA 90210")
                    Text("legal@memorialgen.org")
                }
                
                // Acceptance toggle
                Toggle("I have read and agree to the Terms of Service", isOn: $acceptedTerms)
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.top, 20)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        .navigationTitle("Terms of Service")
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }
    
    private func definitionItem(_ term: String, _ definition: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(term)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(definition)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

struct TermsOfServiceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TermsOfServiceView()
        }
    }
}