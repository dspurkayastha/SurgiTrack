//
//  AppointmentDetailView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 02/03/25.
//


//
//  AppointmentDetailView.swift
//  SurgiTrack
//
//  Created for SurgiTrack App on 3/02/25.
//

import SwiftUI
import CoreData

struct AppointmentDetailView: View {
    // MARK: - Environment & Objects
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var appointment: Appointment
    
    // MARK: - State
    @State private var isShowingEditSheet = false
    @State private var isShowingConfirmationDialog = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingPatientDetail = false
    @State private var dialogAction: AppointmentAction = .complete
    
    // Possible appointment actions
    enum AppointmentAction {
        case complete, cancel, reschedule, delete
    }
    
    // MARK: - Formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    private let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Computed Properties
    
    // Color based on appointment type
    private var typeColor: Color {
        guard let type = appointment.appointmentType else { return .blue }
        
        switch type.lowercased() {
        case "surgery":
            return .red
        case "follow-up":
            return .green
        case "consultation":
            return .blue
        case "pre-operative":
            return .orange
        case "post-operative":
            return .purple
        default:
            return .blue
        }
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with appointment status
                appointmentStatusHeader
                
                // Main info card
                appointmentInfoCard
                
                // Patient card (if available)
                if let patient = appointment.patient {
                    patientCard(patient: patient)
                }
                
                // Surgeon card (if available)
                if let surgeon = appointment.surgeon {
                    surgeonCard(surgeon: surgeon)
                }
                
                // Notes
                if let notes = appointment.notes, !notes.isEmpty {
                    notesCard(notes: notes)
                }
                
                // Action buttons
                actionButtonsView
            }
            .padding()
        }
        .navigationTitle("Appointment Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        isShowingEditSheet = true
                    }) {
                        Label("Edit Appointment", systemImage: "square.and.pencil")
                    }
                    
                    if !appointment.isCompleted {
                        Button(action: {
                            dialogAction = .complete
                            isShowingConfirmationDialog = true
                        }) {
                            Label("Mark as Completed", systemImage: "checkmark.circle")
                        }
                    }
                    
                    Button(action: {
                        dialogAction = .delete
                        isShowingDeleteConfirmation = true
                    }) {
                        Label("Delete Appointment", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditAppointmentView(appointment: appointment)
                .environment(\.managedObjectContext, viewContext)
        }
        .confirmationDialog(
            getDialogTitle(),
            isPresented: $isShowingConfirmationDialog,
            titleVisibility: .visible
        ) {
            Button(getDialogButtonText(), role: .none) {
                performAction()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(getDialogMessage())
        }
        .alert("Delete Appointment", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteAppointment()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this appointment? This action cannot be undone.")
        }
        .sheet(isPresented: $isShowingPatientDetail) {
            if let patient = appointment.patient {
                AccordionPatientDetailView(patient: patient)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - View Components
    
    private var appointmentStatusHeader: some View {
        HStack {
            if appointment.isCompleted {
                Text("COMPLETED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            } else {
                if let type = appointment.appointmentType {
                    Text(type.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(typeColor.opacity(0.2))
                        .foregroundColor(typeColor)
                        .cornerRadius(4)
                }
            }
            Spacer()
        }
    }
    
    private var appointmentInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appointment.title ?? "Untitled Appointment")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(appointment.isCompleted ? .secondary : .primary)
            
            Divider()
            
            // Date and time
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(typeColor)
                        .frame(width: 24)
                    
                    Text(dateFormatter.string(from: appointment.startTime ?? Date()))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(typeColor)
                        .frame(width: 24)
                    
                    Text("\(timeFormatter.string(from: appointment.startTime ?? Date())) - \(timeFormatter.string(from: appointment.endTime ?? Date()))")
                }
                
                if let location = appointment.location, !location.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "mappin.circle")
                            .foregroundColor(typeColor)
                            .frame(width: 24)
                        
                        Text(location)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appointment.isCompleted ? Color.gray.opacity(0.3) : typeColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private func patientCard(patient: Patient) -> some View {
        Button(action: {
            isShowingPatientDetail = true
        }) {
            HStack(spacing: 15) {
                // Patient photo or initials
                Group {
                    if let imageData = patient.profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(typeColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(patient.initials)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(typeColor)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.fullName)
                        .font(.headline)
                    
                    if let mrn = patient.medicalRecordNumber, !mrn.isEmpty {
                        Text("MRN: \(mrn)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let dob = patient.dateOfBirth {
                        Text("DOB: \(dateFormatter.string(from: dob))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func surgeonCard(surgeon: Surgeon) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Surgeon")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack(spacing: 15) {
                // Surgeon photo or initials
                Group {
                    if let imageData = surgeon.profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(getInitials(firstName: surgeon.firstName, lastName: surgeon.lastName))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")")
                        .font(.headline)
                    
                    if let specialty = surgeon.specialty, !specialty.isEmpty {
                        Text(specialty)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(notes)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            if !appointment.isCompleted {
                Button(action: {
                    dialogAction = .complete
                    isShowingConfirmationDialog = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Completed")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    dialogAction = .reschedule
                    isShowingEditSheet = true
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                        Text("Reschedule")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    dialogAction = .cancel
                    isShowingConfirmationDialog = true
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel Appointment")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                }
            } else {
                Button(action: {
                    dialogAction = .reschedule
                    isShowingEditSheet = true
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Schedule Follow-up")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getInitials(firstName: String?, lastName: String?) -> String {
        let first = (firstName ?? "").prefix(1)
        let last = (lastName ?? "").prefix(1)
        
        if !first.isEmpty && !last.isEmpty {
            return String(first) + String(last)
        } else if !first.isEmpty {
            return String(first)
        } else if !last.isEmpty {
            return String(last)
        } else {
            return "?"
        }
    }
    
    private func getDialogTitle() -> String {
        switch dialogAction {
        case .complete:
            return "Mark as Completed"
        case .cancel:
            return "Cancel Appointment"
        case .reschedule:
            return "Reschedule Appointment"
        case .delete:
            return "Delete Appointment"
        }
    }
    
    private func getDialogMessage() -> String {
        switch dialogAction {
        case .complete:
            return "This will mark the appointment as completed. Continue?"
        case .cancel:
            return "This will cancel the appointment without deleting it. Continue?"
        case .reschedule:
            return "You'll be able to select a new date and time."
        case .delete:
            return "This action cannot be undone."
        }
    }
    
    private func getDialogButtonText() -> String {
        switch dialogAction {
        case .complete:
            return "Mark Completed"
        case .cancel:
            return "Cancel Appointment"
        case .reschedule:
            return "Reschedule"
        case .delete:
            return "Delete"
        }
    }
    
    private func performAction() {
        switch dialogAction {
        case .complete:
            markAsCompleted()
        case .cancel:
            cancelAppointment()
        case .reschedule:
            // Handled by the sheet
            break
        case .delete:
            // Handled by the alert
            break
        }
    }
    
    private func markAsCompleted() {
        appointment.isCompleted = true
        saveContext()
    }
    
    private func cancelAppointment() {
        // In a real application, you might want to keep track of cancelled appointments
        // rather than just marking them as completed
        appointment.isCompleted = true
        
        // Use DateFormatter instead of the new formatting API
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let formattedDate = formatter.string(from: Date())
        
        appointment.notes = (appointment.notes ?? "") + "\n\n[CANCELLED] \(formattedDate)"
        saveContext()
    }
    
    private func deleteAppointment() {
        viewContext.delete(appointment)
        saveContext()
        // Navigate back after deletion
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - EditAppointmentView
struct EditAppointmentView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var appointment: Appointment
    
    // MARK: - State
    @State private var title: String
    @State private var appointmentType: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location: String
    @State private var notes: String
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
    init(appointment: Appointment) {
        self.appointment = appointment
        
        // Initialize state with existing appointment values
        _title = State(initialValue: appointment.title ?? "")
        _appointmentType = State(initialValue: appointment.appointmentType ?? "Consultation")
        _startTime = State(initialValue: appointment.startTime ?? Date())
        _endTime = State(initialValue: appointment.endTime ?? Date())
        _location = State(initialValue: appointment.location ?? "")
        _notes = State(initialValue: appointment.notes ?? "")
        
        // Set patient and surgeon IDs if they exist
        if let patient = appointment.patient {
            _selectedPatientID = State(initialValue: patient.objectID)
        } else {
            _selectedPatientID = State(initialValue: nil)
        }
        
        if let surgeon = appointment.surgeon {
            _selectedSurgeonID = State(initialValue: surgeon.objectID)
        } else {
            _selectedSurgeonID = State(initialValue: nil)
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                // Basic information section
                Section(header: Text("Appointment Details")) {
                    TextField("Title", text: $title)
                        .onChange(of: title) { _ in validateForm() }
                    
                    Picker("Type", selection: $appointmentType) {
                        ForEach(appointmentTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    DatePicker("Start", selection: $startTime)
                        .onChange(of: startTime) { newValue in
                            // Ensure end time is after start time
                            if endTime <= newValue {
                                endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                            }
                            validateForm()
                        }
                    
                    DatePicker("End", selection: $endTime)
                        .onChange(of: endTime) { _ in validateForm() }
                    
                    TextField("Location", text: $location)
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
                }
                
                // Status section
                Section(header: Text("Status")) {
                    Toggle("Completed", isOn: Binding(
                        get: { appointment.isCompleted },
                        set: { appointment.isCompleted = $0 }
                    ))
                }
                
                // Notes section
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Appointment")
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
        
        // Update appointment data
        appointment.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.appointmentType = appointmentType
        appointment.startTime = startTime
        appointment.endTime = endTime
        appointment.location = location.trimmingCharacters(in: .whitespacesAndNewlines)
        appointment.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Connect to patient
        if let patientID = selectedPatientID {
            appointment.patient = fetchPatient(by: patientID)
        }
        
        // Connect to surgeon (if selected)
        if let surgeonID = selectedSurgeonID {
            appointment.surgeon = fetchSurgeon(by: surgeonID)
        } else {
            appointment.surgeon = nil
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


