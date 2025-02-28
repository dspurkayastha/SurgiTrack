//
//  NotificationsView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 07/03/25.
//


// NotificationsView.swift
// SurgiTrack
// Created on 07/03/25.

import SwiftUI

struct NotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var notifications: [AppNotification]
    @State private var filter: NotificationFilter = .all
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter tabs
                filterTabsView
                
                // Notification list or empty state
                if filteredNotifications.isEmpty {
                    emptyStateView
                } else {
                    notificationListView
                }
            }
            .navigationTitle("Notifications")
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Mark All Read") {
                    markAllAsRead()
                }
                .disabled(notifications.allSatisfy { $0.isRead })
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredNotifications: [AppNotification] {
        switch filter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        case .alerts:
            return notifications.filter { $0.type == .warning || $0.type == .error }
        case .info:
            return notifications.filter { $0.type == .info }
        }
    }
    
    // MARK: - Component Views
    
    private var filterTabsView: some View {
        HStack(spacing: 0) {
            ForEach(NotificationFilter.allCases) { tabFilter in
                Button(action: {
                    withAnimation {
                        filter = tabFilter
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tabFilter.displayName)
                            .font(.subheadline)
                            .fontWeight(filter == tabFilter ? .semibold : .regular)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        
                        if filter == tabFilter {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                                .matchedGeometryEffect(id: "underline", in: namespace)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .foregroundColor(filter == tabFilter ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(emptyStateMessage)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("New notifications will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    private var emptyStateMessage: String {
        switch filter {
        case .all: return "No Notifications"
        case .unread: return "No Unread Notifications"
        case .alerts: return "No Alert Notifications"
        case .info: return "No Informational Notifications"
        }
    }
    
    private var notificationListView: some View {
        List {
            ForEach(filteredNotifications.indices, id: \.self) { index in
                NotificationRow(notification: $notifications[index])
                    .swipeActions {
                        Button(action: {
                            deleteNotification(at: index)
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                        
                        Button(action: {
                            toggleRead(at: index)
                        }) {
                            Label(notifications[index].isRead ? "Mark Unread" : "Mark Read", 
                                  systemImage: notifications[index].isRead ? "envelope" : "envelope.open")
                        }
                        .tint(.blue)
                    }
            }
        }
    }
    
    // MARK: - Methods
    
    private func markAllAsRead() {
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
    }
    
    private func toggleRead(at index: Int) {
        notifications[index].isRead.toggle()
    }
    
    private func deleteNotification(at index: Int) {
        let notificationIndex = notifications.firstIndex { $0.id == filteredNotifications[index].id }
        if let notificationIndex = notificationIndex {
            notifications.remove(at: notificationIndex)
        }
    }
    
    // MARK: - Namespace
    @Namespace private var namespace
}

// MARK: - Supporting Types

enum NotificationFilter: String, CaseIterable, Identifiable {
    case all
    case unread
    case alerts
    case info
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .unread: return "Unread"
        case .alerts: return "Alerts"
        case .info: return "Info"
        }
    }
}

struct NotificationRow: View {
    @Binding var notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Notification icon
            typeIcon
                .foregroundColor(typeColor)
            
            VStack(alignment: .leading, spacing: 6) {
                // Notification message
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fontWeight(notification.isRead ? .regular : .medium)
                
                // Time stamp
                Text(timeAgo(from: notification.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(typeColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                notification.isRead = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var typeIcon: some View {
        switch notification.type {
        case .info:
            return Image(systemName: "info.circle.fill")
        case .success:
            return Image(systemName: "checkmark.circle.fill")
        case .warning:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .error:
            return Image(systemName: "xmark.octagon.fill")
        }
    }
    
    private var typeColor: Color {
        switch notification.type {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
    
    // Format relative time
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) \(hour == 1 ? "hour" : "hours") ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) \(minute == 1 ? "minute" : "minutes") ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Previews
struct NotificationsView_Previews: PreviewProvider {
    static var sampleNotifications: [AppNotification] = [
        AppNotification(message: "New appointment scheduled with Patient #12345", type: .info, date: Date().addingTimeInterval(-360)),
        AppNotification(message: "Lab results for Patient #23456 are ready", type: .success, date: Date().addingTimeInterval(-3600)),
        AppNotification(message: "Urgent: Surgery for Patient #34567 rescheduled", type: .warning, date: Date().addingTimeInterval(-86400)),
        AppNotification(message: "System maintenance scheduled for tonight", type: .info, date: Date().addingTimeInterval(-172800)),
        AppNotification(message: "Failed to sync data with server", type: .error, date: Date().addingTimeInterval(-259200))
    ]
    
    static var previews: some View {
        NotificationsView(notifications: .constant(sampleNotifications))
    }
}