//
//  TimelineEvent.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 11/03/25.
//


// TimelineEvent.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData

// MARK: - Timeline Event Model

struct TimelineEvent: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let title: String
    let description: String
    let color: Color
    let type: EventType
    let objectID: NSManagedObjectID? // Optional reference to the original entity
    
    enum EventType: String, CaseIterable {
        case initial = "Initial"
        case surgery = "Surgery"
        case followUp = "Follow-up"
        case test = "Test"
        case appointment = "Appointment"
        case discharge = "Discharge"
        
        var iconName: String {
            switch self {
            case .initial: return "stethoscope"
            case .surgery: return "scalpel"
            case .followUp: return "calendar.badge.clock"
            case .test: return "cross.case"
            case .appointment: return "calendar"
            case .discharge: return "arrow.up.forward.square"
            }
        }
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    init(date: Date, title: String, description: String, color: Color, type: EventType, objectID: NSManagedObjectID? = nil) {
        self.date = date
        self.title = title
        self.description = description
        self.color = color
        self.type = type
        self.objectID = objectID
    }
    
    static func == (lhs: TimelineEvent, rhs: TimelineEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Timeline Event Card

struct TimelineEventCard: View {
    let event: TimelineEvent
    let isConnected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    init(event: TimelineEvent, isConnected: Bool = true) {
        self.event = event
        self.isConnected = isConnected
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Left column with circle and vertical line
            VStack(spacing: 0) {
                Circle()
                    .fill(event.color)
                    .frame(width: 20, height: 20)
                
                if isConnected {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 50)
                }
            }
            .frame(width: 20)
            
            // Right column with event details
            VStack(alignment: .leading, spacing: 8) {
                // Event title and date
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: event.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Event icon and type indicator
                HStack {
                    Image(systemName: event.type.iconName)
                        .foregroundColor(event.color)
                        .padding(6)
                        .background(event.color.opacity(0.2))
                        .clipShape(Circle())
                    
                    Text(event.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(event.color.opacity(0.1))
                        .foregroundColor(event.color)
                        .cornerRadius(4)
                }
                
                // Event description
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
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
                .stroke(event.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Timeline Filter Button
struct TimelineFilterButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(isSelected ? color.opacity(0.3) : color.opacity(0.15)))
            .foregroundColor(isSelected ? color : color.opacity(0.8))
        }
    }
}

// MARK: - Timeline View Model
class TimelineViewModel: ObservableObject {
    @Published var events: [TimelineEvent] = []
    @Published var filteredEvents: [TimelineEvent] = []
    @Published var selectedFilter: TimelineEvent.EventType?
    
    func filterEvents(by type: TimelineEvent.EventType?) {
        selectedFilter = type
        
        if let type = type {
            filteredEvents = events.filter { $0.type == type }
        } else {
            filteredEvents = events
        }
    }
    
    func loadEvents(from patient: Patient) {
        var newEvents: [TimelineEvent] = []
        
        // Add surgeries
        if let surgeries = patient.operativeData as? Set<OperativeData> {
            for surgery in surgeries {
                newEvents.append(TimelineEvent(
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
                newEvents.append(TimelineEvent(
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
            newEvents.append(TimelineEvent(
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
                newEvents.append(TimelineEvent(
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
                newEvents.append(TimelineEvent(
                    date: appointment.startTime ?? Date(),
                    title: appointment.title ?? "Appointment",
                    description: appointment.notes ?? "",
                    color: .purple,
                    type: .appointment,
                    objectID: appointment.objectID
                ))
            }
        }
        
        // Add discharge summary if available
        if let dischargeSummary = patient.dischargeSummary {
            newEvents.append(TimelineEvent(
                date: dischargeSummary.dischargeDate ?? Date(),
                title: "Patient Discharged",
                description: "Discharged by " + (dischargeSummary.dischargingPhysician ?? "Unknown"),
                color: .gray,
                type: .discharge,
                objectID: dischargeSummary.objectID
            ))
        }
        
        self.events = newEvents.sorted(by: { $0.date > $1.date })
        self.filteredEvents = self.events
    }
}
