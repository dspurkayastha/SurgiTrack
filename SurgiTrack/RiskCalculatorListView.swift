//
//  RiskCalculatorListView.swift
//  SurgiTrack
//
//  Updated for production-level UI with consistent modern style
//

import SwiftUI
import CoreData

struct RiskCalculatorListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    var patient: Patient?
    @State private var searchText = ""
    
    private let calculators = RiskCalculatorStore.shared.calculators
    
    var filteredCalculators: [RiskCalculator] {
        if searchText.isEmpty {
            return calculators
        } else {
            return calculators.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.shortDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search calculators", text: $searchText)
                    .disableAutocorrection(true)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.secondarySystemBackground)))
            .padding(.horizontal)
            .padding(.top, 10)
            
            if filteredCalculators.isEmpty {
                emptyStateView
            } else {
                calculatorsList
            }
        }
        .navigationTitle("Risk Calculators")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "function")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            Text("No Calculators Found")
                .font(.title2)
                .fontWeight(.medium)
            Text("Try changing your search criteria")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var calculatorsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredCalculators) { calculator in
                    NavigationLink(destination: RiskCalculatorInputView(calculator: calculator, patient: patient)) {
                        calculatorCard(calculator: calculator)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    private func calculatorCard(calculator: RiskCalculator) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForCalculator(calculator))
                    .font(.title2)
                    .foregroundColor(colorForCalculator(calculator))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(colorForCalculator(calculator).opacity(0.2)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(calculator.name)
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            Text(calculator.shortDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            if !calculator.parameters.isEmpty {
                HStack {
                    Text("Parameters:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(calculator.parameters.prefix(3), id: \.id) { parameter in
                        Text(parameter.name.components(separatedBy: " ").first ?? "")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    if calculator.parameters.count > 3 {
                        Text("+\(calculator.parameters.count - 3)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white))
        .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func iconForCalculator(_ calculator: RiskCalculator) -> String {
        switch calculator.calculationType {
        case .rcri:
            return "heart.fill"
        case .apgarScore:
            return "waveform.path.ecg"
        case .possum:
            return "staroflife"
        case .meld:
            return "liver.fill"
        case .childPugh:
            return "stomach.fill"
        case .asa:
            return "cross.fill"
        default:
            return "function"
        }
    }
    
    private func colorForCalculator(_ calculator: RiskCalculator) -> Color {
        switch calculator.calculationType {
        case .rcri:
            return .red
        case .apgarScore:
            return .blue
        case .possum:
            return .purple
        case .meld:
            return .orange
        case .childPugh:
            return .yellow
        case .asa:
            return .green
        default:
            return .gray
        }
    }
}

struct RiskCalculatorListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.firstName = "Jane"
        patient.lastName = "Doe"
        return NavigationView {
            RiskCalculatorListView(patient: patient)
                .environment(\.managedObjectContext, context)
        }
    }
}

