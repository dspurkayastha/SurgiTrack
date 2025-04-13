//
//  EnhancedTrendsView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 13/03/25.
//

import SwiftUI
import CoreData
import Combine

struct EnhancedTrendsView: View {
    // MARK: - Environment & State
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    // New view model (refactored from TrendsAnalysisManager)
    @StateObject private var viewModel: TrendsAnalysisViewModel
    
    // UI States
    @State private var showingPatientPicker = false
    @State private var showingShareSheet = false
    @State private var showingExportOptions = false
    @State private var generatedFileURL: URL? = nil

    // MARK: - Initialization
    
    init(patientID: NSManagedObjectID? = nil) {
        let vm = TrendsAnalysisViewModel(context: PersistenceController.shared.container.viewContext)
        _viewModel = StateObject(wrappedValue: vm)
        if let patientID = patientID {
            let context = PersistenceController.shared.container.viewContext
            if let patient = context.object(with: patientID) as? Patient {
                vm.selectedPatient = patient
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top control bar with level and time range selectors
                analysisLevelSelector
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                
                Divider()
                
                // Main scrollable content
                ScrollView {
                    switch viewModel.selectedLevel {
                    case .individual:
                        individualAnalysisView
                    case .cohort:
                        cohortAnalysisView
                    case .organization:
                        organizationAnalysisView
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Enhanced Trends Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingExportOptions = true
                        }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
                        Button(action: {
                            // Reset analysis
                            viewModel.parameterData = []
                            viewModel.statisticalSummary = nil
                            viewModel.selectedParameter = nil
                            viewModel.selectedPatient = nil
                        }) {
                            Label("Reset Analysis", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPatientPicker) {
                PatientPickerView { patient in
                    Task {
                        viewModel.selectedPatient = patient
                        await viewModel.loadAvailableParameters()
                    }
                }
                .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let file = generatedFileURL {
                    ShareSheet(items: [file])
                }
            }
            .actionSheet(isPresented: $showingExportOptions) {
                ActionSheet(
                    title: Text("Export Options"),
                    message: Text("Choose an export format"),
                    buttons: [
                        .default(Text("PDF Report")) {
                            generateAndShareFile(as: .pdf)
                        },
                        .default(Text("CSV Data")) {
                            generateAndShareFile(as: .csv)
                        },
                        .cancel()
                    ]
                )
            }
            .onAppear {
                if viewModel.selectedPatient != nil {
                    Task {
                        await viewModel.loadAvailableParameters()
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var analysisLevelSelector: some View {
        VStack(spacing: 10) {
            // Analysis level picker
            Picker("Analysis Level", selection: $viewModel.selectedLevel) {
                ForEach(AnalysisLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: viewModel.selectedLevel) { newValue in
                Task { await viewModel.switchAnalysisLevel(to: newValue) }
            }
            
            // Time range picker
            HStack {
                Text("Time Range:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("", selection: $viewModel.selectedTimeRange) {
                    ForEach(AnalysisTimeRange.allCases, id: \.self) { range in
                        Text(range.displayText).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 280)
                .onChange(of: viewModel.selectedTimeRange) { _ in
                    if let parameter = viewModel.selectedParameter {
                        Task { await viewModel.loadParameterData(parameter: parameter) }
                    }
                }
            }
        }
    }
    
    // MARK: - Individual Analysis View
    
    private var individualAnalysisView: some View {
        VStack(spacing: 16) {
            patientSelectionCard
                .padding(.horizontal)
                .padding(.top)
            
            if let patient = viewModel.selectedPatient {
                if let selectedParam = viewModel.selectedParameter {
                    parameterAnalysisView(patient: patient, parameter: selectedParam)
                } else {
                    selectParameterView(patient: patient)
                }
            } else {
                emptyStateView
            }
            
            Spacer(minLength: 40)
        }
    }
    
    private var patientSelectionCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Patient")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let patient = viewModel.selectedPatient {
                    Text(patient.fullName)
                        .font(.headline)
                        .foregroundColor(.primary)
                } else {
                    Text("Select a patient")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            Spacer()
            Button(action: { showingPatientPicker = true }) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            Text("No Data to Display")
                .font(.title2)
                .fontWeight(.medium)
            Text("Select a patient to begin analyzing their data")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: { showingPatientPicker = true }) {
                Text("Select Patient")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func selectParameterView(patient: Patient) -> some View {
        VStack(spacing: 16) {
            Text("Select a parameter to analyze")
                .font(.headline)
                .padding(.top)
            if viewModel.isLoading {
                ProgressView("Loading parameters...")
                    .padding()
            } else if viewModel.organizationParameters.isEmpty {
                Text("No parameters available for this patient")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(viewModel.organizationParameters, id: \.self) { param in
                        Button(action: {
                            Task { await viewModel.loadParameterData(parameter: param) }
                        }) {
                            Text(param)
                                .font(.system(size: 14, weight: .medium))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func parameterAnalysisView(patient: Patient, parameter: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(parameter)
                    .font(.headline)
                Spacer()
                Menu {
                    ForEach(viewModel.organizationParameters, id: \.self) { param in
                        Button(action: {
                            Task { await viewModel.loadParameterData(parameter: param) }
                        }) {
                            HStack {
                                Text(param)
                                if param == parameter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            
            if viewModel.isLoading {
                ProgressView("Loading data...")
                    .padding()
            } else if viewModel.parameterData.isEmpty {
                emptyParameterView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        chartCard(title: "Trend Analysis") {
                            LineChartView(
                                data: viewModel.lineChartData,
                                title: "",
                                lineColor: .blue,
                                showDots: true
                            )
                            .padding(8)
                        }
                        
                        if let stats = viewModel.statisticalSummary {
                            statisticsCard(stats: stats)
                        }
                        
                        chartCard(title: "Monthly Averages") {
                            BarChartView(
                                data: viewModel.barChartData,
                                title: "",
                                showLabels: true
                            )
                            .padding(8)
                        }
                        
                        chartCard(title: "Results Distribution") {
                            PieChartView(
                                data: viewModel.pieChartData,
                                title: "",
                                showLegend: true
                            )
                            .padding(8)
                        }
                        
                        dataTable
                    }
                    .padding()
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private var emptyParameterView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom)
            Text("No data available")
                .font(.headline)
            Text("There is no data for this parameter within the selected time range.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: {
                viewModel.selectedTimeRange = .all
                if let parameter = viewModel.selectedParameter {
                    Task { await viewModel.loadParameterData(parameter: parameter) }
                }
            }) {
                Text("View All-Time Data")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            content()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func statisticsCard(stats: StatisticalSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistical Summary")
                .font(.headline)
                .padding(.horizontal)
            HStack {
                StatBox(title: "Min", value: String(format: "%.1f", stats.min), color: .blue)
                StatBox(title: "Max", value: String(format: "%.1f", stats.max), color: .purple)
                StatBox(title: "Mean", value: String(format: "%.1f", stats.mean), color: .green)
                StatBox(title: "Median", value: String(format: "%.1f", stats.median), color: .orange)
            }
            .padding(8)
            Divider()
                .padding(.horizontal)
            HStack {
                StatBox(
                    title: "Change",
                    value: String(format: "%+.1f%%", stats.percentChange),
                    color: stats.trend.color
                )
                StatBox(
                    title: "Trend",
                    value: stats.trend.rawValue,
                    color: stats.trend.color
                )
                StatBox(
                    title: "Std Dev",
                    value: String(format: "%.2f", stats.standardDeviation),
                    color: .blue
                )
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var dataTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data Points")
                .font(.headline)
                .padding(.horizontal)
            VStack(spacing: 0) {
                HStack {
                    Text("Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    Text("Value")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .trailing)
                    Text("Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .center)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color(.tertiarySystemBackground))
                
                ForEach(viewModel.parameterData.reversed()) { point in
                    HStack {
                        Text(formatDate(point.date))
                            .font(.subheadline)
                            .frame(width: 100, alignment: .leading)
                        Text(String(format: "%.1f", point.value))
                            .font(.subheadline)
                            .frame(width: 80, alignment: .trailing)
                            .foregroundColor(point.isAbnormal ? .red : .primary)
                        Text(point.isAbnormal ? "Abnormal" : "Normal")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(point.isAbnormal ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                            .foregroundColor(point.isAbnormal ? .red : .green)
                            .cornerRadius(4)
                            .frame(width: 80, alignment: .center)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color(.systemBackground))
                    
                    Divider()
                        .padding(.leading)
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Cohort & Organization Analysis Views
    
    private var cohortAnalysisView: some View {
        VStack(spacing: 20) {
            comingSoonView(
                title: "Cohort Analysis",
                message: "Cohort analysis capabilities will be available in the next phase.",
                color: .orange
            )
        }
        .padding()
    }
    
    private var organizationAnalysisView: some View {
        VStack(spacing: 20) {
            comingSoonView(
                title: "Organization-Wide Analysis",
                message: "Organization-wide analytics will be available in the next phase.",
                color: .purple
            )
        }
        .padding()
    }
    
    private func comingSoonView(title: String, message: String, color: Color) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(color.opacity(0.6))
                .padding(.bottom, 10)
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(color.opacity(0.8))
                .padding(.top, 10)
            Text("Coming Soon")
                .font(.headline)
                .foregroundColor(color)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(color.opacity(0.2))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func generateAndShareFile(as format: ExportFormat) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName: String
        switch format {
        case .pdf:
            fileName = "Trends_Report_\(Date().timeIntervalSince1970).pdf"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            // Define a page size for the PDF (A4: 595 x 842 points)
            let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
            
            let data = renderer.pdfData { context in
                context.beginPage()
                // Draw header
                let headerText = "Trends Analysis Report"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.black
                ]
                let headerSize = headerText.size(withAttributes: attributes)
                let headerRect = CGRect(x: (pageRect.width - headerSize.width) / 2,
                                        y: 40,
                                        width: headerSize.width,
                                        height: headerSize.height)
                headerText.draw(in: headerRect, withAttributes: attributes)
                
                // Draw summary if available
                if let stats = viewModel.statisticalSummary {
                    let summaryText = """
                    Statistical Summary:
                    Min: \(String(format: "%.1f", stats.min))
                    Max: \(String(format: "%.1f", stats.max))
                    Mean: \(String(format: "%.1f", stats.mean))
                    Median: \(String(format: "%.1f", stats.median))
                    Std Dev: \(String(format: "%.2f", stats.standardDeviation))
                    Change: \(String(format: "%+.1f%%", stats.percentChange))
                    Trend: \(stats.trend.rawValue)
                    """
                    let summaryAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 16),
                        .foregroundColor: UIColor.darkGray
                    ]
                    let summaryRect = CGRect(x: 40, y: headerRect.maxY + 40, width: pageRect.width - 80, height: 300)
                    summaryText.draw(in: summaryRect, withAttributes: summaryAttributes)
                }
                // Additional drawing can be added here.
            }
            
            do {
                try data.write(to: fileURL)
                generatedFileURL = fileURL
                showingShareSheet = true
            } catch {
                print("Error creating PDF: \(error)")
            }
            
        case .csv:
            fileName = "Trends_Data_\(Date().timeIntervalSince1970).csv"
            let fileURL = tempDir.appendingPathComponent(fileName)
            var csvContent = "Date,Value,IsAbnormal\n"
            for point in viewModel.parameterData {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: point.date)
                csvContent += "\(dateString),\(point.value),\(point.isAbnormal ? "Yes" : "No")\n"
            }
            do {
                try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
                generatedFileURL = fileURL
                showingShareSheet = true
            } catch {
                print("Error creating CSV: \(error)")
            }
        }
    }
    
    enum ExportFormat {
        case pdf, csv
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Patient Picker View

struct PatientPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var onSelect: ((Patient) -> Void)? = nil
    @Binding var selectedID: NSManagedObjectID?
    
    // Initialize with either a binding or a closure
    init(selectedID: Binding<NSManagedObjectID?>) {
        self._selectedID = selectedID
    }
    
    init(onSelect: @escaping (Patient) -> Void) {
        self.onSelect = onSelect
        self._selectedID = .constant(nil)
    }
    
    @State private var searchText = ""
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Patient.lastName, ascending: true),
            NSSortDescriptor(keyPath: \Patient.firstName, ascending: true)
        ],
        animation: .default
    ) private var patients: FetchedResults<Patient>
    
    var filteredPatients: [Patient] {
        if searchText.isEmpty {
            return Array(patients)
        } else {
            return patients.filter { patient in
                let fullName = "\(patient.firstName ?? "") \(patient.lastName ?? "")"
                return fullName.lowercased().contains(searchText.lowercased()) ||
                       (patient.medicalRecordNumber ?? "").lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search patients", text: $searchText)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Patient list
                List(filteredPatients, id: \.objectID) { patient in
                    Button(action: {
                        if let select = onSelect {
                            select(patient)
                        } else {
                            selectedID = patient.objectID
                        }
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(patient.fullName)
                            Spacer()
                            if let mrn = patient.medicalRecordNumber {
                                Text(mrn)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Patient")
            .navigationBarItems(trailing: Button("Cancel") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

// MARK: - Previews

struct EnhancedTrendsView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedTrendsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

// Factory method for external usage
extension EnhancedTrendsView {
    static func createWithPatient(_ patient: Patient?) -> EnhancedTrendsView {
        if let patient = patient {
            return EnhancedTrendsView(patientID: patient.objectID)
        } else {
            return EnhancedTrendsView()
        }
    }
}

