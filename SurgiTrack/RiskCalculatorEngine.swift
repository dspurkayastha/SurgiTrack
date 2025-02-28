//
//  RiskCalculatorEngine.swift
//  SurgiTrack
//
//  Created by [Your Name] on [Date]
//  Production‑level engine with full calculation logic and separate interpretation logic.
//

import Foundation
import SwiftUI

// MARK: - Calculation Result
public struct CalculationResult {
    public let score: Double
    public let riskPercentage: Double
    public let interpretation: String
}

// MARK: - Risk Calculator Engine
public struct RiskCalculatorEngine {
    
    public static func calculate(calculator: RiskCalculator, parameters: [String: Any]) -> CalculationResult {
        switch calculator.calculationType {
        case .rcri:
            return calculateRCRI(parameters: parameters)
        case .apgarScore:
            return calculateSurgicalApgar(parameters: parameters)
        case .asa:
            return calculateASA(parameters: parameters)
        case .possum:
            return calculatePOSSUM(parameters: parameters)
        case .caprini:
            return calculateCaprini(parameters: parameters)
        default:
            return CalculationResult(score: 0, riskPercentage: 0, interpretation: "Calculation not implemented for this calculator.")
        }
    }
    
    // MARK: RCRI Calculation
    public static func calculateRCRI(parameters: [String: Any]) -> CalculationResult {
        var score = 0
        if (parameters["History of Ischemic Heart Disease"] as? Bool) == true { score += 1 }
        if (parameters["History of Congestive Heart Failure"] as? Bool) == true { score += 1 }
        if (parameters["History of Cerebrovascular Disease"] as? Bool) == true { score += 1 }
        if (parameters["Diabetes Mellitus Requiring Insulin"] as? Bool) == true { score += 1 }
        if (parameters["Preoperative Serum Creatinine >2.0 mg/dL"] as? Bool) == true { score += 1 }
        if (parameters["High-Risk Surgery"] as? Bool) == true { score += 1 }
        
        let (risk, interpretation) = interpretRCRI(score: score)
        return CalculationResult(score: Double(score), riskPercentage: risk, interpretation: interpretation)
    }
    
    private static func interpretRCRI(score: Int) -> (Double, String) {
        switch score {
        case 0:
            return (0.5, "RCRI Score 0: Minimal risk (<1% risk of major cardiac events).")
        case 1:
            return (1.3, "RCRI Score 1: Low risk (approximately 1.3% risk of major cardiac events).")
        case 2:
            return (5.5, "RCRI Score 2: Intermediate risk (approximately 5.5% risk of major cardiac events).")
        default:
            return (10.0, "RCRI Score \(score): High risk (approximately 10% risk of major cardiac events).")
        }
    }
    
    // MARK: Surgical Apgar Calculation
    public static func calculateSurgicalApgar(parameters: [String: Any]) -> CalculationResult {
        let eblStr = parameters["Estimated Blood Loss"] as? String ?? ""
        let eblPoints = pointsForEstimatedBloodLoss(eblStr)
        
        let mapStr = parameters["Lowest Mean Arterial Pressure"] as? String ?? ""
        let mapPoints = pointsForMAP(mapStr)
        
        let hrStr = parameters["Lowest Heart Rate"] as? String ?? ""
        let hrPoints = pointsForHeartRate(hrStr)
        
        let totalScore = eblPoints + mapPoints + hrPoints
        let (risk, interpretation) = interpretSurgicalApgar(totalScore: totalScore)
        return CalculationResult(score: Double(totalScore), riskPercentage: risk, interpretation: interpretation)
    }
    
    private static func pointsForEstimatedBloodLoss(_ ebl: String) -> Int {
        if ebl.contains("≤100") || ebl.contains("<100") {
            return 3
        } else if ebl.contains("101") && ebl.contains("600") {
            return 2
        } else if ebl.contains("601") && ebl.contains("1000") {
            return 1
        } else if ebl.contains(">1000") {
            return 0
        } else {
            return 0
        }
    }
    
    private static func pointsForMAP(_ map: String) -> Int {
        if map.contains("≥70") {
            return 3
        } else if map.contains("55") && map.contains("69") {
            return 2
        } else if map.contains("40") && map.contains("54") {
            return 1
        } else if map.contains("<40") {
            return 0
        } else {
            return 0
        }
    }
    
    private static func pointsForHeartRate(_ hr: String) -> Int {
        if hr.contains("≤55") {
            return 4
        } else if hr.contains("56") && hr.contains("65") {
            return 3
        } else if hr.contains("66") && hr.contains("75") {
            return 2
        } else if hr.contains("76") && hr.contains("85") {
            return 1
        } else if hr.contains(">85") {
            return 0
        } else {
            return 0
        }
    }
    
    private static func interpretSurgicalApgar(totalScore: Int) -> (Double, String) {
        if totalScore <= 2 {
            return (75.0, "Surgical Apgar Score \(totalScore): Very high risk of poor outcome. (Approximately 14% mortality and 75% risk of major complications)")
        } else if totalScore <= 4 {
            return (56.0, "Surgical Apgar Score \(totalScore): Very high risk of poor outcome. (Approximately 14% mortality and 56% risk of major complications)")
        } else if totalScore <= 6 {
            return (16.0, "Surgical Apgar Score \(totalScore): High risk of poor outcome. (Approximately 4% mortality and 16% risk of major complications)")
        } else if totalScore <= 8 {
            return (6.0, "Surgical Apgar Score \(totalScore): Moderate risk of poor outcome. (Approximately 1% mortality and 6% risk of major complications)")
        } else {
            return (3.0, "Surgical Apgar Score \(totalScore): Low risk of poor outcome. (Approximately 0% mortality and <4% risk of major complications)")
        }
    }
    
    // MARK: ASA Calculation
    public static func calculateASA(parameters: [String: Any]) -> CalculationResult {
        let asaClassStr = parameters["ASA Class"] as? String ?? "ASA I"
        let isEmergency = parameters["Emergency Surgery"] as? Bool ?? false
        
        let numericValue: Int = {
            if asaClassStr.contains("I") { return 1 }
            else if asaClassStr.contains("II") { return 2 }
            else if asaClassStr.contains("III") { return 3 }
            else if asaClassStr.contains("IV") { return 4 }
            else if asaClassStr.contains("V") { return 5 }
            else if asaClassStr.contains("VI") { return 6 }
            else { return 1 }
        }()
        
        let (baseRisk, baseInterpretation) = interpretASA(numericValue: numericValue)
        let multiplier = isEmergency ? 1.8 : 1.0
        let finalRisk = min(100.0, baseRisk * multiplier)
        let interpretation = isEmergency ? baseInterpretation + " Emergency surgery further increases risk." : baseInterpretation
        return CalculationResult(score: Double(numericValue), riskPercentage: finalRisk, interpretation: interpretation)
    }
    
    private static func interpretASA(numericValue: Int) -> (Double, String) {
        switch numericValue {
        case 1:
            return (0.1, "ASA I: Normal healthy patient with minimal anesthetic risk.")
        case 2:
            return (1.3, "ASA II: Patient with mild systemic disease; low risk.")
        case 3:
            return (3.0, "ASA III: Patient with severe systemic disease; moderate risk.")
        case 4:
            return (8.0, "ASA IV: Moribund patient not expected to survive without the operation; high risk.")
        case 5:
            return (15.0, "ASA V: Very high risk patient; extremely high risk.")
        case 6:
            return (100.0, "ASA VI: Brain-dead patient; not applicable for risk calculation.")
        default:
            return (0.1, "Unknown ASA classification.")
        }
    }
    
    // MARK: POSSUM Calculation
    public static func calculatePOSSUM(parameters: [String: Any]) -> CalculationResult {
        guard let physScore = parameters["Physiological Score"] as? Double,
              let opScore = parameters["Operative Severity Score"] as? Double else {
            return CalculationResult(score: 0, riskPercentage: 0, interpretation: "Insufficient parameters for POSSUM calculation.")
        }
        let L = -5.91 + 0.16 * physScore + 0.19 * opScore
        let odds = exp(L)
        let riskPercentage = (odds / (1 + odds)) * 100.0
        let totalScore = physScore + opScore
        let interpretation = "POSSUM Score: \(totalScore). Estimated risk of postoperative complications is approximately \(String(format: "%.1f", riskPercentage))%."
        return CalculationResult(score: totalScore, riskPercentage: riskPercentage, interpretation: interpretation)
    }
    
    // MARK: Caprini Calculation
    public static func calculateCaprini(parameters: [String: Any]) -> CalculationResult {
        guard let pointsArray = parameters["Caprini Points"] as? [Int] else {
            return CalculationResult(score: 0, riskPercentage: 0, interpretation: "No risk factors provided.")
        }
        let totalPoints = pointsArray.reduce(0, +)
        let (risk, interpretation) = interpretCaprini(totalPoints: totalPoints)
        return CalculationResult(score: Double(totalPoints), riskPercentage: risk, interpretation: interpretation)
    }
    
    private static func interpretCaprini(totalPoints: Int) -> (Double, String) {
        switch totalPoints {
        case 0:
            return (0.0, "Very low risk: Minimal risk of VTE.")
        case 1...2:
            return (0.5, "Low risk of VTE.")
        case 3...4:
            return (0.7, "Moderate risk of VTE.")
        case 5...6:
            return (1.8, "High risk of VTE.")
        case 7...8:
            return (4.0, "High risk of VTE.")
        default:
            return (10.7, "Very high risk of VTE.")
        }
    }
}

// MARK: - Risk Calculator Store
public class RiskCalculatorStore {
    public static let shared = RiskCalculatorStore()
    
    public var calculators: [RiskCalculator] {
        return [
            createRCRICalculator(),
            createSurgicalApgarCalculator(),
            createASACalculator(),
            createPOSSUMCalculator(),
            createCapriniCalculator()
        ]
    }
    
    public func createRCRICalculator() -> RiskCalculator {
        return RiskCalculator(
            name: "Revised Cardiac Risk Index (RCRI)",
            shortDescription: "Predicts cardiac risk for non‐cardiac surgery",
            longDescription: "The RCRI uses 6 independent risk factors: high‐risk surgery, insulin‐dependent diabetes, renal failure (creatinine >2 mg/dL), history of ischemic heart disease, congestive heart failure, and cerebrovascular disease. Each factor adds equally to the score.",
            parameters: [
                CalculatorParameter(name: "History of Ischemic Heart Disease", description: "History of MI, positive stress test, chest pain, nitrates use, or ECG changes.", parameterType: .boolean, options: nil),
                CalculatorParameter(name: "History of Congestive Heart Failure", description: "History of heart failure or pulmonary edema.", parameterType: .boolean, options: nil),
                CalculatorParameter(name: "History of Cerebrovascular Disease", description: "History of TIA or stroke.", parameterType: .boolean, options: nil),
                CalculatorParameter(name: "Diabetes Mellitus Requiring Insulin", description: "Patient on insulin therapy.", parameterType: .boolean, options: nil),
                CalculatorParameter(name: "Preoperative Serum Creatinine >2.0 mg/dL", description: "Elevated creatinine level.", parameterType: .boolean, options: nil),
                CalculatorParameter(name: "High-Risk Surgery", description: "Intraperitoneal, intrathoracic, or major vascular surgery.", parameterType: .boolean, options: nil)
            ],
            calculationType: .rcri
        )
    }
    
    public func createSurgicalApgarCalculator() -> RiskCalculator {
        return RiskCalculator(
            name: "Surgical Apgar Score",
            shortDescription: "Assesses intraoperative risk",
            longDescription: "The Surgical Apgar Score is based on estimated blood loss, lowest mean arterial pressure, and lowest heart rate. Scores are summed to provide a total that correlates with the risk of major complications.",
            parameters: [
                CalculatorParameter(name: "Estimated Blood Loss", description: "Select the blood loss range.", parameterType: .selection, options: ["≤100 mL", "101-600 mL", "601-1000 mL", ">1000 mL"]),
                CalculatorParameter(name: "Lowest Mean Arterial Pressure", description: "Select the lowest MAP.", parameterType: .selection, options: ["≥70 mmHg", "55-69 mmHg", "40-54 mmHg", "<40 mmHg"]),
                CalculatorParameter(name: "Lowest Heart Rate", description: "Select the lowest heart rate.", parameterType: .selection, options: ["≤55 bpm", "56-65 bpm", "66-75 bpm", "76-85 bpm", ">85 bpm"])
            ],
            calculationType: .apgarScore
        )
    }
    
    public func createASACalculator() -> RiskCalculator {
        return RiskCalculator(
            name: "ASA Physical Status Classification",
            shortDescription: "Evaluates preoperative patient status",
            longDescription: """
            The ASA classification ranges from I to VI:
            • ASA I: Normal healthy patient.
            • ASA II: Patient with mild systemic disease.
            • ASA III: Patient with severe systemic disease.
            • ASA IV: Patient with severe systemic disease that is a constant threat to life.
            • ASA V: Moribund patient not expected to survive without surgery.
            • ASA VI: Brain-dead patient.
            For emergency surgery, add an 'E' suffix.
            """,
            parameters: [
                CalculatorParameter(name: "ASA Class", description: "Select the appropriate ASA class.", parameterType: .selection, options: ["ASA I", "ASA II", "ASA III", "ASA IV", "ASA V", "ASA VI"]),
                CalculatorParameter(name: "Emergency Surgery", description: "Is this an emergency procedure?", parameterType: .boolean, options: nil)
            ],
            calculationType: .asa
        )
    }
    
    public func createPOSSUMCalculator() -> RiskCalculator {
        return RiskCalculator(
            name: "POSSUM Score",
            shortDescription: "Predicts postoperative complications",
            longDescription: "POSSUM is calculated using a physiological score (12 variables) and an operative severity score (6 variables). The risk is estimated using the formula: ln(R/(1-R)) = -5.91 + 0.16×(physiological score) + 0.19×(operative severity score).",
            parameters: [
                CalculatorParameter(name: "Physiological Score", description: "Enter the total physiological score (min 12, max 88).", parameterType: .number, options: nil),
                CalculatorParameter(name: "Operative Severity Score", description: "Enter the operative severity score (min 6, max 48).", parameterType: .number, options: nil)
            ],
            calculationType: .possum
        )
    }
    
    public func createCapriniCalculator() -> RiskCalculator {
        return RiskCalculator(
            name: "Caprini Score",
            shortDescription: "Assesses VTE risk in surgical patients",
            longDescription: "The Caprini score is determined by adding points assigned to multiple risk factors including age, surgery type, and past medical history. A higher score indicates a higher risk of venous thromboembolism.",
            parameters: [
                CalculatorParameter(name: "Caprini Points", description: "Enter the point values for each risk factor as an array (e.g., [1, 2, 0, 1]).", parameterType: .number, options: nil)
            ],
            calculationType: .caprini
        )
    }
}

