//
//  PrescriptionDetailView.swift
//  SurgiTrack
//
//  View for displaying and editing prescription details
//  Created on December 26, 2025
//

import SwiftUI
import CoreData

struct PrescriptionDetailView: View {

    // MARK: - Properties

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var prescription: Prescription

    @StateObject private var prescriptionService: PrescriptionService

    @State private var isEditing = false
    @State private var editedGeneralInstructions: String
    @State private var editedPhysician: String
    @State private var editedStatus: String

    @State private var showingAddMedication = false
    @State private var showingEditItem: PrescriptionItem?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var itemToDelete: PrescriptionItem?

    // MARK: - Initialization

    init(prescription: Prescription) {
        self.prescription = prescription
        _prescriptionService = StateObject(wrappedValue: PrescriptionService(
            context: PersistenceController.shared.container.viewContext
        ))
        _editedGeneralInstructions = State(initialValue: prescription.generalInstructions ?? "")
        _editedPhysician = State(initialValue: prescription.prescribingPhysician ?? "")
        _editedStatus = State(initialValue: prescription.status ?? "active")
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Patient info
                    if let patient = prescription.patient {
                        patientInfoSection(patient: patient)
                    }

                    // Prescription header
                    prescriptionHeaderSection

                    // General instructions
                    generalInstructionsSection

                    // Medications list
                    medicationsSection

                    // Actions
                    if !isEditing {
                        actionsSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Prescription Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationItemView(prescription: prescription)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $showingEditItem) { item in
                EditMedicationItemView(item: item)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                if itemToDelete != nil {
                    Button("Cancel", role: .cancel) {
                        itemToDelete = nil
                    }
                    Button("Delete", role: .destructive) {
                        if let item = itemToDelete {
                            deleteItem(item)
                        }
                    }
                } else {
                    Button("OK", role: .cancel) {}
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Sections

    private func patientInfoSection(patient: Patient) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patient")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(patient.initials)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(patient.fullName)
                        .font(.headline)

                    if let mrn = patient.medicalRecordNumber {
                        Text("MRN: \(mrn)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            )
        }
    }

    private var prescriptionHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prescription Information")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                // Date created
                HStack {
                    Label("Created", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(prescription.formattedDateCreated)
                        .font(.subheadline)
                }

                Divider()

                // Prescribing physician
                HStack {
                    Label("Physician", systemImage: "stethoscope")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    if isEditing {
                        TextField("Physician Name", text: $editedPhysician)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 200)
                    } else {
                        Text(prescription.prescribingPhysician ?? "Not specified")
                            .font(.subheadline)
                    }
                }

                Divider()

                // Status
                HStack {
                    Label("Status", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    if isEditing {
                        Picker("Status", selection: $editedStatus) {
                            Text("Active").tag("active")
                            Text("Completed").tag("completed")
                            Text("Discontinued").tag("discontinued")
                        }
                        .pickerStyle(MenuPickerStyle())
                    } else {
                        Text(prescription.statusDisplayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(prescription.statusColor)
                            )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            )
        }
    }

    private var generalInstructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General Instructions")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            if isEditing {
                TextEditor(text: $editedGeneralInstructions)
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                if let instructions = prescription.generalInstructions, !instructions.isEmpty {
                    Text(instructions)
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        )
                } else {
                    Text("No general instructions provided")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        )
                }
            }
        }
    }

    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Medications")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if !isEditing {
                    Button(action: {
                        showingAddMedication = true
                    }) {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(.caption)
                    }
                }
            }

            if prescription.sortedItems.isEmpty {
                Text("No medications in this prescription")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    )
            } else {
                ForEach(prescription.sortedItems, id: \.objectID) { item in
                    MedicationDetailCard(item: item)
                        .onTapGesture {
                            if !isEditing {
                                showingEditItem = item
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                showingEditItem = item
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive, action: {
                                itemToDelete = item
                                alertTitle = "Delete Medication"
                                alertMessage = "Are you sure you want to delete \(item.fullMedicationName)?"
                                showAlert = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if prescription.isActive {
                Button(action: {
                    updateStatus(to: "completed")
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark as Completed")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }

                Button(action: {
                    updateStatus(to: "discontinued")
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Discontinue Prescription")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
                }
            } else if prescription.status == "discontinued" {
                Button(action: {
                    updateStatus(to: "active")
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Reactivate Prescription")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func saveChanges() {
        do {
            try prescriptionService.updatePrescription(
                prescription,
                generalInstructions: editedGeneralInstructions.isEmpty ? nil : editedGeneralInstructions,
                prescribingPhysician: editedPhysician.isEmpty ? nil : editedPhysician,
                status: editedStatus
            )

            isEditing = false

            alertTitle = "Success"
            alertMessage = "Prescription updated successfully"
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to update prescription: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func updateStatus(to status: String) {
        do {
            try prescriptionService.updatePrescriptionStatus(prescription, status: status)

            alertTitle = "Success"
            alertMessage = "Prescription status updated to \(status)"
            showAlert = true
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to update status: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func deleteItem(_ item: PrescriptionItem) {
        do {
            try prescriptionService.deletePrescriptionItem(item)
            itemToDelete = nil
        } catch {
            alertTitle = "Error"
            alertMessage = "Failed to delete medication: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Medication Detail Card

struct MedicationDetailCard: View {
    @ObservedObject var item: PrescriptionItem
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with drug name and status
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.fullMedicationName)
                        .font(.headline)

                    if let form = item.product?.form, !form.isEmpty {
                        Text(form)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(item.itemStatus.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(item.itemStatus.color)
                    )
            }

            Divider()

            // Dosing information
            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "pills", label: "Dosage", value: item.dosage ?? "Not specified")
                infoRow(icon: "clock", label: "Frequency", value: item.frequency ?? "Not specified")
                infoRow(icon: "syringe", label: "Route", value: item.route ?? "Not specified")
            }

            Divider()

            // Dates
            VStack(alignment: .leading, spacing: 8) {
                infoRow(icon: "calendar", label: "Start Date", value: item.formattedStartDate)
                infoRow(icon: "calendar.badge.clock", label: "End Date", value: item.formattedEndDate)
                infoRow(icon: "hourglass", label: "Duration", value: item.durationDisplayString)
            }

            // Special instructions
            if let instructions = item.specialInstructions, !instructions.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Special Instructions")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(instructions)
                        .font(.caption)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(item.itemStatus.color.opacity(0.3), lineWidth: 1)
        )
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.caption)
        }
    }
}

// MARK: - Add Medication Item View

struct AddMedicationItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    @ObservedObject var prescription: Prescription

    @StateObject private var prescriptionService: PrescriptionService

    @State private var drugName = ""
    @State private var strength = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var route = "Oral"
    @State private var duration = ""
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days
    @State private var specialInstructions = ""

    @State private var showAlert = false
    @State private var alertMessage = ""

    init(prescription: Prescription) {
        self.prescription = prescription
        _prescriptionService = StateObject(wrappedValue: PrescriptionService(
            context: PersistenceController.shared.container.viewContext
        ))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medication")) {
                    TextField("Drug Name", text: $drugName)
                    TextField("Strength (e.g., 500mg)", text: $strength)
                }

                Section(header: Text("Dosing")) {
                    TextField("Dosage (e.g., 1 tablet)", text: $dosage)
                    TextField("Frequency (e.g., twice daily)", text: $frequency)

                    Picker("Route", selection: $route) {
                        Text("Oral").tag("Oral")
                        Text("IV").tag("IV")
                        Text("IM").tag("IM")
                        Text("Subcutaneous").tag("Subcutaneous")
                        Text("Topical").tag("Topical")
                        Text("Inhaled").tag("Inhaled")
                        Text("Rectal").tag("Rectal")
                        Text("Other").tag("Other")
                    }
                }

                Section(header: Text("Schedule")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    Toggle("Has End Date", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }

                    TextField("Duration (e.g., 7 days)", text: $duration)
                }

                Section(header: Text("Special Instructions")) {
                    TextEditor(text: $specialInstructions)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedication()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var isFormValid: Bool {
        !drugName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !frequency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveMedication() {
        let itemData = PrescriptionItemData(
            drugName: drugName,
            strength: strength,
            dosage: dosage,
            frequency: frequency,
            route: route,
            duration: duration,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            specialInstructions: specialInstructions
        )

        do {
            try prescriptionService.addPrescriptionItem(to: prescription, itemData: itemData)
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to add medication: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Edit Medication Item View

struct EditMedicationItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    @ObservedObject var item: PrescriptionItem

    @StateObject private var prescriptionService: PrescriptionService

    @State private var drugName: String
    @State private var strength: String
    @State private var dosage: String
    @State private var frequency: String
    @State private var route: String
    @State private var duration: String
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var specialInstructions: String

    @State private var showAlert = false
    @State private var alertMessage = ""

    init(item: PrescriptionItem) {
        self.item = item
        _prescriptionService = StateObject(wrappedValue: PrescriptionService(
            context: PersistenceController.shared.container.viewContext
        ))

        _drugName = State(initialValue: item.drugName ?? "")
        _strength = State(initialValue: item.strength ?? "")
        _dosage = State(initialValue: item.dosage ?? "")
        _frequency = State(initialValue: item.frequency ?? "")
        _route = State(initialValue: item.route ?? "Oral")
        _duration = State(initialValue: item.duration ?? "")
        _startDate = State(initialValue: item.startDate ?? Date())
        _hasEndDate = State(initialValue: item.endDate != nil)
        _endDate = State(initialValue: item.endDate ?? Date())
        _specialInstructions = State(initialValue: item.specialInstructions ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medication")) {
                    TextField("Drug Name", text: $drugName)
                    TextField("Strength (e.g., 500mg)", text: $strength)
                }

                Section(header: Text("Dosing")) {
                    TextField("Dosage (e.g., 1 tablet)", text: $dosage)
                    TextField("Frequency (e.g., twice daily)", text: $frequency)

                    Picker("Route", selection: $route) {
                        Text("Oral").tag("Oral")
                        Text("IV").tag("IV")
                        Text("IM").tag("IM")
                        Text("Subcutaneous").tag("Subcutaneous")
                        Text("Topical").tag("Topical")
                        Text("Inhaled").tag("Inhaled")
                        Text("Rectal").tag("Rectal")
                        Text("Other").tag("Other")
                    }
                }

                Section(header: Text("Schedule")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                    Toggle("Has End Date", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }

                    TextField("Duration (e.g., 7 days)", text: $duration)
                }

                Section(header: Text("Special Instructions")) {
                    TextEditor(text: $specialInstructions)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedication()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var isFormValid: Bool {
        !drugName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !frequency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveMedication() {
        let itemData = PrescriptionItemData(
            drugName: drugName,
            strength: strength,
            dosage: dosage,
            frequency: frequency,
            route: route,
            duration: duration,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            specialInstructions: specialInstructions
        )

        do {
            try prescriptionService.updatePrescriptionItem(item, itemData: itemData)
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Failed to update medication: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Preview

struct PrescriptionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        // Create sample data
        let patient = Patient(context: context)
        patient.id = UUID()
        patient.firstName = "John"
        patient.lastName = "Doe"

        let prescription = Prescription(context: context)
        prescription.id = UUID()
        prescription.dateCreated = Date()
        prescription.status = "active"
        prescription.patient = patient

        return PrescriptionDetailView(prescription: prescription)
            .environment(\.managedObjectContext, context)
    }
}
