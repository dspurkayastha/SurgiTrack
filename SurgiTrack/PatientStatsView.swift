//
//  PatientStatsView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 07/03/25.
//


// PatientStatsView.swift
// SurgiTrack
// Created on 07/03/25.

import SwiftUI
import CoreData

struct PatientStatsView: View {
    @ObservedObject var patient: Patient
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEnhancedAnalysis = false

    
    // MARK: - Computed Properties
    
    private var surgeryCount: Int {
        return (patient.operativeData as? Set<OperativeData>)?.count ?? 0
    }
    
    private var followUpCount: Int {
        return (patient.followUps as? Set<FollowUp>)?.count ?? 0
    }
    
    private var appointmentCount: Int {
        return (patient.appointments as? Set<Appointment>)?.count ?? 0
    }
    
    private var completedAppointmentsCount: Int {
        return (patient.appointments as? Set<Appointment>)?.filter { $0.isCompleted }.count ?? 0
    }
    
    private var testCount: Int {
        return (patient.medicalTests as? Set<MedicalTest>)?.count ?? 0
    }
    
    private var abnormalTestCount: Int {
        return (patient.medicalTests as? Set<MedicalTest>)?.filter { $0.isAbnormal }.count ?? 0
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary stats
                HStack(spacing: 16) {
                    statsCard(title: "Surgeries", value: "\(surgeryCount)", icon: "scalpel", color: .orange)
                    statsCard(title: "Follow-ups", value: "\(followUpCount)", icon: "calendar.badge.clock", color: .green)
                }
                
                HStack(spacing: 16) {
                    statsCard(title: "Tests", value: "\(testCount)", icon: "cross.case", color: .blue)
                    statsCard(title: "Appointments", value: "\(appointmentCount)", icon: "calendar", color: .purple)
                }
                Button(action: {
                    showingEnhancedAnalysis = true
                }) {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("Advanced Trends Analysis")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Appointment completion pie chart
                if appointmentCount > 0 {
                    PieChartView(
                        data: [
                            ChartData(value: Double(completedAppointmentsCount), label: "Completed", color: .green, date: Date()),
                            ChartData(value: Double(appointmentCount - completedAppointmentsCount), label: "Scheduled", color: .blue, date: Date())
                        ],
                        title: "Appointment Status",
                        showLegend: true
                    )
                }
                
                // Test results chart
                if testCount > 0 {
                    BarChartView(
                        data: getTestResultsData(),
                        title: "Test Results",
                        showLabels: true
                    )
                }
                
                // Timeline chart if multiple surgeries or visits
                if surgeryCount > 1 || followUpCount > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Patient History Timeline")
                            .font(.headline)
                        
                        timelineView
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                }
                
                // Risk assessments summary
                if let calculations = fetchCalculations(), !calculations.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Risk Assessments")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(calculations, id: \.objectID) { calculation in
                            NavigationLink(destination: CalculationDetailView(calculation: calculation)) {
                                riskAssessmentRow(calculation: calculation)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                }
                
                
            }
            .padding()
        }
        .navigationTitle("Patient Statistics")
        .sheet(isPresented: $showingEnhancedAnalysis) {
            EnhancedTrendsView.createWithPatient(patient)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    // MARK: - Component Views
    
    private func statsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
        .frame(maxWidth: .infinity)
    }
    
    private var timelineView: some View {
        VStack(spacing: 0) {
            ForEach(getTimelineEvents().sorted(by: { $0.date > $1.date }), id: \.id) { event in
                HStack(spacing: 15) {
                    // Vertical timeline with date bullets
                    VStack(spacing: 0) {
                        Circle()
                            .fill(event.color)
                            .frame(width: 12, height: 12)
                        
                        if event != getTimelineEvents().sorted(by: { $0.date > $1.date }).last {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 2)
                                .frame(height: 50)
                        }
                    }
                    .frame(width: 30)
                    
                    // Event details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(formatDate(event.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !event.description.isEmpty {
                            Text(event.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private func riskAssessmentRow(calculation: StoredCalculation) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(calculation.calculatorName ?? "Risk Assessment")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let date = calculation.calculationDate {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(String(format: "%.1f%%", calculation.resultPercentage))
                .font(.headline)
                .foregroundColor(calculation.riskColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(calculation.riskColor.opacity(0.1))
                )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getTestResultsData() -> [ChartData] {
        // Categorize tests by type
        let medicalTests = patient.medicalTests as? Set<MedicalTest> ?? []
        var categoryCounts: [String: (normal: Int, abnormal: Int)] = [:]
        
        for test in medicalTests {
            let category = test.testCategory ?? "Other"
            var current = categoryCounts[category] ?? (normal: 0, abnormal: 0)
            
            if test.isAbnormal {
                current.abnormal += 1
            } else {
                current.normal += 1
            }
            
            categoryCounts[category] = current
        }
        
        // Convert to chart data
        var chartData: [ChartData] = []
        
        for (category, counts) in categoryCounts.sorted(by: { $0.key < $1.key }) {
            if counts.normal > 0 {
                chartData.append(ChartData(
                    value: Double(counts.normal),
                    label: "\(category) (Normal)",
                    color: .green,
                    date: Date()
                ))
            }
            
            if counts.abnormal > 0 {
                chartData.append(ChartData(
                    value: Double(counts.abnormal),
                    label: "\(category) (Abnormal)",
                    color: .red,
                    date: Date()
                ))
            }
        }
        
        return chartData
    }
    
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
                    type: .surgery,
                    objectID: surgery.objectID
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
                    type: .followUp,
                    objectID: followUp.objectID
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
                type: .initial,
                objectID: initialPresentation.objectID
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
                    type: .test,
                    objectID: test.objectID
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
                        type: .appointment,
                        objectID: appointment.objectID
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
                type: .discharge,
                objectID: dischargeSummary.objectID
            ))
        }
        
        return events
    }
    
    private func fetchCalculations() -> [StoredCalculation]? {
        let request: NSFetchRequest<StoredCalculation> = StoredCalculation.fetchRequest()
        request.predicate = NSPredicate(format: "patient == %@", patient)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredCalculation.calculationDate, ascending: false)]
        request.fetchLimit = 5
        
        return try? viewContext.fetch(request)
    }
}

struct PatientStatsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.firstName = "John"
        patient.lastName = "Doe"
        
        return PatientStatsView(patient: patient)
            .environment(\.managedObjectContext, context)
    }
}
