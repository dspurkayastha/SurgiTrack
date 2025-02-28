//
//  CalculationDetailView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 02/03/25.
//


import SwiftUI
import CoreData

struct CalculationDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var calculation: StoredCalculation
    @State private var showingDeleteConfirmation = false
    @State private var notes = ""
    @State private var isEditingNotes = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Result
                resultView
                
                // Notes
                notesView
                
                // Related Data (if any)
                if let operativeData = calculation.operativeData {
                    relatedDataView(title: "Related Procedure", subtitle: operativeData.procedureName ?? "Unnamed Procedure", date: operativeData.operationDate, iconName: "scalpel", color: .orange)
                }
                
                if let followUp = calculation.followUp {
                    relatedDataView(title: "Related Follow-up", subtitle: "Post-operative assessment", date: followUp.followUpDate, iconName: "calendar.badge.clock", color: .green)
                }
                
                // Delete button
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Calculation")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Risk Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Calculation"),
                message: Text("Are you sure you want to delete this risk calculation? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteCalculation()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $isEditingNotes) {
            NavigationView {
                VStack {
                    TextEditor(text: $notes)
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Edit Notes")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        isEditingNotes = false
                    },
                    trailing: Button("Save") {
                        calculation.notes = notes
                        try? viewContext.save()
                        isEditingNotes = false
                    }
                )
            }
        }
        .onAppear {
            notes = calculation.notes ?? ""
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text(calculation.calculatorName ?? "Risk Assessment")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            if let date = calculation.calculationDate {
                Text(dateFormatter.string(from: date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let patient = calculation.patient {
                NavigationLink(destination: AccordionPatientDetailView(patient: patient)) {
                    Text("Patient: \(patient.fullName)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var resultView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Assessment Result")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                // Risk Score
                VStack {
                    Text("Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.0f", calculation.resultScore))
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                
                // Risk Percentage
                VStack {
                    Text("Risk")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", calculation.resultPercentage))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(calculation.riskColor)
                }
                .frame(maxWidth: .infinity)
                
                // Risk Level
                VStack {
                    Text("Level")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(calculation.riskLevel.rawValue)
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(calculation.riskColor.opacity(0.2))
                        .foregroundColor(calculation.riskColor)
                        .cornerRadius(5)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            
            // Risk visualization
            riskGaugeView
            
            // Interpretation
            if let interpretation = calculation.resultInterpretation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Interpretation")
                        .font(.headline)
                    
                    Text(interpretation)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var riskGaugeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Risk Level")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Custom gauge visualization
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                
                // Filled portion
                let fillWidth = min(1.0, max(0.0, calculation.resultPercentage / 100.0))
                RoundedRectangle(cornerRadius: 6)
                    .fill(calculation.riskColor)
                    .frame(width: fillWidth * UIScreen.main.bounds.width * 0.8, height: 12)
            }
            
            // Risk labels
            HStack {
                Text("Low")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("Moderate")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Spacer()
                
                Text("High")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var notesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    isEditingNotes = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.blue)
                }
            }
            
            if let notes = calculation.notes, !notes.isEmpty {
                Text(notes)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Button(action: {
                    isEditingNotes = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Notes")
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
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
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func relatedDataView(title: String, subtitle: String, date: Date?, iconName: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Data")
                .font(.headline)
            
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let date = date {
                        Text(dateFormatter.string(from: date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func deleteCalculation() {
        viewContext.delete(calculation)
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error deleting calculation: \(error)")
        }
    }
}
