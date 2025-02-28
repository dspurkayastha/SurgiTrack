// FollowUpSegment.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData

struct FollowUpSegment: View {
    @ObservedObject var patient: Patient
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddFollowUp = false
    @Binding var editMode: Bool
    
    private var followUpsArray: [FollowUp] {
        (patient.followUps as? Set<FollowUp>)?.sorted {
            ($0.followUpDate ?? Date()) > ($1.followUpDate ?? Date())
        } ?? []
    }
    
    private var upcomingAppointments: [Appointment] {
        let now = Date()
        return (patient.appointments as? Set<Appointment>)?.filter {
            ($0.startTime ?? Date()) > now && !$0.isCompleted
        }.sorted {
            ($0.startTime ?? Date()) < ($1.startTime ?? Date())
        } ?? []
    }
    
    var body: some View {
        Group {
            if followUpsArray.isEmpty {
                EmptyStateView(
                    title: "No Follow-up Records",
                    message: "Add follow-up visits to track patient progress",
                    iconName: "calendar.badge.clock",
                    color: DetailSegment.followup.color,
                    actionButton: AnyView(addButton)
                )
            } else {
                VStack(spacing: 16) {
                    // Follow-up count and add button
                    HStack {
                        Text("\(followUpsArray.count) Follow-up Record\(followUpsArray.count == 1 ? "" : "s")")
                            .font(.headline)
                            .foregroundColor(DetailSegment.followup.color)
                        
                        Spacer()
                        
                        if editMode {
                            Button(action: {
                                showingAddFollowUp = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add")
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(DetailSegment.followup.color.opacity(0.2))
                                .foregroundColor(DetailSegment.followup.color)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Upcoming appointments section
                    if !upcomingAppointments.isEmpty {
                        upcomingAppointmentsSection
                    }
                    
                    Divider()
                    
                    // List of follow-ups
                    LazyVStack(spacing: 16) {
                        ForEach(followUpsArray, id: \.objectID) { followUp in
                            FollowUpCard(followUp: followUp)
                                .onTapGesture {
                                    // In a real implementation, this would navigate to a follow-up detail view
                                    print("Navigate to follow-up detail")
                                }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingAddFollowUp) {
            AddFollowUpView(patient: patient)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var upcomingAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming Appointments")
                .font(.headline)
                .foregroundColor(.blue)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(upcomingAppointments, id: \.objectID) { appointment in
                        upcomingAppointmentCard(appointment)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func upcomingAppointmentCard(_ appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                
                Text(formatDate(appointment.startTime))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text(appointment.title ?? "Appointment")
                .font(.subheadline)
                .lineLimit(1)
            
            if let type = appointment.appointmentType {
                Text(type)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(getAppointmentColor(type: type).opacity(0.2))
                    .foregroundColor(getAppointmentColor(type: type))
                    .cornerRadius(4)
            }
            
            if let location = appointment.location, !location.isEmpty {
                Text(location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getAppointmentColor(type: String) -> Color {
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
    
    private var addButton: some View {
        Button(action: {
            showingAddFollowUp = true
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Follow-up Visit")
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(DetailSegment.followup.color)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FollowUpSegment_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.firstName = "John"
        patient.lastName = "Doe"
        
        return FollowUpSegment(patient: patient, editMode: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}
