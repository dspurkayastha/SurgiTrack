//
//  OperativeDataSegment.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 11/03/25.
//


// OperativeDataSegment.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData

struct OperativeDataSegment: View {
    @ObservedObject var patient: Patient
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddOperativeData = false
    @Binding var editMode: Bool
    
    private var operativeArray: [OperativeData] {
        (patient.operativeData as? Set<OperativeData>)?.sorted {
            ($0.operationDate ?? Date()) > ($1.operationDate ?? Date())
        } ?? []
    }
    
    var body: some View {
        Group {
            if operativeArray.isEmpty {
                EmptyStateView(
                    title: "No Surgical Procedures",
                    message: "Add operative data when the patient undergoes a procedure",
                    iconName: "scalpel",
                    color: DetailSegment.operative.color,
                    actionButton: addButton as! AnyView
                )
            } else {
                VStack(spacing: 16) {
                    // Surgery count and add button
                    HStack {
                        Text("\(operativeArray.count) Surgical Procedure\(operativeArray.count == 1 ? "" : "s")")
                            .font(.headline)
                            .foregroundColor(DetailSegment.operative.color)
                        
                        Spacer()
                        
                        if editMode {
                            Button(action: {
                                showingAddOperativeData = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add")
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(DetailSegment.operative.color.opacity(0.2))
                                .foregroundColor(DetailSegment.operative.color)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    Divider()
                    
                    // List of procedures
                    LazyVStack(spacing: 16) {
                        ForEach(operativeArray, id: \.objectID) { opData in
                            NavigationLink(destination: OperativeDataDetailView(operativeData: opData)) {
                                OperativeCard(operativeData: opData)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingAddOperativeData) {
            AddOperativeDataView(patient: patient)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            showingAddOperativeData = true
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Surgical Procedure")
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(DetailSegment.operative.color)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OperativeDataSegment_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.firstName = "John"
        patient.lastName = "Doe"
        
        return OperativeDataSegment(patient: patient, editMode: .constant(true))
            .environment(\.managedObjectContext, context)
    }
}
