import SwiftUI
import CoreData
import PDFKit
import UIKit
import QuickLook

struct TestDetailView: View {
    // MARK: - Environment & Properties
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject var navigationState: ReportsNavigationState
    
    @ObservedObject var test: MedicalTest
    
    // MARK: - State
    @State private var showingAttachments = false
    @State private var showingEditOptions = false
    @State private var showingDeleteConfirmation = false
    @State private var showingTrendView = false
    @State private var showingShareSheet = false
    @State private var generatedPDF: URL? = nil
    @State private var isGeneratingPDF = false
    @State private var showingEnhancedAnalysis = false

    
    // MARK: - Computed Properties
    
    private var isRadiologyTest: Bool {
        let radiologyTests = ["USG", "MRI", "MRCP", "CECT", "CT", "X-Ray"]
        return radiologyTests.contains { test.testType?.contains($0) ?? false }
    }
    
    private var parameters: [TestParameter] {
        return (test.testParameters as? Set<TestParameter>)?.sorted {
            $0.displayOrder < $1.displayOrder
        } ?? []
    }
    
    private var abnormalParameters: [TestParameter] {
        return parameters.filter { $0.isAbnormal }
    }
    
    private var attachments: [Attachment] {
        return (test.attachments as? Set<Attachment>)?.sorted {
            ($0.dateCreated ?? Date()) > ($1.dateCreated ?? Date())
        } ?? []
    }
    
    // MARK: - Formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Body
    var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Content based on test type
                    if isRadiologyTest {
                        radiologyContent
                    } else {
                        laboratoryContent
                    }
                    
                    // Attachments section
                    if !attachments.isEmpty {
                        attachmentsSection
                    }
                    
                    // Notes section if available
                    if let notes = test.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(test.testType ?? "Test Results")
            .navigationBarItems(
                trailing: HStack {
                    Button(action: {
                        showingEditOptions = true
                    }) {
                        Image(systemName: "ellipsis")
                    }
                }
            )
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingAttachments) {
                AttachmentView(parent: .medicalTest(test))
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingTrendView) {
                TestTrendView(testType: test.testType ?? "", patientID: test.patient?.objectID)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdf = generatedPDF {
                    ShareSheet(items: [pdf])
                }
            }
            .sheet(isPresented: $showingEnhancedAnalysis) {
                if let parameter = getSelectedParameter(), let patient = test.patient {
                    EnhancedTrendsView.createWithPatient(patient)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .onAppear {
                print("📌 TestDetailView: onAppear")
            }
            .onDisappear {
                print("📌 TestDetailView: onDisappear")
                navigationState.ensureButtonVisibility()
                print("📌 TestDetailView: After ensuring button visibility: \(navigationState.showingAnalysisButton)")
            }
            .actionSheet(isPresented: $showingEditOptions) {
                ActionSheet(
                    title: Text("Test Options"),
                    buttons: [
                        .default(Text("Generate Report")) {
                            generateAndSharePDF()
                        },
                        .default(Text("Add Attachment")) {
                            showingAttachments = true
                        },
                        .destructive(Text("Delete Test")) {
                            showingDeleteConfirmation = true
                        },
                        .cancel()
                    ]
                )
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Test"),
                    message: Text("Are you sure you want to delete this test? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteTest()
                    },
                    secondaryButton: .cancel()
                )
            }
            .overlay(
                Group {
                    if isGeneratingPDF {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                
                                Text("Generating PDF...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding(25)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                            .shadow(radius: 10)
                        }
                    }
                }
            )
        }
        
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 10) {
            // Test type and status
            HStack {
                testTypeIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(test.testType ?? "Unknown Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let patient = test.patient {
                        Text("Patient: \(patient.fullName)")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                // Status badge
                statusBadge
            }
            
            Divider()
            
            // Date, lab, and physician info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text("Date:")
                            .foregroundColor(.secondary)
                        Text(dateFormatter.string(from: test.testDate ?? Date()))
                    }
                    .font(.caption)
                    
                    if let lab = test.laboratory, !lab.isEmpty {
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundColor(.secondary)
                            Text("Facility:")
                                .foregroundColor(.secondary)
                            Text(lab)
                        }
                        .font(.caption)
                    }
                }
                
                Spacer()
                
                if let physician = test.orderingPhysician as? String, !physician.isEmpty  {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack {
                            Text("Ordered by:")
                                .foregroundColor(.secondary)
                            Text(physician)
                        }
                        .font(.caption)
                        
                        if let resultDate = test.resultEntryDate {
                            HStack {
                                Text("Results entered:")
                                    .foregroundColor(.secondary)
                                Text(dateFormatter.string(from: resultDate))
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
    
    private var laboratoryContent: some View {
        VStack(spacing: 16) {
            // Abnormal results callout if applicable
            if test.isAbnormal {
                abnormalResultsAlert
            }
            
            // Parameters by category
            let groupedParameters = Dictionary(grouping: parameters) { $0.parameterCategory ?? "Other" }
            
            ForEach(groupedParameters.keys.sorted(), id: \.self) { category in
                if let categoryParams = groupedParameters[category] {
                    parameterGroupView(category: category, parameters: categoryParams)
                }
            }
            
            // No parameters notice
            if parameters.isEmpty {
                noParametersView
            }
        }
    }
    
    private var radiologyContent: some View {
        VStack(spacing: 16) {
            // Findings section
            if let details = test.notes, !details.isEmpty {
                sectionsCard(title: "Findings", content: details)
            }
            
            // Impression/Summary section
            if let summary = test.summary, !summary.isEmpty {
                sectionsCard(title: "Impression", content: summary)
            }
            
            // Measurements as a table if available
            if !parameters.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Measurements")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Divider()
                    
                    ForEach(parameters, id: \.objectID) { param in
                        HStack {
                            Text(param.parameterName ?? "")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if let value = param.value, !value.isEmpty {
                                Text("\(value) \(param.unit ?? "")")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "paperclip")
                    .foregroundColor(.blue)
                
                Text("Attachments")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingAttachments = true
                }) {
                    Text("Manage")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(attachments, id: \.objectID) { attachment in
                        attachmentThumbnail(attachment)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                
                Text("Notes")
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            Text(notes)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button(action: {
                    generateAndSharePDF()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Report")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            // New button for enhanced analysis
            Button(action: {
                showingEnhancedAnalysis = true
            }) {
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                    Text("Enhanced Analysis")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            .padding(.top, 10)
        }
    }
    
    private var testTypeIcon: some View {
        let iconName: String
        let color: Color
        
        switch test.testType?.lowercased() ?? "" {
        case let type where type.contains("blood") || type.contains("cbc"):
            iconName = "drop.fill"
            color = .red
        case let type where type.contains("liver") || type.contains("metabolic"):
            iconName = "syringe.fill"
            color = .orange
        case let type where type.contains("xray") || type.contains("ct") || type.contains("mri") || type.contains("imaging") || type.contains("usg") || type.contains("mrcp") || type.contains("cect"):
            iconName = "xray"
            color = .purple
        case let type where type.contains("urine") || type.contains("urinalysis"):
            iconName = "flask.fill"
            color = .yellow
        case let type where type.contains("coagulation") || type.contains("clotting"):
            iconName = "bandage.fill"
            color = .blue
        default:
            iconName = "chart.line.text.clipboard"
            color = .gray
        }
        
        return Image(systemName: iconName)
            .foregroundColor(color)
            .font(.system(size: 24))
            .frame(width: 40, height: 40)
            .background(color.opacity(0.2))
            .clipShape(Circle())
    }
    
    private var statusBadge: some View {
        let status = test.status ?? "Completed"
        let color: Color
        
        switch status.lowercased() {
        case "pending":
            color = .orange
        case "abnormal":
            color = .red
        case "completed":
            color = .green
        default:
            color = .gray
        }
        
        return Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(20)
    }
    
    private var abnormalResultsAlert: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Abnormal Results Detected")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("\(abnormalParameters.count) parameter\(abnormalParameters.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            
            Divider()
                .background(Color.red.opacity(0.5))
            
            // List the abnormal parameters
            ForEach(abnormalParameters, id: \.objectID) { param in
                HStack {
                    Text(param.parameterName ?? "Unknown")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(param.value ?? "")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                    
                    if let unit = param.unit, !unit.isEmpty {
                        Text(unit)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
            
            if abnormalParameters.count > 3 {
                Button(action: {
                    // Scroll to the parameters section
                }) {
                    Text("View all abnormal results")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func parameterGroupView(category: String, parameters: [TestParameter]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category)
                .font(.headline)
                .padding(.bottom, 4)
            
            Divider()
            
            // Parameter rows
            ForEach(parameters, id: \.objectID) { param in
                parameterRow(param)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func parameterRow(_ parameter: TestParameter) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(parameter.parameterName ?? "Unknown")
                    .fontWeight(parameter.isAbnormal ? .bold : .regular)
                    .foregroundColor(parameter.isAbnormal ? .red : .primary)
                
                if let referenceText = parameter.referenceText, !referenceText.isEmpty {
                    Text("Ref: \(referenceText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if parameter.referenceRangeLow > 0 || parameter.referenceRangeHigh > 0 {
                    Text("Ref: \(String(format: "%.1f", parameter.referenceRangeLow))-\(String(format: "%.1f", parameter.referenceRangeHigh))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(alignment: .center, spacing: 4) {
                Text(parameter.value ?? "")
                    .fontWeight(parameter.isAbnormal ? .bold : .regular)
                    .foregroundColor(parameter.isAbnormal ? .red : .primary)
                
                if let unit = parameter.unit, !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if parameter.isAbnormal {
                    let trendIcon = determineTrendIcon(for: parameter)
                    Image(systemName: trendIcon.iconName)
                        .foregroundColor(trendIcon.color)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var noParametersView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No Parameters Available")
                .font(.headline)
            
            Text("This test doesn't have any quantitative parameters recorded.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    private func getSelectedParameter() -> String? {
        // If we're viewing a specific parameter, return its name
        if let selectedParam = parameters.first {
            return selectedParam.parameterName
        }
        return nil
    }
    
    private func sectionsCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            Divider()
            
            Text(content)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func attachmentThumbnail(_ attachment: Attachment) -> some View {
    VStack {
        if let contentType = attachment.contentType, contentType.hasPrefix("image"),
           let data = attachment.data, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        } else {
            Image(systemName: getAttachmentIcon(for: attachment.contentType ?? ""))
                .font(.system(size: 40))
                .foregroundColor(getAttachmentColor(for: attachment.contentType ?? ""))
                .frame(width: 100, height: 100)
                .background(getAttachmentColor(for: attachment.contentType ?? "").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
        }
        
        Text(attachment.filename ?? "File")
            .font(.caption)
            .lineLimit(1)
            .frame(width: 100)
    }
    .onTapGesture {
        showAttachmentDetail(attachment)
    }
}

// MARK: - Helper Methods
    private func determineTrendIcon(for parameter: TestParameter) -> (iconName: String, color: Color) {
           // Get previous test results for comparison
           if let value = Double(parameter.value ?? "0"),
              let previousValue = getPreviousTestValue(for: parameter) {
               
               // Calculate percent change
               let percentChange = ((value - previousValue) / previousValue) * 100
               
               if percentChange > 15 {
                   return ("arrow.up", value > parameter.referenceRangeHigh ? .red : .orange)
               } else if percentChange < -15 {
                   return ("arrow.down", value < parameter.referenceRangeLow ? .blue : .orange)
               } else if value > parameter.referenceRangeHigh {
                   return ("arrow.up", .red)
               } else if value < parameter.referenceRangeLow {
                   return ("arrow.down", .blue)
               }
           } else {
               // Fallback to reference range comparison if no history
               if let valueString = parameter.value, let value = Double(valueString) {
                   if value > parameter.referenceRangeHigh && parameter.referenceRangeHigh > 0 {
                       return ("arrow.up", .red)
                   } else if value < parameter.referenceRangeLow && parameter.referenceRangeLow > 0 {
                       return ("arrow.down", .blue)
                   }
               }
           }
           
           return ("exclamationmark.circle", .orange)
       }
       
       private func getPreviousTestValue(for parameter: TestParameter) -> Double? {
           guard let currentTest = parameter.medicalTest,
                 let patientID = currentTest.patient?.objectID,
                 let parameterName = parameter.parameterName else {
               return nil
           }
           
           // Fetch request for previous tests
           let request: NSFetchRequest<MedicalTest> = MedicalTest.fetchRequest()

           // Use explicit casts to ensure type clarity
           request.predicate = NSPredicate(format: "patient.objectID == %@ AND testType == %@ AND testDate < %@ AND SELF != %@",
                                          patientID as CVarArg,  // Ensure patientID is correctly handled
                                          (currentTest.testType ?? "") as CVarArg,
                                          (currentTest.testDate ?? Date()) as NSDate,
                                          currentTest)

           request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicalTest.testDate, ascending: false)]
           request.fetchLimit = 1
           
           do {
               let previousTests = try viewContext.fetch(request)
               if let previousTest = previousTests.first,
                  let parameters = previousTest.testParameters as? Set<TestParameter>,
                  let previousParam = parameters.first(where: { $0.parameterName == parameterName }),
                  let previousValueString = previousParam.value,
                  let previousValue = Double(previousValueString) {
                   return previousValue
               }
           } catch {
               print("Error fetching previous test: \(error)")
           }
           
           return nil
       }


private func getAttachmentIcon(for contentType: String) -> String {
    switch contentType {
    case _ where contentType.hasPrefix("image"):
        return "photo"
    case _ where contentType.hasPrefix("application/pdf"):
        return "doc.text.fill"
    case _ where contentType.hasPrefix("text"):
        return "doc.text"
    case _ where contentType.hasPrefix("video"):
        return "film"
    case _ where contentType.hasPrefix("audio"):
        return "waveform"
    case _ where contentType.hasPrefix("application/msword") || contentType.hasPrefix("application/vnd.openxmlformats-officedocument.wordprocessingml"):
        return "doc.fill"
    case _ where contentType.hasPrefix("application/vnd.ms-excel") || contentType.hasPrefix("application/vnd.openxmlformats-officedocument.spreadsheetml"):
        return "chart.bar.doc.horizontal"
    default:
        return "doc.fill"
    }
}

private func getAttachmentColor(for contentType: String) -> Color {
    switch contentType {
    case _ where contentType.hasPrefix("image"):
        return .blue
    case _ where contentType.hasPrefix("application/pdf"):
        return .red
    case _ where contentType.hasPrefix("text"):
        return .green
    case _ where contentType.hasPrefix("video"):
        return .purple
    case _ where contentType.hasPrefix("audio"):
        return .orange
    case _ where contentType.hasPrefix("application/msword") || contentType.hasPrefix("application/vnd.openxmlformats-officedocument.wordprocessingml"):
        return .indigo
    case _ where contentType.hasPrefix("application/vnd.ms-excel") || contentType.hasPrefix("application/vnd.openxmlformats-officedocument.spreadsheetml"):
        return Color(red: 0.0, green: 0.5, blue: 0.0)
    default:
        return .gray
    }
}

    private func deleteTest() {
            // Confirm if there are dependencies before deletion
            let attachmentCount = (test.attachments as? Set<Attachment>)?.count ?? 0
            if attachmentCount > 0 {
                // Delete all attachments first
                if let attachments = test.attachments as? Set<Attachment> {
                    for attachment in attachments {
                        viewContext.delete(attachment)
                    }
                }
            }
            
            // Delete test parameters
            if let parameters = test.testParameters as? Set<TestParameter> {
                for parameter in parameters {
                    viewContext.delete(parameter)
                }
            }
            
            // Delete the test itself
            viewContext.delete(test)
            
            // Commit the changes to the database
            do {
                try viewContext.save()
                
                // Log the deletion
                LogManager.shared.logEvent(category: .data, action: .delete, detail: "Test \(test.testType ?? "Unknown") deleted")
                
                // Dismiss the view
                presentationMode.wrappedValue.dismiss()
            } catch {
                // Handle errors
                print("Error deleting test: \(error)")
                
                // Show error alert to user
                let nsError = error as NSError
                appState.showAlert(title: "Deletion Failed",
                                 message: "Could not delete test: \(nsError.localizedDescription)")
            }
        }
        
        private func generateAndSharePDF() {
            isGeneratingPDF = true
            
            // Create PDF generator
            let generator = TestReportPDFGenerator(test: test, viewContext: viewContext)
            
            // Generate PDF on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Generate PDF data
                    let pdfData = generator.generatePDF()
                    
                    // Create a temporary file URL for the PDF
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileName = "Test_Report_\(self.test.testType?.replacingOccurrences(of: " ", with: "_") ?? "Report")_\(Date().timeIntervalSince1970).pdf"
                    let fileURL = tempDir.appendingPathComponent(fileName)
                    
                    // Write PDF data to file
                    try pdfData.write(to: fileURL)
                    
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        self.generatedPDF = fileURL
                        self.isGeneratingPDF = false
                        self.showingShareSheet = true
                        
                        // Log successful PDF generation
                        LogManager.shared.logEvent(category: .export,
                                                 action: .create,
                                                 detail: "PDF report generated for test \(self.test.testType ?? "Unknown")")
                    }
                } catch {
                    // Update UI on main thread in case of error
                    DispatchQueue.main.async {
                        self.isGeneratingPDF = false
                        
                        // Show error alert
                        self.appState.showAlert(title: "PDF Generation Failed",
                                              message: "Could not generate PDF: \(error.localizedDescription)")
                        
                        // Log error
                        LogManager.shared.logEvent(category: .export,
                                                 action: .error,
                                                 detail: "PDF generation failed: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        private func showAttachmentDetail(_ attachment: Attachment) {
            guard let contentType = attachment.contentType, let data = attachment.data else {
                appState.showAlert(title: "Error", message: "Cannot open attachment: data is missing or corrupted")
                return
            }
            
            // Create temporary file to preview if needed
            if contentType.hasPrefix("image") {
                // Show image using a custom image viewer
                if let uiImage = UIImage(data: data) {
                    let detailView = AttachmentImageViewer(image: uiImage, title: attachment.filename ?? "Image")
                    appState.presentSheet(view: AnyView(detailView))
                }
            } else {
                // For non-image files, use QuickLook
                do {
                    // Create temporary file
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileExt = attachment.filename?.components(separatedBy: ".").last ?? "dat"
                    let tempFile = tempDir.appendingPathComponent(UUID().uuidString + "." + fileExt)
                    
                    // Write data to temp file
                    try data.write(to: tempFile)
                    
                    // Show preview using QuickLook
                    let previewController = AttachmentPreviewController(url: tempFile, title: attachment.filename ?? "File")
                    appState.presentSheet(view: AnyView(previewController))
                    
                } catch {
                    appState.showAlert(title: "Error", message: "Could not open attachment: \(error.localizedDescription)")
                }
            }
        }
        
    } // End of TestDetailView struct

// MARK: - ShareSheet for PDF Sharing
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}

// MARK: - Attachment Image Viewer
struct AttachmentImageViewer: View {
    let image: UIImage
    let title: String
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    
                                    // Limit minimum scale to 0.5 and maximum to 5.0
                                    let newScale = scale * delta
                                    scale = min(max(newScale, 0.5), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { value in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1.0 {
                                    // Reset scale and offset on double tap if zoomed in
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    // Zoom to 2x on double tap if at normal scale
                                    scale = 2.0
                                }
                            }
                        }
                }
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Attachment Preview Controller
struct AttachmentPreviewController: UIViewControllerRepresentable {
    let url: URL
    let title: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        previewController.delegate = context.coordinator
        previewController.currentPreviewItemIndex = 0
        previewController.title = title
        
        let navigationController = UINavigationController(rootViewController: previewController)
        
        // Add done button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.dismiss))
        previewController.navigationItem.rightBarButtonItem = doneButton
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: AttachmentPreviewController
        
        init(_ parent: AttachmentPreviewController) {
            self.parent = parent
        }
        
        // MARK: - QLPreviewControllerDataSource
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as NSURL
        }
        
        // MARK: - QLPreviewControllerDelegate
        
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            // Handle QuickLook dismiss event
        }
        
        @objc func dismiss() {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Test Trend View
struct TestTrendView: View {
    var testType: String
    var patientID: NSManagedObjectID?
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedParameter: String?
    @State private var availableParameters: [String] = []
    @State private var trendData: [LineChartData] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var dateRange: DateRangeFilter = .sixMonths
    
    enum DateRangeFilter: String, CaseIterable, Identifiable {
        case threeMonths = "3 Months"
        case sixMonths = "6 Months"
        case oneYear = "1 Year"
        case all = "All Time"
        
        var id: String { self.rawValue }
        
        var days: Int {
            switch self {
            case .threeMonths: return 90
            case .sixMonths: return 180
            case .oneYear: return 365
            case .all: return 3650  // ~10 years
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter controls
                HStack {
                    Menu {
                        ForEach(DateRangeFilter.allCases) { range in
                            Button(action: {
                                dateRange = range
                                loadTrendData()
                            }) {
                                HStack {
                                    Text(range.rawValue)
                                    if dateRange == range {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label(dateRange.rawValue, systemImage: "calendar")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    if !availableParameters.isEmpty {
                        Menu {
                            ForEach(availableParameters, id: \.self) { param in
                                Button(action: {
                                    selectedParameter = param
                                    updateChartForParameter()
                                }) {
                                    HStack {
                                        Text(param)
                                        if selectedParameter == param {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label(selectedParameter ?? "Select Parameter", systemImage: "chart.bar")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if isLoading {
                            ProgressView("Loading trend data...")
                                .padding()
                        } else if let error = errorMessage {
                            errorView(message: error)
                        } else if trendData.isEmpty {
                            noDataView
                        } else {
                            // Display trend chart
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Trend Analysis: \(selectedParameter ?? "")")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                LineChartView(
                                    data: trendData,
                                    title: "",
                                    lineColor: .blue,
                                    showDots: true
                                )
                                
                                // Statistics
                                if trendData.count > 1 {
                                    statisticsView
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                        }
                        
                        // Parameter selection if not shown in menu
                        if availableParameters.count > 0 && isLoading == false {
                            parameterSelectionView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Test Trends")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                loadTrendData()
                
            }
        }
    }
    
    private var statisticsView: some View {
        // Calculate statistics for current data
        let values = trendData.map { $0.value }
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        let avg = values.reduce(0, +) / Double(values.count)
        
        // Calculate trend
        let trend: String
        if values.count > 1 {
            let firstValue = values.first ?? 0
            let lastValue = values.last ?? 0
            let change = ((lastValue - firstValue) / firstValue) * 100
            
            if abs(change) < 5 {
                trend = "Stable"
            } else if change > 0 {
                trend = "Increasing"
            } else {
                trend = "Decreasing"
            }
        } else {
            trend = "N/A"
        }
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .font(.headline)
                .padding(.top, 8)
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Minimum")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", min))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading) {
                    Text("Maximum")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", max))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading) {
                    Text("Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", avg))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(trend)
                        .font(.subheadline)
                        .foregroundColor(getTrendColor(trend))
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func getTrendColor(_ trend: String) -> Color {
        switch trend {
        case "Increasing": return .red
        case "Decreasing": return .blue
        case "Stable": return .green
        default: return .primary
        }
    }
    
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Trend Data Available")
                .font(.headline)
            
            if selectedParameter != nil {
                Text("There isn't enough historical data to display trends for \(selectedParameter!).")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Select a parameter to view historical trends.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if dateRange != .all {
                Button(action: {
                    dateRange = .all
                    loadTrendData()
                }) {
                    Text("Show All-Time Data")
                        .font(.subheadline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Error Loading Trend Data")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                loadTrendData()
            }) {
                Text("Try Again")
                    .font(.subheadline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var parameterSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Parameters")
                .font(.headline)
                .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableParameters, id: \.self) { param in
                        Button(action: {
                            selectedParameter = param
                            updateChartForParameter()
                        }) {
                            Text(param)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedParameter == param ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedParameter == param ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func loadTrendData() {
        guard let patientID = patientID else {
            isLoading = false
            errorMessage = "No patient specified"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Calculate date range
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -dateRange.days, to: endDate) ?? endDate
        
        // Fetch request for tests
        let request: NSFetchRequest<MedicalTest> = MedicalTest.fetchRequest()
        
        // Filter by patient, test type and date range
        request.predicate = NSPredicate(format: "patient.objectID == %@ AND testType == %@ AND testDate >= %@ AND testDate <= %@",
                                       patientID,
                                       testType,
                                       startDate as NSDate,
                                       endDate as NSDate)
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicalTest.testDate, ascending: true)]
        
        do {
            let tests = try viewContext.fetch(request)
            
            if tests.isEmpty {
                availableParameters = []
                trendData = []
                isLoading = false
                return
            }
            
            // Get all available parameters
            var parameters = Set<String>()
            
            for test in tests {
                if let testParams = test.testParameters as? Set<TestParameter> {
                    for param in testParams {
                        if let name = param.parameterName, !name.isEmpty {
                            parameters.insert(name)
                        }
                    }
                }
            }
            
            availableParameters = Array(parameters).sorted()
            
            // Select first parameter if none selected
            if selectedParameter == nil && !availableParameters.isEmpty {
                selectedParameter = availableParameters.first
            }
            
            // Update chart for selected parameter
            updateChartForParameter(tests: tests)
            
        } catch {
            print("Error fetching tests: \(error)")
            errorMessage = "Failed to load test data: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func updateChartForParameter(tests: [MedicalTest]? = nil) {
        guard let paramName = selectedParameter else {
            trendData = []
            isLoading = false
            return
        }
        
        let testsToProcess: [MedicalTest]
        
        if let providedTests = tests {
            testsToProcess = providedTests
        } else {
            // If tests weren't provided, fetch them again
            guard let patientID = patientID else {
                isLoading = false
                return
            }
            
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -dateRange.days, to: endDate) ?? endDate
            
            let request: NSFetchRequest<MedicalTest> = MedicalTest.fetchRequest()
            request.predicate = NSPredicate(format: "patient.objectID == %@ AND testType == %@ AND testDate >= %@ AND testDate <= %@",
                                           patientID,
                                           testType,
                                           startDate as NSDate,
                                           endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicalTest.testDate, ascending: true)]
            
            do {
                testsToProcess = try viewContext.fetch(request)
            } catch {
                print("Error fetching tests for parameter update: \(error)")
                errorMessage = "Failed to load test data: \(error.localizedDescription)"
                isLoading = false
                return
            }
        }
        
        // Extract data for the selected parameter
        var chartData: [LineChartData] = []
        
        for test in testsToProcess {
            if let testParams = test.testParameters as? Set<TestParameter>,
               let param = testParams.first(where: { $0.parameterName == paramName }),
               let valueString = param.value,
               let value = Double(valueString),
               let date = test.testDate {
                
                chartData.append(LineChartData(
                    value: value,
                    label: formattedDate(date),
                    date: date
                ))
            }
        }
        
        trendData = chartData
        isLoading = false
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - TestReportPDFGenerator

class TestReportPDFGenerator {
    private let test: MedicalTest
    private let viewContext: NSManagedObjectContext
    
    private let pageWidth = 8.5 * 72.0    // 8.5 inches at 72 dpi
    private let pageHeight = 11 * 72.0    // 11 inches at 72 dpi
    private let margin: CGFloat = 50
    private var yPosition: CGFloat = 0
    
    init(test: MedicalTest, viewContext: NSManagedObjectContext) {
        self.test = test
        self.viewContext = viewContext
    }
    
    func generatePDF() -> Data {
        // Create a PDFDocument to hold the pages
        let pdfDocument = PDFDocument()
        
        // Create first page
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let format = UIGraphicsPDFRendererFormat()
        
        // Set PDF metadata
        let pdfMetaData: [String: Any] = [
            kCGPDFContextCreator as String: "SurgiTrack Medical System",
            kCGPDFContextAuthor as String: "SurgiTrack App",
            kCGPDFContextTitle as String: "Medical Test Report",
            kCGPDFContextSubject as String: test.testType ?? "Test Report"
        ]
        format.documentInfo = pdfMetaData
        
        // Create renderer for each page
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        // Generate content for first page
        let firstPageData = renderer.pdfData { context in
            context.beginPage()
            yPosition = margin
            
            drawHeader()
            drawPatientInfo()
            drawTestDetails()
            drawParameters(context: context)
            
            if let notes = test.notes, !notes.isEmpty {
                if yPosition > pageHeight - margin - 200 {
                    // Start a new page for notes if needed
                    drawPageFooter(pageNumber: 1)
                    context.beginPage()
                    yPosition = margin
                    drawHeader(isFirstPage: false)
                }
                drawNotes(notes)
            }
            
            drawPageFooter(pageNumber: pdfDocument.pageCount + 1)
        }
        
        // Convert data to PDFPage and add to document
        if let pdfPage = PDFPage(image: UIImage(data: firstPageData)!) {
            pdfDocument.insert(pdfPage, at: 0)
        }
        
        // Create attachment pages if needed
        if let attachments = test.attachments as? Set<Attachment>, !attachments.isEmpty {
            let imageAttachments = attachments.filter {
                $0.contentType?.hasPrefix("image") ?? false
            }
            
            for (index, attachment) in imageAttachments.enumerated() {
                if let data = attachment.data, let image = UIImage(data: data) {
                    let attachmentPageData = renderer.pdfData { context in
                        context.beginPage()
                        
                        // Draw attachment header
                        let titleFont = UIFont.boldSystemFont(ofSize: 14)
                        let title = "ATTACHMENT: \(attachment.filename ?? "Image \(index + 1)")" as NSString
                        title.draw(at: CGPoint(x: margin, y: margin), withAttributes: [.font: titleFont])
                        
                        // Calculate image size to fit page while maintaining aspect ratio
                        let maxWidth = pageWidth - (margin * 2)
                        let maxHeight = pageHeight - (margin * 3)
                        
                        let imageSize = image.size
                        let aspectRatio = imageSize.width / imageSize.height
                        
                        var drawWidth = maxWidth
                        var drawHeight = drawWidth / aspectRatio
                        
                        if drawHeight > maxHeight {
                            drawHeight = maxHeight
                            drawWidth = drawHeight * aspectRatio
                        }
                        
                        // Calculate position to center image
                        let xPos = (pageWidth - drawWidth) / 2
                        let yPos = margin + 30 + (maxHeight - drawHeight) / 2
                        
                        // Draw image
                        image.draw(in: CGRect(x: xPos, y: yPos, width: drawWidth, height: drawHeight))
                        
                        // Draw page footer
                        drawPageFooter(pageNumber: pdfDocument.pageCount + index + 1)
                    }
                    
                    if let pdfPage = PDFPage(image: UIImage(data: attachmentPageData)!) {
                        pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
                    }
                }
            }
        }
        
        // Update page count in each page
        let totalPages = pdfDocument.pageCount
        for i in 0..<totalPages {
            if let page = pdfDocument.page(at: i) {
                // Add page number annotation
                let pageNumberAnnotation = PDFAnnotation(
                    bounds: CGRect(x: pageWidth - margin - 100, y: pageHeight - margin, width: 100, height: 20),
                    forType: .freeText,
                    withProperties: nil
                )
                pageNumberAnnotation.contents = "Page \(i+1) of \(totalPages)"
                pageNumberAnnotation.color = .clear
                pageNumberAnnotation.font = UIFont.systemFont(ofSize: 8)
                pageNumberAnnotation.fontColor = .gray
                page.addAnnotation(pageNumberAnnotation)
            }
        }
        
        // Convert PDFDocument to Data
        if let data = pdfDocument.dataRepresentation() {
            return data
        }
        
        // Fallback to empty data if conversion fails
        return Data()
    }
    
    private func drawHeader(isFirstPage: Bool = true) {
        // Hospital/clinic logo
        if let logo = UIImage(named: "HospitalLogo") {
            let logoRect = CGRect(x: margin, y: yPosition, width: 100, height: 50)
            logo.draw(in: logoRect)
        }
        
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let subtitleFont = UIFont.systemFont(ofSize: 12)
        
        let titleString = isFirstPage ? "MEDICAL TEST REPORT" : "MEDICAL TEST REPORT (CONTINUED)"
            let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
            let titleSize = (titleString as NSString).size(withAttributes: titleAttributes)
            let titleX = (pageWidth - titleSize.width) / 2
            (titleString as NSString).draw(at: CGPoint(x: titleX, y: yPosition + 10), withAttributes: titleAttributes)
        
        if isFirstPage {
            // Draw test type on first page
            let subtitleString = test.testType ?? "Test Report"
            let subtitleAttributes: [NSAttributedString.Key: Any] = [.font: subtitleFont]
            
            // Cast to NSString only when calling methods that require it
            let subtitleSize = (subtitleString as NSString).size(withAttributes: subtitleAttributes)
            let subtitleX = (pageWidth - subtitleSize.width) / 2
            
            // Cast to NSString again for drawing
            (subtitleString as NSString).draw(at: CGPoint(x: subtitleX, y: yPosition + 35), withAttributes: subtitleAttributes)
        }
        
        // Draw horizontal line under header
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: yPosition + 60))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition + 60))
        UIColor.gray.setStroke()
        path.stroke()
        
        yPosition += 70
    }
    
    // Draw page numbers and footer
    private func drawPageFooter(pageNumber: Int) {
        let footerFont = UIFont.systemFont(ofSize: 8)
        let footerAttributes: [NSAttributedString.Key: Any] = [.font: footerFont, .foregroundColor: UIColor.gray]
        
        let footerY = pageHeight - margin
        
        // Draw line above footer
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: footerY - 10))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: footerY - 10))
        UIColor.gray.setStroke()
        path.stroke()
        
        // Footer text
        let footerText = "This report was generated by SurgiTrack Medical System. For official medical records, please contact your healthcare provider." as NSString
        footerText.draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttributes)
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        let dateString = "Generated: \(dateFormatter.string(from: Date()))" as NSString
        
        let dateSize = dateString.size(withAttributes: footerAttributes)
        dateString.draw(at: CGPoint(x: pageWidth - margin - dateSize.width, y: footerY - 20), withAttributes: footerAttributes)
    }
    
    private func drawPatientInfo() {
        let sectionFont = UIFont.boldSystemFont(ofSize: 12)
        let labelFont = UIFont.boldSystemFont(ofSize: 10)
        let valueFont = UIFont.systemFont(ofSize: 10)
        
        let sectionTitle = "PATIENT INFORMATION" as NSString
        sectionTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: sectionFont])
        
        yPosition += 20
        
        if let patient = test.patient {
            // Left column
            drawInfoRow(label: "Name:", value: patient.fullName, x: margin, y: yPosition, labelFont: labelFont, valueFont: valueFont)
            yPosition += 15
            
            if let mrn = patient.medicalRecordNumber {
                drawInfoRow(label: "MRN:", value: mrn, x: margin, y: yPosition, labelFont: labelFont, valueFont: valueFont)
            }
            yPosition += 15
            
            // Right column
            if let dob = patient.dateOfBirth {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                drawInfoRow(label: "DOB:", value: formatter.string(from: dob), x: margin + 250, y: yPosition - 30, labelFont: labelFont, valueFont: valueFont)
            }
            
            if let gender = patient.gender {
                drawInfoRow(label: "Gender:", value: gender, x: margin + 250, y: yPosition - 15, labelFont: labelFont, valueFont: valueFont)
            }
        }
        
        yPosition += 20
    }
    
    private func drawTestDetails() {
        let sectionFont = UIFont.boldSystemFont(ofSize: 12)
        let labelFont = UIFont.boldSystemFont(ofSize: 10)
        let valueFont = UIFont.systemFont(ofSize: 10)
        
        let sectionTitle = "TEST INFORMATION" as NSString
        sectionTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: sectionFont])
        
        yPosition += 20
        
        // Left column
        drawInfoRow(label: "Test Type:", value: test.testType ?? "Unknown", x: margin, y: yPosition, labelFont: labelFont, valueFont: valueFont)
        yPosition += 15
        
        if let testDate = test.testDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            drawInfoRow(label: "Date:", value: formatter.string(from: testDate), x: margin, y: yPosition, labelFont: labelFont, valueFont: valueFont)
        }
        yPosition += 15
        
        if let lab = test.laboratory, !lab.isEmpty {
            drawInfoRow(label: "Facility:", value: lab, x: margin, y: yPosition, labelFont: labelFont, valueFont: valueFont)
        }
        
        // Right column
        if let status = test.status {
            drawInfoRow(label: "Status:", value: status, x: margin + 250, y: yPosition - 30, labelFont: labelFont, valueFont: valueFont)
        }
        
        if let physician = test.orderingPhysician as? String, !physician.isEmpty  {
            drawInfoRow(label: "Ordered By:", value: physician, x: margin + 250, y: yPosition - 15, labelFont: labelFont, valueFont: valueFont)
        }
        
        yPosition += 30
    }
    
    private func drawParameters(context: UIGraphicsPDFRendererContext) {
        let sectionFont = UIFont.boldSystemFont(ofSize: 12)
        let labelFont = UIFont.boldSystemFont(ofSize: 10)
        let valueFont = UIFont.systemFont(ofSize: 10)
        
        let sectionTitle = "TEST RESULTS" as NSString
        sectionTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: sectionFont])
        
        yPosition += 20
        
        // Draw parameters table
        let parameters = (test.testParameters as? Set<TestParameter>)?.sorted { $0.displayOrder < $1.displayOrder } ?? []
        
        if parameters.isEmpty {
            let noParameters = "No parameters recorded for this test." as NSString
            noParameters.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: valueFont])
            yPosition += 20
            return
        }
        
        // Group parameters by category
        let groupedParameters = Dictionary(grouping: parameters) { $0.parameterCategory ?? "Other" }
        
        for (category, params) in groupedParameters.sorted(by: { $0.key < $1.key }) {
            // Draw category heading
            let categoryTitle = category as NSString
            categoryTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: labelFont])
            
            yPosition += 15
            
            // Draw table header
            drawParameterTableHeader(x: margin, y: yPosition)
            yPosition += 20
            
            // Draw parameters in this category
            for param in params {
                drawParameterRow(param, x: margin, y: yPosition, labelFont: valueFont, valueFont: valueFont)
                yPosition += 15
                
                // Check if we need a new page
                if yPosition > pageHeight - margin - 100 {
                    drawPageFooter(pageNumber: 1) // Temporary page number, will be updated later
                    context.beginPage()
                    yPosition = margin
                    drawHeader(isFirstPage: false)
                    drawParameterTableHeader(x: margin, y: yPosition)
                    yPosition += 20
                }
            }
            
            yPosition += 15
        }
    }
    
    private func drawParameterTableHeader(x: CGFloat, y: CGFloat) {
        let headerFont = UIFont.boldSystemFont(ofSize: 10)
        let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont]
        
        let paramHeader = "Parameter" as NSString
        let valueHeader = "Value" as NSString
        let unitsHeader = "Units" as NSString
        let referenceHeader = "Reference Range" as NSString
        let flagsHeader = "Flags" as NSString
        
        paramHeader.draw(at: CGPoint(x: x, y: y), withAttributes: headerAttributes)
        valueHeader.draw(at: CGPoint(x: x + 150, y: y), withAttributes: headerAttributes)
        unitsHeader.draw(at: CGPoint(x: x + 230, y: y), withAttributes: headerAttributes)
        referenceHeader.draw(at: CGPoint(x: x + 300, y: y), withAttributes: headerAttributes)
        flagsHeader.draw(at: CGPoint(x: x + 430, y: y), withAttributes: headerAttributes)
        
        // Draw line under headers
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y + 15))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y + 15))
        UIColor.gray.setStroke()
        path.stroke()
    }
    
    private func drawParameterRow(_ parameter: TestParameter, x: CGFloat, y: CGFloat, labelFont: UIFont, valueFont: UIFont) {
        let nameAttributes: [NSAttributedString.Key: Any] = [.font: labelFont]
        let valueAttributes: [NSAttributedString.Key: Any] = [.font: valueFont]
        let abnormalAttributes: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: UIColor.red]
        
        let name = (parameter.parameterName ?? "Unknown") as NSString
        let value = (parameter.value ?? "") as NSString
        let unit = (parameter.unit ?? "") as NSString
        
        // Reference range text
        let referenceText: NSString
        if let refText = parameter.referenceText, !refText.isEmpty {
            referenceText = refText as NSString
        } else if parameter.referenceRangeLow > 0 || parameter.referenceRangeHigh > 0 {
            referenceText = "\(parameter.referenceRangeLow)-\(parameter.referenceRangeHigh)" as NSString
        } else {
            referenceText = "N/A" as NSString
        }
        
        name.draw(at: CGPoint(x: x, y: y), withAttributes: nameAttributes)
        value.draw(at: CGPoint(x: x + 150, y: y), withAttributes: parameter.isAbnormal ? abnormalAttributes : valueAttributes)
        unit.draw(at: CGPoint(x: x + 230, y: y), withAttributes: valueAttributes)
        referenceText.draw(at: CGPoint(x: x + 300, y: y), withAttributes: valueAttributes)
        
        if parameter.isAbnormal {
            let flag = "ABNORMAL" as NSString
            flag.draw(at: CGPoint(x: x + 430, y: y), withAttributes: abnormalAttributes)
        }
    }
    
    private func drawNotes(_ notes: String) {
        let sectionFont = UIFont.boldSystemFont(ofSize: 12)
        let valueFont = UIFont.systemFont(ofSize: 10)
        
        let sectionTitle = "NOTES" as NSString
        sectionTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: sectionFont])
        
        yPosition += 20
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let notesAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .paragraphStyle: paragraphStyle
        ]
        
        let notesWidth = pageWidth - (margin * 2)
        let notesRect = CGRect(x: margin, y: yPosition, width: notesWidth, height: 1000)
        
        (notes as NSString).draw(in: notesRect, withAttributes: notesAttributes)
        
        // Calculate height of text
        let notesHeight = (notes as NSString).boundingRect(with: CGSize(width: notesWidth, height: 1000),
                                                        options: .usesLineFragmentOrigin,
                                                        attributes: notesAttributes, context: nil).height
        yPosition += notesHeight + 20
    }
    
    private func drawInfoRow(label: String, value: String, x: CGFloat, y: CGFloat, labelFont: UIFont, valueFont: UIFont) {
        let labelString = label as NSString
        let valueString = value as NSString
        
        labelString.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: labelFont])
        valueString.draw(at: CGPoint(x: x + 70, y: y), withAttributes: [.font: valueFont])
    }
}
// MARK: - LogManager for tracking events
class LogManager {
    static let shared = LogManager()
    
    enum LogCategory: String {
        case data = "DATA"
        case export = "EXPORT"
        case user = "USER"
        case error = "ERROR"
    }
    
    enum LogAction: String {
        case create = "CREATE"
        case read = "READ"
        case update = "UPDATE"
        case delete = "DELETE"
        case export = "EXPORT"
        case error = "ERROR"
    }
    
    func logEvent(category: LogCategory, action: LogAction, detail: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logString = "[\(timestamp)] [\(category.rawValue)] [\(action.rawValue)] \(detail)"
        print(logString)
        
        // In a real app, this would save to a log file or send to a logging service
    }
}
