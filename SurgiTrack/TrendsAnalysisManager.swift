//
//  TrendsAnalysisManager.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 13/03/25.
//

import SwiftUI
import Charts
import CoreData
import Combine

// MARK: - Supporting Models

enum AnalysisTimeRange: String, CaseIterable, Identifiable, Hashable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"
    
    var id: String { self.rawValue }
    var days: Int {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .all: return 3650  // ~10 years
        }
    }
    var displayText: String { self.rawValue }  // Added for Picker display
}

enum AnalysisLevel: String, CaseIterable, Identifiable, Hashable {
    case individual = "Individual"
    case cohort = "Cohort"
    case organization = "Organization"
    
    var id: String { self.rawValue }
}

struct ParameterDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let isAbnormal: Bool
    let testID: NSManagedObjectID
    let testName: String
    let patientID: NSManagedObjectID?
    let referenceRange: ReferenceRange?
}

struct ReferenceRange {
    let low: Double
    let high: Double
    let unit: String
}

struct StatisticalSummary {
    let min: Double
    let max: Double
    let mean: Double
    let median: Double
    let standardDeviation: Double
    let percentChange: Double
    let trend: TrendDirection
    
    enum TrendDirection: String {
        case increasing = "Increasing"
        case decreasing = "Decreasing"
        case stable = "Stable"
        case unknown = "Unknown"
        
        var color: Color {
            switch self {
            case .increasing: return .red
            case .decreasing: return .blue
            case .stable: return .green
            case .unknown: return .gray
            }
        }
    }
}

// MARK: - Trends Analysis ViewModel

class TrendsAnalysisViewModel: ObservableObject {
    // Published properties for UI state
    @Published var selectedLevel: AnalysisLevel = .individual
    @Published var selectedTimeRange: AnalysisTimeRange = .threeMonths
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Individual analysis data
    @Published var selectedPatient: Patient?
    @Published var selectedParameter: String?
    @Published var parameterData: [ParameterDataPoint] = []
    @Published var statisticalSummary: StatisticalSummary?
    
    // For parameter selection UI – available parameters for the patient
    @Published var organizationParameters: [String] = []
    
    // Placeholders for cohort and organization analysis
    @Published var cohortData: [String: [ParameterDataPoint]] = [:]
    @Published var organizationData: [String: [ParameterDataPoint]] = [:]
    
    // Reference to Core Data context
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // MARK: - Async Data Loading Methods
    
    func loadAvailableParameters() async {
        guard let patient = selectedPatient else {
            await MainActor.run { errorMessage = "No patient selected" }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let endDate = Date()
        let startDate = getStartDate(for: selectedTimeRange)
        let request: NSFetchRequest<MedicalTest> = MedicalTest.fetchRequest()
        request.predicate = NSPredicate(format: "patient == %@ AND testDate >= %@ AND testDate <= %@",
                                        patient, startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicalTest.testDate, ascending: true)]
        
        do {
            let tests = try viewContext.fetch(request)
            var parameters = Set<String>()
            for test in tests {
                if let testParams = test.testParameters as? Set<TestParameter> {
                    for param in testParams {
                        if let name = param.parameterName {
                            parameters.insert(name)
                        }
                    }
                }
            }
            let sortedParams = Array(parameters).sorted()
            await MainActor.run {
                self.organizationParameters = sortedParams
                if self.selectedParameter == nil, let first = sortedParams.first {
                    self.selectedParameter = first
                }
                self.isLoading = false
            }
            if let parameter = self.selectedParameter {
                await loadParameterData(parameter: parameter)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error loading parameters: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func loadParameterData(parameter: String) async {
        guard let patient = selectedPatient else {
            await MainActor.run { errorMessage = "No patient selected" }
            return
        }
        await MainActor.run {
            selectedParameter = parameter
            isLoading = true
            errorMessage = nil
        }
        
        let endDate = Date()
        let startDate = getStartDate(for: selectedTimeRange)
        let request: NSFetchRequest<MedicalTest> = MedicalTest.fetchRequest()
        request.predicate = NSPredicate(format: "patient == %@ AND testDate >= %@ AND testDate <= %@",
                                        patient, startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicalTest.testDate, ascending: true)]
        
        do {
            let tests = try viewContext.fetch(request)
            var dataPoints: [ParameterDataPoint] = []
            for test in tests {
                if let params = test.testParameters as? Set<TestParameter> {
                    if let param = params.first(where: { $0.parameterName == parameter }) {
                        let referenceRange = ReferenceRange(
                            low: param.referenceRangeLow,
                            high: param.referenceRangeHigh,
                            unit: param.unit ?? ""
                        )
                        dataPoints.append(ParameterDataPoint(
                            date: test.testDate ?? Date(),
                            value: param.numericValue,
                            isAbnormal: param.isAbnormal,
                            testID: test.objectID,
                            testName: test.testType ?? "Unknown Test",
                            patientID: patient.objectID,
                            referenceRange: referenceRange
                        ))
                    }
                }
            }
            await MainActor.run {
                self.parameterData = dataPoints.sorted(by: { $0.date < $1.date })
                self.isLoading = false
                if dataPoints.count > 1 {
                    self.calculateStatistics()
                } else {
                    self.statisticalSummary = nil
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error loading parameter data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func switchAnalysisLevel(to level: AnalysisLevel) async {
        await MainActor.run {
            selectedLevel = level
            parameterData = []
            statisticalSummary = nil
            errorMessage = nil
        }
        switch level {
        case .individual:
            if let patient = selectedPatient, let parameter = selectedParameter {
                await loadParameterData(parameter: parameter)
            }
        case .cohort:
            await loadCohortData()
        case .organization:
            await loadOrganizationData()
        }
    }
    
    func loadCohortData() async {
        await MainActor.run { isLoading = true }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            isLoading = false
            errorMessage = "Cohort analysis will be available in the next phase."
        }
    }
    
    func loadOrganizationData() async {
        await MainActor.run { isLoading = true }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
            isLoading = false
            errorMessage = "Organization-wide analysis will be available in the next phase."
        }
    }
    
    // MARK: - Helper Methods
    
    private func getStartDate(for timeRange: AnalysisTimeRange) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
    }
    
    private func calculateStatistics() {
        guard !parameterData.isEmpty else {
            statisticalSummary = nil
            return
        }
        
        let values = parameterData.map { $0.value }
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        let mean = values.reduce(0, +) / Double(values.count)
        
        let sortedValues = values.sorted()
        let median: Double = (values.count % 2 == 0)
            ? (sortedValues[values.count/2 - 1] + sortedValues[values.count/2]) / 2
            : sortedValues[values.count/2]
        
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        let percentChange: Double
        let trendDirection: StatisticalSummary.TrendDirection
        if values.count > 1, let firstValue = values.first, let lastValue = values.last, firstValue != 0 {
            percentChange = ((lastValue - firstValue) / firstValue) * 100
            if abs(percentChange) < 5 {
                trendDirection = .stable
            } else if percentChange > 0 {
                trendDirection = .increasing
            } else {
                trendDirection = .decreasing
            }
        } else {
            percentChange = 0
            trendDirection = .unknown
        }
        
        statisticalSummary = StatisticalSummary(
            min: min,
            max: max,
            mean: mean,
            median: median,
            standardDeviation: standardDeviation,
            percentChange: percentChange,
            trend: trendDirection
        )
    }
    
    // MARK: - Chart Data Generators
    
    var lineChartData: [LineChartData] {
        parameterData.map { dataPoint in
            LineChartData(
                value: dataPoint.value,
                label: formatDateShort(dataPoint.date),
                date: dataPoint.date
            )
        }
    }
    
    var barChartData: [ChartData] {
        let groupedByMonth = Dictionary(grouping: parameterData) { dataPoint in
            let components = Calendar.current.dateComponents([.year, .month], from: dataPoint.date)
            return "\(components.year ?? 0)-\(components.month ?? 0)"
        }
        return groupedByMonth.sorted { $0.key < $1.key }.map { (month, points) in
            let average = points.map { $0.value }.reduce(0, +) / Double(points.count)
            let representativeDate = points.first?.date
            return ChartData(
                value: average,
                label: formatMonth(representativeDate ?? Date()),
                color: .blue,
                date: representativeDate
            )
        }
    }
    
    var pieChartData: [ChartData] {
        let abnormalCount = parameterData.filter { $0.isAbnormal }.count
        let normalCount = parameterData.count - abnormalCount
        return [
            ChartData(value: Double(normalCount), label: "Normal", color: .green, date: nil),
            ChartData(value: Double(abnormalCount), label: "Abnormal", color: .red, date: nil)
        ]
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yy"
        return formatter.string(from: date)
    }
}

// For backward compatibility, you can add a typealias:
typealias TrendsAnalysisManager = TrendsAnalysisViewModel

