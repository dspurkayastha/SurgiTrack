import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct AddMedicalTestView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    var patient: Patient?
    @Binding var testType: TestType?
    
    // MARK: - State
    @State private var selectedPatientID: NSManagedObjectID?
    @State private var selectedTestType: String = ""
    @State private var testDate = Date()
    @State private var laboratory = ""
    @State private var orderingPhysicianName = ""
    @State private var testNotes = ""
    @State private var testStatus = "Pending"
    @State private var isAbnormal = false
    @State private var showingPatientPicker = false
    @State private var showingAttachments = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedParameters: [TestParameterTemplate] = []
    @State private var showingParameterEditor = false
    @State private var createdTest: MedicalTest?
    @State private var isUploadingAttachment = false
    
    // Radiology specific fields
    @State private var radiologyFindings = ""
    @State private var radiologyImpression = ""
    @State private var anatomicalStructures: [String: String] = [:]
    @State private var measurements: [String: String] = [:]
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return (patient != nil || selectedPatientID != nil) && !selectedTestType.isEmpty
    }
    
    private var isRadiologyTest: Bool {
        let radiologyTests = ["USG", "MRI", "MRCP", "CECT", "CT", "X-Ray"]
        return radiologyTests.contains { selectedTestType.contains($0) }
    }
    
    // Anatomical structures based on test type
    private var relevantAnatomicalStructures: [String] {
        switch selectedTestType {
        case "USG (Hepatobiliary)":
            return ["Liver", "Gallbladder", "Bile Ducts", "Portal Vein", "Hepatic Veins"]
        case "USG (Inguinal)":
            return ["Inguinal Canal", "Internal Ring", "External Ring", "Spermatic Cord", "Testes"]
        case "USG (Whole Abdomen)":
            return ["Liver", "Gallbladder", "Pancreas", "Spleen", "Kidneys", "Bowel", "Bladder"]
        case "USG (KUBP)":
            return ["Kidneys", "Ureters", "Bladder", "Prostate/Uterus"]
        case "MRCP":
            return ["Liver", "Biliary Tree", "Pancreatic Duct", "Gallbladder"]
        case "MRI Perineum":
            return ["Anal Canal", "Sphincter Complex", "Ischiorectal Fossa", "Levator Ani"]
        case "MRI Pelvis":
            return ["Bladder", "Rectum", "Prostate/Uterus", "Seminal Vesicles/Ovaries", "Pelvic Lymph Nodes"]
        case "CECT (Thorax)":
            return ["Lungs", "Pleura", "Mediastinum", "Chest Wall", "Great Vessels"]
        case "CECT (Abdomen)":
            return ["Liver", "Spleen", "Pancreas", "Kidneys", "Bowel", "Vessels", "Lymph Nodes"]
        case "CECT (Triphasic)":
            return ["Liver", "Hepatic Arteries", "Portal Veins", "Hepatic Veins", "Lesions"]
        default:
            return []
        }
    }
    
    // Measurements needed based on test type
    private var relevantMeasurements: [String] {
        switch selectedTestType {
        case "USG (Hepatobiliary)":
            return ["Liver Span", "CBD Diameter", "Portal Vein Diameter", "Gallbladder Wall Thickness"]
        case "USG (Inguinal)":
            return ["Inguinal Canal Length", "Defect Size (if present)", "Hernia Sac Diameter (if present)"]
        case "USG (Whole Abdomen)":
            return ["Liver Span", "Spleen Size", "Kidney Dimensions", "Aortic Diameter"]
        case "USG (KUBP)":
            return ["Kidney Dimensions", "Bladder Wall Thickness", "Post-void Residual Volume", "Prostate Volume (males)"]
        case "MRCP":
            return ["CBD Diameter", "Pancreatic Duct Diameter", "Lesion Size (if present)"]
        case "MRI Perineum", "MRI Pelvis":
            return ["Lesion Size (if present)", "Fistula Length (if present)", "Wall Thickness"]
        case "CECT (Thorax)", "CECT (Abdomen)", "CECT (Triphasic)":
            return ["Lesion Size (if present)", "Lymph Node Size (if present)", "Wall Thickness"]
        default:
            return []
        }
    }
    
    // Test type options
    private let standardTestTypes = [
        "Complete Blood Count",
        "Comprehensive Metabolic Panel",
        "Liver Function Test",
        "Kidney Function Test",
        "Urinalysis",
        "Lipid Profile",
        "Coagulation Profile",
        "Tumor Markers" // Added new test type
    ]
    
    private let radiologyTestTypes = [
        "USG (Hepatobiliary)",
        "USG (Inguinal)",
        "USG (Whole Abdomen)",
        "USG (KUBP)",
        "MRCP",
        "MRI Perineum",
        "MRI Pelvis",
        "CECT (Thorax)",
        "CECT (Abdomen)",
        "CECT (Triphasic)",
        "X-Ray",
        "CT Scan",
        "MRI"
    ]
    
    // Status options
    private let statusOptions = ["Pending", "Completed", "Abnormal", "Cancelled"]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Patient selection section
                Section(header: Text("Patient Information")) {
                    if let existingPatient = patient {
                        HStack {
                            Text("Patient")
                            Spacer()
                            Text(existingPatient.fullName)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // Patient picker button
                        HStack {
                            Text("Patient")
                            Spacer()
                            Button(action: {
                                showingPatientPicker = true
                            }) {
                                HStack {
                                    if let patientID = selectedPatientID,
                                       let patient = fetchPatient(by: patientID) {
                                        Text(patient.fullName)
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("Select Patient")
                                            .foregroundColor(.blue)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                // Test information
                Section(header: Text("Test Information")) {
                    // Test type picker with segmented control
                    VStack(alignment: .leading) {
                        Text("Test Type")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Test Category", selection: $selectedTestType) {
                            // Show relevant options based on test type passed in
                            ForEach([standardTestTypes, radiologyTestTypes].flatMap { $0 }, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedTestType) { newValue in
                            // Initialize anatomical structures and measurements when test type changes
                            initializeFieldsForTestType()
                        }
                    }
                    
                    DatePicker("Test Date", selection: $testDate,
                              in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Laboratory/Facility", text: $laboratory)
                    
                    TextField("Ordering Physician", text: $orderingPhysicianName)
                    
                    Picker("Status", selection: $testStatus) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status).tag(status)
                        }
                    }
                    
                    Toggle("Abnormal Results", isOn: $isAbnormal)
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                }
                
                // Radiology specific section
                if isRadiologyTest {
                    radiologySection
                }
                
                // Test parameters section for lab tests
                if !isRadiologyTest {
                    Section(header: Text("Test Parameters")) {
                        if selectedParameters.isEmpty {
                            Button(action: {
                                // Load default parameters for selected test type
                                selectedParameters = getDefaultParameters(for: selectedTestType)
                                showingParameterEditor = true
                            }) {
                                Label("Add Parameters", systemImage: "plus.circle")
                            }
                        } else {
                            ForEach(selectedParameters) { parameter in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(parameter.name)
                                            .font(.headline)
                                        
                                        if !parameter.value.isEmpty {
                                            Text("\(parameter.value) \(parameter.unit)")
                                                .font(.subheadline)
                                                .foregroundColor(parameter.isAbnormal ? .red : .secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if parameter.isAbnormal {
                                        Text("Abnormal")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .onDelete(perform: deleteParameter)
                            
                            Button(action: {
                                showingParameterEditor = true
                            }) {
                                Label("Edit Parameters", systemImage: "pencil")
                            }
                        }
                    }
                }
                
                // Notes section
                Section(header: Text("Notes")) {
                    TextEditor(text: $testNotes)
                        .frame(minHeight: 100)
                }
                
                // Attachments section
                if createdTest != nil {
                    Section {
                        Button(action: {
                            showingAttachments = true
                        }) {
                            HStack {
                                Image(systemName: "paperclip")
                                Text("Manage Attachments")
                            }
                        }
                    }
                }
            }
            .navigationTitle(isRadiologyTest ? "Add Imaging Test" : "Add Laboratory Test")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTest()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingPatientPicker) {
                PatientPickerView(selectedID: $selectedPatientID)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $showingParameterEditor) {
                ParameterEditorView(parameters: $selectedParameters, testType: selectedTestType)
            }
            .sheet(isPresented: $showingAttachments) {
                if let test = createdTest {
                    AttachmentView(parent: .medicalTest(test))
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                // Initialize test type if passed in
                if let type = testType {
                    selectedTestType = type.rawValue
                    initializeFieldsForTestType()
                    // Reset the binding to avoid repeated changes
                    DispatchQueue.main.async {
                        self.testType = nil
                    }
                }
            }
            .overlay(
                Group {
                    if isUploadingAttachment {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                
                                Text("Processing Test Report...")
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
    }
    
    // MARK: - Radiology Section
    
    private var radiologySection: some View {
        Group {
            // Findings section
            Section(header: Text("Radiological Findings")) {
                TextEditor(text: $radiologyFindings)
                    .frame(minHeight: 120)
            }
            
            // Anatomical structures section
            if !relevantAnatomicalStructures.isEmpty {
                Section(header: Text("Anatomical Structures")) {
                    ForEach(relevantAnatomicalStructures, id: \.self) { structure in
                        VStack(alignment: .leading) {
                            Text(structure)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Findings", text: Binding(
                                get: { anatomicalStructures[structure] ?? "" },
                                set: { anatomicalStructures[structure] = $0 }
                            ))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Measurements section
            if !relevantMeasurements.isEmpty {
                Section(header: Text("Measurements")) {
                    ForEach(relevantMeasurements, id: \.self) { measurement in
                        VStack(alignment: .leading) {
                            Text(measurement)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                TextField("Value", text: Binding(
                                    get: { measurements[measurement] ?? "" },
                                    set: { measurements[measurement] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                
                                // Add units as appropriate
                                Text(measurementUnit(for: measurement))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Impression section
            Section(header: Text("Impression")) {
                TextEditor(text: $radiologyImpression)
                    .frame(minHeight: 120)
            }
        }
    }
    
    // MARK: - Methods
    
    private func fetchPatient(by id: NSManagedObjectID) -> Patient? {
        return viewContext.object(with: id) as? Patient
    }
    
    private func fetchUserProfile(named name: String) -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@", name, name)
        request.fetchLimit = 1
        do {
            let profiles = try viewContext.fetch(request)
            return profiles.first
        } catch {
            print("Error fetching user profile: \(error)")
            return nil
        }
    }
    
    private func initializeFieldsForTestType() {
        // Clear existing data
        anatomicalStructures = [:]
        measurements = [:]
        
        // Initialize with empty strings
        for structure in relevantAnatomicalStructures {
            anatomicalStructures[structure] = ""
        }
        
        for measurement in relevantMeasurements {
            measurements[measurement] = ""
        }
    }
    
    private func measurementUnit(for measurement: String) -> String {
        if measurement.contains("Diameter") || measurement.contains("Size") || measurement.contains("Thickness") || measurement.contains("Length") {
            return "mm"
        } else if measurement.contains("Span") || measurement.contains("Dimensions") {
            return "cm"
        } else if measurement.contains("Volume") {
            return "mL"
        } else {
            return ""
        }
    }
    
    private func saveTest() {
        guard isFormValid else {
            alertMessage = "Please select a patient and test type"
            showingAlert = true
            return
        }
        
        // Create new MedicalTest
        let newTest = MedicalTest(context: viewContext)
        newTest.id = UUID()
        newTest.testType = selectedTestType
        newTest.testDate = testDate
        newTest.laboratory = laboratory.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Store the physician name in the notes field since orderingPhysician is a relationship to UserProfile
        let physicianName = orderingPhysicianName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !physicianName.isEmpty {
            // Try to find the physician in UserProfile entities
            if let physician = fetchUserProfile(named: physicianName) {
                newTest.orderingPhysician = physician
            } else {
                // If physician not found, add to notes
                let physicianInfo = "Ordering Physician: \(physicianName)"
                if newTest.notes?.isEmpty ?? true {
                    newTest.notes = physicianInfo
                } else {
                    newTest.notes = physicianInfo + "\n\n" + (newTest.notes ?? "")
                }
            }
        }
        
        newTest.status = testStatus
        newTest.isAbnormal = isAbnormal
        newTest.resultEntryDate = Date()
        
        // Add additional notes
        if !testNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if newTest.notes?.isEmpty ?? true {
                newTest.notes = testNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                newTest.notes = (newTest.notes ?? "") + "\n\n" + testNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Set test category based on type
        if selectedTestType.contains("Blood") || selectedTestType.contains("CBC") {
            newTest.testCategory = "Hematology"
        } else if selectedTestType.contains("Metabolic") || selectedTestType.contains("Liver") || selectedTestType.contains("Kidney") {
            newTest.testCategory = "Chemistry"
        } else if selectedTestType.contains("X-Ray") || selectedTestType.contains("CT") ||
                  selectedTestType.contains("MRI") || selectedTestType.contains("USG") ||
                  selectedTestType.contains("CECT") || selectedTestType.contains("MRCP") {
            newTest.testCategory = "Imaging"
        } else if selectedTestType.contains("Urinalysis") {
            newTest.testCategory = "Urinalysis"
        } else if selectedTestType.contains("Coagulation") {
            newTest.testCategory = "Coagulation"
        } else if selectedTestType.contains("Lipid") {
            newTest.testCategory = "Lipids"
        } else if selectedTestType.contains("Tumor") {
            newTest.testCategory = "Oncology"
        } else {
            newTest.testCategory = "Other"
        }
        
        // Connect to patient
        if let existingPatient = patient {
            newTest.patient = existingPatient
        } else if let patientID = selectedPatientID {
            newTest.patient = fetchPatient(by: patientID)
        }
        
        // Handle radiology specific data
        if isRadiologyTest {
            // Combine findings
            var combinedFindings = radiologyFindings.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Add structured anatomical findings
            if !anatomicalStructures.isEmpty {
                combinedFindings += "\n\nANATOMICAL STRUCTURES:\n"
                for (structure, finding) in anatomicalStructures {
                    if !finding.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        combinedFindings += "\n• \(structure): \(finding.trimmingCharacters(in: .whitespacesAndNewlines))"
                    }
                }
            }
            
            // Add measurements
            if !measurements.isEmpty {
                combinedFindings += "\n\nMEASUREMENTS:\n"
                for (measurement, value) in measurements {
                    if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        combinedFindings += "\n• \(measurement): \(value.trimmingCharacters(in: .whitespacesAndNewlines)) \(measurementUnit(for: measurement))"
                    }
                }
            }
            
            // Set findings to the notes field
            if newTest.notes?.isEmpty ?? true {
                newTest.notes = combinedFindings
            } else {
                newTest.notes = (newTest.notes ?? "") + "\n\n" + combinedFindings
            }
            
            // Set impression to the summary field
            newTest.summary = radiologyImpression.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create a test parameter for each measurement (for data analysis purposes)
            for (measurement, value) in measurements {
                if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let parameter = TestParameter(context: viewContext)
                    parameter.id = UUID()
                    parameter.parameterName = measurement
                    parameter.parameterCategory = "Measurements"
                    parameter.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    parameter.unit = measurementUnit(for: measurement)
                    parameter.isAbnormal = false // Default to normal unless explicitly marked
                    parameter.medicalTest = newTest
                }
            }
        } else {
            // Add parameters for lab tests
            for paramTemplate in selectedParameters {
                let parameter = TestParameter(context: viewContext)
                parameter.id = UUID()
                parameter.parameterName = paramTemplate.name
                parameter.parameterCategory = paramTemplate.category
                parameter.value = paramTemplate.value
                parameter.unit = paramTemplate.unit
                parameter.referenceRangeLow = paramTemplate.rangeLow
                parameter.referenceRangeHigh = paramTemplate.rangeHigh
                parameter.referenceText = paramTemplate.referenceText
                parameter.isAbnormal = paramTemplate.isAbnormal
                parameter.numericValue = Double(paramTemplate.value) ?? 0.0
                parameter.displayOrder = Int16(paramTemplate.order)
                parameter.medicalTest = newTest
            }
            
            // Update any abnormal flags based on parameters
            if !isAbnormal && selectedParameters.contains(where: { $0.isAbnormal }) {
                newTest.isAbnormal = true
            }
            
            // Generate summary if parameters exist
            if !selectedParameters.isEmpty {
                let abnormalCount = selectedParameters.filter { $0.isAbnormal }.count
                if abnormalCount > 0 {
                    newTest.summary = "\(abnormalCount) abnormal parameter(s) found"
                } else {
                    newTest.summary = "All parameters within normal range"
                }
            }
        }
        
        do {
            try viewContext.save()
            createdTest = newTest
            
            // Show attachment view
            isUploadingAttachment = false
            showingAttachments = true
        } catch {
            alertMessage = "Error saving test: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteParameter(at offsets: IndexSet) {
        selectedParameters.remove(atOffsets: offsets)
    }
    
    private func getDefaultParameters(for testType: String) -> [TestParameterTemplate] {
        switch testType {
        case "Complete Blood Count":
            return [
                TestParameterTemplate(name: "RBC", category: "Blood Cells", unit: "mill/mm³", rangeLow: 4.5, rangeHigh: 5.9, order: 1),
                TestParameterTemplate(name: "Hemoglobin", category: "Blood Cells", unit: "g/dL", rangeLow: 12.0, rangeHigh: 15.5, order: 2),
                TestParameterTemplate(name: "Hematocrit", category: "Blood Cells", unit: "%", rangeLow: 36.0, rangeHigh: 46.0, order: 3),
                TestParameterTemplate(name: "WBC", category: "Blood Cells", unit: "thou/mm³", rangeLow: 4.5, rangeHigh: 11.0, order: 4),
                TestParameterTemplate(name: "Neutrophils", category: "Differential", unit: "%", rangeLow: 40.0, rangeHigh: 70.0, order: 5),
                TestParameterTemplate(name: "Lymphocytes", category: "Differential", unit: "%", rangeLow: 20.0, rangeHigh: 40.0, order: 6),
                TestParameterTemplate(name: "Platelets", category: "Platelets", unit: "thou/mm³", rangeLow: 150.0, rangeHigh: 450.0, order: 7)
            ]
        case "Liver Function Test":
            return [
                TestParameterTemplate(name: "ALT", category: "Enzymes", unit: "U/L", rangeLow: 7.0, rangeHigh: 55.0, order: 1),
                TestParameterTemplate(name: "AST", category: "Enzymes", unit: "U/L", rangeLow: 8.0, rangeHigh: 48.0, order: 2),
                TestParameterTemplate(name: "ALP", category: "Enzymes", unit: "U/L", rangeLow: 40.0, rangeHigh: 129.0, order: 3),
                TestParameterTemplate(name: "GGT", category: "Enzymes", unit: "U/L", rangeLow: 8.0, rangeHigh: 61.0, order: 4),
                TestParameterTemplate(name: "Total Bilirubin", category: "Bilirubin", unit: "mg/dL", rangeLow: 0.1, rangeHigh: 1.2, order: 5),
                TestParameterTemplate(name: "Direct Bilirubin", category: "Bilirubin", unit: "mg/dL", rangeLow: 0.0, rangeHigh: 0.3, order: 6),
                TestParameterTemplate(name: "Albumin", category: "Proteins", unit: "g/dL", rangeLow: 3.4, rangeHigh: 5.4, order: 7),
                TestParameterTemplate(name: "Protein Total", category: "Proteins", unit: "g/dL", rangeLow: 6.0, rangeHigh: 8.3, order: 8)
            ]
        case "Kidney Function Test":
            return [
                TestParameterTemplate(name: "Creatinine", category: "Kidney", unit: "mg/dL", rangeLow: 0.6, rangeHigh: 1.2, order: 1),
                TestParameterTemplate(name: "BUN", category: "Kidney", unit: "mg/dL", rangeLow: 7.0, rangeHigh: 20.0, order: 2),
                TestParameterTemplate(name: "eGFR", category: "Kidney", unit: "mL/min", rangeLow: 90.0, rangeHigh: 120.0, order: 3),
                TestParameterTemplate(name: "Sodium", category: "Electrolytes", unit: "mmol/L", rangeLow: 135.0, rangeHigh: 145.0, order: 4),
                TestParameterTemplate(name: "Potassium", category: "Electrolytes", unit: "mmol/L", rangeLow: 3.5, rangeHigh: 5.0, order: 5),
                TestParameterTemplate(name: "Chloride", category: "Electrolytes", unit: "mmol/L", rangeLow: 96.0, rangeHigh: 106.0, order: 6)
            ]
        case "Coagulation Profile":
            return [
                TestParameterTemplate(name: "PT", category: "Coagulation", unit: "sec", rangeLow: 11.0, rangeHigh: 13.5, order: 1),
                TestParameterTemplate(name: "INR", category: "Coagulation", unit: "", rangeLow: 0.8, rangeHigh: 1.1, order: 2),
                TestParameterTemplate(name: "aPTT", category: "Coagulation", unit: "sec", rangeLow: 25.0, rangeHigh: 35.0, order: 3),
                TestParameterTemplate(name: "D-dimer", category: "Coagulation", unit: "µg/mL", rangeLow: 0.0, rangeHigh: 0.5, order: 4)
            ]
        case "Lipid Profile":
            return [
                TestParameterTemplate(name: "Total Cholesterol", category: "Lipids", unit: "mg/dL", rangeLow: 125.0, rangeHigh: 200.0, order: 1),
                TestParameterTemplate(name: "LDL", category: "Lipids", unit: "mg/dL", rangeLow: 0.0, rangeHigh: 130.0, order: 2),
                TestParameterTemplate(name: "HDL", category: "Lipids", unit: "mg/dL", rangeLow: 40.0, rangeHigh: 60.0, order: 3),
                TestParameterTemplate(name: "Triglycerides", category: "Lipids", unit: "mg/dL", rangeLow: 0.0, rangeHigh: 150.0, order: 4)
            ]
        case "Comprehensive Metabolic Panel":
            return [
                TestParameterTemplate(name: "Glucose", category: "Metabolic", unit: "mg/dL", rangeLow: 70.0, rangeHigh: 99.0, order: 1),
                TestParameterTemplate(name: "Calcium", category: "Metabolic", unit: "mg/dL", rangeLow: 8.5, rangeHigh: 10.2, order: 2),
                TestParameterTemplate(name: "Albumin", category: "Proteins", unit: "g/dL", rangeLow: 3.4, rangeHigh: 5.4, order: 3),
                TestParameterTemplate(name: "Sodium", category: "Electrolytes", unit: "mmol/L", rangeLow: 135.0, rangeHigh: 145.0, order: 5),
                TestParameterTemplate(name: "Potassium", category: "Electrolytes", unit: "mmol/L", rangeLow: 3.5, rangeHigh: 5.0, order: 6),
                TestParameterTemplate(name: "CO2", category: "Electrolytes", unit: "mmol/L", rangeLow: 23.0, rangeHigh: 29.0, order: 7),
                TestParameterTemplate(name: "Chloride", category: "Electrolytes", unit: "mmol/L", rangeLow: 96.0, rangeHigh: 106.0, order: 8),
                TestParameterTemplate(name: "BUN", category: "Kidney", unit: "mg/dL", rangeLow: 7.0, rangeHigh: 20.0, order: 9),
                TestParameterTemplate(name: "Creatinine", category: "Kidney", unit: "mg/dL", rangeLow: 0.6, rangeHigh: 1.2, order: 10),
                TestParameterTemplate(name: "ALP", category: "Enzymes", unit: "U/L", rangeLow: 40.0, rangeHigh: 129.0, order: 11),
                TestParameterTemplate(name: "ALT", category: "Enzymes", unit: "U/L", rangeLow: 7.0, rangeHigh: 55.0, order: 12),
                TestParameterTemplate(name: "AST", category: "Enzymes", unit: "U/L", rangeLow: 8.0, rangeHigh: 48.0, order: 13),
                TestParameterTemplate(name: "Bilirubin Total", category: "Bilirubin", unit: "mg/dL", rangeLow: 0.1, rangeHigh: 1.2, order: 14)
            ]
        case "Urinalysis":
            return [
                TestParameterTemplate(name: "Color", category: "Physical", unit: "", rangeLow: 0, rangeHigh: 0, referenceText: "Yellow", order: 1),
                TestParameterTemplate(name: "Clarity", category: "Physical", unit: "", rangeLow: 0, rangeHigh: 0, referenceText: "Clear", order: 2),
                TestParameterTemplate(name: "Specific Gravity", category: "Physical", unit: "", rangeLow: 1.002, rangeHigh: 1.030, order: 3),
                TestParameterTemplate(name: "pH", category: "Chemical", unit: "", rangeLow: 4.5, rangeHigh: 8.0, order: 4),
                TestParameterTemplate(name: "Glucose", category: "Chemical", unit: "", rangeLow: 0, rangeHigh: 0, referenceText: "Negative", order: 5),
                TestParameterTemplate(name: "Ketones", category: "Chemical", unit: "", rangeLow: 0, rangeHigh: 0, referenceText: "Negative", order: 6),
                TestParameterTemplate(name: "Protein", category: "Chemical", unit: "", rangeLow: 0, rangeHigh: 0, referenceText: "Negative", order: 7),
                TestParameterTemplate(name: "Blood", category: "Chemical", unit: "", rangeLow: 0, rangeHigh: 0, referenceText: "Negative", order: 8),
                TestParameterTemplate(name: "Leukocyte Esterase", category: "Chemical", unit: "", rangeLow: 0, rangeHigh: 0, referenceText: "Negative", order: 9),
                TestParameterTemplate(name: "Nitrite", category: "Chemical", unit: "", rangeLow: 0, rangeHigh: 0, referenceText: "Negative", order: 10),
                TestParameterTemplate(name: "WBC", category: "Microscopic", unit: "/HPF", rangeLow: 0, rangeHigh: 5, order: 11),
                TestParameterTemplate(name: "RBC", category: "Microscopic", unit: "/HPF", rangeLow: 0, rangeHigh: 2, order: 12),
                TestParameterTemplate(name: "Epithelial Cells", category: "Microscopic", unit: "/HPF", rangeLow: 0, rangeHigh: 5, order: 13),
                TestParameterTemplate(name: "Bacteria", category: "Microscopic", unit: "/HPF", rangeLow: 0, rangeHigh: 0, referenceText: "None", order: 14),
                TestParameterTemplate(name: "Crystals", category: "Microscopic", unit: "/HPF", rangeLow: 0, rangeHigh: 0, referenceText: "None", order: 15)
            ]
        case "Tumor Markers":
            return [
                TestParameterTemplate(name: "Alpha Fetoprotein (AFP)", category: "Tumor Markers", unit: "ng/mL", rangeLow: 0.0, rangeHigh: 15.0, referenceText: "< 15 ng/mL", order: 1),
                TestParameterTemplate(name: "Beta HCG", category: "Tumor Markers", unit: "mIU/mL", rangeLow: 0.0, rangeHigh: 5.0, referenceText: "< 5 mIU/mL in males and non-pregnant females", order: 2),
                TestParameterTemplate(name: "CA 19-9", category: "Tumor Markers", unit: "U/mL", rangeLow: 0.0, rangeHigh: 40.0, referenceText: "< 40 U/mL", order: 3),
                TestParameterTemplate(name: "CA-125", category: "Tumor Markers", unit: "U/mL", rangeLow: 0.0, rangeHigh: 35.0, referenceText: "< 35 U/mL", order: 4),
                TestParameterTemplate(name: "CEA", category: "Tumor Markers", unit: "μg/L", rangeLow: 0.0, rangeHigh: 5.0, referenceText: "< 5 μg/L (higher in smokers)", order: 5),
                TestParameterTemplate(name: "PSA", category: "Tumor Markers", unit: "ng/mL", rangeLow: 0.0, rangeHigh: 4.0, referenceText: "Age-specific; < 4.0 ng/mL (varies)", order: 6),
                TestParameterTemplate(name: "PAP", category: "Tumor Markers", unit: "units/dL", rangeLow: 0.0, rangeHigh: 3.0, referenceText: "< 3 units/dL", order: 7),
                TestParameterTemplate(name: "Calcitonin", category: "Tumor Markers", unit: "pg/mL", rangeLow: 0.0, rangeHigh: 15.0, referenceText: "< 15 pg/mL", order: 8)
            ]
        default:
            return []
        }
    }
}

// MARK: - Parameter Editor View
struct ParameterEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var parameters: [TestParameterTemplate]
    var testType: String
    
    @State private var workingParameters: [TestParameterTemplate] = []
    @State private var newParameterName = ""
    @State private var newParameterCategory = ""
    @State private var newParameterValue = ""
    @State private var newParameterUnit = ""
    @State private var newParameterRangeLow: Double = 0.0
    @State private var newParameterRangeHigh: Double = 0.0
    @State private var newParameterReferenceText = ""
    @State private var showingAddParameter = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Test Parameters")) {
                    if workingParameters.isEmpty {
                        Text("No parameters added yet")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(0..<workingParameters.count, id: \.self) { index in
                            parameterEditor(for: $workingParameters[index])
                        }
                        .onDelete(perform: deleteParameter)
                        .onMove(perform: moveParameter)
                    }
                    
                    Button(action: {
                        showingAddParameter = true
                    }) {
                        Label("Add Parameter", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Edit Parameters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        parameters = workingParameters
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddParameter) {
                newParameterSheet
            }
            .onAppear {
                workingParameters = parameters
            }
        }
    }
    
    private func parameterEditor(for parameter: Binding<TestParameterTemplate>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(parameter.wrappedValue.name)
                    .font(.headline)
                
                Spacer()
                
                Toggle("", isOn: parameter.isAbnormal)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .red))
            }
            
            HStack {
                TextField("Value", text: parameter.value)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .padding(6)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                
                Text(parameter.wrappedValue.unit)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if parameter.wrappedValue.rangeLow > 0 || parameter.wrappedValue.rangeHigh > 0 {
                    Text("Ref: \(String(format: "%.1f", parameter.wrappedValue.rangeLow))-\(String(format: "%.1f", parameter.wrappedValue.rangeHigh))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !parameter.wrappedValue.referenceText.isEmpty {
                    Text("Ref: \(parameter.wrappedValue.referenceText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var newParameterSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Parameter Details")) {
                    TextField("Name", text: $newParameterName)
                    
                    TextField("Category", text: $newParameterCategory)
                    
                    TextField("Value", text: $newParameterValue)
                        .keyboardType(.decimalPad)
                    
                    TextField("Unit", text: $newParameterUnit)
                }
                
                Section(header: Text("Reference Range")) {
                    HStack {
                        Text("Low")
                        Spacer()
                        TextField("", value: $newParameterRangeLow, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("High")
                        Spacer()
                        TextField("", value: $newParameterRangeHigh, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    TextField("Text Reference", text: $newParameterReferenceText)
                }
            }
            .navigationTitle("Add Parameter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddParameter = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addNewParameter()
                        showingAddParameter = false
                    }
                    .disabled(newParameterName.isEmpty)
                }
            }
        }
    }
    
    private func addNewParameter() {
        let newParam = TestParameterTemplate(
            name: newParameterName.trimmingCharacters(in: .whitespacesAndNewlines),
            category: newParameterCategory.trimmingCharacters(in: .whitespacesAndNewlines),
            value: newParameterValue.trimmingCharacters(in: .whitespacesAndNewlines),
            unit: newParameterUnit.trimmingCharacters(in: .whitespacesAndNewlines),
            rangeLow: newParameterRangeLow,
            rangeHigh: newParameterRangeHigh,
            referenceText: newParameterReferenceText.trimmingCharacters(in: .whitespacesAndNewlines),
            order: workingParameters.count + 1
        )
        
        workingParameters.append(newParam)
        
        // Reset fields
        newParameterName = ""
        newParameterCategory = ""
        newParameterValue = ""
        newParameterUnit = ""
        newParameterRangeLow = 0.0
        newParameterRangeHigh = 0.0
        newParameterReferenceText = ""
    }
    
    private func deleteParameter(at offsets: IndexSet) {
        workingParameters.remove(atOffsets: offsets)
        
        // Update order
        for i in 0..<workingParameters.count {
            workingParameters[i].order = i + 1
        }
    }
    
    private func moveParameter(from source: IndexSet, to destination: Int) {
        workingParameters.move(fromOffsets: source, toOffset: destination)
        
        // Update order
        for i in 0..<workingParameters.count {
            workingParameters[i].order = i + 1
        }
    }
}

// MARK: - Supporting Types

struct TestParameterTemplate: Identifiable {
    var id = UUID()
    var name: String
    var category: String
    var value: String = ""
    var unit: String
    var rangeLow: Double
    var rangeHigh: Double
    var referenceText: String = ""
    var isAbnormal: Bool = false
    var order: Int
    
    init(name: String, category: String = "", value: String = "", unit: String = "", rangeLow: Double = 0.0, rangeHigh: Double = 0.0, referenceText: String = "", isAbnormal: Bool = false, order: Int) {
        self.name = name
        self.category = category
        self.value = value
        self.unit = unit
        self.rangeLow = rangeLow
        self.rangeHigh = rangeHigh
        self.referenceText = referenceText
        self.isAbnormal = isAbnormal
        self.order = order
    }
}
