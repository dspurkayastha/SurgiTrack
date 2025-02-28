//
//  LicenseAgreementView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// LicenseAgreementView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct LicenseAgreementView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let licenseVersion = "Version 2.3"
    private let licenseDate = "March 1, 2025"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                header
                
                Divider()
                
                // License details
                Group {
                    sectionHeader("END USER LICENSE AGREEMENT")
                    Text("This End User License Agreement (\"EULA\") is a legal agreement between you (either an individual or a single entity) and Memorial General Hospital for the SurgiTrack software product identified above.")
                    
                    sectionHeader("1. GRANT OF LICENSE")
                    Text("Memorial General Hospital grants you the following rights provided that you comply with all terms and conditions of this EULA:")
                    
                    licenseItem("Installation and Use", "You may install and use one copy of the Software on a device that is used by authorized medical practitioners within your organization.")
                    
                    licenseItem("Device Limitations", "The Software may only be used on secure devices that meet the minimum security requirements as specified in the documentation.")
                    
                    licenseItem("Institution License", "This license is granted to your healthcare institution and covers all authorized users within the organization.")
                    
                    sectionHeader("2. DESCRIPTION OF OTHER RIGHTS AND LIMITATIONS")
                    
                    licenseItem("Maintenance of Copyright Notices", "You must not remove or alter any copyright notices on all copies of the Software.")
                    
                    licenseItem("Distribution", "You may not distribute, rent, lease, lend, sell, redistribute, sublicense, or provide the Software to any third party.")
                    
                    licenseItem("Limitations on Reverse Engineering", "You may not reverse engineer, decompile, or disassemble the Software, except and only to the extent that such activity is expressly permitted by applicable law.")
                    
                    licenseItem("Support Services", "Memorial General Hospital may provide you with support services related to the Software. Use of Support Services is governed by the policies and programs described in the documentation.")
                    
                    licenseItem("Compliance with Laws", "You must use the Software in compliance with all applicable laws and regulations, including but not limited to health information privacy laws.")
                }
                
                Group {
                    sectionHeader("3. UPDATES")
                    Text("Memorial General Hospital may from time to time provide updates to the Software. All such updates shall be considered part of the Software and subject to the terms and conditions of this EULA.")
                    
                    sectionHeader("4. THIRD PARTY SOFTWARE")
                    Text("The Software may incorporate components licensed under different terms, as documented in the \"About\" or \"Legal Notices\" section of the Software. Your use of these components is subject to the terms of their respective licenses.")
                    
                    sectionHeader("5. INTELLECTUAL PROPERTY RIGHTS")
                    Text("All title, including but not limited to copyrights, in and to the Software and any copies thereof are owned by Memorial General Hospital or its suppliers. All title and intellectual property rights in and to the content which may be accessed through use of the Software is the property of the respective content owner and may be protected by applicable copyright or other intellectual property laws and treaties.")
                    
                    sectionHeader("6. NO WARRANTIES")
                    Text("Memorial General Hospital expressly disclaims any warranty for the Software. The Software is provided 'As Is' without any express or implied warranty of any kind, including but not limited to any warranties of merchantability, non-infringement, or fitness of a particular purpose.")
                    
                    sectionHeader("7. LIMITATION OF LIABILITY")
                    Text("In no event shall Memorial General Hospital be liable for any damages (including, without limitation, lost profits, business interruption, or lost information) rising out of use of or inability to use the Software, even if Memorial General Hospital has been advised of the possibility of such damages.")
                }
                
                Group {
                    sectionHeader("8. INDEMNIFICATION")
                    Text("You agree to indemnify, defend and hold harmless Memorial General Hospital and its affiliates, officers, directors, employees, and agents from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses arising from your use of the Software.")
                    
                    sectionHeader("9. TERMINATION")
                    Text("Without prejudice to any other rights, Memorial General Hospital may terminate this EULA if you fail to comply with the terms and conditions of this EULA. In such event, you must destroy all copies of the Software and all of its component parts.")
                    
                    sectionHeader("10. APPLICABLE LAW")
                    Text("This EULA is governed by the laws of the State of California. You hereby consent to the exclusive jurisdiction and venue of the state and federal courts sitting in Los Angeles County, California to resolve any disputes arising under this EULA.")
                    
                    sectionHeader("ACKNOWLEDGMENT")
                    Text("By using the Software, you acknowledge that you have read this EULA, understand it, and agree to be bound by its terms and conditions.")
                }
                
                Divider()
                
                // License metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("SurgiTrack License")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("License ID: SRGTRK-MGH-2025-03")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(licenseVersion) - \(licenseDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
        .navigationTitle("License Agreement")
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "doc.plaintext.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text("SurgiTrack License Agreement")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("\(licenseVersion) • \(licenseDate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }
    
    private func licenseItem(_ title: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

struct LicenseAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LicenseAgreementView()
        }
    }
}