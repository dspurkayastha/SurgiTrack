//
//  RiskCalculatorInputView.swift
//  SurgiTrack
//
//  Updated with a full 12-phys + 6-op POSSUM UI
//

import SwiftUI
import CoreData

struct RiskCalculatorInputView: View {
    let calculator: RiskCalculator
    let patient: Patient?
    
    @State private var parameterValues: [String: Any] = [:]
    @State private var showingResults = false
    @State private var calculationResult: CalculationResult?
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("About This Calculator")) {
                Text(calculator.longDescription)
                    .font(.body)
            }
            
            // If this is a POSSUM calculator, show the specialized UI
            if calculator.calculationType == .possum {
                FullPossumInputSection(parameterValues: $parameterValues)
            }
            else if calculator.calculationType == .caprini {
                // Your custom Caprini UI section
                CapriniInputSection(parameterValues: $parameterValues)
            }
            else {
                // Standard approach for boolean/selection/number
                standardParametersSection
            }
            
            Section {
                modernButton(title: "Calculate Risk", backgroundColor: .blue) {
                    calculate()
                    showingResults = true
                }
            }
            
            if showingResults, let result = calculationResult {
                Section(header: Text("Result")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Score:")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(result.score))")
                                .font(.headline)
                        }
                        HStack {
                            Text("Risk:")
                                .font(.headline)
                            Spacer()
                            Text("\(String(format: "%.1f", result.riskPercentage))%")
                                .font(.headline)
                                .foregroundColor(result.riskPercentage > 5 ? .red : .green)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Interpretation:")
                                .font(.headline)
                            Text(result.interpretation)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        if patient != nil {
                            modernButton(title: "Save to Patient Record", backgroundColor: .green) {
                                saveResult()
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(calculator.name)
        .onAppear {
            // Initialize parameter values for normal calculators
            // (The full POSSUM subview manages its own states)
            for param in calculator.parameters {
                switch param.parameterType {
                case .boolean:
                    parameterValues[param.name] = false
                case .selection:
                    if let opts = param.options, !opts.isEmpty {
                        parameterValues[param.name] = opts[0]
                    }
                case .number:
                    parameterValues[param.name] = 0
                }
            }
        }
    }
    
    // MARK: - Standard Parameter UI
    @ViewBuilder
    private var standardParametersSection: some View {
        Section(header: Text("Risk Factors")) {
            ForEach(calculator.parameters) { parameter in
                switch parameter.parameterType {
                case .boolean:
                    Toggle(parameter.name, isOn: Binding(
                        get: { parameterValues[parameter.name] as? Bool ?? false },
                        set: { parameterValues[parameter.name] = $0 }
                    ))
                    .font(.headline)
                    if !parameter.description.isEmpty {
                        Text(parameter.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                case .selection:
                    if let options = parameter.options {
                        VStack(alignment: .leading) {
                            Text(parameter.name)
                                .font(.headline)
                            if !parameter.description.isEmpty {
                                Text(parameter.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Picker(parameter.name, selection: Binding(
                                get: { parameterValues[parameter.name] as? String ?? options[0] },
                                set: { parameterValues[parameter.name] = $0 }
                            )) {
                                ForEach(options, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                case .number:
                    TextField("\(parameter.name)", value: Binding(
                        get: { parameterValues[parameter.name] as? Double ?? 0 },
                        set: { parameterValues[parameter.name] = $0 }
                    ), formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                }
            }
        }
    }
    
    // MARK: - Calculate & Save
    private func calculate() {
        calculationResult = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameterValues)
    }
    
    private func saveResult() {
        guard let patient = patient, let result = calculationResult else { return }
        let storedResult = StoredCalculation(context: viewContext)
        storedResult.id = UUID()
        storedResult.calculatorName = calculator.name
        storedResult.resultScore = result.score
        storedResult.resultPercentage = result.riskPercentage
        storedResult.resultInterpretation = result.interpretation
        storedResult.calculationDate = Date()
        storedResult.patient = patient
        do {
            try viewContext.save()
        } catch {
            print("Error saving calculation result: \(error)")
        }
    }
    
    // MARK: - Modern Button
    private func modernButton(title: String, backgroundColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(backgroundColor)
                .cornerRadius(12)
                .shadow(color: backgroundColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Full POSSUM Input Section with 12 Physiological + 6 Operative
struct FullPossumInputSection: View {
    @Binding var parameterValues: [String: Any]
    
    // 12 PHYSIOLOGICAL items
    @State private var physAge: Int = 1
    @State private var physCardiac: Int = 1
    @State private var physSystolicBP: Int = 1
    @State private var physPulse: Int = 1
    @State private var physHemoglobin: Int = 1
    @State private var physWCC: Int = 1
    @State private var physUrea: Int = 1
    @State private var physNa: Int = 1
    @State private var physK: Int = 1
    @State private var physECG: Int = 1
    @State private var physResp: Int = 1
    @State private var physGCS: Int = 1
    
    // 6 OPERATIVE items
    @State private var opMagnitude: Int = 1
    @State private var opNumberProcedures: Int = 1
    @State private var opBloodLoss: Int = 1
    @State private var opSoiling: Int = 1
    @State private var opMalignancy: Int = 1
    @State private var opTiming: Int = 1
    
    var body: some View {
        Section(header: Text("POSSUM: Physiological Variables")) {
            // 1. Age
            possumPicker(
                title: "Age",
                selection: $physAge,
                segments: [
                    ("<60", 1), ("61-70", 2), ("71-80", 4), (">80", 8)
                ]
            )
            // 2. Cardiac
            possumPicker(
                title: "Cardiac Signs",
                selection: $physCardiac,
                segments: [
                    ("Normal", 1),
                    ("AF <100 / Mild", 2),
                    ("Cardiac >100 or severe", 4),
                    ("JVP >6 cm", 8)
                ]
            )
            // 3. Systolic BP
            possumPicker(
                title: "Systolic BP",
                selection: $physSystolicBP,
                segments: [
                    (">100 mmHg", 1),
                    ("80-100", 2),
                    ("70-79", 4),
                    ("<70", 8)
                ]
            )
            // 4. Pulse
            possumPicker(
                title: "Pulse",
                selection: $physPulse,
                segments: [
                    ("<80", 1),
                    ("80-100", 2),
                    ("101-120", 4),
                    (">120", 8)
                ]
            )
            // 5. Hemoglobin
            possumPicker(
                title: "Hemoglobin (g/dL)",
                selection: $physHemoglobin,
                segments: [
                    (">13", 1),
                    ("11-13", 2),
                    ("9-10.9", 4),
                    ("<9", 8)
                ]
            )
            // 6. WCC
            possumPicker(
                title: "WCC (x10^9/L)",
                selection: $physWCC,
                segments: [
                    ("4-10", 1),
                    ("10-20", 2),
                    (">20", 4),
                    ("<4", 8)
                ]
            )
            // 7. Urea
            possumPicker(
                title: "Urea (mmol/L)",
                selection: $physUrea,
                segments: [
                    ("<7.5", 1),
                    ("7.5-10", 2),
                    ("10.1-15", 4),
                    (">15", 8)
                ]
            )
            // 8. Sodium
            possumPicker(
                title: "Sodium (mmol/L)",
                selection: $physNa,
                segments: [
                    ("135-145", 1),
                    ("131-134 or 146-149", 2),
                    ("126-130 or 150-154", 4),
                    ("<125 or >155", 8)
                ]
            )
            // 9. Potassium
            possumPicker(
                title: "Potassium (mmol/L)",
                selection: $physK,
                segments: [
                    ("3.5-5.0", 1),
                    ("3.2-3.4 or 5.1-5.3", 2),
                    ("2.9-3.1 or 5.4-5.9", 4),
                    ("<2.9 or >6.0", 8)
                ]
            )
            // 10. ECG
            possumPicker(
                title: "ECG",
                selection: $physECG,
                segments: [
                    ("Normal", 1),
                    ("AF <100", 2),
                    ("AF >100", 4),
                    ("Other changes", 8)
                ]
            )
            // 11. Respiratory
            possumPicker(
                title: "Respiratory",
                selection: $physResp,
                segments: [
                    ("Normal", 1),
                    ("SOB mod exertion", 2),
                    ("SOB minimal exertion", 4),
                    ("SOB at rest", 8)
                ]
            )
            // 12. GCS
            possumPicker(
                title: "Glasgow Coma Scale",
                selection: $physGCS,
                segments: [
                    ("15", 1),
                    ("12-14", 2),
                    ("9-11", 4),
                    ("<9", 8)
                ]
            )
        }
        Section(header: Text("POSSUM: Operative Severity")) {
            // 1. Operative Magnitude
            possumPicker(
                title: "Operative Magnitude",
                selection: $opMagnitude,
                segments: [
                    ("Minor", 1),
                    ("Intermediate", 2),
                    ("Major", 4),
                    ("Major+", 8)
                ]
            )
            // 2. Number of Procedures
            possumPicker(
                title: "No. of Procedures",
                selection: $opNumberProcedures,
                segments: [
                    ("1", 1),
                    ("2", 2),
                    ("3", 4),
                    (">3", 8)
                ]
            )
            // 3. Blood Loss
            possumPicker(
                title: "Blood Loss (mL)",
                selection: $opBloodLoss,
                segments: [
                    ("<100", 1),
                    ("100-500", 2),
                    ("501-999", 4),
                    (">1000", 8)
                ]
            )
            // 4. Peritoneal Soiling
            possumPicker(
                title: "Peritoneal Soiling",
                selection: $opSoiling,
                segments: [
                    ("None", 1),
                    ("Minor (serous)", 2),
                    ("Local pus", 4),
                    ("Free bowel content", 8)
                ]
            )
            // 5. Presence of Malignancy
            possumPicker(
                title: "Malignancy",
                selection: $opMalignancy,
                segments: [
                    ("None", 1),
                    ("Primary only", 2),
                    ("Nodal metastases", 4),
                    ("Distant mets", 8)
                ]
            )
            // 6. Timing of Operation
            possumPicker(
                title: "Timing of Operation",
                selection: $opTiming,
                segments: [
                    ("Elective", 1),
                    ("Emergency (resusc)", 2),
                    ("Urgent", 4),
                    ("Immediate", 8)
                ]
            )
        }
        .onChange(of: physAge)            { _ in updateScores() }
        .onChange(of: physCardiac)        { _ in updateScores() }
        .onChange(of: physSystolicBP)     { _ in updateScores() }
        .onChange(of: physPulse)          { _ in updateScores() }
        .onChange(of: physHemoglobin)     { _ in updateScores() }
        .onChange(of: physWCC)            { _ in updateScores() }
        .onChange(of: physUrea)           { _ in updateScores() }
        .onChange(of: physNa)             { _ in updateScores() }
        .onChange(of: physK)              { _ in updateScores() }
        .onChange(of: physECG)            { _ in updateScores() }
        .onChange(of: physResp)           { _ in updateScores() }
        .onChange(of: physGCS)            { _ in updateScores() }
        
        .onChange(of: opMagnitude)        { _ in updateScores() }
        .onChange(of: opNumberProcedures) { _ in updateScores() }
        .onChange(of: opBloodLoss)        { _ in updateScores() }
        .onChange(of: opSoiling)          { _ in updateScores() }
        .onChange(of: opMalignancy)       { _ in updateScores() }
        .onChange(of: opTiming)           { _ in updateScores() }
        
        .onAppear {
            updateScores()
        }
    }
    
    private func updateScores() {
        let physTotal = physAge + physCardiac + physSystolicBP + physPulse +
                        physHemoglobin + physWCC + physUrea + physNa +
                        physK + physECG + physResp + physGCS
        
        let opTotal   = opMagnitude + opNumberProcedures + opBloodLoss +
                        opSoiling + opMalignancy + opTiming
        
        parameterValues["Physiological Score"] = Double(physTotal)
        parameterValues["Operative Severity Score"] = Double(opTotal)
    }
    
    // A helper for building segmented pickers
    @ViewBuilder
    private func possumPicker(
        title: String,
        selection: Binding<Int>,
        segments: [(String, Int)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Picker(title, selection: selection) {
                ForEach(segments, id: \.1) { seg in
                    Text(seg.0).tag(seg.1)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.vertical, 4)
    }
}

/// A fully expanded input section for the Caprini Score using segmented controls for mutually exclusive items.
struct CapriniInputSection: View {
    @Binding var parameterValues: [String: Any]
    
    // MARK: - Enumerations for mutually exclusive groups
    
    enum AgeOption: String, CaseIterable, Identifiable {
        case le40 = "≤40"
        case r41to60 = "41-60"
        case r61to74 = "61-74"
        case ge75 = "≥75"
        
        var id: Self { self }
        var points: Int {
            switch self {
            case .le40: return 0
            case .r41to60: return 1
            case .r61to74: return 2
            case .ge75: return 3
            }
        }
    }
    
    enum SurgeryType: String, CaseIterable, Identifiable {
        case minor = "Minor (<45 min)"
        case major = "Major (>45 min)"
        case arthroplasty = "Elective Lower Extremity Arthroplasty"
        
        var id: Self { self }
        var points: Int {
            switch self {
            case .minor: return 0
            case .major: return 1
            case .arthroplasty: return 5
            }
        }
    }
    
    enum RecentEvent: String, CaseIterable, Identifiable {
        case none = "None"
        case majorEvent = "Major event"  // e.g. major surgery, CHF, sepsis, pneumonia, pregnancy/postpartum
        
        var id: Self { self }
        var points: Int {
            switch self {
            case .none: return 0
            case .majorEvent: return 1
            }
        }
    }
    
    enum ImmobilizingCast: String, CaseIterable, Identifiable {
        case no = "No"
        case yes = "Yes"
        
        var id: Self { self }
        var points: Int {
            switch self {
            case .no: return 0
            case .yes: return 1
            }
        }
    }
    
    enum FractureStrokeTrauma: String, CaseIterable, Identifiable {
        case none = "None"
        case present = "Present"
        
        var id: Self { self }
        var points: Int {
            switch self {
            case .none: return 0
            case .present: return 2
            }
        }
    }
    
    enum CentralVenousAccess: String, CaseIterable, Identifiable {
        case no = "No"
        case yes = "Yes"
        
        var id: Self { self }
        var points: Int {
            switch self {
            case .no: return 0
            case .yes: return 1
            }
        }
    }
    
    enum HistoryDVT: String, CaseIterable, Identifiable {
        case no = "No"
        case yes = "Yes"
        
        var id: Self { self }
        var points: Int {
            switch self {
            case .no: return 0
            case .yes: return 3
            }
        }
    }
    
    enum Mobility: String, CaseIterable, Identifiable {
        case normal = "Normal (Ambulatory)"
        case bedRest = "Bed rest"
        case confined = "Confined >72 hrs"
        
        var id: Self { self }
        var points: Int {
            switch self {
            case .normal: return 0
            case .bedRest: return 1
            case .confined: return 2
            }
        }
    }
    
    enum OtherHistory: String, CaseIterable, Identifiable {
        case none = "None"
        case riskFactors = "Systemic risk factors (IBD, BMI >25, MI, COPD, OCP/HRT, etc.)"
        case malignancy = "History of malignancy"
        
        var id: Self { self }
        var points: Int {
            switch self {
            case .none: return 0
            case .riskFactors: return 1
            case .malignancy: return 2
            }
        }
    }
    
    // MARK: - Independent binary factors as simple toggles
    @State private var smoking: Bool = false
    @State private var diabetesInsulin: Bool = false
    @State private var chemotherapy: Bool = false
    @State private var superficialThrombosis: Bool = false
    
    var body: some View {
        Form {
            // Age Section
            Section(header: Text("Age")) {
                Picker("Age", selection: Binding(
                    get: { parameterValues["Age"] as? AgeOption ?? .le40 },
                    set: { newValue in
                        parameterValues["Age"] = newValue
                    }
                )) {
                    ForEach(AgeOption.allCases) { option in
                        Text("\(option.rawValue) (+\(option.points))").tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Surgery Type Section
            Section(header: Text("Type of Surgery")) {
                Picker("Surgery Type", selection: Binding(
                    get: { parameterValues["Surgery Type"] as? SurgeryType ?? .minor },
                    set: { newValue in
                        parameterValues["Surgery Type"] = newValue
                    }
                )) {
                    ForEach(SurgeryType.allCases) { option in
                        Text("\(option.rawValue) (+\(option.points))").tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Recent Event Section
            Section(header: Text("Recent Event (<1 month)")) {
                Picker("Recent Event", selection: Binding(
                    get: { parameterValues["Recent Event"] as? RecentEvent ?? Optional.none },
                    set: { newValue in
                        parameterValues["Recent Event"] = newValue
                    }
                )) {
                    ForEach(RecentEvent.allCases) { option in
                        Text("\(option.rawValue) (+\(option.points))").tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Immobilizing Cast Section
            Section(header: Text("Immobilizing Cast")) {
                Picker("Plaster Cast", selection: Binding(
                    get: { parameterValues["Immobilizing Cast"] as? ImmobilizingCast ?? .no },
                    set: { newValue in
                        parameterValues["Immobilizing Cast"] = newValue
                    }
                )) {
                    ForEach(ImmobilizingCast.allCases) { option in
                        Text("\(option.rawValue) (+\(option.points))").tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Fracture/Stroke/Trauma Section
            Section(header: Text("Fracture/Stroke/Trauma")) {
                Picker("Fracture/Stroke/Trauma", selection: Binding(
                    get: { parameterValues["Fracture/Stroke/Trauma"] as? FractureStrokeTrauma ?? .none },
                    set: { newValue in
                        parameterValues["Fracture/Stroke/Trauma"] = newValue
                    }
                )) {
                    ForEach(FractureStrokeTrauma.allCases) { option in
                        Text("\(option.rawValue) (+\(option.points))").tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Central Venous Access Section
            Section(header: Text("Central Venous Access")) {
                Picker("Central Venous Access", selection: Binding(
                    get: { parameterValues["Central Venous Access"] as? CentralVenousAccess ?? .no },
                    set: { newValue in
                        parameterValues["Central Venous Access"] = newValue
                    }
                )) {
                    ForEach(CentralVenousAccess.allCases) { option in
                        Text("\(option.rawValue) (+\(option.points))").tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // History of DVT/PE Section
            Section(header: Text("History of DVT/PE")) {
                Picker("History of DVT/PE", selection: Binding(
                    get: { parameterValues["History of DVT/PE"] as? HistoryDVT ?? .no },
                    set: { newValue in
                        parameterValues["History of DVT/PE"] = newValue
                    }
                )) {
                    ForEach(HistoryDVT.allCases) { option in
                        Text("\(option.rawValue) (+\(option.points))").tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Mobility Section
            Section(header: Text("Mobility")) {
                Picker("Mobility", selection: Binding(
                    get: { parameterValues["Mobility"] as? Mobility ?? .normal },
                    set: { newValue in
                        parameterValues["Mobility"] = newValue
                    }
                )) {
                    ForEach(Mobility.allCases) { option in
                        Text("\(option.rawValue) (+\(option.points))").tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Other Past History Section
            Section(header: Text("Other Past History")) {
                Picker("Other History", selection: Binding(
                    get: { parameterValues["Other History"] as? OtherHistory ?? .none },
                    set: { newValue in
                        parameterValues["Other History"] = newValue
                    }
                )) {
                    ForEach(OtherHistory.allCases) { option in
                        Text("\(option.rawValue) (+\(option.points))").tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Additional independent factors as toggles (these remain binary)
            Section(header: Text("Additional Factors")) {
                Toggle("Smoking (+1)", isOn: $smoking)
                    .onChange(of: smoking) { newVal in
                        parameterValues["Smoking"] = newVal ? 1 : 0
                    }
                Toggle("Diabetes (requiring insulin) (+1)", isOn: $diabetesInsulin)
                    .onChange(of: diabetesInsulin) { newVal in
                        parameterValues["Diabetes"] = newVal ? 1 : 0
                    }
                Toggle("Chemotherapy (+1)", isOn: $chemotherapy)
                    .onChange(of: chemotherapy) { newVal in
                        parameterValues["Chemotherapy"] = newVal ? 1 : 0
                    }
                Toggle("Superficial Venous Thrombosis (+1)", isOn: $superficialThrombosis)
                    .onChange(of: superficialThrombosis) { newVal in
                        parameterValues["Superficial Thrombosis"] = newVal ? 1 : 0
                    }
            }
        }
    }
}
