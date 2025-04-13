// DischargeFormView.swift
// SurgiTrack
// Created on 10/03/25.

import SwiftUI
import CoreData

struct DischargeFormView: View {
    // MARK: - Environment & Objects
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    // Patient to be discharged
    @ObservedObject var patient: Patient
    
    // MARK: - State
    @State private var dischargeDate = Date()
    @State private var primaryDiagnosis = ""
    @State private var secondaryDiagnoses = ""
    @State private var treatmentSummary = ""
    @State private var procedures = ""
    @State private var medicationsAtDischarge = ""
    @State private var dischargeMedications = ""
    @State private var followUpInstructions = ""
    @State private var activityRestrictions = ""
    @State private var dietaryInstructions = ""
    @State private var dischargingPhysician = ""
    @State private var returnPrecautions = ""
    @State private var additionalNotes = ""
    
    // Discharge checklist
    @State private var patientEducationCompleted = false
    @State private var medicationsReconciled = false
    @State private var followUpAppointmentScheduled = false
    @State private var medicalDevicesProvided = false
    @State private var transportationArranged = false
    
    // Form validation
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    @State private var isFormValid = false
    
    // Confirmation
    @State private var showingConfirmation = false
    @State private var dischargeSummary: DischargeSummary?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Form sections
                Group {
                    // Diagnoses section
                    formSection(title: "Diagnoses", systemImage: "stethoscope") {
                        formField(title: "Primary Diagnosis", text: $primaryDiagnosis, required: true)
                        formField(title: "Secondary Diagnoses", text: $secondaryDiagnoses, multiline: true)
                    }
                    
                    // Treatment section
                    formSection(title: "Treatment Summary", systemImage: "cross.case") {
                        formField(title: "Treatment Provided", text: $treatmentSummary, multiline: true, required: true)
                        formField(title: "Procedures Performed", text: $procedures, multiline: true)
                    }
                    
                    // Medications section
                    formSection(title: "Medications", systemImage: "pills") {
                        formField(title: "Current Medications", text: $medicationsAtDischarge, multiline: true, required: true)
                        formField(title: "Discharge Prescriptions", text: $dischargeMedications, multiline: true, required: true)
                    }
                    
                    // Follow-up instructions
                    formSection(title: "Follow-up Care", systemImage: "calendar.badge.clock") {
                        formField(title: "Follow-up Instructions", text: $followUpInstructions, multiline: true, required: true)
                        formField(title: "Activity Restrictions", text: $activityRestrictions, multiline: true)
                        formField(title: "Dietary Instructions", text: $dietaryInstructions, multiline: true)
                    }
                    
                    // Provider and additional information
                    formSection(title: "Additional Information", systemImage: "doc.text") {
                        formField(title: "Discharging Physician", text: $dischargingPhysician, required: true)
                        formField(title: "Return Precautions", text: $returnPrecautions, multiline: true, required: true)
                        formField(title: "Additional Notes", text: $additionalNotes, multiline: true)
                    }
                    
                    // Discharge checklist
                    dischargeChecklist
                }
                
                // Action buttons
                buttonRow
            }
            .padding()
        }
        .navigationTitle("Discharge Patient")
        .alert(isPresented: $showingValidationAlert) {
            Alert(
                title: Text("Incomplete Form"),
                message: Text(validationMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingConfirmation) {
            if let summary = dischargeSummary {
                DischargeSummaryView(dischargeSummary: summary)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onChange(of: primaryDiagnosis) { _ in validateForm() }
        .onChange(of: treatmentSummary) { _ in validateForm() }
        .onChange(of: medicationsAtDischarge) { _ in validateForm() }
        .onChange(of: dischargeMedications) { _ in validateForm() }
        .onChange(of: followUpInstructions) { _ in validateForm() }
        .onChange(of: dischargingPhysician) { _ in validateForm() }
        .onChange(of: returnPrecautions) { _ in validateForm() }
        .onAppear {
            loadExistingData()
            validateForm()
        }
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text("\(patient.fullName)")
                .font(.title2)
                .fontWeight(.bold)
            
            if let mrn = patient.medicalRecordNumber {
                Text("MRN: \(mrn)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            DatePicker("Discharge Date", selection: $dischargeDate, in: ...Date())
                .padding(.vertical, 5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
            }
            .padding(.bottom, 4)
            
            // Content
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
    
    private func formField(title: String, text: Binding<String>, multiline: Bool = false, required: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if required {
                    Text("*")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            
            if multiline {
                TextEditor(text: text)
                    .frame(minHeight: 80)
                    .padding(4)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                TextField("", text: text)
                    .padding(8)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var dischargeChecklist: some View {
        formSection(title: "Discharge Checklist", systemImage: "checklist") {
            VStack(alignment: .leading, spacing: 10) {
                checklistItem("Patient education completed", isChecked: $patientEducationCompleted)
                checklistItem("Medications reconciled", isChecked: $medicationsReconciled)
                checklistItem("Follow-up appointment scheduled", isChecked: $followUpAppointmentScheduled)
                checklistItem("Medical devices provided (if needed)", isChecked: $medicalDevicesProvided)
                checklistItem("Transportation arranged", isChecked: $transportationArranged)
            }
        }
    }
    
    private func checklistItem(_ text: String, isChecked: Binding<Bool>) -> some View {
        Toggle(isOn: isChecked) {
            Text(text)
                .font(.subheadline)
        }
        .toggleStyle(CheckboxToggleStyle())
    }
    
    private var buttonRow: some View {
        HStack(spacing: 15) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            
            Button(action: {
                if validateFormFields() {
                    dischargePatient()
                }
            }) {
                Text("Complete Discharge")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!isFormValid)
        }
        .padding(.top, 10)
    }
    
    // MARK: - Functions
    
    private func loadExistingData() {
        // Auto-fill form with data from the patient's recent records
        
        // Try to populate primary diagnosis from initial presentation
        if let initialPresentation = patient.initialPresentation,
           let diagnosis = initialPresentation.initialDiagnosis,
           !diagnosis.isEmpty {
            primaryDiagnosis = diagnosis
        }
        
        // Populate procedures from operative data
        if let operativeData = patient.operativeData as? Set<OperativeData>, !operativeData.isEmpty {
            let procedureNames = operativeData.compactMap { $0.procedureName }
            if !procedureNames.isEmpty {
                procedures = procedureNames.joined(separator: "\n")
            }
        }
        
        // Get medications from initial presentation
        if let initialPresentation = patient.initialPresentation,
           let meds = initialPresentation.medications,
           !meds.isEmpty {
            medicationsAtDischarge = meds
        }
        
        // Get discharging physician name from the most recent operative data
        if let operativeData = (patient.operativeData as? Set<OperativeData>)?.sorted(by: {
            ($0.operationDate ?? Date.distantPast) > ($1.operationDate ?? Date.distantPast)
        }).first {
            dischargingPhysician = operativeData.surgeonName ?? ""
        }
    }
    
    private func validateForm() {
        isFormValid = !primaryDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !treatmentSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !medicationsAtDischarge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !dischargeMedications.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !followUpInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !dischargingPhysician.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !returnPrecautions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func validateFormFields() -> Bool {
        var missingFields: [String] = []
        
        if primaryDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Primary Diagnosis")
        }
        if treatmentSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Treatment Summary")
        }
        if medicationsAtDischarge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Current Medications")
        }
        if dischargeMedications.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Discharge Prescriptions")
        }
        if followUpInstructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Follow-up Instructions")
        }
        if dischargingPhysician.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Discharging Physician")
        }
        if returnPrecautions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("Return Precautions")
        }
        
        if !missingFields.isEmpty {
            validationMessage = "Please complete the following required fields:\n" + missingFields.joined(separator: "\n")
            showingValidationAlert = true
            return false
        }
        
        return true
    }
    
    private func dischargePatient() {
        // Create a new DischargeSummary entity
        let summary = DischargeSummary(context: viewContext)
        summary.id = UUID()
        summary.dischargeDate = dischargeDate
        summary.primaryDiagnosis = primaryDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.secondaryDiagnoses = secondaryDiagnoses.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.treatmentSummary = treatmentSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.procedures = procedures.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.medicationsAtDischarge = medicationsAtDischarge.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.dischargeMedications = dischargeMedications.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.followUpInstructions = followUpInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.activityRestrictions = activityRestrictions.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.dietaryInstructions = dietaryInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.dischargingPhysician = dischargingPhysician.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.returnPrecautions = returnPrecautions.trimmingCharacters(in: .whitespacesAndNewlines)
        summary.additionalNotes = additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Set checklist items
        summary.patientEducationCompleted = patientEducationCompleted
        summary.medicationsReconciled = medicationsReconciled
        summary.followUpAppointmentScheduled = followUpAppointmentScheduled
        summary.medicalDevicesProvided = medicalDevicesProvided
        summary.transportationArranged = transportationArranged
        
        // Link to patient
        summary.patient = patient
        
        // Update patient status
        patient.isDischargedStatus = true
        patient.dischargeSummary = summary
        patient.dateModified = Date()
        
        // Save to database
        do {
            try viewContext.save()
            dischargeSummary = summary
            showingConfirmation = true
        } catch {
            print("Error saving discharge: \(error)")
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .font(.system(size: 20, weight: .regular))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}
