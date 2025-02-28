import SwiftUI
import CoreData

struct AddOperativeDataView: View {
    // MARK: - Environment & Objects
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode

    // The patient for whom operative data is being recorded.
    @ObservedObject var patient: Patient
    
    // MARK: - Operative Data State
    @State private var operationDate = Date()
    @State private var operationType: OperationType = .other
    @State private var procedureName = ""
    @State private var preOpDiagnosis = ""
    @State private var postOpDiagnosis = ""
    @State private var comorbidityCodes = ""
    
    // Operative team
    @State private var selectedSurgeonID: NSManagedObjectID?
    @State private var anaesthetistName = ""
    @State private var assistants = ""
    
    // Intraoperative details
    @State private var patientPositioning = ""
    @State private var patientWarming = ""
    @State private var anesthesiaType: String = "General"
    @State private var antibiotics = ""
    @State private var skinPreparation = ""
    @State private var vteProphylaxis = ""
    @State private var operationNarrative = ""
    @State private var estimatedBloodLoss: Int = 0
    @State private var duration: Int = 60 // minutes
    
    // Postoperative orders and notes
    @State private var postoperativeOrders = ""
    @State private var painManagement = ""
    
    // Additional optional comments/attachments
    @State private var additionalComments = ""
    
    // Alert and form validation state
    @State private var isFormValid = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Surgeon picker state (added)
    @State private var isShowingSurgeonPicker: Bool = false
    
    // Operation type picker options
    enum OperationType: String, CaseIterable, Identifiable {
        case laparoscopicCholecystectomy = "Laparoscopic Cholecystectomy"
        case hernioplasty = "Hernioplasty"
        case appendectomy = "Appendectomy"
        case thyroidectomy = "Thyroidectomy"
        case exploratoryLaparotomy = "Exploratory Laparotomy"
        case apr = "APR"
        case gastrectomy = "Gastrectomy"
        case incisionalHerniaRepair = "Incisional Hernia Repair"
        case other = "Other"
        
        var id: String { self.rawValue }
    }
    
    // Anesthesia type options
    private let anesthesiaTypes = ["General", "Local", "Regional", "Spinal", "Epidural", "Sedation", "Other"]
    
    // Computed property for surgeon full name.
    private var surgeonFullName: String? {
        if let surgeonID = selectedSurgeonID, let surgeon = fetchSurgeon(by: surgeonID) {
            return "\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")"
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Basic Operation Information
                Section(header: Text("Basic Operation Information")) {
                    DatePicker("Operation Date", selection: $operationDate,
                               in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Operation Type", selection: $operationType) {
                        ForEach(OperationType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("Procedure Name", text: $procedureName)
                        .onChange(of: procedureName, perform: { _ in validateForm() })
                    
                    TextField("Pre-op Diagnosis", text: $preOpDiagnosis)
                    TextField("Post-op Diagnosis", text: $postOpDiagnosis)
                    TextField("Comorbidity Codes", text: $comorbidityCodes)
                }
                
                // MARK: - Operative Team
                Section(header: Text("Operative Team")) {
                    HStack {
                        Text("Surgeon")
                        Spacer()
                        Button(action: {
                            isShowingSurgeonPicker = true
                        }) {
                            HStack {
                                if let name = surgeonFullName {
                                    Text(name)
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
                
                // MARK: - Intraoperative Details
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
                        Stepper("\(duration)", value: $duration, in: 1...1440, step: 5)
                    }
                    
                    HStack {
                        Text("Estimated Blood Loss (mL)")
                        Spacer()
                        Stepper("\(estimatedBloodLoss)", value: $estimatedBloodLoss, in: 0...10000, step: 50)
                    }
                }
                
                // MARK: - Postoperative Management
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
                
                // MARK: - Additional Comments
                Section(header: Text("Additional Comments")) {
                    TextField("", text: $additionalComments)
                        .placeholder(when: additionalComments.isEmpty) {
                            Text("IV Fluids, Special advice etc...")
                                .foregroundColor(.gray)
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // MARK: - Attachments (Optional)
                Section {
                    Button(action: {
                        if isFormValid {
                            let _ = saveOperativeData()
                            // Trigger attachments view (if needed)
                        } else {
                            alertMessage = "Please fill in required fields before adding attachments."
                            showingAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "paperclip")
                            Text("Add Attachments")
                        }
                    }
                }
            }
            .navigationTitle("Add Operative Data")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let _ = saveOperativeData()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $isShowingSurgeonPicker) {
                SurgeonPickerView(selectedID: $selectedSurgeonID)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                validateForm()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateForm() {
        isFormValid = !procedureName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !operationType.rawValue.isEmpty &&
                      selectedSurgeonID != nil
    }
    
    @discardableResult
    private func saveOperativeData() -> OperativeData? {
        guard isFormValid else {
            alertMessage = "Please fill in required fields."
            showingAlert = true
            return nil
        }
        
        let opData = OperativeData(context: viewContext)
        opData.id = UUID()
        opData.operationDate = operationDate
        opData.operationType = operationType.rawValue
        opData.procedureName = procedureName.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.procedureDetails = operationNarrative.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.indication = preOpDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.preOpDiagnosis = preOpDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.postOpDiagnosis = postOpDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.comorbidityCodes = comorbidityCodes.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.anaesthesiaType = anesthesiaType
        opData.anaesthetistName = anaesthetistName.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.assistants = assistants.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.patientPositioning = patientPositioning.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.patientWarming = patientWarming.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.antibiotics = antibiotics.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.skinPreparation = skinPreparation.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.vteProphylaxis = vteProphylaxis.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.operationNarrative = operationNarrative.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.duration = Double(duration)
        opData.estimatedBloodLoss = Double(estimatedBloodLoss)
        opData.postoperativeOrders = postoperativeOrders.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.painManagement = painManagement.trimmingCharacters(in: .whitespacesAndNewlines)
        opData.additionalComments = additionalComments.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Team details
        if let surgeonID = selectedSurgeonID, let surgeon = fetchSurgeon(by: surgeonID) {
            opData.surgeon = surgeon
            opData.surgeonName = "\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")"
        }
        
        // Connect to patient
        opData.patient = patient
        patient.dateModified = Date()
        
        do {
            try viewContext.save()
            return opData
        } catch {
            alertMessage = "Error saving operative data: \(error.localizedDescription)"
            showingAlert = true
            return nil
        }
    }
    
    private func fetchSurgeon(by id: NSManagedObjectID) -> Surgeon? {
        return viewContext.object(with: id) as? Surgeon
    }
}
