//
//  RiskCalculatorSelectorView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


//
//  RiskCalculatorSelectorView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 11/03/25.
//

import SwiftUI
import CoreData

struct RiskCalculatorSelectorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    let operativeData: OperativeData
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        List {
            Section(header: Text("Preoperative Risk Assessment")) {
                NavigationLink(destination: RiskCalculatorInputView(
                    calculator: RiskCalculatorStore.shared.createASACalculator(),
                    patient: operativeData.patient
                )) {
                    riskCalculatorRow(
                        title: "ASA Physical Status",
                        description: "Anesthesia risk classification",
                        iconName: "cross.circle",
                        color: .green
                    )
                }
                
                NavigationLink(destination: RiskCalculatorInputView(
                    calculator: RiskCalculatorStore.shared.calculators.first(where: { $0.calculationType == .rcri }) ?? RiskCalculatorStore.shared.createRCRICalculator(),
                    patient: operativeData.patient
                )) {
                    riskCalculatorRow(
                        title: "Revised Cardiac Risk Index",
                        description: "Cardiac risk for non-cardiac surgery",
                        iconName: "heart.fill",
                        color: .red
                    )
                }
            }
            
            Section(header: Text("Intraoperative Risk Assessment")) {
                NavigationLink(destination: RiskCalculatorInputView(
                    calculator: RiskCalculatorStore.shared.calculators.first(where: { $0.calculationType == .apgarScore }) ?? RiskCalculatorStore.shared.createSurgicalApgarCalculator(),
                    patient: operativeData.patient
                )) {
                    riskCalculatorRow(
                        title: "Surgical Apgar Score",
                        description: "Predicts postoperative complications",
                        iconName: "waveform.path.ecg",
                        color: .blue
                    )
                }
            }
            
            Section(header: Text("Specialized Risk Assessment")) {
                NavigationLink(destination: RiskCalculatorInputView(
                    calculator: RiskCalculatorStore.shared.calculators.first(where: { $0.calculationType == .possum }) ?? RiskCalculatorStore.shared.calculators[1],
                    patient: operativeData.patient
                )) {
                    riskCalculatorRow(
                        title: "POSSUM Score",
                        description: "Physiological and Operative Severity Score",
                        iconName: "staroflife",
                        color: .purple
                    )
                }
                
                NavigationLink(destination: RiskCalculatorListView(patient: operativeData.patient)) {
                    riskCalculatorRow(
                        title: "View All Calculators",
                        description: "Access all available risk calculators",
                        iconName: "list.bullet",
                        color: .gray
                    )
                }
            }
            
            // Existing assessments section (if any)
            let existingCalculations = fetchCalculations()
            if !existingCalculations.isEmpty {
                Section(header: Text("Existing Assessments")) {
                    ForEach(existingCalculations, id: \.objectID) { calculation in
                        NavigationLink(destination: CalculationDetailView(calculation: calculation)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(calculation.calculatorName ?? "Risk Assessment")
                                        .font(.headline)
                                    if let date = calculation.calculationDate {
                                        Text(dateFormatter.string(from: date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text(String(format: "%.1f%%", calculation.resultPercentage))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(calculation.riskColor)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Risk Calculators")
        .navigationBarItems(trailing: Button("Close") {
            presentationMode.wrappedValue.dismiss()
        })
    }
    
    private func riskCalculatorRow(title: String, description: String, iconName: String, color: Color) -> some View {
        HStack(spacing: 15) {
            Image(systemName: iconName)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func fetchCalculations() -> [StoredCalculation] {
        let request: NSFetchRequest<StoredCalculation> = StoredCalculation.fetchRequest()
        request.predicate = NSPredicate(format: "operativeData == %@", operativeData)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredCalculation.calculationDate, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching calculations: \(error)")
            return []
        }
    }
}
