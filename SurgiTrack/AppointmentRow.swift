//
//  AppointmentRow.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 02/03/25.
//


//
//  AppointmentRow.swift
//  SurgiTrack
//
//  Created for SurgiTrack App on 02/03/25.
//

import SwiftUI

struct AppointmentRow: View {
    @ObservedObject var appointment: Appointment
    @Environment(\.colorScheme) private var colorScheme
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Appointment colors based on type
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
    
    var body: some View {
        HStack(spacing: 15) {
            // Time indicator
            VStack(spacing: 4) {
                Text(timeFormatter.string(from: appointment.startTime ?? Date()))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(timeFormatter.string(from: appointment.endTime ?? Date()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Rectangle()
                    .fill(appointment.isCompleted ? Color.gray : typeColor)
                    .frame(width: 4, height: 40)
                    .cornerRadius(2)
            }
            .frame(width: 60)
            
            // Appointment details
            VStack(alignment: .leading, spacing: 5) {
                Text(appointment.title ?? "Untitled Appointment")
                    .font(.headline)
                    .foregroundColor(appointment.isCompleted ? .secondary : .primary)
                    .strikethrough(appointment.isCompleted)
                
                if let patient = appointment.patient {
                    Text(patient.fullName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let location = appointment.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Status/Type indicator
            VStack(alignment: .trailing, spacing: 5) {
                if let type = appointment.appointmentType {
                    Text(type)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(typeColor.opacity(0.2))
                        .foregroundColor(typeColor)
                        .cornerRadius(4)
                }
                
                if appointment.isCompleted {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct AppointmentRowPreview: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let appointment = Appointment(context: context)
        appointment.id = UUID()
        appointment.title = "Surgical Consultation"
        appointment.startTime = Date()
        appointment.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        appointment.appointmentType = "Consultation"
        appointment.location = "Room 302, Building A"
        appointment.isCompleted = false
        
        return Group {
            AppointmentRow(appointment: appointment)
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.light)
            
            AppointmentRow(appointment: appointment)
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}