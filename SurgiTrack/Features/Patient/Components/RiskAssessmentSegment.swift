//
//  RiskAssessmentSegment.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 11/03/25.
//


// RiskAssessmentSegment.swift
// SurgiTrack
// Created on March 11, 2025

import SwiftUI
import CoreData

struct RiskAssessmentSegment: View {
    @ObservedObject var patient: Patient
    @ObservedObject var viewModel: PatientDetailViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var editMode: Bool
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            let storedCalculations = viewModel.fetchRiskCalculations()
            
            if storedCalculations.isEmpty {
                emptyRiskAssessmentView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Recent calculations section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Assessments")
                                .font(.headline)
                                .foregroundColor(DetailSegment.riskAssessment.color)
                                .padding(.horizontal)
                            
                            ForEach(storedCalculations.prefix(3), id: \.objectID) { calculation in
                                NavigationLink(destination: CalculationDetailView(calculation: calculation)) {
                                    calculationCard(calculation: calculation)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if storedCalculations.count > 3 {
                                NavigationLink(destination: CalculationHistoryView(patient: patient)) {
                                    Text("View All Assessments")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        // Available calculators section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Risk Calculators")
                                .font(.headline)
                                .foregroundColor(DetailSegment.riskAssessment.color)
                                .padding(.horizontal)
                            
                            // Common calculators grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                calculatorButton(
                                    title: "ASA Classification",
                                    iconName: "cross.circle",
                                    color: .green,
                                    destination: AnyView(RiskCalculatorInputView(calculator: RiskCalculatorStore.shared.createASACalculator(), patient: patient))
                                )
                                
                                calculatorButton(
                                    title: "RCRI",
                                    iconName: "heart.fill",
                                    color: .red,
                                    destination: AnyView(RiskCalculatorInputView(calculator: RiskCalculatorStore.shared.calculators.first(where: { $0.calculationType == .rcri }) ?? RiskCalculatorStore.shared.createRCRICalculator(), patient: patient))
                                )
                                
                                calculatorButton(
                                    title: "Surgical Apgar",
                                    iconName: "waveform.path.ecg",
                                    color: .blue,
                                    destination: AnyView(RiskCalculatorInputView(calculator: RiskCalculatorStore.shared.calculators.first(where: { $0.calculationType == .apgarScore }) ?? RiskCalculatorStore.shared.createSurgicalApgarCalculator(), patient: patient))
                                )
                                
                                calculatorButton(
                                    title: "All Calculators",
                                    iconName: "list.bullet",
                                    color: .gray,
                                    destination: AnyView(RiskCalculatorListView(patient: patient))
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(.top)
    }
    
    // EmptyState view for risk assessment
    private var emptyRiskAssessmentView: some View {
        EmptyStateView(
            title: "No Risk Assessments",
            message: "Perform risk calculations to help with clinical decision-making",
            iconName: "function",
            color: DetailSegment.riskAssessment.color,
            actionButton: AnyView(
                NavigationLink(destination: RiskCalculatorListView(patient: patient)) {
                    Text("Perform Risk Assessment")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(DetailSegment.riskAssessment.color)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            )
        )
    }
    
    // Card view for a calculation result
    private func calculationCard(calculation: StoredCalculation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(calculation.calculatorName ?? "Risk Assessment")
                    .font(.headline)
                
                Spacer()
                
                if let date = calculation.calculationDate {
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 20) {
                let riskLevel = calculation.riskLevel
                let riskColor = calculation.riskColor
                
                if calculation.resultScore > 0 {
                    VStack(alignment: .leading) {
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.0f", calculation.resultScore))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Risk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", calculation.resultPercentage))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(riskColor)
                }
                
                Text(riskLevel.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(riskColor.opacity(0.2))
                    .foregroundColor(riskColor)
                    .cornerRadius(4)
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
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // Button for launching calculators
    private func calculatorButton<Destination: View>(title: String, iconName: String, color: Color, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct RiskAssessmentSegment_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.firstName = "John"
        patient.lastName = "Doe"
        
        return RiskAssessmentSegment(
            patient: patient,
            viewModel: PatientDetailViewModel(patient: patient, context: context),
            editMode: .constant(true)
        )
        .environment(\.managedObjectContext, context)
    }
}
