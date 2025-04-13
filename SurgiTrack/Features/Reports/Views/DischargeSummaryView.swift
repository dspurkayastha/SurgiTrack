import SwiftUI
import CoreData
import PDFKit

struct DischargeSummaryView: View {
    // MARK: - Environment & Objects
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    
    // Discharge Summary to display
    @ObservedObject var dischargeSummary: DischargeSummary
    
    // State
    @State private var showingShareSheet = false
    @State private var generatedPDF: URL? = nil
    @State private var isGeneratingPDF = false
    
    // MARK: - Computed Properties
    var patient: Patient? {
        dischargeSummary.patient
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                summaryHeader
                
                Group {
                    // Length of stay
                    if let admissionDate = patient?.dateCreated,
                       let dischargeDate = dischargeSummary.dischargeDate {
                        let days = Calendar.current.dateComponents([.day], from: admissionDate, to: dischargeDate).day ?? 0
                        if days > 0 {
                            infoCard(title: "Length of Stay") {
                                Text("\(days) day\(days == 1 ? "" : "s")")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    
                    // Diagnoses section
                    infoCard(title: "Diagnoses") {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionRow(title: "Primary Diagnosis", content: dischargeSummary.primaryDiagnosis ?? "")
                            
                            if let secondaryDiagnoses = dischargeSummary.secondaryDiagnoses, !secondaryDiagnoses.isEmpty {
                                sectionRow(title: "Secondary Diagnoses", content: secondaryDiagnoses)
                            }
                        }
                    }
                    
                    // Treatment section
                    infoCard(title: "Treatment Summary") {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionRow(title: "Treatment Provided", content: dischargeSummary.treatmentSummary ?? "")
                            
                            if let procedures = dischargeSummary.procedures, !procedures.isEmpty {
                                sectionRow(title: "Procedures Performed", content: procedures)
                            }
                        }
                    }
                    
                    // Medications section
                    infoCard(title: "Medications") {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionRow(title: "Current Medications", content: dischargeSummary.medicationsAtDischarge ?? "")
                            sectionRow(title: "Discharge Prescriptions", content: dischargeSummary.dischargeMedications ?? "")
                        }
                    }
                    
                    // Follow-up instructions
                    infoCard(title: "Follow-up Care") {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionRow(title: "Follow-up Instructions", content: dischargeSummary.followUpInstructions ?? "")
                            
                            if let activityRestrictions = dischargeSummary.activityRestrictions, !activityRestrictions.isEmpty {
                                sectionRow(title: "Activity Restrictions", content: activityRestrictions)
                            }
                            
                            if let dietaryInstructions = dischargeSummary.dietaryInstructions, !dietaryInstructions.isEmpty {
                                sectionRow(title: "Dietary Instructions", content: dietaryInstructions)
                            }
                        }
                    }
                    
                    // Return precautions
                    infoCard(title: "Return Precautions") {
                        Text(dischargeSummary.returnPrecautions ?? "")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Provider information
                    infoCard(title: "Discharge Information") {
                        VStack(alignment: .leading, spacing: 10) {
                            if let dischargingPhysician = dischargeSummary.dischargingPhysician, !dischargingPhysician.isEmpty {
                                sectionRow(title: "Discharging Physician", content: dischargingPhysician)
                            }
                            
                            if let dischargeDate = dischargeSummary.dischargeDate {
                                sectionRow(title: "Discharge Date", content: dateFormatter.string(from: dischargeDate))
                            }
                            
                            if patient?.bedNumber != nil {
                                sectionRow(title: "Bed Number", content: patient?.bedNumber ?? "Not assigned")
                            }
                            
                            if let additionalNotes = dischargeSummary.additionalNotes, !additionalNotes.isEmpty {
                                sectionRow(title: "Additional Notes", content: additionalNotes)
                            }
                        }
                    }
                    
                    // Discharge checklist
                    checklistCard
                }
                
                // Action buttons row
                buttonRow
                
                // PDF generation indicator
                if isGeneratingPDF {
                    ProgressView("Generating PDF...")
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Discharge Summary")
        .navigationBarTitleDisplayMode(.inline)
        // Toolbar for share button, if you like:
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    generateAndSharePDF()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(isGeneratingPDF)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdf = generatedPDF {
                ShareSheet(items: [pdf])
            }
        }
    }
    
    // MARK: - Header
    private var summaryHeader: some View {
        ZStack {
            // **Metallic** gradient arrays for light vs. dark mode:
            let lightGrayMetal: [Color] = [
                Color(hex: "F4F4F4"), // fairly bright near top-left
                Color(hex: "9EA3A8"), // mid steel
                Color(hex: "3C4349")  // darkest near bottom-right
            ]
            let darkGrayMetal: [Color] = [
                Color(hex: "26282A"), // less bright but still lighter top-left
                Color(hex: "3F4548"), // mid
                Color(hex: "71787B")  // lighter highlight near bottom-right
            ]
            
            // Decide which array to use:
            let backgroundColors = (colorScheme == .dark) ? darkGrayMetal : lightGrayMetal
            
            // Main multi-stop gradient
            LinearGradient(
                gradient: Gradient(colors: backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(12)
            
            // Two overlay highlights for metallic sheen
            ZStack {
                // Top-left highlight
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white.opacity(0.3), location: 0.0),
                        .init(color: .clear, location: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .blendMode(.screen)
                
                // Bottom-right highlight
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white.opacity(0.2), location: 0.0),
                        .init(color: .clear, location: 0.4)
                    ]),
                    startPoint: .bottomTrailing,
                    endPoint: .center
                )
                .blendMode(.overlay)
            }
            .allowsHitTesting(false)
            .cornerRadius(12)
            
            // Content: HStack with patient image + text
            HStack(spacing: 16) {
                // If the patient has an image, use it; else show fallback
                if let patient = patient,
                   let imageData = patient.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 60, height: 60)
                        Image(systemName: "person.circle")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Larger, softly glowing patient name
                    Text(patient?.fullName ?? "Unknown Patient")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 0)
                    
                    if let mrn = patient?.medicalRecordNumber, !mrn.isEmpty {
                        Text("MRN: \(mrn)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if let dischargeDate = dischargeSummary.dischargeDate {
                        Text("Discharged on \(dateFormatter.string(from: dischargeDate))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.bottom, 8)
    }
    
    // MARK: - Info Card
    private func infoCard<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(appState.currentTheme.primaryColor)
            
            Divider()
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func sectionRow(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Checklist
    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Discharge Checklist")
                .font(.headline)
                .foregroundColor(appState.currentTheme.primaryColor)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                checklistRow("Patient education completed", isChecked: dischargeSummary.patientEducationCompleted)
                checklistRow("Medications reconciled", isChecked: dischargeSummary.medicationsReconciled)
                checklistRow("Follow-up appointment scheduled", isChecked: dischargeSummary.followUpAppointmentScheduled)
                checklistRow("Medical devices provided (if needed)", isChecked: dischargeSummary.medicalDevicesProvided)
                checklistRow("Transportation arranged", isChecked: dischargeSummary.transportationArranged)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func checklistRow(_ text: String, isChecked: Bool) -> some View {
        HStack {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundColor(isChecked ? .green : .gray)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
    
    // MARK: - Bottom Button Row
    private var buttonRow: some View {
        HStack(spacing: 8) {
            // Export PDF
            Button(action: {
                generateAndSharePDF()
            }) {
                Text("Export PDF")
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .buttonStyle(ModernButtonStyle(backgroundColor: .green))
            .disabled(isGeneratingPDF)
            
            // Readmit (only if discharged)
            if let patient = patient, patient.isDischargedStatus {
                Button(action: {
                    readmitPatient()
                }) {
                    Text("Readmit")
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .buttonStyle(ModernButtonStyle(backgroundColor: .orange))
            }
            
            // Done
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .buttonStyle(ModernButtonStyle(backgroundColor: .blue))
        }
        .padding(.top, 8)
    }
    
    // MARK: - Logic: Readmit
    private func readmitPatient() {
        guard let patient = patient else { return }
        
        // Reactivate patient
        patient.isDischargedStatus = false
        patient.dateModified = Date()
        
        // Save changes
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error readmitting patient: \(error)")
        }
    }
    
    // MARK: - Logic: Generate & Share PDF
    private func generateAndSharePDF() {
        isGeneratingPDF = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let currentUser = UIDevice.current.name
            
            // Fetch the current UserProfile from Core Data
            let fetchRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isCurrentUser == YES")
            
            var currentUserProfile: UserProfile?
            do {
                let results = try self.viewContext.fetch(fetchRequest)
                currentUserProfile = results.first
            } catch {
                print("Error fetching current user profile: \(error)")
            }
            
            // If no UserProfile is found, create a dummy instance with placeholder values.
            if currentUserProfile == nil {
                let dummyUserProfile = UserProfile(context: self.viewContext)
                dummyUserProfile.firstName = "Dr"
                dummyUserProfile.lastName = "" // You can add a placeholder last name if desired.
                // Optionally set default hospital details if needed:
                dummyUserProfile.hospitalName = "Default Hospital Name"
                dummyUserProfile.hospitalAddress = "Default Hospital Address"
                dummyUserProfile.departmentName = "Default Department"
                dummyUserProfile.unitName = "Default Unit"
                currentUserProfile = dummyUserProfile
            }
            
            guard let userProfile = currentUserProfile else {
                DispatchQueue.main.async {
                    print("No user profile available")
                    self.isGeneratingPDF = false
                }
                return
            }
            
            let pdfGenerator = DischargeSummaryPDFGenerator(
                dischargeSummary: self.dischargeSummary,
                viewContext: self.viewContext,
                currentUser: currentUser,
                userProfile: userProfile
            )
            let pdfData = pdfGenerator.generatePDF()
            
            // Create a temporary file URL for the PDF
            let tempDir = FileManager.default.temporaryDirectory
            let patientName = self.patient?.fullName.replacingOccurrences(of: " ", with: "_") ?? "Patient"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "Discharge_Summary_\(patientName)_\(dateString).pdf"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            do {
                try pdfData.write(to: fileURL)
                DispatchQueue.main.async {
                    self.generatedPDF = fileURL
                    self.isGeneratingPDF = false
                    self.showingShareSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error creating PDF file: \(error)")
                    self.isGeneratingPDF = false
                }
            }
        }
    }
    
    
    // MARK: - Share Sheet
    struct ShareSheet: UIViewControllerRepresentable {
        var items: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: items, applicationActivities: nil)
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
            // nothing
        }
    }
    
}
