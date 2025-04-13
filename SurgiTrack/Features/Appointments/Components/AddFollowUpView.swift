//
//  AddFollowUpView.swift
//  SurgiTrack
//
//  Created for SurgiTrack App on 3/02/25.
//

import SwiftUI
import CoreData

struct AddFollowUpView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Properties
    @ObservedObject var patient: Patient
    
    // MARK: - State
    @State private var followUpDate = Date()
    @State private var nextAppointment = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var followUpNotes = ""
    @State private var outcomeAssessment = ""
    @State private var complications = ""
    @State private var medicationChanges = ""
    @State private var additionalTests = ""
    @State private var vitalSigns = ""
    @State private var woundHealingStatus = ""
    
    @State private var isShowingAttachments = false
    @State private var isFormValid = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // MARK: - Initialization
    
    // Default initializer
    init(patient: Patient) {
        self.patient = patient
    }
    
    // Initializer with pre-populated notes (for post-operative follow-ups)
    init(patient: Patient, initialNotes: String) {
        self.patient = patient
        _followUpNotes = State(initialValue: initialNotes)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Date Information section
                Section(header: Text("Follow-up Visit Information")) {
                    DatePicker("Follow-up Date", selection: $followUpDate, in: ...Date(), displayedComponents: .date)
                        .padding(10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.vertical, 4)
                    
                    DatePicker("Next Appointment", selection: $nextAppointment, in: Date()..., displayedComponents: .date)
                        .padding(10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.vertical, 4)
                }
                
                // Assessment section
                Section(header: Text("Clinical Assessment")) {
                    formTextEditor(title: "Outcome Assessment", text: $outcomeAssessment, height: 80, onChange: { _ in validateForm() })
                    
                    formTextEditor(title: "Wound Healing Status", text: $woundHealingStatus, height: 80)
                    
                    formTextEditor(title: "Vital Signs", text: $vitalSigns, height: 60)
                    
                    formTextEditor(title: "Complications", text: $complications, height: 80)
                }
                
                // Follow-up care section
                Section(header: Text("Follow-up Care")) {
                    formTextEditor(title: "Medication Changes", text: $medicationChanges, height: 80)
                    
                    formTextEditor(title: "Additional Tests", text: $additionalTests, height: 80)
                }
                
                // Notes section
                Section(header: Text("Notes")) {
                    formTextEditor(title: "", text: $followUpNotes, height: 100, onChange: { _ in validateForm() })
                }
                
                // Attachments section
                Section {
                    Button(action: {
                        // First save the follow-up, then show attachments
                        if isFormValid {
                            let followUp = saveFollowUp()
                            if followUp != nil {
                                isShowingAttachments = true
                            }
                        } else {
                            alertMessage = "Please fill in required fields before adding attachments"
                            showingAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "paperclip")
                            Text("Add Attachments")
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Follow-up")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let _ = saveFollowUp()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $isShowingAttachments) {
                if let followUp = fetchLatestFollowUp() {
                    AttachmentView(parent: .followUp(followUp))
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
                validateForm()
            }
        }
    }
    
    // MARK: - Form Components
    
    private func formDatePicker(title: String, selection: Binding<Date>, displayedComponents: DatePickerComponents = .date, range: ClosedRange<Date>? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Group {
                if let dateRange = range {
                    DatePicker("", selection: selection, in: dateRange, displayedComponents: displayedComponents)
                        .labelsHidden()
                } else {
                    DatePicker("", selection: selection, displayedComponents: displayedComponents)
                        .labelsHidden()
                }
            }
            .padding(10)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.vertical, 4)
    }
    
    private func formTextEditor(title: String, text: Binding<String>, height: CGFloat = 100, onChange: ((String) -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            TextEditor(text: text)
                .frame(minHeight: height)
                .padding(10)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: text.wrappedValue) { newValue in
                    onChange?(newValue)
                }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Methods
    
    private func validateForm() {
        isFormValid = !followUpNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                     !outcomeAssessment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @discardableResult
    private func saveFollowUp() -> FollowUp? {
        guard isFormValid else {
            alertMessage = "Please provide follow-up notes or an outcome assessment"
            showingAlert = true
            return nil
        }
        
        // Create new Follow-up record
        let followUp = FollowUp(context: viewContext)
        followUp.id = UUID()
        followUp.followUpDate = followUpDate
        followUp.followUpNotes = followUpNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        followUp.outcomeAssessment = outcomeAssessment.trimmingCharacters(in: .whitespacesAndNewlines)
        followUp.complications = complications.trimmingCharacters(in: .whitespacesAndNewlines)
        followUp.medicationChanges = medicationChanges.trimmingCharacters(in: .whitespacesAndNewlines)
        followUp.additionalTests = additionalTests.trimmingCharacters(in: .whitespacesAndNewlines)
        followUp.woundHealingStatus = woundHealingStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        followUp.vitalSigns = vitalSigns.trimmingCharacters(in: .whitespacesAndNewlines)
        followUp.nextAppointment = nextAppointment
        
        // Connect to patient
        followUp.patient = patient
        
        // Update patient modification date
        patient.dateModified = Date()
        
        do {
            try viewContext.save()
            return followUp
        } catch {
            alertMessage = "Error saving follow-up: \(error.localizedDescription)"
            showingAlert = true
            return nil
        }
    }
    
    private func fetchLatestFollowUp() -> FollowUp? {
        let request: NSFetchRequest<FollowUp> = FollowUp.fetchRequest()
        request.predicate = NSPredicate(format: "patient == %@", patient)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FollowUp.followUpDate, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            return results.first
        } catch {
            print("Error fetching latest follow-up: \(error)")
            return nil
        }
    }
}

struct AddFollowUpView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.id = UUID()
        patient.firstName = "Test"
        patient.lastName = "Patient"
        
        return AddFollowUpView(patient: patient)
            .environment(\.managedObjectContext, context)
    }
}
