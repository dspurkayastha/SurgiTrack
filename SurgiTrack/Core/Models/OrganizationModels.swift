// OrganizationModels.swift
// SurgiTrack → MedTrack
// Multi-tenant organization models for B2B healthcare platform
// Created on 26/12/2025

import Foundation
import SwiftUI

// MARK: - Organization Type

/// Types of healthcare organizations
enum OrganizationType: String, CaseIterable, Codable {
    case hospital = "Hospital"
    case clinic = "Clinic"
    case healthSystem = "Health System"
    case ambulatorySurgeryCenter = "Ambulatory Surgery Center"
    case urgentCare = "Urgent Care"
    case privatePractice = "Private Practice"

    var icon: String {
        switch self {
        case .hospital: return "building.2.fill"
        case .clinic: return "cross.case.fill"
        case .healthSystem: return "building.columns.fill"
        case .ambulatorySurgeryCenter: return "scissors"
        case .urgentCare: return "staroflife.fill"
        case .privatePractice: return "person.crop.square.fill"
        }
    }
}

// MARK: - Subscription Tier

/// B2B subscription tiers
enum SubscriptionTier: String, CaseIterable, Codable {
    case starter = "Starter"
    case professional = "Professional"
    case enterprise = "Enterprise"

    var maxFacilities: Int {
        switch self {
        case .starter: return 1
        case .professional: return 5
        case .enterprise: return .max
        }
    }

    var maxDepartments: Int {
        switch self {
        case .starter: return 3
        case .professional: return .max
        case .enterprise: return .max
        }
    }

    var maxStaff: Int {
        switch self {
        case .starter: return 25
        case .professional: return 200
        case .enterprise: return .max
        }
    }

    var features: [String] {
        switch self {
        case .starter:
            return ["Core Assessment Library", "Email Support", "Basic Analytics"]
        case .professional:
            return ["Full Assessment Library", "Custom Assessments", "Analytics Dashboard",
                    "Priority Support", "API Access (Limited)"]
        case .enterprise:
            return ["Everything in Professional", "White-Labeling", "Full API Access",
                    "Custom Integrations", "Dedicated Support", "On-Premise Option"]
        }
    }
}

// MARK: - Department Type

/// All supported medical departments/specialties
enum DepartmentType: String, CaseIterable, Codable, Identifiable {
    // Surgical
    case generalSurgery = "General Surgery"
    case orthopedicSurgery = "Orthopedic Surgery"
    case cardiacSurgery = "Cardiac Surgery"
    case neurosurgery = "Neurosurgery"
    case plasticSurgery = "Plastic Surgery"
    case urology = "Urology"
    case ophthalmology = "Ophthalmology"
    case entSurgery = "ENT Surgery"
    case thoracicSurgery = "Thoracic Surgery"
    case vascularSurgery = "Vascular Surgery"
    case pediatricSurgery = "Pediatric Surgery"

    // Medicine
    case internalMedicine = "Internal Medicine"
    case cardiology = "Cardiology"
    case pulmonology = "Pulmonology"
    case gastroenterology = "Gastroenterology"
    case nephrology = "Nephrology"
    case endocrinology = "Endocrinology"
    case rheumatology = "Rheumatology"
    case infectiousDisease = "Infectious Disease"
    case hematology = "Hematology"
    case oncology = "Oncology"
    case neurology = "Neurology"
    case dermatology = "Dermatology"
    case geriatrics = "Geriatrics"

    // Critical Care
    case emergencyMedicine = "Emergency Medicine"
    case intensiveCare = "Intensive Care"
    case traumaSurgery = "Trauma Surgery"
    case anesthesiology = "Anesthesiology"

    // Women's Health
    case obstetricsGynecology = "Obstetrics & Gynecology"
    case maternalFetalMedicine = "Maternal-Fetal Medicine"
    case reproductiveEndocrinology = "Reproductive Endocrinology"
    case gynecologicOncology = "Gynecologic Oncology"

    // Pediatrics
    case generalPediatrics = "General Pediatrics"
    case neonatology = "Neonatology"
    case pediatricCardiology = "Pediatric Cardiology"
    case pediatricNeurology = "Pediatric Neurology"

    // Mental Health
    case psychiatry = "Psychiatry"
    case psychology = "Psychology"
    case addictionMedicine = "Addiction Medicine"

    // Diagnostics
    case radiology = "Radiology"
    case pathology = "Pathology"
    case laboratoryMedicine = "Laboratory Medicine"
    case nuclearMedicine = "Nuclear Medicine"

    // Rehabilitation
    case physicalMedicine = "Physical Medicine & Rehabilitation"
    case physicalTherapy = "Physical Therapy"
    case occupationalTherapy = "Occupational Therapy"
    case speechTherapy = "Speech Therapy"

    // Support
    case pharmacy = "Pharmacy"
    case nutrition = "Nutrition Services"
    case socialWork = "Social Work"
    case caseManagement = "Case Management"
    case palliativeCare = "Palliative Care"

    var id: String { rawValue }

    var category: DepartmentCategory {
        switch self {
        case .generalSurgery, .orthopedicSurgery, .cardiacSurgery, .neurosurgery,
             .plasticSurgery, .urology, .ophthalmology, .entSurgery,
             .thoracicSurgery, .vascularSurgery, .pediatricSurgery:
            return .surgical
        case .internalMedicine, .cardiology, .pulmonology, .gastroenterology,
             .nephrology, .endocrinology, .rheumatology, .infectiousDisease,
             .hematology, .oncology, .neurology, .dermatology, .geriatrics:
            return .medicine
        case .emergencyMedicine, .intensiveCare, .traumaSurgery, .anesthesiology:
            return .criticalCare
        case .obstetricsGynecology, .maternalFetalMedicine, .reproductiveEndocrinology, .gynecologicOncology:
            return .womensHealth
        case .generalPediatrics, .neonatology, .pediatricCardiology, .pediatricNeurology:
            return .pediatrics
        case .psychiatry, .psychology, .addictionMedicine:
            return .mentalHealth
        case .radiology, .pathology, .laboratoryMedicine, .nuclearMedicine:
            return .diagnostics
        case .physicalMedicine, .physicalTherapy, .occupationalTherapy, .speechTherapy:
            return .rehabilitation
        case .pharmacy, .nutrition, .socialWork, .caseManagement, .palliativeCare:
            return .support
        }
    }

    var icon: String {
        switch category {
        case .surgical: return "scissors"
        case .medicine: return "stethoscope"
        case .criticalCare: return "waveform.path.ecg"
        case .womensHealth: return "figure.dress.line.vertical.figure"
        case .pediatrics: return "figure.and.child.holdinghands"
        case .mentalHealth: return "brain.head.profile"
        case .diagnostics: return "xray"
        case .rehabilitation: return "figure.walk"
        case .support: return "hands.sparkles.fill"
        }
    }

    var color: Color {
        switch category {
        case .surgical: return MedicalColors.Surgery.inProgress
        case .medicine: return MedicalColors.Brand.primary
        case .criticalCare: return MedicalColors.PatientStatus.critical
        case .womensHealth: return Color(hex: "EC4899")
        case .pediatrics: return Color(hex: "8B5CF6")
        case .mentalHealth: return Color(hex: "6366F1")
        case .diagnostics: return Color(hex: "0EA5E9")
        case .rehabilitation: return Color(hex: "22C55E")
        case .support: return Color(hex: "F59E0B")
        }
    }

    /// Available assessment types for this department
    var availableAssessments: [AssessmentType] {
        switch self {
        case .generalSurgery, .orthopedicSurgery, .cardiacSurgery, .neurosurgery,
             .plasticSurgery, .urology, .thoracicSurgery, .vascularSurgery, .pediatricSurgery:
            return [.rcri, .surgicalApgar, .asaPhysicalStatus, .possum, .capriniVTE, .mallampati, .stopBang]
        case .emergencyMedicine, .traumaSurgery:
            return [.esi, .glasgowComaScale, .nihss, .heart, .curb65, .wells, .pecarn]
        case .cardiology:
            return [.grace, .timi, .chadsVasc, .hasBled, .dukeActivityStatus, .nyha]
        case .obstetricsGynecology, .maternalFetalMedicine:
            return [.bishopScore, .apgarNewborn, .edinburghPostnatal]
        case .oncology:
            return [.ecogPerformance, .karnofskyPerformance, .tnmStaging]
        case .neurology:
            return [.nihss, .huntHess, .modifiedRankin, .glasgowComaScale]
        case .intensiveCare:
            return [.apacheII, .sofa, .glasgowComaScale, .rass, .cam_icu]
        case .pulmonology:
            return [.curb65, .psi, .bode]
        case .psychiatry:
            return [.phq9, .gad7, .auditC, .cows]
        default:
            return [.news2] // Universal vital signs assessment
        }
    }
}

enum DepartmentCategory: String, CaseIterable, Codable {
    case surgical = "Surgical"
    case medicine = "Medicine"
    case criticalCare = "Critical Care"
    case womensHealth = "Women's Health"
    case pediatrics = "Pediatrics"
    case mentalHealth = "Mental Health"
    case diagnostics = "Diagnostics"
    case rehabilitation = "Rehabilitation"
    case support = "Support Services"

    var departments: [DepartmentType] {
        DepartmentType.allCases.filter { $0.category == self }
    }
}

// MARK: - Staff Role

/// Role-based access control roles
enum StaffRole: String, CaseIterable, Codable, Comparable {
    // Administrative
    case systemAdmin = "System Admin"
    case organizationAdmin = "Organization Admin"
    case facilityAdmin = "Facility Admin"
    case departmentHead = "Department Head"

    // Clinical - Physicians
    case attendingPhysician = "Attending Physician"
    case fellow = "Fellow"
    case resident = "Resident"
    case intern = "Intern"

    // Clinical - Nursing
    case nurseManager = "Nurse Manager"
    case registeredNurse = "Registered Nurse"
    case licensedPracticalNurse = "Licensed Practical Nurse"
    case nurseAide = "Nurse Aide"

    // Clinical - Allied Health
    case physicianAssistant = "Physician Assistant"
    case nursePractitioner = "Nurse Practitioner"
    case technician = "Technician"
    case therapist = "Therapist"
    case pharmacist = "Pharmacist"

    // Support
    case caseManager = "Case Manager"
    case socialWorker = "Social Worker"
    case administrativeStaff = "Administrative Staff"
    case schedulingCoordinator = "Scheduling Coordinator"

    // External
    case referringPhysician = "Referring Physician"
    case consultant = "Consultant"
    case readOnly = "Read Only"

    var level: Int {
        switch self {
        case .systemAdmin: return 100
        case .organizationAdmin: return 90
        case .facilityAdmin: return 80
        case .departmentHead: return 70
        case .attendingPhysician, .nursePractitioner: return 60
        case .fellow, .physicianAssistant: return 55
        case .resident, .nurseManager: return 50
        case .intern, .registeredNurse, .pharmacist: return 45
        case .licensedPracticalNurse, .therapist, .technician: return 40
        case .nurseAide: return 35
        case .caseManager, .socialWorker: return 30
        case .administrativeStaff, .schedulingCoordinator: return 25
        case .referringPhysician, .consultant: return 20
        case .readOnly: return 10
        }
    }

    static func < (lhs: StaffRole, rhs: StaffRole) -> Bool {
        lhs.level < rhs.level
    }

    var permissions: Set<Permission> {
        switch self {
        case .systemAdmin:
            return Set(Permission.allCases)
        case .organizationAdmin:
            return [.viewPatients, .editPatients, .createPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReferrals, .createReferrals, .manageReferrals,
                    .viewReports, .createReports,
                    .manageStaff, .manageDepartments, .viewAnalytics]
        case .facilityAdmin:
            return [.viewPatients, .editPatients, .createPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReferrals, .createReferrals, .manageReferrals,
                    .viewReports, .createReports,
                    .manageStaff, .viewAnalytics]
        case .departmentHead:
            return [.viewPatients, .editPatients, .createPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReferrals, .createReferrals, .manageReferrals,
                    .viewReports, .createReports,
                    .manageStaff]
        case .attendingPhysician, .nursePractitioner:
            return [.viewPatients, .editPatients, .createPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReferrals, .createReferrals,
                    .viewReports, .createReports,
                    .prescribe, .orderTests]
        case .fellow, .physicianAssistant:
            return [.viewPatients, .editPatients, .createPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReferrals, .createReferrals,
                    .viewReports,
                    .prescribe, .orderTests]
        case .resident:
            return [.viewPatients, .editPatients, .createPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReferrals,
                    .viewReports,
                    .orderTests]
        case .intern:
            return [.viewPatients, .editPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReferrals,
                    .viewReports]
        case .nurseManager:
            return [.viewPatients, .editPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReferrals,
                    .viewReports, .createReports,
                    .manageStaff]
        case .registeredNurse:
            return [.viewPatients, .editPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReferrals,
                    .viewReports]
        case .licensedPracticalNurse, .nurseAide:
            return [.viewPatients,
                    .viewAssessments,
                    .viewReports]
        case .pharmacist:
            return [.viewPatients,
                    .viewAssessments,
                    .viewReports,
                    .reviewPrescriptions]
        case .technician, .therapist:
            return [.viewPatients,
                    .viewAssessments, .completeAssessments,
                    .viewReports]
        case .caseManager, .socialWorker:
            return [.viewPatients,
                    .viewReferrals, .createReferrals,
                    .viewReports]
        case .administrativeStaff, .schedulingCoordinator:
            return [.viewPatients,
                    .viewReferrals,
                    .manageScheduling]
        case .referringPhysician, .consultant:
            return [.viewPatients,
                    .viewAssessments,
                    .viewReferrals,
                    .viewReports]
        case .readOnly:
            return [.viewPatients, .viewAssessments, .viewReports]
        }
    }

    var category: String {
        switch self {
        case .systemAdmin, .organizationAdmin, .facilityAdmin, .departmentHead:
            return "Administrative"
        case .attendingPhysician, .fellow, .resident, .intern:
            return "Physician"
        case .nurseManager, .registeredNurse, .licensedPracticalNurse, .nurseAide:
            return "Nursing"
        case .physicianAssistant, .nursePractitioner, .technician, .therapist, .pharmacist:
            return "Allied Health"
        case .caseManager, .socialWorker, .administrativeStaff, .schedulingCoordinator:
            return "Support"
        case .referringPhysician, .consultant, .readOnly:
            return "External"
        }
    }
}

// MARK: - Permissions

enum Permission: String, CaseIterable, Codable {
    // Patient
    case viewPatients = "View Patients"
    case editPatients = "Edit Patients"
    case createPatients = "Create Patients"
    case deletePatients = "Delete Patients"

    // Assessments
    case viewAssessments = "View Assessments"
    case completeAssessments = "Complete Assessments"
    case createAssessments = "Create Assessment Templates"

    // Referrals
    case viewReferrals = "View Referrals"
    case createReferrals = "Create Referrals"
    case manageReferrals = "Manage Referrals"

    // Reports
    case viewReports = "View Reports"
    case createReports = "Create Reports"
    case exportReports = "Export Reports"

    // Clinical
    case prescribe = "Prescribe Medications"
    case orderTests = "Order Tests"
    case reviewPrescriptions = "Review Prescriptions"

    // Administrative
    case manageStaff = "Manage Staff"
    case manageDepartments = "Manage Departments"
    case manageFacilities = "Manage Facilities"
    case manageOrganization = "Manage Organization"
    case manageScheduling = "Manage Scheduling"
    case viewAnalytics = "View Analytics"
    case viewAuditLogs = "View Audit Logs"
}

// MARK: - Encounter Type

/// Types of patient encounters
enum EncounterType: String, CaseIterable, Codable {
    case inpatientAdmission = "Inpatient Admission"
    case outpatientVisit = "Outpatient Visit"
    case emergencyVisit = "Emergency Visit"
    case observation = "Observation"
    case procedural = "Procedural"
    case consultation = "Consultation"
    case telehealth = "Telehealth"
    case preOperative = "Pre-Operative"
    case postOperative = "Post-Operative"
    case followUp = "Follow-Up"

    var icon: String {
        switch self {
        case .inpatientAdmission: return "bed.double.fill"
        case .outpatientVisit: return "person.fill"
        case .emergencyVisit: return "staroflife.fill"
        case .observation: return "eye.fill"
        case .procedural: return "scissors"
        case .consultation: return "bubble.left.and.bubble.right.fill"
        case .telehealth: return "video.fill"
        case .preOperative: return "clock.fill"
        case .postOperative: return "bandage.fill"
        case .followUp: return "calendar.badge.clock"
        }
    }
}

// MARK: - Encounter Status

enum EncounterStatus: String, CaseIterable, Codable {
    case scheduled = "Scheduled"
    case checkedIn = "Checked In"
    case inProgress = "In Progress"
    case awaitingResults = "Awaiting Results"
    case pendingDischarge = "Pending Discharge"
    case discharged = "Discharged"
    case cancelled = "Cancelled"
    case noShow = "No Show"

    var color: Color {
        switch self {
        case .scheduled: return MedicalColors.Surgery.scheduled
        case .checkedIn: return MedicalColors.PatientStatus.preOperative
        case .inProgress: return MedicalColors.Surgery.inProgress
        case .awaitingResults: return Color(hex: "F59E0B")
        case .pendingDischarge: return MedicalColors.PatientStatus.readyForDischarge
        case .discharged: return MedicalColors.PatientStatus.discharged
        case .cancelled: return MedicalColors.Surgery.cancelled
        case .noShow: return Color(hex: "6B7280")
        }
    }

    var isActive: Bool {
        switch self {
        case .checkedIn, .inProgress, .awaitingResults, .pendingDischarge:
            return true
        default:
            return false
        }
    }
}

// MARK: - Referral Status

enum ReferralStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case reviewed = "Reviewed"
    case accepted = "Accepted"
    case declined = "Declined"
    case scheduled = "Scheduled"
    case completed = "Completed"
    case cancelled = "Cancelled"

    var color: Color {
        switch self {
        case .pending: return Color(hex: "F59E0B")
        case .reviewed: return Color(hex: "3B82F6")
        case .accepted: return MedicalColors.Clinical.normal
        case .declined: return MedicalColors.Clinical.criticalValue
        case .scheduled: return MedicalColors.Surgery.scheduled
        case .completed: return MedicalColors.Surgery.completed
        case .cancelled: return MedicalColors.Surgery.cancelled
        }
    }
}

// MARK: - Referral Priority

enum ReferralPriority: String, CaseIterable, Codable {
    case routine = "Routine"
    case urgent = "Urgent"
    case emergent = "Emergent"
    case stat = "STAT"

    var color: Color {
        switch self {
        case .routine: return MedicalColors.Clinical.normal
        case .urgent: return Color(hex: "F59E0B")
        case .emergent: return MedicalColors.Clinical.abnormal
        case .stat: return MedicalColors.Clinical.criticalValue
        }
    }

    var responseTimeHours: Int {
        switch self {
        case .routine: return 72
        case .urgent: return 24
        case .emergent: return 4
        case .stat: return 1
        }
    }
}

// MARK: - Assessment Type

/// All available clinical assessments across departments
enum AssessmentType: String, CaseIterable, Codable, Identifiable {
    // Surgical Risk
    case rcri = "RCRI"
    case surgicalApgar = "Surgical Apgar"
    case asaPhysicalStatus = "ASA Physical Status"
    case possum = "POSSUM"
    case capriniVTE = "Caprini VTE"
    case mallampati = "Mallampati"
    case stopBang = "STOP-BANG"

    // Emergency Medicine
    case esi = "ESI Triage"
    case glasgowComaScale = "Glasgow Coma Scale"
    case nihss = "NIHSS"
    case heart = "HEART Score"
    case curb65 = "CURB-65"
    case wells = "Wells Score"
    case pecarn = "PECARN"

    // Cardiology
    case grace = "GRACE Score"
    case timi = "TIMI Risk"
    case chadsVasc = "CHA₂DS₂-VASc"
    case hasBled = "HAS-BLED"
    case dukeActivityStatus = "Duke Activity Status"
    case nyha = "NYHA Classification"

    // Obstetrics
    case bishopScore = "Bishop Score"
    case apgarNewborn = "APGAR (Newborn)"
    case edinburghPostnatal = "Edinburgh Postnatal"

    // Oncology
    case ecogPerformance = "ECOG Performance"
    case karnofskyPerformance = "Karnofsky Performance"
    case tnmStaging = "TNM Staging"

    // Neurology
    case huntHess = "Hunt-Hess"
    case modifiedRankin = "Modified Rankin"

    // Critical Care
    case apacheII = "APACHE II"
    case sofa = "SOFA Score"
    case rass = "RASS"
    case cam_icu = "CAM-ICU"

    // Pulmonology
    case psi = "Pneumonia Severity Index"
    case bode = "BODE Index"

    // Psychiatry
    case phq9 = "PHQ-9"
    case gad7 = "GAD-7"
    case auditC = "AUDIT-C"
    case cows = "COWS"

    // Universal
    case news2 = "NEWS2"

    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .rcri: return "Revised Cardiac Risk Index"
        case .surgicalApgar: return "Surgical Apgar Score"
        case .asaPhysicalStatus: return "ASA Physical Status Classification"
        case .possum: return "POSSUM Scoring System"
        case .capriniVTE: return "Caprini VTE Risk Assessment"
        case .mallampati: return "Mallampati Classification"
        case .stopBang: return "STOP-BANG Sleep Apnea"
        case .esi: return "Emergency Severity Index"
        case .glasgowComaScale: return "Glasgow Coma Scale"
        case .nihss: return "NIH Stroke Scale"
        case .heart: return "HEART Score for Chest Pain"
        case .curb65: return "CURB-65 Pneumonia Severity"
        case .wells: return "Wells Criteria"
        case .pecarn: return "PECARN Pediatric Head Injury"
        case .grace: return "GRACE ACS Risk Score"
        case .timi: return "TIMI Risk Score"
        case .chadsVasc: return "CHA₂DS₂-VASc Stroke Risk"
        case .hasBled: return "HAS-BLED Bleeding Risk"
        case .dukeActivityStatus: return "Duke Activity Status Index"
        case .nyha: return "NYHA Functional Classification"
        case .bishopScore: return "Bishop Score for Cervical Ripening"
        case .apgarNewborn: return "APGAR Score (Newborn)"
        case .edinburghPostnatal: return "Edinburgh Postnatal Depression Scale"
        case .ecogPerformance: return "ECOG Performance Status"
        case .karnofskyPerformance: return "Karnofsky Performance Scale"
        case .tnmStaging: return "TNM Cancer Staging"
        case .huntHess: return "Hunt-Hess Classification"
        case .modifiedRankin: return "Modified Rankin Scale"
        case .apacheII: return "APACHE II Score"
        case .sofa: return "Sequential Organ Failure Assessment"
        case .rass: return "Richmond Agitation-Sedation Scale"
        case .cam_icu: return "Confusion Assessment Method for ICU"
        case .psi: return "Pneumonia Severity Index"
        case .bode: return "BODE Index for COPD"
        case .phq9: return "Patient Health Questionnaire-9"
        case .gad7: return "Generalized Anxiety Disorder-7"
        case .auditC: return "Alcohol Use Disorders Identification"
        case .cows: return "Clinical Opiate Withdrawal Scale"
        case .news2: return "National Early Warning Score 2"
        }
    }

    var category: String {
        switch self {
        case .rcri, .surgicalApgar, .asaPhysicalStatus, .possum, .capriniVTE, .mallampati, .stopBang:
            return "Surgical Risk"
        case .esi, .glasgowComaScale, .nihss, .heart, .curb65, .wells, .pecarn:
            return "Emergency Medicine"
        case .grace, .timi, .chadsVasc, .hasBled, .dukeActivityStatus, .nyha:
            return "Cardiology"
        case .bishopScore, .apgarNewborn, .edinburghPostnatal:
            return "Obstetrics"
        case .ecogPerformance, .karnofskyPerformance, .tnmStaging:
            return "Oncology"
        case .huntHess, .modifiedRankin:
            return "Neurology"
        case .apacheII, .sofa, .rass, .cam_icu:
            return "Critical Care"
        case .psi, .bode:
            return "Pulmonology"
        case .phq9, .gad7, .auditC, .cows:
            return "Psychiatry"
        case .news2:
            return "Universal"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension OrganizationType {
    static var preview: OrganizationType { .hospital }
}

extension DepartmentType {
    static var preview: DepartmentType { .generalSurgery }
}

extension StaffRole {
    static var preview: StaffRole { .attendingPhysician }
}
#endif
