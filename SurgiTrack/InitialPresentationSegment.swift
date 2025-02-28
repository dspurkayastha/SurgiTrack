// InitialPresentationSegment.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData

struct InitialPresentationSegment: View {
    @ObservedObject var patient: Patient
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditInitialPresentation = false
    @State private var showingAddInitialPresentation = false
    @Binding var editMode: Bool
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        Group {
            if let presentation = patient.initialPresentation {
                presentationView(presentation)
            } else {
                EmptyStateView(
                    title: "No Initial Presentation Data",
                    message: "Add initial presentation details to complete the patient record",
                    iconName: "clipboard.fill",
                    color: DetailSegment.initial.color,
                    actionButton: AnyView(addButton)
                )
            }
        }
        .sheet(isPresented: $showingAddInitialPresentation) {
            AddInitialPresentationView(patient: patient)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingEditInitialPresentation) {
            if let presentation = patient.initialPresentation {
                EditInitialPresentationView(initialPresentation: presentation)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func presentationView(_ presentation: InitialPresentation) -> some View {
        VStack(spacing: 16) {
            InfoCard(title: "Presentation Details", color: DetailSegment.initial.color) {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        InfoRow(label: "Date", value: dateFormatter.string(from: presentation.presentationDate ?? Date()))
                        InfoRow(label: "Chief Complaint", value: presentation.chiefComplaint ?? "N/A")
                        InfoRow(label: "Initial Diagnosis", value: presentation.initialDiagnosis ?? "N/A")
                    }
                    
                    Spacer()
                    
                    if editMode {
                        Button(action: {
                            showingEditInitialPresentation = true
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16))
                                .foregroundColor(DetailSegment.initial.color)
                        }
                    }
                }
            }
            
            InfoCard(title: "Clinical Assessment", color: DetailSegment.initial.color) {
                InfoRow(label: "History", value: presentation.historyOfPresentIllness ?? "N/A", isMultiline: true)
                InfoRow(label: "Physical Exam", value: presentation.physicalExamination ?? "N/A", isMultiline: true)
            }
            
            InfoCard(title: "Medical History", color: DetailSegment.initial.color) {
                InfoRow(label: "Past Medical History", value: presentation.pastMedicalHistory ?? "N/A", isMultiline: true)
                InfoRow(label: "Allergies", value: presentation.allergies ?? "N/A", isMultiline: true)
            }
            
            InfoCard(title: "Tests & Medications", color: DetailSegment.initial.color) {
                InfoRow(label: "Lab Tests", value: presentation.labTests ?? "N/A", isMultiline: true)
                InfoRow(label: "Imaging", value: presentation.imagingReports ?? "N/A", isMultiline: true)
                InfoRow(label: "Medications", value: presentation.medications ?? "N/A", isMultiline: true)
            }
        }
        .transition(.opacity)
    }
    
    private var addButton: some View {
        Button(action: {
            showingAddInitialPresentation = true
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Initial Presentation")
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(DetailSegment.initial.color)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InitialPresentationSegment_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.firstName = "John"
        patient.lastName = "Doe"
        
        return InitialPresentationSegment(patient: patient, editMode: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}
