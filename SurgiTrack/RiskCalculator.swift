//
//  RiskCalculator.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 02/03/25.
//  Updated for production-level usage.
//

import SwiftUI
import CoreData

public struct RiskCalculator: Identifiable {
    public let id = UUID()
    public let name: String
    public let shortDescription: String
    public let longDescription: String
    public let parameters: [CalculatorParameter]
    public let calculationType: CalculationType
    
    public enum CalculationType: Hashable {
        case rcri, apgarScore, possum, meld, childPugh, asa, caprini, custom(String)
        
        public init(rawValue: String) {
            switch rawValue {
            case "rcri": self = .rcri
            case "apgarScore": self = .apgarScore
            case "possum": self = .possum
            case "meld": self = .meld
            case "childPugh": self = .childPugh
            case "asa": self = .asa
            case "caprini": self = .caprini
            default: self = .custom(rawValue)
            }
        }
    }
}

public struct CalculatorParameter: Identifiable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let parameterType: ParameterType
    public let options: [String]?
    
    public enum ParameterType {
        case boolean, number, selection
    }
}
