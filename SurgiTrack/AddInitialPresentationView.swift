//
//  AddInitialPresentationView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 02/03/25.
//


//
//  AddInitialPresentationView.swift
//  SurgiTrack
//
//  Created for SurgiTrack App on 02/03/25.
//

import SwiftUI
import CoreData

struct AddInitialPresentationView: View {
    // MARK: - Properties
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var patient: Patient
    
    // MARK: - State
    @State private var presentationDate = Date()
    @State private var chiefComplaint = ""
    @State private var historyOfPresentIllness = ""
    @State private var pastMedicalHistory = ""
    @State private var physicalExamination = ""
    @State private var initialDiagnosis = ""
    @State private var labTests = ""
    @State private var imagingReports = ""
    @State private var medications = ""
    @State private var allergies = ""
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isFormValid = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Presentation Information")) {
                    DatePicker("Presentation Date", selection: $presentationDate, 
                              in: ...Date(), displayedComponents: .date)
                    
                    VStack(alignment: .leading) {
                        Text("Chief Complaint").font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $chiefComplaint)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .onChange(of: chiefComplaint) { _ in validateForm() }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Initial Diagnosis").font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $initialDiagnosis)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            .onChange(of: initialDiagnosis) { _ in validateForm() }
                    }
                }
                
                Section(header: Text("History")) {
                    VStack(alignment: .leading) {
                        Text("History of Present Illness").font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $historyOfPresentIllness)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Past Medical History").font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $pastMedicalHistory)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Allergies").font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $allergies)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
                
                Section(header: Text("Examination")) {
                    VStack(alignment: .leading) {
                        Text("Physical Examination").font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $physicalExamination)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
                
                Section(header: Text("Tests & Medications")) {
                    VStack(alignment: .leading) {
                        Text("Lab Tests").font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $labTests)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Imaging Reports").font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $imagingReports)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Medications").font(.subheadline).foregroundColor(.secondary)
                        TextEditor(text: $medications)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Initial Presentation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveInitialPresentation()
                    }
                    .disabled(!isFormValid)
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
                validateForm()
            }
        }
    }
    
    // MARK: - Methods
    private func validateForm() {
        isFormValid = !chiefComplaint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !initialDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveInitialPresentation() {
        guard isFormValid else {
            alertMessage = "Please provide at least a chief complaint and initial diagnosis"
            showingAlert = true
            return
        }
        
        // Create new Initial Presentation
        let initialPresentation = InitialPresentation(context: viewContext)
        initialPresentation.id = UUID()
        initialPresentation.presentationDate = presentationDate
        initialPresentation.chiefComplaint = chiefComplaint.trimmingCharacters(in: .whitespacesAndNewlines)
        initialPresentation.historyOfPresentIllness = historyOfPresentIllness.trimmingCharacters(in: .whitespacesAndNewlines)
        initialPresentation.pastMedicalHistory = pastMedicalHistory.trimmingCharacters(in: .whitespacesAndNewlines)
        initialPresentation.physicalExamination = physicalExamination.trimmingCharacters(in: .whitespacesAndNewlines)
        initialPresentation.initialDiagnosis = initialDiagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
        initialPresentation.labTests = labTests.trimmingCharacters(in: .whitespacesAndNewlines)
        initialPresentation.imagingReports = imagingReports.trimmingCharacters(in: .whitespacesAndNewlines)
        initialPresentation.medications = medications.trimmingCharacters(in: .whitespacesAndNewlines)
        initialPresentation.allergies = allergies.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Connect to patient
        initialPresentation.patient = patient
        patient.initialPresentation = initialPresentation
        
        // Update patient modification date
        patient.dateModified = Date()
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Error saving initial presentation: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Preview
struct AddInitialPresentationView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.id = UUID()
        patient.firstName = "Preview"
        patient.lastName = "Patient"
        patient.dateCreated = Date()
        
        return AddInitialPresentationView(patient: patient)
            .environment(\.managedObjectContext, context)
    }
}