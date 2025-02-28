//
//  StoredCalculationExtensions.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 02/03/25.
//

import CoreData
import SwiftUI

// Extension for StoredCalculation entity
extension StoredCalculation {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: calculationDate ?? Date())
    }
    
    var riskLevel: RiskLevel {
        let percentage = resultPercentage
        
        if percentage < 1.0 {
            return .veryLow
        } else if percentage < 5.0 {
            return .low
        } else if percentage < 10.0 {
            return .moderate
        } else if percentage < 20.0 {
            return .high
        } else {
            return .veryHigh
        }
    }
    
    var riskColor: Color {
        switch riskLevel {
        case .veryLow:
            return .green
        case .low:
            return .mint
        case .moderate:
            return .yellow
        case .high:
            return .orange
        case .veryHigh:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    enum RiskLevel: String {
        case veryLow = "Very Low"
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case veryHigh = "Very High"
        case unknown = "Unknown"
    }
}

// Function to serialize and deserialize parameter data
func encodeParameters(_ parameters: [String: Any]) -> Data? {
    // Convert parameters to a format that can be serialized
    var serializableParams: [String: String] = [:]
    
    for (key, value) in parameters {
        if let boolVal = value as? Bool {
            serializableParams[key] = boolVal ? "true" : "false"
        } else if let doubleVal = value as? Double {
            serializableParams[key] = String(doubleVal)
        } else if let intVal = value as? Int {
            serializableParams[key] = String(intVal)
        } else if let stringVal = value as? String {
            serializableParams[key] = stringVal
        }
    }
    
    return try? JSONEncoder().encode(serializableParams)
}

func decodeParameters(_ data: Data) -> [String: Any]? {
    guard let decodedDict = try? JSONDecoder().decode([String: String].self, from: data) else {
        return nil
    }
    
    var result: [String: Any] = [:]
    
    for (key, value) in decodedDict {
        // Try to convert to appropriate types
        if value == "true" || value == "false" {
            result[key] = (value == "true")
        } else if let doubleVal = Double(value) {
            result[key] = doubleVal
        } else {
            result[key] = value
        }
    }
    
    return result
}
