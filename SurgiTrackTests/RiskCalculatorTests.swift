// RiskCalculatorTests.swift
// SurgiTrackTests
// Tests for risk calculator engines
// Created on 26/12/2025

import Testing
@testable import SurgiTrack

struct RiskCalculatorTests {

    // MARK: - RCRI Calculator Tests

    @Test func rcri_scoreZero_minimalRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createRCRICalculator()
        let parameters: [String: Any] = [
            "History of Ischemic Heart Disease": false,
            "History of Congestive Heart Failure": false,
            "History of Cerebrovascular Disease": false,
            "Diabetes Mellitus Requiring Insulin": false,
            "Preoperative Serum Creatinine >2.0 mg/dL": false,
            "High-Risk Surgery": false
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 0, "RCRI score should be 0")
        #expect(result.riskPercentage == 0.5, "Risk should be 0.5%")
        #expect(result.interpretation.contains("Minimal risk"), "Should indicate minimal risk")
    }

    @Test func rcri_scoreOne_lowRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createRCRICalculator()
        let parameters: [String: Any] = [
            "History of Ischemic Heart Disease": true,
            "History of Congestive Heart Failure": false,
            "History of Cerebrovascular Disease": false,
            "Diabetes Mellitus Requiring Insulin": false,
            "Preoperative Serum Creatinine >2.0 mg/dL": false,
            "High-Risk Surgery": false
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 1, "RCRI score should be 1")
        #expect(result.riskPercentage == 1.3, "Risk should be 1.3%")
        #expect(result.interpretation.contains("Low risk"), "Should indicate low risk")
    }

    @Test func rcri_scoreTwo_intermediateRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createRCRICalculator()
        let parameters: [String: Any] = [
            "History of Ischemic Heart Disease": true,
            "History of Congestive Heart Failure": true,
            "History of Cerebrovascular Disease": false,
            "Diabetes Mellitus Requiring Insulin": false,
            "Preoperative Serum Creatinine >2.0 mg/dL": false,
            "High-Risk Surgery": false
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 2, "RCRI score should be 2")
        #expect(result.riskPercentage == 5.5, "Risk should be 5.5%")
        #expect(result.interpretation.contains("Intermediate risk"), "Should indicate intermediate risk")
    }

    @Test func rcri_scoreThreeOrMore_highRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createRCRICalculator()
        let parameters: [String: Any] = [
            "History of Ischemic Heart Disease": true,
            "History of Congestive Heart Failure": true,
            "History of Cerebrovascular Disease": true,
            "Diabetes Mellitus Requiring Insulin": false,
            "Preoperative Serum Creatinine >2.0 mg/dL": false,
            "High-Risk Surgery": false
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 3, "RCRI score should be 3")
        #expect(result.riskPercentage == 10.0, "Risk should be 10%")
        #expect(result.interpretation.contains("High risk"), "Should indicate high risk")
    }

    @Test func rcri_allRiskFactors_maxScore() async throws {
        let calculator = RiskCalculatorStore.shared.createRCRICalculator()
        let parameters: [String: Any] = [
            "History of Ischemic Heart Disease": true,
            "History of Congestive Heart Failure": true,
            "History of Cerebrovascular Disease": true,
            "Diabetes Mellitus Requiring Insulin": true,
            "Preoperative Serum Creatinine >2.0 mg/dL": true,
            "High-Risk Surgery": true
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 6, "RCRI score should be 6 with all risk factors")
    }

    // MARK: - Surgical Apgar Score Tests

    @Test func surgicalApgar_optimalValues_highScore() async throws {
        let calculator = RiskCalculatorStore.shared.createSurgicalApgarCalculator()
        let parameters: [String: Any] = [
            "Estimated Blood Loss": "≤100 mL",
            "Lowest Mean Arterial Pressure": "≥70 mmHg",
            "Lowest Heart Rate": "≤55 bpm"
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 10, "Optimal values should give score of 10")
        #expect(result.riskPercentage == 3.0, "Risk should be 3%")
        #expect(result.interpretation.contains("Low risk"), "Should indicate low risk")
    }

    @Test func surgicalApgar_worstValues_lowScore() async throws {
        let calculator = RiskCalculatorStore.shared.createSurgicalApgarCalculator()
        let parameters: [String: Any] = [
            "Estimated Blood Loss": ">1000 mL",
            "Lowest Mean Arterial Pressure": "<40 mmHg",
            "Lowest Heart Rate": ">85 bpm"
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 0, "Worst values should give score of 0")
        #expect(result.riskPercentage == 75.0, "Risk should be 75%")
        #expect(result.interpretation.contains("Very high risk"), "Should indicate very high risk")
    }

    // MARK: - ASA Classification Tests

    @Test func asa_classI_minimalRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createASACalculator()
        let parameters: [String: Any] = [
            "ASA Class": "ASA I",
            "Emergency Surgery": false
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 1, "ASA I should have score of 1")
        #expect(result.riskPercentage == 0.1, "Risk should be 0.1%")
        #expect(result.interpretation.contains("Normal healthy patient"), "Should describe healthy patient")
    }

    @Test func asa_classIII_moderateRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createASACalculator()
        let parameters: [String: Any] = [
            "ASA Class": "ASA III",
            "Emergency Surgery": false
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 3, "ASA III should have score of 3")
        #expect(result.riskPercentage == 3.0, "Risk should be 3%")
    }

    @Test func asa_emergencySurgery_increasesRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createASACalculator()
        let parametersNonEmergency: [String: Any] = [
            "ASA Class": "ASA II",
            "Emergency Surgery": false
        ]
        let parametersEmergency: [String: Any] = [
            "ASA Class": "ASA II",
            "Emergency Surgery": true
        ]

        let resultNonEmergency = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parametersNonEmergency)
        let resultEmergency = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parametersEmergency)

        #expect(resultEmergency.riskPercentage > resultNonEmergency.riskPercentage, "Emergency should increase risk")
        #expect(resultEmergency.riskPercentage == resultNonEmergency.riskPercentage * 1.8, accuracy: 0.01, "Emergency multiplier should be 1.8x")
        #expect(resultEmergency.interpretation.contains("Emergency surgery"), "Should mention emergency")
    }

    @Test func asa_classVI_brainDead() async throws {
        let calculator = RiskCalculatorStore.shared.createASACalculator()
        let parameters: [String: Any] = [
            "ASA Class": "ASA VI",
            "Emergency Surgery": false
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 6, "ASA VI should have score of 6")
        #expect(result.riskPercentage == 100.0, "Risk should be 100%")
        #expect(result.interpretation.contains("Brain-dead"), "Should mention brain-dead")
    }

    // MARK: - POSSUM Calculator Tests

    @Test func possum_lowScores_lowRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createPOSSUMCalculator()
        let parameters: [String: Any] = [
            "Physiological Score": 12.0,  // Minimum
            "Operative Severity Score": 6.0  // Minimum
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 18, "Total should be 18")
        #expect(result.riskPercentage < 5, "Risk should be low")
    }

    @Test func possum_highScores_highRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createPOSSUMCalculator()
        let parameters: [String: Any] = [
            "Physiological Score": 50.0,
            "Operative Severity Score": 30.0
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 80, "Total should be 80")
        #expect(result.riskPercentage > 50, "Risk should be high")
    }

    @Test func possum_missingParameters_returnsZero() async throws {
        let calculator = RiskCalculatorStore.shared.createPOSSUMCalculator()
        let parameters: [String: Any] = [
            "Physiological Score": 20.0
            // Missing Operative Severity Score
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 0, "Missing params should return 0")
        #expect(result.interpretation.contains("Insufficient"), "Should indicate insufficient parameters")
    }

    // MARK: - Caprini VTE Score Tests

    @Test func caprini_noRiskFactors_veryLowRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createCapriniCalculator()
        let parameters: [String: Any] = [
            "Caprini Points": [0]
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 0, "Score should be 0")
        #expect(result.riskPercentage == 0.0, "Risk should be 0%")
        #expect(result.interpretation.contains("Very low risk"), "Should indicate very low risk")
    }

    @Test func caprini_lowRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createCapriniCalculator()
        let parameters: [String: Any] = [
            "Caprini Points": [1, 1]  // Total 2
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 2, "Score should be 2")
        #expect(result.riskPercentage == 0.5, "Risk should be 0.5%")
        #expect(result.interpretation.contains("Low risk"), "Should indicate low risk")
    }

    @Test func caprini_moderateRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createCapriniCalculator()
        let parameters: [String: Any] = [
            "Caprini Points": [1, 1, 1, 1]  // Total 4
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 4, "Score should be 4")
        #expect(result.riskPercentage == 0.7, "Risk should be 0.7%")
        #expect(result.interpretation.contains("Moderate risk"), "Should indicate moderate risk")
    }

    @Test func caprini_highRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createCapriniCalculator()
        let parameters: [String: Any] = [
            "Caprini Points": [2, 2, 2]  // Total 6
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 6, "Score should be 6")
        #expect(result.riskPercentage == 1.8, "Risk should be 1.8%")
        #expect(result.interpretation.contains("High risk"), "Should indicate high risk")
    }

    @Test func caprini_veryHighRisk() async throws {
        let calculator = RiskCalculatorStore.shared.createCapriniCalculator()
        let parameters: [String: Any] = [
            "Caprini Points": [3, 3, 3, 3]  // Total 12
        ]

        let result = RiskCalculatorEngine.calculate(calculator: calculator, parameters: parameters)

        #expect(result.score == 12, "Score should be 12")
        #expect(result.riskPercentage == 10.7, "Risk should be 10.7%")
        #expect(result.interpretation.contains("Very high risk"), "Should indicate very high risk")
    }

    // MARK: - Calculator Store Tests

    @Test func calculatorStore_hasAllCalculators() async throws {
        let store = RiskCalculatorStore.shared
        let calculators = store.calculators

        #expect(calculators.count == 5, "Should have 5 calculators")

        let names = calculators.map { $0.name }
        #expect(names.contains { $0.contains("RCRI") }, "Should have RCRI")
        #expect(names.contains { $0.contains("Surgical Apgar") }, "Should have Surgical Apgar")
        #expect(names.contains { $0.contains("ASA") }, "Should have ASA")
        #expect(names.contains { $0.contains("POSSUM") }, "Should have POSSUM")
        #expect(names.contains { $0.contains("Caprini") }, "Should have Caprini")
    }

    @Test func calculatorStore_calculatorsHaveParameters() async throws {
        let store = RiskCalculatorStore.shared

        for calculator in store.calculators {
            #expect(calculator.parameters.count > 0, "\(calculator.name) should have parameters")
            #expect(!calculator.shortDescription.isEmpty, "\(calculator.name) should have short description")
            #expect(!calculator.longDescription.isEmpty, "\(calculator.name) should have long description")
        }
    }
}

// MARK: - Helper for floating point comparison

extension Double {
    static func expect(_ actual: Double, equals expected: Double, accuracy: Double, message: String = "") {
        let isClose = abs(actual - expected) <= accuracy
        #expect(isClose, "\(message) Expected \(expected), got \(actual)")
    }
}
