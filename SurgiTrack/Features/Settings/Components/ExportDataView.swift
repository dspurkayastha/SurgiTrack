//
//  ExportDataView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// ExportDataView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct ExportDataView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var exportOption: ExportOption = .allData
    @State private var timeFrame: TimeFrame = .allTime
    @State private var includeImages = true
    @State private var includeDocuments = true
    @State private var exportFormat: ExportFormat = .pdf
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordProtected = false
    @State private var isExporting = false
    @State private var exportProgress: Double = 0.0
    @State private var exportComplete = false
    @State private var exportedFileURL: URL? = nil
    
    var body: some View {
        VStack {
            if isExporting {
                exportProgressView
            } else if exportComplete {
                exportCompleteView
            } else {
                exportFormView
            }
        }
        .navigationTitle("Export Your Data")
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            if !isExporting && !exportComplete {
                Text("Cancel")
            }
        })
    }
    
    // MARK: - Content Views
    
    private var exportFormView: some View {
        Form {
            // Export data selection
            Section(header: Text("What to Export")) {
                Picker("Data Selection", selection: $exportOption) {
                    ForEach(ExportOption.allCases, id: \.self) { option in
                        Text(option.description)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                
                if exportOption != .patientList {
                    Picker("Time Frame", selection: $timeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { period in
                            Text(period.description)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                Toggle("Include Images", isOn: $includeImages)
                Toggle("Include Documents", isOn: $includeDocuments)
            }
            
            // Export format
            Section(header: Text("Format")) {
                Picker("File Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.description)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Security
            Section(header: Text("Security")) {
                Toggle("Password Protection", isOn: $isPasswordProtected)
                
                if isPasswordProtected {
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                    
                    if !password.isEmpty && password != confirmPassword {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            // Information
            Section(header: Text("Important Information")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The exported file will contain sensitive medical information. It is your responsibility to keep this data secure.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("By proceeding, you agree to our data export terms and conditions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Export button
            Section {
                Button(action: {
                    startExport()
                }) {
                    Text("Export Data")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(isPasswordProtected && (password.isEmpty || password != confirmPassword))
            }
        }
    }
    
    private var exportProgressView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ProgressView()
                .scaleEffect(2)
                .padding()
            
            Text("Exporting Your Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            ProgressView(value: exportProgress, total: 1.0)
                .padding(.horizontal, 40)
            
            Text("\(Int(exportProgress * 100))% Complete")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Please do not close the app during export")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    private var exportCompleteView: some View {
        VStack(spacing: 25) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Export Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                Text("Your data has been successfully exported.")
                    .font(.body)
                
                if let url = exportedFileURL {
                    Text("File: \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    shareExportedFile()
                }) {
                    Label("Share File", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    exportComplete = false
                    resetForm()
                }) {
                    Text("Export More Data")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func startExport() {
        // Validate password if enabled
        if isPasswordProtected && (password.isEmpty || password != confirmPassword) {
            return
        }
        
        isExporting = true
        exportProgress = 0.0
        
        // Simulate export process with a timer
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if exportProgress < 1.0 {
                exportProgress += 0.02
            } else {
                timer.invalidate()
                completeExport()
            }
        }
        
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func completeExport() {
        // In a real app, we would generate an actual file here
        // For this demo, we'll create a simulated file URL
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let filename = "SurgiTrack_Export_\(timestamp).\(exportFormat.fileExtension)"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        exportedFileURL = documentsDirectory.appendingPathComponent(filename)
        
        // Simulate a short delay for completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isExporting = false
            self.exportComplete = true
        }
    }
    
    private func shareExportedFile() {
        // In a real app, this would open the iOS share sheet
        // For this demo, we'll just print the file details
        if let url = exportedFileURL {
            print("Sharing file: \(url.path)")
        }
    }
    
    private func resetForm() {
        password = ""
        confirmPassword = ""
        exportedFileURL = nil
    }
}

// MARK: - Supporting Types

enum ExportOption: String, CaseIterable {
    case allData
    case patientRecords
    case surgicalRecords
    case followUpData
    case patientList
    
    var description: String {
        switch self {
        case .allData: return "All Data"
        case .patientRecords: return "Patient Records"
        case .surgicalRecords: return "Surgical Records"
        case .followUpData: return "Follow-up Data"
        case .patientList: return "Patient List"
        }
    }
}

enum TimeFrame: String, CaseIterable {
    case last30Days
    case last90Days
    case lastYear
    case allTime
    
    var description: String {
        switch self {
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        case .lastYear: return "Last Year"
        case .allTime: return "All Time"
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case pdf
    case csv
    case json
    
    var description: String {
        switch self {
        case .pdf: return "PDF"
        case .csv: return "CSV"
        case .json: return "JSON"
        }
    }
    
    var fileExtension: String {
        return self.rawValue
    }
}

struct ExportDataView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExportDataView()
        }
    }
}