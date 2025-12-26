//
//  ExportDataView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//  Updated on 26/12/2025 - Real export functionality with PDF, CSV, JSON support
//

import SwiftUI

struct ExportDataView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var exportService = DataExportService.shared
    @State private var exportOption: ExportOption = .allData
    @State private var timeFrame: TimeFrame = .allTime
    @State private var includeImages = true
    @State private var includeDocuments = true
    @State private var exportFormat: ExportFormat = .pdf
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordProtected = false
    @State private var exportComplete = false
    @State private var exportedFileURL: URL? = nil
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            if exportService.isExporting {
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
            if !exportService.isExporting && !exportComplete {
                Text("Cancel")
            }
        })
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
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
                        HStack {
                            Image(systemName: format.icon)
                            Text(format.description)
                        }
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Text(exportFormat.formatDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                    Label {
                        Text("This export contains protected health information (PHI)")
                    } icon: {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.orange)
                    }
                    .font(.caption)

                    Text("Handle in accordance with HIPAA regulations. It is your responsibility to keep this data secure.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Export button
            Section {
                Button(action: {
                    startExport()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Data")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(isPasswordProtected && (password.isEmpty || password != confirmPassword))
            }
        }
    }

    private var exportProgressView: some View {
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: exportService.progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: exportService.progress)

                Image(systemName: exportFormat.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
            }

            Text("Exporting Your Data")
                .font(.title2)
                .fontWeight(.semibold)

            Text(exportService.currentStep)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ProgressView(value: exportService.progress, total: 1.0)
                .padding(.horizontal, 40)

            Text("\(Int(exportService.progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            HStack {
                Image(systemName: "info.circle")
                Text("Please do not close the app during export")
            }
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
                    HStack {
                        Image(systemName: exportFormat.icon)
                        Text(url.lastPathComponent)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    showShareSheet = true
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

        Task {
            do {
                let fileURL = try await exportService.exportData(
                    option: exportOption,
                    timeFrame: timeFrame,
                    format: exportFormat,
                    includeImages: includeImages,
                    includeDocuments: includeDocuments,
                    password: isPasswordProtected ? password : nil
                )

                await MainActor.run {
                    exportedFileURL = fileURL
                    exportComplete = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func resetForm() {
        password = ""
        confirmPassword = ""
        exportedFileURL = nil
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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

    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .csv: return "tablecells"
        case .json: return "curlybraces"
        }
    }

    var formatDescription: String {
        switch self {
        case .pdf: return "Best for printing and sharing. Formatted document with headers and styling."
        case .csv: return "Best for spreadsheets. Import into Excel, Numbers, or Google Sheets."
        case .json: return "Best for technical use. Machine-readable format for data transfer."
        }
    }
}

struct ExportDataView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExportDataView()
        }
    }
}
