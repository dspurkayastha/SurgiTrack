//
//  CalculationHistoryView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 12/03/25.
//


//
//  CalculationHistoryView.swift
//  SurgiTrack
//
//  Created by [Your Name] on [Date]
//

import SwiftUI
import CoreData

struct CalculationHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var patient: Patient
    
    @FetchRequest var calculationHistory: FetchedResults<StoredCalculation>
    
    init(patient: Patient) {
        self.patient = patient
        _calculationHistory = FetchRequest(
            entity: StoredCalculation.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \StoredCalculation.calculationDate, ascending: false)],
            predicate: NSPredicate(format: "patient == %@", patient)
        )
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        List {
            ForEach(calculationHistory, id: \.self) { calculation in
                NavigationLink(destination: CalculationDetailView(calculation: calculation)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(calculation.calculatorName ?? "Risk Assessment")
                            .font(.headline)
                        if let date = calculation.calculationDate {
                            Text(dateFormatter.string(from: date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteCalculations)
        }
        .navigationTitle("Calculation History")
        .navigationBarItems(trailing: EditButton())
    }
    
    private func deleteCalculations(at offsets: IndexSet) {
        withAnimation {
            offsets.map { calculationHistory[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting calculations: \(error)")
            }
        }
    }
}
