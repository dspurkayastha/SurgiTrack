//
//  AddAppointmentView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 02/03/25.
//

import SwiftUI
import CoreData

struct AddAppointmentView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Properties
    var date: Date
    
    // MARK: - State
    @State private var title = ""
    @State private var appointmentType = "Consultation"
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location = ""
    @State private var notes = ""
    @State private var selectedPatientID: NSManagedObjectID?
    @State private var selectedSurgeonID: NSManagedObjectID?
    
    @State private var isShowingPatientPicker = false
    @State private var isShowingSurgeonPicker = false
    @State private var isFormValid = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Appointment type options
    private let appointmentTypes = ["Consultation", "Surgery", "Pre-operative", "Post-operative", "Follow-up", "Other"]
    
    // MARK: - Initialization
    init(date: Date) {
        self.date = date
        
        // Set default times (9 AM for 1 hour on the selected date)
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
        startComponents.hour = 9
        startComponents.minute = 0
        
        let defaultStart = calendar.date(from: startComponents) ?? date
        let defaultEnd = calendar.date(byAdding: .hour, value: 1, to: defaultStart) ?? Date()
        
        // Initialize state properties
        _startTime = State(initialValue: defaultStart)
        _endTime = State(initialValue: defaultEnd)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Basic information section
                Section(header: Text("Appointment Details")) {
                    formTextField(title: "Title", text: $title, onEditingChanged: { _ in validateForm() })
                    
                    formPicker(title: "Type", selection: $appointmentType, options: appointmentTypes)
                    
                    formDatePicker(title: "Start", selection: $startTime, onChange: { newValue in
                        // Ensure end time is after start time
                        if endTime <= newValue {
                            endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                        }
                        validateForm()
                    })
                    
                    formDatePicker(title: "End", selection: $endTime, onChange: { _ in validateForm() })
                    
                    formTextField(title: "Location", text: $location)
                }
                
                // Related entities section
                Section(header: Text("Patient & Surgeon")) {
                    // Patient picker button
                    HStack {
                        Text("Patient")
                        Spacer()
                        Button(action: {
                            isShowingPatientPicker = true
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
                    .padding(.vertical, 8)
                    .onChange(of: selectedPatientID) { _ in validateForm() }
                    
                    // Surgeon picker button
                    HStack {
                        Text("Surgeon")
                        Spacer()
                        Button(action: {
                            isShowingSurgeonPicker = true
                        }) {
                            HStack {
                                if let surgeonID = selectedSurgeonID,
                                   let surgeon = fetchSurgeon(by: surgeonID) {
                                    Text("\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")")
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Surgeon (Optional)")
                                        .foregroundColor(.blue)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Notes section
                Section(header: Text("Notes")) {
                    formTextEditor(text: $notes)
                }
            }
            .navigationTitle("Add Appointment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAppointment()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $isShowingPatientPicker) {
                PatientPickerView(selectedID: $selectedPatientID)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isShowingSurgeonPicker) {
                SurgeonPickerView(selectedID: $selectedSurgeonID)
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
    
    // MARK: - Form Components
    
    private func formTextField(title: String, text: Binding<String>, onEditingChanged: ((Bool) -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("", text: text, onEditingChanged: { isEditing in
                onEditingChanged?(isEditing)
            }, onCommit: {})
                .padding(10)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: text.wrappedValue) { _ in
                    validateForm()
                }
        }
        .padding(.vertical, 4)
    }
    
    private func formTextEditor(text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextEditor(text: text)
                .frame(minHeight: 100)
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
    
    private func formPicker<T: Hashable>(title: String, selection: Binding<T>, options: [T]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(String(describing: option)).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
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
    
    private func formDatePicker(title: String, selection: Binding<Date>, onChange: ((Date) -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            DatePicker("", selection: selection)
                .labelsHidden()
                .padding(10)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: selection.wrappedValue) { newValue in
                    onChange?(newValue)
                }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Methods
    
    private func validateForm() {
        // Check required fields
        isFormValid = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                     selectedPatientID != nil &&
                     startTime < endTime
    }
    
    private func saveAppointment() {
        guard isFormValid else {
            alertMessage = "Please complete all required fields"
            showingAlert = true
            return
        }
        
        let newAppointment = Appointment(context: viewContext)
        newAppointment.id = UUID()
        newAppointment.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        newAppointment.appointmentType = appointmentType
        newAppointment.startTime = startTime
        newAppointment.endTime = endTime
        newAppointment.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        newAppointment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        newAppointment.isCompleted = false
        
        // Connect to patient
        if let patientID = selectedPatientID {
            newAppointment.patient = fetchPatient(by: patientID)
        }
        
        // Connect to surgeon (if selected)
        if let surgeonID = selectedSurgeonID {
            newAppointment.surgeon = fetchSurgeon(by: surgeonID)
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Error saving appointment: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func fetchPatient(by id: NSManagedObjectID) -> Patient? {
        return viewContext.object(with: id) as? Patient
    }
    
    private func fetchSurgeon(by id: NSManagedObjectID) -> Surgeon? {
        return viewContext.object(with: id) as? Surgeon
    }
}

// MARK: - Surgeon Picker View

struct SurgeonPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedID: NSManagedObjectID?
    
    // State to show the add surgeon view.
    @State private var isShowingAddSurgeon = false
    
    // Fetch surgeons
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Surgeon.lastName, ascending: true)],
        animation: .default)
    private var surgeons: FetchedResults<Surgeon>
    
    var body: some View {
        NavigationView {
            List {
                // Button to add a new surgeon.
                Button(action: {
                    isShowingAddSurgeon = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Add New Surgeon")
                            .foregroundColor(.blue)
                        Spacer()
                    }
                }
                
                // Option to clear selection.
                Button(action: {
                    selectedID = nil
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text("None")
                            .foregroundColor(.blue)
                        Spacer()
                        if selectedID == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // List of surgeons.
                ForEach(surgeons, id: \.objectID) { surgeon in
                    Button(action: {
                        selectedID = surgeon.objectID
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text("\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")")
                            Spacer()
                            if selectedID == surgeon.objectID {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Select Surgeon")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $isShowingAddSurgeon) {
                AddSurgeonView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

struct AddAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        AddAppointmentView(date: Date())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
