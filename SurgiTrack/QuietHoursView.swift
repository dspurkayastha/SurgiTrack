//
//  QuietHoursView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// QuietHoursView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct QuietHoursView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var quietHoursEnabled = true
    @State private var startTime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))!
    @State private var endTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0))!
    @State private var allowUrgentNotifications = true
    @State private var showingSaveConfirmation = false
    
    // Define urgent notification types
    @State private var urgentTypes: Set<UrgentType> = [.emergencyChanges, .criticalUpdates, .abnormalResults]
    
    var body: some View {
        Form {
            Section(header: Text("Quiet Hours")) {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                    .onChange(of: quietHoursEnabled) { newValue in
                        if !newValue {
                            // Disable urgent notifications if quiet hours are disabled
                            allowUrgentNotifications = false
                        }
                    }
                
                if quietHoursEnabled {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
            }
            
            if quietHoursEnabled {
                Section(header: Text("Exceptions")) {
                    Toggle("Allow Urgent Notifications", isOn: $allowUrgentNotifications)
                    
                    if allowUrgentNotifications {
                        Text("During quiet hours, you'll only receive the following types of notifications:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        ForEach(UrgentType.allCases, id: \.self) { type in
                            Toggle(type.description, isOn: Binding(
                                get: { urgentTypes.contains(type) },
                                set: { newValue in
                                    if newValue {
                                        urgentTypes.insert(type)
                                    } else {
                                        urgentTypes.remove(type)
                                    }
                                }
                            ))
                        }
                    }
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("Quiet Hours Active")
                                .font(.headline)
                            
                            Text("\(formatTime(startTime)) - \(formatTime(endTime))")
                                .font(.subheadline)
                            
                            Text(allowUrgentNotifications ? "Urgent notifications allowed" : "All notifications silenced")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Save button
            Section {
                Button(action: {
                    saveSettings()
                    showingSaveConfirmation = true
                    
                    // Dismiss confirmation after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showingSaveConfirmation = false
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Save Settings")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Quiet Hours")
        .alert(isPresented: $showingSaveConfirmation) {
            Alert(
                title: Text("Settings Saved"),
                message: Text("Your quiet hours have been updated."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveSettings() {
        // Here we would save to UserDefaults or Core Data
        // For now, we'll just simulate saving
        
        print("Saving quiet hours settings:")
        print("Enabled: \(quietHoursEnabled)")
        if quietHoursEnabled {
            print("Start: \(formatTime(startTime))")
            print("End: \(formatTime(endTime))")
            print("Allow urgent: \(allowUrgentNotifications)")
            if allowUrgentNotifications {
                print("Urgent types: \(urgentTypes.map { $0.description }.joined(separator: ", "))")
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

enum UrgentType: String, CaseIterable {
    case emergencyChanges = "emergencyChanges"
    case criticalUpdates = "criticalUpdates"
    case abnormalResults = "abnormalResults"
    case operationChanges = "operationChanges"
    
    var description: String {
        switch self {
        case .emergencyChanges:
            return "Emergency Schedule Changes"
        case .criticalUpdates:
            return "Critical Patient Updates"
        case .abnormalResults:
            return "Abnormal Test Results"
        case .operationChanges:
            return "Operation Time Changes"
        }
    }
}

struct QuietHoursView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QuietHoursView()
        }
    }
}