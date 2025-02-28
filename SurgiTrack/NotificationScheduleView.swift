//
//  NotificationScheduleView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


// NotificationScheduleView.swift
// SurgiTrack
// Created for SurgiTrack App

import SwiftUI

struct NotificationScheduleView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var reminderTime = Date()
    @State private var enabledDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    @State private var enablePreOpReminders = true
    @State private var enablePostOpReminders = true
    @State private var preOpReminderHours = 24
    @State private var postOpReminderDays = 1
    @State private var showingSaveConfirmation = false

    var body: some View {
        Form {
            // Daily reminder time
            Section(header: Text("Daily Reminder Time")) {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .frame(maxHeight: 180)
            }
            
            // Days of week
            Section(header: Text("Active Days")) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Toggle(day.name, isOn: Binding(
                        get: { enabledDays.contains(day) },
                        set: { newValue in
                            if newValue {
                                enabledDays.insert(day)
                            } else {
                                enabledDays.remove(day)
                            }
                        }
                    ))
                }
                
                HStack {
                    Spacer()
                    Button("Weekdays Only") {
                        enabledDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                    }
                    Spacer()
                    Button("All Days") {
                        enabledDays = Set(Weekday.allCases)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Pre-operative reminders
            Section(header: Text("Pre-operative Reminders")) {
                Toggle("Enable", isOn: $enablePreOpReminders)
                
                if enablePreOpReminders {
                    Stepper(value: $preOpReminderHours, in: 1...72) {
                        Text("Remind \(preOpReminderHours) hours before")
                    }
                }
            }
            
            // Post-operative reminders
            Section(header: Text("Post-operative Reminders")) {
                Toggle("Enable", isOn: $enablePostOpReminders)
                
                if enablePostOpReminders {
                    Stepper(value: $postOpReminderDays, in: 1...14) {
                        Text("Remind \(postOpReminderDays) days after")
                    }
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
                .disabled(enabledDays.isEmpty)
            }
        }
        .navigationTitle("Notification Schedule")
        .alert(isPresented: $showingSaveConfirmation) {
            Alert(
                title: Text("Settings Saved"),
                message: Text("Your notification schedule has been updated."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveSettings() {
        // Here we would save to UserDefaults or Core Data
        // For now, we'll just simulate saving
        
        // Schedule notifications in iOS based on these settings
        // This would interface with UNUserNotificationCenter
        
        print("Saving notification schedule:")
        print("Time: \(formatTime(reminderTime))")
        print("Days: \(enabledDays.map { $0.name }.joined(separator: ", "))")
        print("Pre-op: \(enablePreOpReminders ? "\(preOpReminderHours) hours before" : "Disabled")")
        print("Post-op: \(enablePostOpReminders ? "\(postOpReminderDays) days after" : "Disabled")")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

enum Weekday: Int, CaseIterable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

struct NotificationScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationScheduleView()
        }
    }
}