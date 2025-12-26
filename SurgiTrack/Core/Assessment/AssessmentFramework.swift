// AssessmentFramework.swift
// SurgiTrack → MedTrack
// Modular assessment framework supporting all departments
// Created on 26/12/2025

import Foundation
import SwiftUI

// MARK: - Assessment Template

/// A configurable assessment form template
struct AssessmentTemplate: Identifiable, Codable {
    let id: UUID
    let type: AssessmentType
    let name: String
    let description: String
    let category: String
    let supportedDepartments: [DepartmentType]
    let sections: [AssessmentSection]
    let scoringLogic: ScoringLogic
    let riskStratification: [RiskThreshold]
    let version: Int
    let isActive: Bool

    init(
        id: UUID = UUID(),
        type: AssessmentType,
        name: String? = nil,
        description: String? = nil,
        supportedDepartments: [DepartmentType],
        sections: [AssessmentSection],
        scoringLogic: ScoringLogic,
        riskStratification: [RiskThreshold],
        version: Int = 1,
        isActive: Bool = true
    ) {
        self.id = id
        self.type = type
        self.name = name ?? type.fullName
        self.description = description ?? ""
        self.category = type.category
        self.supportedDepartments = supportedDepartments
        self.sections = sections
        self.scoringLogic = scoringLogic
        self.riskStratification = riskStratification
        self.version = version
        self.isActive = isActive
    }
}

// MARK: - Assessment Section

struct AssessmentSection: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String?
    let fields: [AssessmentField]
    let conditionalLogic: ConditionalLogic?

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        fields: [AssessmentField],
        conditionalLogic: ConditionalLogic? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.fields = fields
        self.conditionalLogic = conditionalLogic
    }
}

// MARK: - Assessment Field

struct AssessmentField: Identifiable, Codable {
    let id: String
    let type: FieldType
    let label: String
    let helpText: String?
    let options: [FieldOption]?
    let validation: FieldValidation?
    let scoringWeight: Double?
    let isRequired: Bool
    let defaultValue: FieldValue?

    init(
        id: String,
        type: FieldType,
        label: String,
        helpText: String? = nil,
        options: [FieldOption]? = nil,
        validation: FieldValidation? = nil,
        scoringWeight: Double? = nil,
        isRequired: Bool = true,
        defaultValue: FieldValue? = nil
    ) {
        self.id = id
        self.type = type
        self.label = label
        self.helpText = helpText
        self.options = options
        self.validation = validation
        self.scoringWeight = scoringWeight
        self.isRequired = isRequired
        self.defaultValue = defaultValue
    }
}

enum FieldType: String, Codable {
    case numeric
    case decimal
    case text
    case multilineText
    case singleChoice
    case multipleChoice
    case yesNo
    case date
    case time
    case dateTime
    case slider
    case stepper
}

struct FieldOption: Identifiable, Codable {
    let id: String
    let label: String
    let value: FieldValue
    let score: Double?
    let description: String?

    init(
        id: String? = nil,
        label: String,
        value: FieldValue,
        score: Double? = nil,
        description: String? = nil
    ) {
        self.id = id ?? label.lowercased().replacingOccurrences(of: " ", with: "_")
        self.label = label
        self.value = value
        self.score = score
        self.description = description
    }
}

enum FieldValue: Codable, Equatable {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case date(Date)
    case array([String])

    var intValue: Int? {
        if case .int(let value) = self { return value }
        if case .double(let value) = self { return Int(value) }
        return nil
    }

    var doubleValue: Double? {
        if case .double(let value) = self { return value }
        if case .int(let value) = self { return Double(value) }
        return nil
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
}

struct FieldValidation: Codable {
    let minValue: Double?
    let maxValue: Double?
    let minLength: Int?
    let maxLength: Int?
    let pattern: String?
    let customMessage: String?

    init(
        minValue: Double? = nil,
        maxValue: Double? = nil,
        minLength: Int? = nil,
        maxLength: Int? = nil,
        pattern: String? = nil,
        customMessage: String? = nil
    ) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.minLength = minLength
        self.maxLength = maxLength
        self.pattern = pattern
        self.customMessage = customMessage
    }
}

// MARK: - Conditional Logic

struct ConditionalLogic: Codable {
    let conditions: [Condition]
    let action: ConditionalAction

    struct Condition: Codable {
        let fieldId: String
        let comparison: Comparison
        let value: FieldValue

        enum Comparison: String, Codable {
            case equals
            case notEquals
            case greaterThan
            case lessThan
            case contains
            case isEmpty
            case isNotEmpty
        }
    }

    enum ConditionalAction: String, Codable {
        case show
        case hide
        case require
        case disable
    }
}

// MARK: - Scoring Logic

struct ScoringLogic: Codable {
    let method: ScoringMethod
    let formula: String?
    let maxScore: Double?
    let minScore: Double?
    let interpretation: [ScoreInterpretation]

    enum ScoringMethod: String, Codable {
        case sum           // Add all field scores
        case average       // Average of field scores
        case weighted      // Weighted sum
        case formula       // Custom formula
        case classification // Categorical result
    }

    struct ScoreInterpretation: Codable {
        let minScore: Double
        let maxScore: Double
        let label: String
        let description: String
        let color: String // Hex color
    }
}

// MARK: - Risk Threshold

struct RiskThreshold: Codable {
    let level: RiskLevel
    let minValue: Double
    let maxValue: Double
    let percentageRange: String
    let recommendation: String

    enum RiskLevel: String, Codable, CaseIterable {
        case minimal = "Minimal"
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case veryHigh = "Very High"
        case critical = "Critical"

        var color: Color {
            switch self {
            case .minimal: return MedicalColors.RiskLevel.minimal
            case .low: return MedicalColors.RiskLevel.low
            case .moderate: return MedicalColors.RiskLevel.moderate
            case .high: return MedicalColors.RiskLevel.high
            case .veryHigh: return MedicalColors.RiskLevel.veryHigh
            case .critical: return MedicalColors.RiskLevel.critical
            }
        }
    }
}

// MARK: - Assessment Response

/// A completed assessment
struct AssessmentResponse: Identifiable, Codable {
    let id: UUID
    let templateId: UUID
    let templateType: AssessmentType
    let encounterId: UUID?
    let patientId: UUID
    let completedBy: UUID // Staff member ID
    let responses: [String: FieldValue] // fieldId -> value
    let calculatedScore: Double?
    let riskLevel: RiskThreshold.RiskLevel?
    let interpretation: String?
    let notes: String?
    let completedAt: Date

    init(
        id: UUID = UUID(),
        templateId: UUID,
        templateType: AssessmentType,
        encounterId: UUID? = nil,
        patientId: UUID,
        completedBy: UUID,
        responses: [String: FieldValue],
        calculatedScore: Double? = nil,
        riskLevel: RiskThreshold.RiskLevel? = nil,
        interpretation: String? = nil,
        notes: String? = nil,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.templateId = templateId
        self.templateType = templateType
        self.encounterId = encounterId
        self.patientId = patientId
        self.completedBy = completedBy
        self.responses = responses
        self.calculatedScore = calculatedScore
        self.riskLevel = riskLevel
        self.interpretation = interpretation
        self.notes = notes
        self.completedAt = completedAt
    }
}

// MARK: - Assessment Engine

/// Calculates scores and risk levels from assessment responses
class AssessmentEngine {

    static let shared = AssessmentEngine()

    private init() {}

    /// Calculate the score for a completed assessment
    func calculateScore(
        template: AssessmentTemplate,
        responses: [String: FieldValue]
    ) -> (score: Double, riskLevel: RiskThreshold.RiskLevel?, interpretation: String?) {

        var totalScore: Double = 0
        var totalWeight: Double = 0

        // Calculate score based on scoring method
        for section in template.sections {
            for field in section.fields {
                guard let response = responses[field.id],
                      let weight = field.scoringWeight else { continue }

                let fieldScore = calculateFieldScore(field: field, value: response)
                totalScore += fieldScore * weight
                totalWeight += weight
            }
        }

        // Apply scoring method
        let finalScore: Double
        switch template.scoringLogic.method {
        case .sum:
            finalScore = totalScore
        case .average:
            finalScore = totalWeight > 0 ? totalScore / totalWeight : 0
        case .weighted:
            finalScore = totalScore
        case .formula:
            // Custom formula evaluation would go here
            finalScore = totalScore
        case .classification:
            finalScore = totalScore
        }

        // Determine risk level
        let riskLevel = determineRiskLevel(score: finalScore, thresholds: template.riskStratification)

        // Get interpretation
        let interpretation = getInterpretation(score: finalScore, logic: template.scoringLogic)

        return (finalScore, riskLevel, interpretation)
    }

    private func calculateFieldScore(field: AssessmentField, value: FieldValue) -> Double {
        // For choice fields, look up the score from options
        if let options = field.options {
            for option in options {
                if option.value == value, let score = option.score {
                    return score
                }
            }
        }

        // For numeric fields, use the value directly
        if let numericValue = value.doubleValue {
            return numericValue
        }

        // For yes/no fields
        if let boolValue = value.boolValue {
            return boolValue ? 1.0 : 0.0
        }

        return 0
    }

    private func determineRiskLevel(score: Double, thresholds: [RiskThreshold]) -> RiskThreshold.RiskLevel? {
        for threshold in thresholds {
            if score >= threshold.minValue && score <= threshold.maxValue {
                return threshold.level
            }
        }
        return nil
    }

    private func getInterpretation(score: Double, logic: ScoringLogic) -> String? {
        for interpretation in logic.interpretation {
            if score >= interpretation.minScore && score <= interpretation.maxScore {
                return interpretation.description
            }
        }
        return nil
    }
}

// MARK: - Built-in Assessment Templates

extension AssessmentTemplate {

    /// NEWS2 - National Early Warning Score 2
    static var news2: AssessmentTemplate {
        AssessmentTemplate(
            type: .news2,
            description: "National Early Warning Score 2 for detecting deteriorating patients",
            supportedDepartments: DepartmentType.allCases,
            sections: [
                AssessmentSection(
                    title: "Vital Signs",
                    fields: [
                        AssessmentField(
                            id: "respiratory_rate",
                            type: .stepper,
                            label: "Respiratory Rate",
                            helpText: "Breaths per minute",
                            validation: FieldValidation(minValue: 0, maxValue: 60),
                            scoringWeight: 1.0
                        ),
                        AssessmentField(
                            id: "oxygen_saturation",
                            type: .stepper,
                            label: "SpO2 (%)",
                            helpText: "Oxygen saturation percentage",
                            validation: FieldValidation(minValue: 0, maxValue: 100),
                            scoringWeight: 1.0
                        ),
                        AssessmentField(
                            id: "supplemental_oxygen",
                            type: .yesNo,
                            label: "On Supplemental Oxygen?",
                            scoringWeight: 1.0
                        ),
                        AssessmentField(
                            id: "systolic_bp",
                            type: .stepper,
                            label: "Systolic Blood Pressure",
                            helpText: "mmHg",
                            validation: FieldValidation(minValue: 0, maxValue: 300),
                            scoringWeight: 1.0
                        ),
                        AssessmentField(
                            id: "heart_rate",
                            type: .stepper,
                            label: "Heart Rate",
                            helpText: "Beats per minute",
                            validation: FieldValidation(minValue: 0, maxValue: 250),
                            scoringWeight: 1.0
                        ),
                        AssessmentField(
                            id: "consciousness",
                            type: .singleChoice,
                            label: "Level of Consciousness",
                            options: [
                                FieldOption(label: "Alert", value: .string("A"), score: 0),
                                FieldOption(label: "Responds to Voice", value: .string("V"), score: 3),
                                FieldOption(label: "Responds to Pain", value: .string("P"), score: 3),
                                FieldOption(label: "Unresponsive", value: .string("U"), score: 3)
                            ],
                            scoringWeight: 1.0
                        ),
                        AssessmentField(
                            id: "temperature",
                            type: .decimal,
                            label: "Temperature",
                            helpText: "°C",
                            validation: FieldValidation(minValue: 30, maxValue: 45),
                            scoringWeight: 1.0
                        )
                    ]
                )
            ],
            scoringLogic: ScoringLogic(
                method: .sum,
                formula: nil,
                maxScore: 20,
                minScore: 0,
                interpretation: [
                    .init(minScore: 0, maxScore: 4, label: "Low", description: "Ward-based response", color: "22C55E"),
                    .init(minScore: 5, maxScore: 6, label: "Medium", description: "Key threshold for urgent response", color: "F59E0B"),
                    .init(minScore: 7, maxScore: 20, label: "High", description: "Emergency response threshold", color: "EF4444")
                ]
            ),
            riskStratification: [
                RiskThreshold(level: .low, minValue: 0, maxValue: 4, percentageRange: "N/A", recommendation: "Continue routine NEWS monitoring"),
                RiskThreshold(level: .moderate, minValue: 5, maxValue: 6, percentageRange: "N/A", recommendation: "Urgent review by clinician"),
                RiskThreshold(level: .high, minValue: 7, maxValue: 20, percentageRange: "N/A", recommendation: "Emergency assessment by critical care team")
            ]
        )
    }

    /// Glasgow Coma Scale
    static var glasgowComaScale: AssessmentTemplate {
        AssessmentTemplate(
            type: .glasgowComaScale,
            description: "Assessment of consciousness level",
            supportedDepartments: [.emergencyMedicine, .neurology, .intensiveCare, .traumaSurgery, .neurosurgery],
            sections: [
                AssessmentSection(
                    title: "Eye Opening",
                    fields: [
                        AssessmentField(
                            id: "eye_response",
                            type: .singleChoice,
                            label: "Eye Opening Response",
                            options: [
                                FieldOption(label: "Spontaneous", value: .int(4), score: 4),
                                FieldOption(label: "To verbal command", value: .int(3), score: 3),
                                FieldOption(label: "To pain", value: .int(2), score: 2),
                                FieldOption(label: "No response", value: .int(1), score: 1)
                            ],
                            scoringWeight: 1.0
                        )
                    ]
                ),
                AssessmentSection(
                    title: "Verbal Response",
                    fields: [
                        AssessmentField(
                            id: "verbal_response",
                            type: .singleChoice,
                            label: "Verbal Response",
                            options: [
                                FieldOption(label: "Oriented", value: .int(5), score: 5),
                                FieldOption(label: "Confused", value: .int(4), score: 4),
                                FieldOption(label: "Inappropriate words", value: .int(3), score: 3),
                                FieldOption(label: "Incomprehensible sounds", value: .int(2), score: 2),
                                FieldOption(label: "No response", value: .int(1), score: 1)
                            ],
                            scoringWeight: 1.0
                        )
                    ]
                ),
                AssessmentSection(
                    title: "Motor Response",
                    fields: [
                        AssessmentField(
                            id: "motor_response",
                            type: .singleChoice,
                            label: "Motor Response",
                            options: [
                                FieldOption(label: "Obeys commands", value: .int(6), score: 6),
                                FieldOption(label: "Localizes pain", value: .int(5), score: 5),
                                FieldOption(label: "Withdraws from pain", value: .int(4), score: 4),
                                FieldOption(label: "Abnormal flexion", value: .int(3), score: 3),
                                FieldOption(label: "Extension", value: .int(2), score: 2),
                                FieldOption(label: "No response", value: .int(1), score: 1)
                            ],
                            scoringWeight: 1.0
                        )
                    ]
                )
            ],
            scoringLogic: ScoringLogic(
                method: .sum,
                formula: nil,
                maxScore: 15,
                minScore: 3,
                interpretation: [
                    .init(minScore: 13, maxScore: 15, label: "Mild", description: "Mild brain injury", color: "22C55E"),
                    .init(minScore: 9, maxScore: 12, label: "Moderate", description: "Moderate brain injury", color: "F59E0B"),
                    .init(minScore: 3, maxScore: 8, label: "Severe", description: "Severe brain injury - consider intubation", color: "EF4444")
                ]
            ),
            riskStratification: [
                RiskThreshold(level: .low, minValue: 13, maxValue: 15, percentageRange: "N/A", recommendation: "Monitor and reassess"),
                RiskThreshold(level: .moderate, minValue: 9, maxValue: 12, percentageRange: "N/A", recommendation: "Close monitoring, consider CT"),
                RiskThreshold(level: .critical, minValue: 3, maxValue: 8, percentageRange: "N/A", recommendation: "Immediate intervention, secure airway")
            ]
        )
    }

    /// PHQ-9 for Depression Screening
    static var phq9: AssessmentTemplate {
        let questions = [
            "Little interest or pleasure in doing things",
            "Feeling down, depressed, or hopeless",
            "Trouble falling or staying asleep, or sleeping too much",
            "Feeling tired or having little energy",
            "Poor appetite or overeating",
            "Feeling bad about yourself or that you are a failure",
            "Trouble concentrating on things",
            "Moving or speaking slowly, or being fidgety/restless",
            "Thoughts of being better off dead or hurting yourself"
        ]

        let options = [
            FieldOption(label: "Not at all", value: .int(0), score: 0),
            FieldOption(label: "Several days", value: .int(1), score: 1),
            FieldOption(label: "More than half the days", value: .int(2), score: 2),
            FieldOption(label: "Nearly every day", value: .int(3), score: 3)
        ]

        return AssessmentTemplate(
            type: .phq9,
            description: "Patient Health Questionnaire for depression screening",
            supportedDepartments: [.psychiatry, .psychology, .internalMedicine, .generalPediatrics],
            sections: [
                AssessmentSection(
                    title: "Over the last 2 weeks, how often have you been bothered by:",
                    fields: questions.enumerated().map { index, question in
                        AssessmentField(
                            id: "phq9_q\(index + 1)",
                            type: .singleChoice,
                            label: question,
                            options: options,
                            scoringWeight: 1.0
                        )
                    }
                )
            ],
            scoringLogic: ScoringLogic(
                method: .sum,
                formula: nil,
                maxScore: 27,
                minScore: 0,
                interpretation: [
                    .init(minScore: 0, maxScore: 4, label: "Minimal", description: "Minimal depression", color: "22C55E"),
                    .init(minScore: 5, maxScore: 9, label: "Mild", description: "Mild depression", color: "84CC16"),
                    .init(minScore: 10, maxScore: 14, label: "Moderate", description: "Moderate depression", color: "F59E0B"),
                    .init(minScore: 15, maxScore: 19, label: "Moderately Severe", description: "Moderately severe depression", color: "F97316"),
                    .init(minScore: 20, maxScore: 27, label: "Severe", description: "Severe depression", color: "EF4444")
                ]
            ),
            riskStratification: [
                RiskThreshold(level: .minimal, minValue: 0, maxValue: 4, percentageRange: "N/A", recommendation: "Patient may not need treatment"),
                RiskThreshold(level: .low, minValue: 5, maxValue: 9, percentageRange: "N/A", recommendation: "Watchful waiting; repeat PHQ-9"),
                RiskThreshold(level: .moderate, minValue: 10, maxValue: 14, percentageRange: "N/A", recommendation: "Treatment plan, consider counseling"),
                RiskThreshold(level: .high, minValue: 15, maxValue: 19, percentageRange: "N/A", recommendation: "Active treatment with pharmacotherapy"),
                RiskThreshold(level: .critical, minValue: 20, maxValue: 27, percentageRange: "N/A", recommendation: "Immediate initiation of pharmacotherapy; consider referral")
            ]
        )
    }

    /// All built-in templates
    static var allBuiltIn: [AssessmentTemplate] {
        [.news2, .glasgowComaScale, .phq9]
    }
}
