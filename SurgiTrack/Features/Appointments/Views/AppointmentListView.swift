//
//  AppointmentListView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 02/03/25.
//


//
//  AppointmentListView.swift
//  SurgiTrack
//
//  Created for SurgiTrack App on 02/03/25.
//

import SwiftUI
import CoreData

struct AppointmentListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // State for calendar/date selection
    @State private var selectedDate: Date = Date()
    @State private var calendarId: UUID = UUID() // Used to force calendar refresh
    
    // State for new appointment sheet
    @State private var isShowingNewAppointment = false
    
    // Date formatters
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Fetch appointments for the selected date
    var filteredAppointments: [Appointment] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Appointment.startTime, ascending: true)]
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching appointments: \(error.localizedDescription)")
            return []
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Date Picker
                VStack(spacing: 10) {
                    // Month and Year header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(monthYearString(from: selectedDate))")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        // Navigation buttons
                        HStack(spacing: 15) {
                            Button(action: previousDay) {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: goToToday) {
                                Text("Today")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: nextDay) {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Calendar week view
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(-3...3, id: \.self) { offset in
                                let date = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate)!
                                dayButton(date: date)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .id(calendarId) // Force refresh when calendarId changes
                }
                .padding(.bottom, 15)
                .background(
                    colorScheme == .dark ? Color(UIColor.systemBackground) : Color.white
                )
                
                // Appointments List
                if filteredAppointments.isEmpty {
                    emptyStateView
                } else {
                    appointmentListView
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingNewAppointment = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $isShowingNewAppointment) {
                AddAppointmentView(date: selectedDate)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func dayButton(date: Date) -> some View {
        let calendar = Calendar.current
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        
        return Button(action: {
            selectedDate = date
        }) {
            VStack(spacing: 8) {
                Text(dayOfWeek(from: date))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
            }
            .frame(width: 45, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Appointments")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("No appointments scheduled for this day")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                isShowingNewAppointment = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Appointment")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var appointmentListView: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(filteredAppointments, id: \.objectID) { appointment in
                    NavigationLink(destination: AppointmentDetailView(appointment: appointment)) {
                        AppointmentRow(appointment: appointment)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - Helper Methods
    
    private func previousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            selectedDate = newDate
            calendarId = UUID() // Force calendar refresh
        }
    }
    
    private func nextDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            selectedDate = newDate
            calendarId = UUID() // Force calendar refresh
        }
    }
    
    private func goToToday() {
        selectedDate = Date()
        calendarId = UUID() // Force calendar refresh
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview Provider
struct AppointmentListView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


