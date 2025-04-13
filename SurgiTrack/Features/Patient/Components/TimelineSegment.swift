//
//  TimelineSegment.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 11/03/25.
//


// TimelineSegment.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData

struct TimelineSegment: View {
    @ObservedObject var viewModel: TimelineViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    init(patient: Patient) {
        let vm = TimelineViewModel()
        _viewModel = ObservedObject(wrappedValue: vm)
        vm.loadEvents(from: patient)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.events.isEmpty {
                EmptyStateView(
                    title: "No Timeline Data",
                    message: "This patient has no recorded events to display on the timeline.",
                    iconName: "clock",
                    color: DetailSegment.timeline.color
                )
            } else {
                // Timeline filter buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TimelineFilterButton(
                            title: "All",
                            icon: "circle.grid.cross",
                            color: .blue,
                            isSelected: viewModel.selectedFilter == nil,
                            action: { viewModel.filterEvents(by: nil) }
                        )
                        
                        ForEach(TimelineEvent.EventType.allCases, id: \.self) { type in
                            TimelineFilterButton(
                                title: type.displayName,
                                icon: type.iconName,
                                color: eventColor(for: type),
                                isSelected: viewModel.selectedFilter == type,
                                action: { viewModel.filterEvents(by: type) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.bottom, 8)
                
                // Timeline events
                timelineEventsView
            }
        }
    }
    
    private var timelineEventsView: some View {
        VStack(spacing: 0) {
            if viewModel.filteredEvents.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(DetailSegment.timeline.color.opacity(0.6))
                    
                    Text("No events match the current filter")
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text("Try selecting a different filter")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                )
            } else {
                ForEach(Array(viewModel.filteredEvents.enumerated()), id: \.element.id) { index, event in
                    VStack(spacing: 0) {
                        TimelineEventCard(
                            event: event,
                            isConnected: index < viewModel.filteredEvents.count - 1
                        )
                        .onTapGesture {
                            navigateToDetail(for: event)
                        }
                        
                        if index < viewModel.filteredEvents.count - 1 {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 2, height: 20)
                                .padding(.leading, 19) // Align with circle center
                        }
                    }
                }
            }
        }
    }
    
    private func eventColor(for type: TimelineEvent.EventType) -> Color {
        switch type {
        case .initial:
            return .blue
        case .surgery:
            return .orange
        case .followUp:
            return .green
        case .test:
            return .red
        case .appointment:
            return .purple
        case .discharge:
            return .gray
        }
    }
    
    private func navigateToDetail(for event: TimelineEvent) {
        guard let objectID = event.objectID else { return }
        
        // In a real implementation, this would navigate to the appropriate detail view
        // based on the event type and object ID
        print("Navigate to detail for \(event.type.rawValue) with ID: \(objectID)")
        
        // Example of how this might work:
        /*
        switch event.type {
        case .surgery:
            if let operativeData = viewContext.object(with: objectID) as? OperativeData {
                // Navigate to OperativeDataDetailView
            }
        case .followUp:
            if let followUp = viewContext.object(with: objectID) as? FollowUp {
                // Navigate to FollowUpDetailView
            }
        // ... and so on for other types
        }
        */
    }
}

// MARK: - Preview Provider

struct TimelineSegment_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.firstName = "John"
        patient.lastName = "Doe"
        
        return TimelineSegment(patient: patient)
            .environment(\.managedObjectContext, context)
    }
}