//
//  PrescriptionListView.swift
//  SurgiTrack
//
//  View for displaying a patient's prescription list
//  Created on December 26, 2025
//

import SwiftUI
import CoreData

struct PrescriptionListView: View {

    // MARK: - Properties

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var patient: Patient

    @StateObject private var prescriptionService: PrescriptionService

    @State private var selectedPrescription: Prescription?
    @State private var showingNewPrescription = false
    @State private var showingDetail = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var prescriptionToDelete: Prescription?

    @State private var filterStatus: PrescriptionFilter = .all

    // MARK: - Fetch Request

    @FetchRequest private var prescriptions: FetchedResults<Prescription>

    // MARK: - Initialization

    init(patient: Patient) {
        self.patient = patient
        _prescriptionService = StateObject(wrappedValue: PrescriptionService(
            context: PersistenceController.shared.container.viewContext
        ))

        // Initialize fetch request for this patient's prescriptions
        _prescriptions = FetchRequest<Prescription>(
            entity: Prescription.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Prescription.dateCreated, ascending: false)
            ],
            predicate: NSPredicate(format: "patient == %@", patient),
            animation: .default
        )
    }

    // MARK: - Filtered Prescriptions

    var filteredPrescriptions: [Prescription] {
        switch filterStatus {
        case .all:
            return Array(prescriptions)
        case .active:
            return prescriptions.filter { $0.status?.lowercased() == "active" }
        case .completed:
            return prescriptions.filter { $0.status?.lowercased() == "completed" }
        case .discontinued:
            return prescriptions.filter { $0.status?.lowercased() == "discontinued" }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Filter picker
            filterPicker

            // Prescriptions list
            if filteredPrescriptions.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredPrescriptions, id: \.objectID) { prescription in
                            PrescriptionCard(prescription: prescription)
                                .onTapGesture {
                                    selectedPrescription = prescription
                                    showingDetail = true
                                }
                                .contextMenu {
                                    Button(action: {
                                        selectedPrescription = prescription
                                        showingDetail = true
                                    }) {
                                        Label("View Details", systemImage: "eye")
                                    }

                                    if prescription.isActive {
                                        Button(action: {
                                            updateStatus(prescription, to: "completed")
                                        }) {
                                            Label("Mark as Completed", systemImage: "checkmark.circle")
                                        }

                                        Button(action: {
                                            updateStatus(prescription, to: "discontinued")
                                        }) {
                                            Label("Discontinue", systemImage: "xmark.circle")
                                        }
                                    }

                                    Divider()

                                    Button(role: .destructive, action: {
                                        prescriptionToDelete = prescription
                                        showAlert = true
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Prescriptions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewPrescription = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewPrescription) {
            PrescriptionsView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingDetail) {
            if let prescription = selectedPrescription {
                PrescriptionDetailView(prescription: prescription)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .alert("Delete Prescription", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let prescription = prescriptionToDelete {
                    deletePrescription(prescription)
                }
            }
        } message: {
            Text("Are you sure you want to delete this prescription? This action cannot be undone.")
        }
    }

    // MARK: - Subviews

    private var filterPicker: some View {
        Picker("Filter", selection: $filterStatus) {
            ForEach(PrescriptionFilter.allCases, id: \.self) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "pills.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Prescriptions")
                .font(.title2)
                .fontWeight(.semibold)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                showingNewPrescription = true
            }) {
                Label("Add Prescription", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)

            Spacer()
        }
    }

    private var emptyStateMessage: String {
        switch filterStatus {
        case .all:
            return "No prescriptions have been created for \(patient.fullName). Tap the button below to add one."
        case .active:
            return "No active prescriptions found."
        case .completed:
            return "No completed prescriptions found."
        case .discontinued:
            return "No discontinued prescriptions found."
        }
    }

    // MARK: - Helper Methods

    private func updateStatus(_ prescription: Prescription, to status: String) {
        do {
            try prescriptionService.updatePrescriptionStatus(prescription, status: status)
            alertMessage = "Prescription status updated to \(status)"
        } catch {
            alertMessage = "Error updating prescription: \(error.localizedDescription)"
        }
    }

    private func deletePrescription(_ prescription: Prescription) {
        do {
            try prescriptionService.deletePrescription(prescription)
        } catch {
            alertMessage = "Error deleting prescription: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Prescription Card

struct PrescriptionCard: View {
    @ObservedObject var prescription: Prescription
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prescription.formattedDateCreated)
                        .font(.headline)

                    if let physician = prescription.prescribingPhysician, !physician.isEmpty {
                        Text("Dr. \(physician)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Status badge
                Text(prescription.statusDisplayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(prescription.statusColor)
                    )
            }

            Divider()

            // Medications count
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
                Text("\(prescription.itemCount) medication\(prescription.itemCount == 1 ? "" : "s")")
                    .font(.subheadline)

                if prescription.hasActiveItems {
                    Spacer()
                    Text("\(prescription.activeItems.count) active")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Preview of medications
            if !prescription.sortedItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(prescription.sortedItems.prefix(3), id: \.objectID) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.itemStatus.color)
                                .frame(width: 6, height: 6)

                            Text(item.fullMedicationName)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()

                            Text(item.itemStatus.displayName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    if prescription.itemCount > 3 {
                        Text("+ \(prescription.itemCount - 3) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 14)
                    }
                }
                .padding(.top, 4)
            }

            // General instructions preview
            if let instructions = prescription.generalInstructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Supporting Types

enum PrescriptionFilter: CaseIterable {
    case all
    case active
    case completed
    case discontinued

    var displayName: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .completed: return "Completed"
        case .discontinued: return "Discontinued"
        }
    }
}

// MARK: - Preview

struct PrescriptionListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        // Create a sample patient
        let patient = Patient(context: context)
        patient.id = UUID()
        patient.firstName = "John"
        patient.lastName = "Doe"

        return NavigationView {
            PrescriptionListView(patient: patient)
                .environment(\.managedObjectContext, context)
        }
    }
}
