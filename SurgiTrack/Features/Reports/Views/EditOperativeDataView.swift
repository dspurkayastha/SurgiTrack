import SwiftUI
import CoreData

struct EditOperativeDataView: View {
    // MARK: - Environment & Objects
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var operativeData: OperativeData

    // MARK: - State
    @State private var operationDate: Date
    @State private var operationType: String
    @State private var indication: String// New field for type of operation
    @State private var procedureName: String
    @State private var procedureDetails: String
    @State private var preOpDiagnosis: String
    @State private var postOpDiagnosis: String
    @State private var comorbidityCodes: String

    // Operative team
    @State private var selectedSurgeonID: NSManagedObjectID?
    @State private var anaesthetistName: String
    @State private var assistants: String

    // Intraoperative details
    @State private var patientPositioning: String
    @State private var patientWarming: String
    @State private var anesthesiaType: String
    @State private var antibiotics: String
    @State private var skinPreparation: String
    @State private var vteProphylaxis: String
    @State private var operationNarrative: String
    @State private var duration: Double
    @State private var estimatedBloodLoss: Double

    // Postoperative orders and notes
    @State private var postoperativeOrders: String
    @State private var painManagement: String

    // Additional optional comments
    @State private var additionalComments: String

    // Alert and form validation
    @State private var isFormValid = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Surgeon picker state
    @State private var isShowingSurgeonPicker: Bool = false
    @State private var isShowingAttachments: Bool = false

    // Anesthesia type options
    private let anesthesiaTypes = ["General", "Local", "Regional", "Spinal", "Epidural", "Sedation", "Other"]

    // MARK: - Computed Properties
    private var surgeonFullName: String {
        if let surgeonID = selectedSurgeonID,
           let surgeon = fetchSurgeon(by: surgeonID) {
            return "\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")"
        } else if let name = operativeData.surgeonName, !name.isEmpty {
            return name
        }
        return ""
    }
    
    // MARK: - Initialization
    init(operativeData: OperativeData) {
        self.operativeData = operativeData
        
        // Initialize state with existing data.
        _operationDate = State(initialValue: operativeData.operationDate ?? Date())
        _operationType = State(initialValue: operativeData.operationType ?? "")
        _indication = State(initialValue: operativeData.indication ?? "")
        _procedureName = State(initialValue: operativeData.procedureName ?? "")
        _procedureDetails = State(initialValue: operativeData.procedureDetails ?? "")
        _preOpDiagnosis = State(initialValue: operativeData.preOpDiagnosis ?? "")
        _postOpDiagnosis = State(initialValue: operativeData.postOpDiagnosis ?? "")
        _comorbidityCodes = State(initialValue: operativeData.comorbidityCodes ?? "")
        _anesthesiaType = State(initialValue: operativeData.anaesthesiaType ?? "General")
        _duration = State(initialValue: operativeData.duration)
        _estimatedBloodLoss = State(initialValue: operativeData.estimatedBloodLoss)
        _assistants = State(initialValue: operativeData.assistants ?? "")
        _operationNarrative = State(initialValue: operativeData.operativeNotes ?? "")
        _postoperativeOrders = State(initialValue: operativeData.postoperativeOrders ?? "")
        _painManagement = State(initialValue: operativeData.painManagement ?? "")
        
        // New intraoperative details fields
        _patientPositioning = State(initialValue: operativeData.patientPositioning ?? "")
        _patientWarming = State(initialValue: operativeData.patientWarming ?? "")
        _antibiotics = State(initialValue: operativeData.antibiotics ?? "")
        _skinPreparation = State(initialValue: operativeData.skinPreparation ?? "")
        _vteProphylaxis = State(initialValue: operativeData.vteProphylaxis ?? "")
        
        // Additional comments field
        _additionalComments = State(initialValue: operativeData.additionalComments ?? "")
        _anaesthetistName = State(initialValue: operativeData.anaesthetistName ?? "")
        // Set surgeon ID if available.
        if let surgeon = operativeData.surgeon {
            _selectedSurgeonID = State(initialValue: surgeon.objectID)
        } else {
            _selectedSurgeonID = State(initialValue: nil)
        }
        
        // Optionally, if you have procedureDetails separate from operationNarrative, adjust accordingly.
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Section: Basic Operation Information
                Section(header: Text("Basic Operation Information")) {
                    DatePicker("Operation Date", selection: $operationDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Operation Type (e.g., Appendectomy)", text: $operationType)
                        .onChange(of: operationType, perform: { _ in validateForm() })
                    
                    TextField("Procedure Name", text: $procedureName)
                        .onChange(of: procedureName, perform: { _ in validateForm() })
                    
                    TextField("Pre-op Diagnosis", text: $preOpDiagnosis)
                    TextField("Post-op Diagnosis", text: $postOpDiagnosis)
                    TextField("Comorbidity Codes", text: $comorbidityCodes)
                }
                
                // Section: Operative Team
                Section(header: Text("Operative Team")) {
                    HStack {
                        Text("Surgeon")
                        Spacer()
                        Button(action: {
                            isShowingSurgeonPicker = true
                        }) {
                            HStack {
                                if !surgeonFullName.isEmpty {
                                    Text(surgeonFullName)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Surgeon")
                                        .foregroundColor(.blue)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    TextField("Anaesthetist Name", text: $anaesthetistName)
                    TextField("Assistants", text: $assistants)
                }
                
                // Section: Intraoperative Details
                Section(header: Text("Intraoperative Details")) {
                    TextField("Patient Positioning", text: $patientPositioning)
                    TextField("Patient Warming", text: $patientWarming)
                    
                    Picker("Anaesthesia Type", selection: $anesthesiaType) {
                        ForEach(anesthesiaTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    TextField("Antibiotics", text: $antibiotics)
                    TextField("Skin Preparation", text: $skinPreparation)
                    TextField("VTE Prophylaxis", text: $vteProphylaxis)
                    
                    VStack(alignment: .leading) {
                        Text("Operation Narrative")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $operationNarrative)
                            .frame(minHeight: 150)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    }
                    
                    HStack {
                        Text("Duration (min)")
                        Spacer()
                        Stepper("\(Int(duration))", value: $duration, in: 1...1440, step: 5)
                    }
                    
                    HStack {
                        Text("Estimated Blood Loss (mL)")
                        Spacer()
                        Stepper("\(Int(estimatedBloodLoss))", value: $estimatedBloodLoss, in: 0...10000, step: 50)
                    }
                }
                
                // Section: Postoperative Management
                Section(header: Text("Postoperative Management")) {
                    VStack(alignment: .leading) {
                        Text("Postoperative Orders")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $postoperativeOrders)
                            .frame(minHeight: 80)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Pain Management")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextEditor(text: $painManagement)
                            .frame(minHeight: 80)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    }
                }
                
                // Section: Additional Comments
                Section(header: Text("Additional Comments")) {
                    TextField("", text: $additionalComments)
                        .placeholder(when: additionalComments.isEmpty) {
                            Text("IV Fluids, Special advice etc...")
                                .foregroundColor(.gray)
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Section: Attachments
                Section {
                    Button(action: {
                        isShowingAttachments = true
                    }) {
                        HStack {
                            Image(systemName: "paperclip")
                            let hasAttachments = (operativeData.attachments?.count ?? 0) > 0
                            Text(hasAttachments ? "View Attachments" : "Add Attachments")
                        }
                    }
                }
            }
            .navigationTitle("Edit Procedure")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateOperativeData()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $isShowingSurgeonPicker) {
                SurgeonPickerView(selectedID: $selectedSurgeonID)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isShowingAttachments) {
                AttachmentView(parent: .operativeData(operativeData))
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                validateForm()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateForm() {
        isFormValid = !procedureName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func updateOperativeData() {
        guard isFormValid else {
            alertMessage = "Please provide a procedure name"
            showingAlert = true
            return
        }
        
        operativeData.operationDate = operationDate
        operativeData.operationType = operationType
        operativeData.procedureName = procedureName.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.procedureDetails = procedureDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.indication = indication.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.preOpDiagnosis = preOpDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.postOpDiagnosis = postOpDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.comorbidityCodes = comorbidityCodes.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.anaesthesiaType = anesthesiaType
        operativeData.duration = duration
        operativeData.estimatedBloodLoss = estimatedBloodLoss
        operativeData.assistants = assistants.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.postoperativeOrders = postoperativeOrders.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.painManagement = painManagement.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.additionalComments = additionalComments.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Intraoperative details
        // (Assuming these attributes exist in your updated Core Data model)
        operativeData.patientPositioning = patientPositioning.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.patientWarming = patientWarming.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.antibiotics = antibiotics.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.skinPreparation = skinPreparation.trimmingCharacters(in: .whitespacesAndNewlines)
        operativeData.vteProphylaxis = vteProphylaxis.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update surgeon
        if let surgeonID = selectedSurgeonID,
           let surgeon = fetchSurgeon(by: surgeonID) {
            operativeData.surgeon = surgeon
            operativeData.surgeonName = "\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")"
        } else {
            operativeData.surgeon = nil
            operativeData.surgeonName = nil
        }
        
        // Update patient modification date
        if let patient = operativeData.patient {
            patient.dateModified = Date()
        }
        
        do {
            try viewContext.save()
        } catch {
            alertMessage = "Error saving operative data: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func fetchSurgeon(by id: NSManagedObjectID) -> Surgeon? {
        return viewContext.object(with: id) as? Surgeon
    }
}

