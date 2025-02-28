//
//  EditInitialPresentationView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 02/03/25.
//


//
//  EditInitialPresentationView.swift
//  SurgiTrack
//
//  Created for SurgiTrack App on 03/02/25.
//

import SwiftUI
import CoreData

struct EditInitialPresentationView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Properties
    @ObservedObject var initialPresentation: InitialPresentation
    
    // MARK: - State
    @State private var presentationDate: Date
    @State private var chiefComplaint: String
    @State private var historyOfPresentIllness: String
    @State private var pastMedicalHistory: String
    @State private var physicalExamination: String
    @State private var initialDiagnosis: String
    @State private var labTests: String
    @State private var imagingReports: String
    @State private var medications: String
    @State private var allergies: String
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isFormValid = false
    
    // MARK: - Initialization
    init(initialPresentation: InitialPresentation) {
        self.initialPresentation = initialPresentation
        
        // Initialize state properties from the initialPresentation object
        _presentationDate = State(initialValue: initialPresentation.presentationDate ?? Date())
        _chiefComplaint = State(initialValue: initialPresentation.chiefComplaint ?? "")
        _historyOfPresentIllness = State(initialValue: initialPresentation.historyOfPresentIllness ?? "")
        _pastMedicalHistory = State(initialValue: initialPresentation.pastMedicalHistory ?? "")
        _physicalExamination = State(initialValue: initialPresentation.physicalExamination ?? "")
        _initialDiagnosis = State(initialValue: initialPresentation.initialDiagnosis ?? "")
        _labTests = State(initialValue: initialPresentation.labTests ?? "")
        _imagingReports = State(initialValue: initialPresentation.imagingReports ?? "")
        _medications = State(initialValue: initialPresentation.medications ?? "")
        _allergies = State(initialValue: initialPresentation.allergies ?? "")
    }
    
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
            .navigationTitle("Edit Initial Presentation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateInitialPresentation()
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
    
    private func updateInitialPresentation() {
        guard isFormValid else {
            alertMessage = "Please provide at least a chief complaint and initial diagnosis"
            showingAlert = true
            return
        }
        
        // Update Initial Presentation
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
        
        // Update patient modification date
        if let patient = initialPresentation.patient {
            patient.dateModified = Date()
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Error updating initial presentation: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Preview
struct EditInitialPresentationView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let initialPresentation = InitialPresentation(context: context)
        initialPresentation.id = UUID()
        initialPresentation.chiefComplaint = "Sample complaint"
        initialPresentation.initialDiagnosis = "Sample diagnosis"
        
        return EditInitialPresentationView(initialPresentation: initialPresentation)
            .environment(\.managedObjectContext, context)
    }
}