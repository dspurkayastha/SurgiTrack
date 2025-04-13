//
//  ThirdPartySoftwareView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// ThirdPartySoftwareView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct ThirdPartySoftwareView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedLibrary: ThirdPartyLibrary? = nil
    
    // List of third-party libraries
    private let libraries = [
        ThirdPartyLibrary(
            name: "SwiftUI Charts",
            version: "1.2.0",
            license: "MIT",
            purpose: "Data visualization components",
            url: "https://github.com/example/swiftui-charts",
            licenseText: "MIT License\n\nCopyright (c) 2024 SwiftUI Charts Contributors\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
        ),
        ThirdPartyLibrary(
            name: "MedicalRecordKit",
            version: "3.5.2",
            license: "Apache 2.0",
            purpose: "Medical record management and standardization",
            url: "https://github.com/example/medicalrecordkit",
            licenseText: "Apache License\nVersion 2.0, January 2004\nhttp://www.apache.org/licenses/\n\nCopyright (c) 2024 MedicalRecordKit Contributors\n\nLicensed under the Apache License, Version 2.0 (the \"License\"); you may not use this file except in compliance with the License. You may obtain a copy of the License at\n\nhttp://www.apache.org/licenses/LICENSE-2.0\n\nUnless required by applicable law or agreed to in writing, software distributed under the License is distributed on an \"AS IS\" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License."
        ),
        ThirdPartyLibrary(
            name: "PDFKit Extensions",
            version: "2.1.0",
            license: "BSD-3-Clause",
            purpose: "Enhanced PDF generation and manipulation",
            url: "https://github.com/example/pdfkit-extensions",
            licenseText: "BSD 3-Clause License\n\nCopyright (c) 2024, PDFKit Extensions Contributors\nAll rights reserved.\n\nRedistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:\n\n1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n\n2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n\n3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.\n\nTHIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED."
        ),
        ThirdPartyLibrary(
            name: "HealthDataSync",
            version: "1.4.3",
            license: "MIT",
            purpose: "Health data synchronization utilities",
            url: "https://github.com/example/healthdatasync",
            licenseText: "MIT License\n\nCopyright (c) 2024 HealthDataSync Contributors\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software."
        ),
        ThirdPartyLibrary(
            name: "SecureStorageSwift",
            version: "4.2.1",
            license: "MPL-2.0",
            purpose: "Encrypted data storage for sensitive information",
            url: "https://github.com/example/securestorage-swift",
            licenseText: "Mozilla Public License Version 2.0\n\nCopyright (c) 2024 SecureStorageSwift Contributors\n\nThis Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at https://mozilla.org/MPL/2.0/."
        ),
        ThirdPartyLibrary(
            name: "MedicalImageProcessing",
            version: "2.8.0",
            license: "Apache 2.0",
            purpose: "Medical imaging tools and viewers",
            url: "https://github.com/example/medical-image-processing",
            licenseText: "Apache License\nVersion 2.0, January 2004\nhttp://www.apache.org/licenses/\n\nCopyright (c) 2024 MedicalImageProcessing Contributors"
        ),
        ThirdPartyLibrary(
            name: "CoreDataExtensions",
            version: "1.7.2",
            license: "MIT",
            purpose: "Extensions for working with Core Data",
            url: "https://github.com/example/coredata-extensions",
            licenseText: "MIT License\n\nCopyright (c) 2024 CoreDataExtensions Contributors"
        ),
        ThirdPartyLibrary(
            name: "BiometricAuthKit",
            version: "3.0.1",
            license: "MIT",
            purpose: "Biometric authentication utilities",
            url: "https://github.com/example/biometric-auth-kit",
            licenseText: "MIT License\n\nCopyright (c) 2024 BiometricAuthKit Contributors"
        )
    ]
    
    var body: some View {
        Group {
            if let selectedLib = selectedLibrary {
                licenseDetailView(for: selectedLib)
            } else {
                librariesListView
            }
        }
        .navigationTitle("Third-Party Software")
        .navigationBarItems(trailing: 
            Group {
                if selectedLibrary != nil {
                    Button("Done") {
                        selectedLibrary = nil
                    }
                }
            }
        )
    }
    
    // MARK: - Views
    
    private var librariesListView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search libraries", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            // Explanation text
            Text("SurgiTrack uses the following third-party libraries. Tap on a library to view its license.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.bottom)
            
            // Libraries list
            List {
                ForEach(filteredLibraries, id: \.name) { library in
                    Button(action: {
                        selectedLibrary = library
                    }) {
                        libraryRow(for: library)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func libraryRow(for library: ThirdPartyLibrary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(library.name)
                    .font(.headline)
                
                Spacer()
                
                Text(library.version)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(library.purpose)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("License: \(library.license)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func licenseDetailView(for library: ThirdPartyLibrary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Library info header
                VStack(alignment: .leading, spacing: 4) {
                    Text(library.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Version \(library.version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(library.purpose)
                        .font(.body)
                        .padding(.top, 4)
                    
                    if !library.url.isEmpty {
                        Link(destination: URL(string: library.url)!) {
                            HStack {
                                Text("Project Website")
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // License type header
                HStack {
                    Text("License: \(library.license)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = library.licenseText
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 8)
                
                // License text
                Text(library.licenseText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredLibraries: [ThirdPartyLibrary] {
        if searchText.isEmpty {
            return libraries
        } else {
            return libraries.filter { library in
                library.name.localizedCaseInsensitiveContains(searchText) ||
                library.purpose.localizedCaseInsensitiveContains(searchText) ||
                library.license.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Supporting Types

struct ThirdPartyLibrary {
    let name: String
    let version: String
    let license: String
    let purpose: String
    let url: String
    let licenseText: String
}

struct ThirdPartySoftwareView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ThirdPartySoftwareView()
        }
    }
}