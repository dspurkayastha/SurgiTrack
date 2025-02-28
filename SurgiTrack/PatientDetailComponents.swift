//
//  PatientDetailComponents.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 11/03/25.
//

// PatientDetailComponents.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData



// MARK: - Reusable Components for Patient Detail Views

struct InfoCard<Content: View>: View {
    let title: String
    let color: Color
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(title: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            
            content
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
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}



struct PatientStatusBanner: View {
    @ObservedObject var patient: Patient
    
    private func calculateAge(from dob: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        
        if let age = ageComponents.year {
            return "\(age)"
        } else {
            return "Unknown"
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            Circle()
                .fill(patient.isDischargedStatus ? Color.gray : Color.green)
                .frame(width: 10, height: 10)
            
            // Status text
            Text(patient.isDischargedStatus ? "DISCHARGED" : "ACTIVE")
                .font(.caption)
                .fontWeight(.bold)
            
            Spacer()
            
            // Bed number (for active patients)
            if !patient.isDischargedStatus, let bedNumber = patient.bedNumber, !bedNumber.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bed.double")
                        .font(.caption)
                    Text("Bed \(bedNumber)")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
            
            // Length of stay for discharged patients
            if patient.isDischargedStatus && patient.lengthOfStay > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("\(patient.lengthOfStay) day\(patient.lengthOfStay == 1 ? "" : "s")")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
            
            // Patient age and gender
            if let dob = patient.dateOfBirth {
                Text("Age: \(calculateAge(from: dob)) • \(patient.gender ?? "Unknown")")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            patient.isDischargedStatus ? Color.gray.opacity(0.1) : Color.green.opacity(0.1)
        )
    }
}

struct OperativeCard: View {
    let operativeData: OperativeData
    @Environment(\.colorScheme) private var colorScheme
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(operativeData.procedureName ?? "Unknown procedure")
                    .font(.headline)
                    .foregroundColor(DetailSegment.operative.color)
                
                Spacer()
                
                if let date = operativeData.operationDate {
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    if let anesthesia = operativeData.anaesthesiaType {
                        Label(anesthesia, systemImage: "lungs.fill")
                            .font(.caption)
                    }
                    
                    if operativeData.duration > 0 {
                        Label("\(Int(operativeData.duration)) min", systemImage: "clock")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if let surgeon = operativeData.surgeon {
                        Label("\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")", systemImage: "person.crop.rectangle")
                            .font(.caption)
                    } else if let surgeonName = operativeData.surgeonName {
                        Label(surgeonName, systemImage: "person.crop.rectangle")
                            .font(.caption)
                    }
                    
                    Label("\(Int(operativeData.estimatedBloodLoss)) mL", systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if let findings = operativeData.operativeFindings, !findings.isEmpty {
                Text("Findings: \(findings)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DetailSegment.operative.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

struct FollowUpCard: View {
    let followUp: FollowUp
    @Environment(\.colorScheme) private var colorScheme
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let followUpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private func timeSinceOperation(followUpDate: Date?) -> String {
        guard let followUpDate = followUpDate,
              let patient = followUp.patient else { return "" }
        
        // Find the most recent operation before this follow-up
        let operations = (patient.operativeData as? Set<OperativeData>)?.sorted {
            ($0.operationDate ?? Date()) > ($1.operationDate ?? Date())
        } ?? []
        
        guard let mostRecentOp = operations.first(where: { ($0.operationDate ?? Date()) < followUpDate }),
              let opDate = mostRecentOp.operationDate else {
            return ""
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: opDate, to: followUpDate)
        
        if let days = components.day {
            if days < 30 {
                return "\(days) days post-op"
            } else {
                let months = days / 30
                return "\(months) \(months == 1 ? "month" : "months") post-op"
            }
        }
        
        return ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(followUpDateFormatter.string(from: followUp.followUpDate ?? Date()))
                    .font(.headline)
                    .foregroundColor(DetailSegment.followup.color)
                
                Spacer()
                
                Text(timeSinceOperation(followUpDate: followUp.followUpDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Divider()
            
            if let assessment = followUp.outcomeAssessment, !assessment.isEmpty {
                Group {
                    Text("Outcome Assessment")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(assessment)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if let notes = followUp.followUpNotes, !notes.isEmpty {
                Group {
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(notes)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if let medicationChanges = followUp.medicationChanges, !medicationChanges.isEmpty {
                Group {
                    Text("Medication Changes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(medicationChanges)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text("Next Appointment: ")
                    .foregroundColor(.secondary)
                
                Text(dateFormatter.string(from: followUp.nextAppointment ?? Date()))
                    .fontWeight(.medium)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DetailSegment.followup.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

struct ContentHeaderView: View {
    let segment: DetailSegment
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(segment.rawValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(segment.color)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

struct ActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
                    .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct RiskAssessmentRow: View {
    let calculation: StoredCalculation
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(calculation.calculatorName ?? "Risk Assessment")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let date = calculation.calculationDate {
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(String(format: "%.1f%%", calculation.resultPercentage))
                .font(.headline)
                .foregroundColor(StoredCalculationHelpers(calculation: calculation).riskColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(StoredCalculationHelpers(calculation: calculation).riskColor.opacity(0.1))
                )
        }
        .padding(.vertical, 8)
    }
}

// Helper for risk assessment visualization
enum CalculationRiskLevel: String {
    case low = "Low Risk"
    case moderate = "Moderate Risk"
    case high = "High Risk"
    case veryHigh = "Very High Risk"
}

// Extension that provides view-related helpers without modifying the model
struct StoredCalculationHelpers {
    let calculation: StoredCalculation
    
    var riskLevel: CalculationRiskLevel {
        switch calculation.resultPercentage {
        case 0..<10:
            return .low
        case 10..<30:
            return .moderate
        case 30..<60:
            return .high
        default:
            return .veryHigh
        }
    }
    
    var riskColor: Color {
        switch riskLevel {
        case .low:
            return .green
        case .moderate:
            return .yellow
        case .high:
            return .orange
        case .veryHigh:
            return .red
        }
    }
}

