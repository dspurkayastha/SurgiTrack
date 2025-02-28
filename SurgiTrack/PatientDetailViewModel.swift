//
//  PatientDetailViewModel.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 11/03/25.
//


// PatientDetailViewModel.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData
import Combine

class PatientDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var patient: Patient
    @Published var selectedSegment: DetailSegment = .overview
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Action Sheet States
    @Published var showingAddFollowUp = false
    @Published var showingAddOperativeData = false
    @Published var showingAddInitialPresentation = false
    @Published var showingEditPatient = false
    @Published var showingAttachments = false
    @Published var showingEditInitialPresentation = false
    @Published var showingDischargePatient = false
    @Published var showingDischargeSummary = false
    @Published var showConfirmReadmission = false
    
    // Segment Transition
    @Published var segmentTransition = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let viewContext: NSManagedObjectContext
    
    // MARK: - Computed Properties
    
    var hasInitialPresentation: Bool {
        return patient.initialPresentation != nil
    }
    
    var operativeDataArray: [OperativeData] {
        return (patient.operativeData as? Set<OperativeData>)?.sorted {
            ($0.operationDate ?? Date()) > ($1.operationDate ?? Date())
        } ?? []
    }
    
    var followUpsArray: [FollowUp] {
        return (patient.followUps as? Set<FollowUp>)?.sorted {
            ($0.followUpDate ?? Date()) > ($1.followUpDate ?? Date())
        } ?? []
    }
    
    var timelineEvents: [TimelineEvent] {
        getTimelineEvents()
    }
    
    var appointmentsArray: [Appointment] {
        return (patient.appointments as? Set<Appointment>)?.sorted {
            ($0.startTime ?? Date()) > ($1.startTime ?? Date())
        } ?? []
    }
    
    var upcomingAppointmentsArray: [Appointment] {
        let now = Date()
        return appointmentsArray.filter {
            ($0.startTime ?? Date()) > now && !$0.isCompleted
        }
    }
    
    var headerDescription: String {
        switch selectedSegment {
        case .overview:
            return "Patient demographic and basic information"
        case .initial:
            return "Initial assessment and diagnosis details"
        case .operative:
            return "\(operativeDataArray.count) surgical procedures"
        case .followup:
            return "\(followUpsArray.count) follow-up appointments"
        case .riskAssessment:
            return "Surgical risk assessment tools"
        case .timeline:
            return "Chronological view of patient events"
            
        // ADD THESE:
        case .reports:
            return "Lab, imaging, and other medical reports"
        case .prescriptions:
            return "Medication plans for this patient"
        case .attachments:
            return "Files and images attached to the patient record"
        }
    }

    
    // MARK: - Initializer
    
    init(patient: Patient, context: NSManagedObjectContext) {
        self.patient = patient
        self.viewContext = context
        
        // Setup observation of the patient object
        setupObservation()
    }
    
    // MARK: - Public Methods
    
    func changeSegment(to segment: DetailSegment) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedSegment = segment
            // Create slight delay for smoother transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.segmentTransition.toggle()
            }
        }
    }
    
    func readmitPatient() {
        isLoading = true
        
        // Reactivate patient
        patient.isDischargedStatus = false
        patient.dateModified = Date()
        
        // Save changes
        do {
            try viewContext.save()
            isLoading = false
        } catch {
            errorMessage = "Error readmitting patient: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    func dischargePatient() {
        showingDischargePatient = true
    }
    
    func fetchRiskCalculations() -> [StoredCalculation] {
        let request: NSFetchRequest<StoredCalculation> = StoredCalculation.fetchRequest()
        request.predicate = NSPredicate(format: "patient == %@", patient)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredCalculation.calculationDate, ascending: false)]
        request.fetchLimit = 10
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching calculations: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservation() {
        // For future implementation:
        // This would observe changes to the patient object and related entities
        // to keep the UI in sync with CoreData changes
    }
    
    // Function to build timeline events from patient data
    private func getTimelineEvents() -> [TimelineEvent] {
        var events: [TimelineEvent] = []
        
        // Add surgeries
        if let surgeries = patient.operativeData as? Set<OperativeData> {
            for surgery in surgeries {
                events.append(TimelineEvent(
                    date: surgery.operationDate ?? Date(),
                    title: surgery.procedureName ?? "Surgery",
                    description: surgery.anaesthesiaType ?? "",
                    color: .orange,
                    type: .surgery
                ))
            }
        }
        
        // Add follow-ups
        if let followUps = patient.followUps as? Set<FollowUp> {
            for followUp in followUps {
                events.append(TimelineEvent(
                    date: followUp.followUpDate ?? Date(),
                    title: "Follow-up Visit",
                    description: followUp.followUpNotes ?? "",
                    color: .green,
                    type: .followUp
                ))
            }
        }
        
        // Add initial presentation
        if let initialPresentation = patient.initialPresentation {
            events.append(TimelineEvent(
                date: initialPresentation.presentationDate ?? Date(),
                title: "Initial Presentation",
                description: initialPresentation.chiefComplaint ?? "",
                color: .blue,
                type: .initial
            ))
        }
        
        // Add tests
        if let tests = patient.medicalTests as? Set<MedicalTest> {
            for test in tests {
                events.append(TimelineEvent(
                    date: test.testDate ?? Date(),
                    title: test.testType ?? "Medical Test",
                    description: test.isAbnormal ? "Abnormal results" : "Normal results",
                    color: test.isAbnormal ? .red : .blue,
                    type: .test
                ))
            }
        }
        
        // Add appointments
        if let appointments = patient.appointments as? Set<Appointment> {
            for appointment in appointments {
                if appointment.isCompleted {
                    events.append(TimelineEvent(
                        date: appointment.startTime ?? Date(),
                        title: appointment.title ?? "Appointment",
                        description: appointment.notes ?? "",
                        color: .purple,
                        type: .appointment
                    ))
                }
            }
        }
        
        // Add discharge summary if available
        if let dischargeSummary = patient.dischargeSummary {
            events.append(TimelineEvent(
                date: dischargeSummary.dischargeDate ?? Date(),
                title: "Patient Discharged",
                description: "Discharged by " + (dischargeSummary.dischargingPhysician ?? "Unknown"),
                color: .gray,
                type: .discharge
            ))
        }
        
        return events
    }
    
    // Helper function to calculate age from date of birth
    func calculateAge(from dob: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        
        if let age = ageComponents.year {
            return "\(age) years"
        } else {
            return "Unknown"
        }
    }
    
    // Helper function to calculate BMI
    func calculateBMI() -> String {
        guard patient.height > 0, patient.weight > 0 else { return "N/A" }
        
        // BMI = weight(kg) / (height(m))²
        let heightInMeters = patient.height / 100
        let bmi = patient.weight / (heightInMeters * heightInMeters)
        
        return String(format: "%.1f", bmi)
    }
    
    // Format dates consistently
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}


struct InfoRow: View {
    let label: String
    let value: String
    let iconName: String?
    let accentColor: Color?
    let isMultiline: Bool
    
    // Constants to control layout sizing
    private let minLabelWidth: CGFloat = 80
    private let maxLabelWidth: CGFloat = 120
    private let iconWidth: CGFloat = 18
    private let horizontalSpacing: CGFloat = 10
    private let compactWidthThreshold: CGFloat = 320
    
    init(label: String, value: String, iconName: String? = nil, accentColor: Color? = nil, isMultiline: Bool = false) {
        self.label = label
        self.value = value
        self.iconName = iconName
        self.accentColor = accentColor
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        let displayColor = accentColor ?? .primary
        
        // Adaptive layout based on available width and content mode
        GeometryReader { geometry in
            if isMultiline {
                createMultilineLayout(displayColor: displayColor)
                    .padding(.horizontal, 8)
            } else if geometry.size.width < compactWidthThreshold {
                createCompactLayout(displayColor: displayColor)
                    .padding(.horizontal, 8)
            } else {
                createStandardLayout(displayColor: displayColor, availableWidth: geometry.size.width)
                    .padding(.horizontal, 8)
            }
        }
        .frame(minHeight: isMultiline ? 100 : 44)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // Standard side-by-side layout for wider screens
    private func createStandardLayout(displayColor: Color, availableWidth: CGFloat) -> some View {
        HStack(alignment: .top, spacing: horizontalSpacing) {
            // Icon
            if let iconName = iconName {
                Image(systemName: iconName)
                    .foregroundColor(displayColor)
                    .frame(width: iconWidth)
            }
            
            // Label (with controlled width)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(width: min(maxLabelWidth, max(minLabelWidth, availableWidth * 0.25)), alignment: .leading)
            
            // Value (with overflow protection)
            if value.isEmpty || value == "N/A" {
                Text("Not provided")
                    .italic()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(value)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1) // Prioritize this content when space is limited
            }
        }
    }
    
    // Compact layout for narrow screens
    private func createCompactLayout(displayColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label row with icon
            HStack(spacing: 6) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(displayColor)
                        .frame(width: iconWidth)
                }
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Value with proper wrapping
            if value.isEmpty || value == "N/A" {
                Text("Not provided")
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.leading, iconName != nil ? iconWidth + 6 : 0)
            } else {
                Text(value)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .padding(.leading, iconName != nil ? iconWidth + 6 : 0)
            }
        }
    }
    
    // Multiline layout with stacked elements
    private func createMultilineLayout(displayColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label row with icon
            HStack {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(displayColor)
                        .frame(width: iconWidth)
                }
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Value with container
            if value.isEmpty || value == "N/A" {
                Text("Not provided")
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            } else {
                ScrollView {
                    Text(value)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .frame(maxHeight: 150) // Prevent excessive vertical growth
            }
        }
    }
}

// MARK: - Preview
struct InfoRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview different variations
            InfoRow(label: "Name", value: "John Smith", iconName: "person", accentColor: .blue)
            
            InfoRow(label: "Address", value: "123 Very Long Street Name That Should Wrap Properly When It Gets Too Long For The Available Space", iconName: "location", accentColor: .green)
            
            InfoRow(label: "Medical History", value: "Patient has a long history of hypertension and diabetes. Regular medication includes metformin and lisinopril.", iconName: "heart.text.square", accentColor: .red, isMultiline: true)
            
            InfoRow(label: "Notes", value: "", iconName: "note.text")
            
            // Extra long text to test overflow
            InfoRow(label: "Diagnosis", value: "Pneumonoultramicroscopicsilicovolcanoconiosis with associated supercalifragilisticexpialidocious symptoms requiring immediate attention", iconName: "stethoscope", accentColor: .purple)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
