//
//  OverviewSegment.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 11/03/25.
//


// OverviewSegment.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData

struct OverviewSegment: View {
    @ObservedObject var patient: Patient
    @ObservedObject var viewModel: PatientDetailViewModel
    @Binding var editMode: Bool
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Patient Profile Card
            if let imageData = patient.profileImageData, let uiImage = UIImage(data: imageData) {
                VStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            }
            
            InfoCard(title: "Patient Information", color: DetailSegment.overview.color) {
                InfoRow(label: "Date of Birth", value: dateFormatter.string(from: patient.dateOfBirth ?? Date()))
                InfoRow(label: "Age", value: viewModel.calculateAge(from: patient.dateOfBirth ?? Date()))
                InfoRow(label: "Gender", value: patient.gender ?? "Not specified")
                InfoRow(label: "MRN", value: patient.medicalRecordNumber ?? "N/A")
                
                if let bloodType = patient.bloodType, !bloodType.isEmpty && bloodType != "Unknown" {
                    InfoRow(label: "Blood Type", value: bloodType)
                }
                
                if patient.height > 0 || patient.weight > 0 {
                    Divider()
                    
                    if patient.height > 0 {
                        InfoRow(label: "Height", value: String(format: "%.1f cm", patient.height))
                    }
                    
                    if patient.weight > 0 {
                        InfoRow(label: "Weight", value: String(format: "%.1f kg", patient.weight))
                    }
                    
                    if patient.height > 0 && patient.weight > 0 {
                        InfoRow(label: "BMI", value: viewModel.calculateBMI())
                    }
                }
            }
            
            InfoCard(title: "Contact Information", color: DetailSegment.overview.color) {
                InfoRow(label: "Phone", value: patient.phone ?? patient.contactInfo ?? "Not provided")
                
                if let email = patient.contactInfo, email != patient.phone {
                    InfoRow(label: "Email", value: email)
                }
                
                InfoRow(label: "Address", value: patient.address ?? "Not provided")
                
                if let emergencyName = patient.emergencyContactName, !emergencyName.isEmpty {
                    Divider()
                    Text("Emergency Contact")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    InfoRow(label: "Name", value: emergencyName)
                    InfoRow(label: "Phone", value: patient.emergencyContactPhone ?? "Not provided")
                }
            }
            
            if let insurance = patient.insuranceProvider, !insurance.isEmpty {
                InfoCard(title: "Insurance", color: DetailSegment.overview.color) {
                    InfoRow(label: "Provider", value: insurance)
                    InfoRow(label: "Policy Number", value: patient.insurancePolicyNumber ?? "Not provided")
                    
                    if let details = patient.insuranceDetails, !details.isEmpty {
                        InfoRow(label: "Details", value: details, isMultiline: true)
                    }
                }
            }
            
            // Clinical Summary Card
            clinicalSummaryCard
            
            // Discharge information (if discharged)
            if patient.isDischargedStatus, let dischargeSummary = patient.dischargeSummary {
                dischargeSummaryCard(dischargeSummary)
            }
        }
    }
    
    private var clinicalSummaryCard: some View {
        InfoCard(title: "Clinical Summary", color: DetailSegment.overview.color) {
            VStack(alignment: .leading, spacing: 10) {
                if let initialDiagnosis = patient.initialPresentation?.initialDiagnosis, !initialDiagnosis.isEmpty {
                    InfoRow(label: "Diagnosis", value: initialDiagnosis)
                }
                
                let surgeryCount = (patient.operativeData as? Set<OperativeData>)?.count ?? 0
                InfoRow(label: "Surgeries", value: surgeryCount > 0 ? "\(surgeryCount)" : "None")
                
                let followUpCount = (patient.followUps as? Set<FollowUp>)?.count ?? 0
                InfoRow(label: "Follow-ups", value: followUpCount > 0 ? "\(followUpCount)" : "None")
                
                let testCount = (patient.medicalTests as? Set<MedicalTest>)?.count ?? 0
                if testCount > 0 {
                    let abnormalCount = (patient.medicalTests as? Set<MedicalTest>)?.filter { $0.isAbnormal }.count ?? 0
                    InfoRow(label: "Tests", value: "\(testCount) (\(abnormalCount) abnormal)")
                } else {
                    InfoRow(label: "Tests", value: "None")
                }
                
                // Show upcoming appointments if any
                let upcomingAppointments = (patient.appointments as? Set<Appointment>)?.filter {
                    ($0.startTime ?? Date()) > Date() && !$0.isCompleted
                }.sorted {
                    ($0.startTime ?? Date()) < ($1.startTime ?? Date())
                } ?? []
                
                if !upcomingAppointments.isEmpty {
                    Divider()
                    Text("Upcoming Appointments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    ForEach(upcomingAppointments.prefix(2), id: \.objectID) { appointment in
                        HStack {
                            Text(formatDateTime(appointment.startTime))
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text(appointment.title ?? "Appointment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    if upcomingAppointments.count > 2 {
                        Text("+ \(upcomingAppointments.count - 2) more")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func dischargeSummaryCard(_ dischargeSummary: DischargeSummary) -> some View {
        InfoCard(title: "Discharge Information", color: DetailSegment.overview.color) {
            InfoRow(label: "Date", value: dateFormatter.string(from: dischargeSummary.dischargeDate ?? Date()))
            InfoRow(label: "Physician", value: dischargeSummary.dischargingPhysician ?? "Unknown")
            InfoRow(label: "Length of Stay", value: "\(patient.lengthOfStay) day\(patient.lengthOfStay == 1 ? "" : "s")")
            
            Button(action: {
                viewModel.showingDischargeSummary = true
            }) {
                Text("View Full Discharge Summary")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private func formatDateTime(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


struct OverviewSegment_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.firstName = "John"
        patient.lastName = "Doe"
        
        return OverviewSegment(
            patient: patient,
            viewModel: PatientDetailViewModel(patient: patient, context: context),
            editMode: .constant(true)
        )
        .environment(\.managedObjectContext, context)
    }
}
