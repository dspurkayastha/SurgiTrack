# SurgiTrack → MedTrack: B2B Healthcare Platform Expansion

## Executive Summary

Transform SurgiTrack from a surgery-specific application into **MedTrack** - a comprehensive, multi-tenant B2B healthcare platform serving all hospital departments and patient types. This expansion creates a scalable SaaS product that hospitals and healthcare systems can deploy organization-wide.

---

## Market Opportunity

### Current Limitations
- Single-department focus (Surgery)
- Limited to surgical patient workflows
- No multi-organization support
- Fixed assessment tools (surgical risk calculators only)

### B2B Value Proposition
- **One Platform, All Departments**: Unified patient management across the entire healthcare organization
- **Reduced Training Costs**: Consistent UI/UX means staff can move between departments seamlessly
- **Data Continuity**: Patient records flow automatically between departments
- **Customizable Workflows**: Each department configures their specific needs
- **Enterprise Analytics**: Organization-wide insights and reporting

---

## Target Departments & Specialties

### Tier 1: High-Priority Departments
| Department | Key Features | Assessment Tools |
|------------|-------------|------------------|
| **Surgery** (existing) | Pre-op, Operative, Post-op | RCRI, Apgar, ASA, POSSUM, Caprini |
| **Emergency Medicine** | Triage, Trauma, Acute Care | ESI, HEART, NIHSS, GCS |
| **Internal Medicine** | Chronic Disease, Admissions | NEWS2, CURB-65, Wells Score |
| **Cardiology** | Cardiac Care, Interventions | GRACE, TIMI, CHA₂DS₂-VASc |

### Tier 2: Specialty Departments
| Department | Key Features | Assessment Tools |
|------------|-------------|------------------|
| **Obstetrics** | Prenatal, L&D, Postnatal | Bishop Score, APGAR (newborn) |
| **Oncology** | Chemo Tracking, Staging | ECOG, Karnofsky, TNM Staging |
| **Orthopedics** | Fracture Care, Joint Replacement | Oxford Hip/Knee, WOMAC |
| **Pediatrics** | Growth Tracking, Immunizations | PEWS, Denver II |
| **Neurology** | Stroke, Seizure Management | NIHSS, Hunt-Hess, mRS |

### Tier 3: Support Departments
| Department | Key Features |
|------------|-------------|
| **Radiology** | Imaging Orders, Report Distribution |
| **Pathology** | Lab Orders, Result Management |
| **Pharmacy** | Medication Orders, Interactions |
| **Rehabilitation** | PT/OT Sessions, Progress Tracking |
| **Psychiatry** | Mental Health Assessments, Care Plans |

---

## Technical Architecture

### 1. Multi-Tenant Data Model

```
Organization (Hospital/Health System)
├── Facilities (Physical Locations)
│   ├── Departments
│   │   ├── Staff (Role-Based)
│   │   ├── Workflows
│   │   ├── Assessment Templates
│   │   └── Dashboard Configurations
│   └── Shared Resources
│       ├── Patients (Universal Record)
│       ├── Encounters
│       └── Referrals
└── Organization Settings
    ├── Branding
    ├── Compliance Rules
    └── Integration Configs
```

### 2. Core Data Entities

#### Organization Model
```swift
Organization
├── id: UUID
├── name: String
├── type: OrganizationType (hospital, clinic, health_system)
├── subscriptionTier: SubscriptionTier
├── facilities: [Facility]
├── settings: OrganizationSettings
└── createdAt: Date
```

#### Department Model
```swift
Department
├── id: UUID
├── name: String
├── type: DepartmentType (enum with all specialties)
├── facility: Facility
├── workflows: [WorkflowTemplate]
├── assessmentTemplates: [AssessmentTemplate]
├── staff: [StaffMember]
├── settings: DepartmentSettings
└── isActive: Bool
```

#### Universal Patient Record
```swift
Patient
├── id: UUID
├── demographics: PatientDemographics
├── organization: Organization
├── encounters: [Encounter]  // Per-department visits
├── medicalHistory: MedicalHistory
├── allergies: [Allergy]
├── medications: [Medication]
├── documents: [Document]
└── referrals: [Referral]
```

#### Encounter Model (Department-Specific Visit)
```swift
Encounter
├── id: UUID
├── patient: Patient
├── department: Department
├── type: EncounterType (admission, outpatient, emergency, etc.)
├── status: EncounterStatus
├── admissionDate: Date
├── dischargeDate: Date?
├── attendingProvider: StaffMember
├── assessments: [Assessment]
├── notes: [ClinicalNote]
├── orders: [Order]
└── outcomes: [Outcome]
```

### 3. Role-Based Access Control (RBAC)

```
Roles Hierarchy:
├── System Admin (Platform-wide)
├── Organization Admin
│   ├── Facility Admin
│   │   ├── Department Head
│   │   │   ├── Attending Physician
│   │   │   ├── Resident
│   │   │   ├── Nurse Manager
│   │   │   │   ├── Registered Nurse
│   │   │   │   └── Licensed Practical Nurse
│   │   │   ├── Technician
│   │   │   └── Administrative Staff
│   │   └── Read-Only Access
│   └── Cross-Department Roles
│       ├── Hospitalist
│       ├── Case Manager
│       └── Quality Assurance
└── External Roles
    ├── Referring Physician
    └── Patient Portal Access
```

### 4. Modular Assessment Framework

```swift
AssessmentTemplate
├── id: UUID
├── name: String
├── category: AssessmentCategory
├── departmentTypes: [DepartmentType]  // Which departments can use
├── sections: [AssessmentSection]
├── scoringLogic: ScoringConfiguration
├── riskStratification: [RiskLevel]
└── version: Int

AssessmentSection
├── title: String
├── fields: [AssessmentField]
└── conditionalLogic: ConditionalRules?

AssessmentField
├── id: String
├── type: FieldType (numeric, choice, multiSelect, text, date)
├── label: String
├── options: [FieldOption]?
├── validation: ValidationRules
├── scoringWeight: Double?
└── required: Bool
```

---

## Implementation Phases

### Phase 1: Platform Foundation (Weeks 1-4)
**Goal**: Multi-tenant architecture with department framework

#### Week 1-2: Data Model Expansion
- [ ] Create Organization, Facility, Department CoreData entities
- [ ] Create StaffMember with role system
- [ ] Create Encounter model (replaces surgery-specific model)
- [ ] Create Referral model for inter-department transfers
- [ ] Migrate existing Patient model to universal structure

#### Week 3-4: Authentication & Authorization
- [ ] Implement organization-aware authentication
- [ ] Build role-based permission system
- [ ] Create department access controls
- [ ] Add staff invitation/onboarding flow

### Phase 2: Department Configuration (Weeks 5-8)
**Goal**: Configurable department system with templates

#### Week 5-6: Department Templates
- [ ] Create department type definitions (all specialties)
- [ ] Build department setup wizard
- [ ] Implement workflow template system
- [ ] Create department-specific settings

#### Week 7-8: Assessment Framework
- [ ] Build modular assessment engine
- [ ] Create assessment template builder
- [ ] Port surgical risk calculators to new framework
- [ ] Add 10+ new department-specific assessments

### Phase 3: Inter-Department Features (Weeks 9-12)
**Goal**: Seamless cross-department collaboration

#### Week 9-10: Referral System
- [ ] Build referral creation flow
- [ ] Implement referral acceptance/rejection
- [ ] Add referral tracking and notifications
- [ ] Create referral analytics

#### Week 11-12: Shared Patient Timeline
- [ ] Build unified patient timeline view
- [ ] Add cross-department encounter visibility
- [ ] Implement clinical handoff documentation
- [ ] Create care team collaboration features

### Phase 4: Enterprise Features (Weeks 13-16)
**Goal**: B2B-ready enterprise capabilities

#### Week 13-14: Analytics & Reporting
- [ ] Build organization-wide dashboard
- [ ] Create department comparison analytics
- [ ] Add quality metrics tracking
- [ ] Implement custom report builder

#### Week 15-16: Enterprise Administration
- [ ] Multi-facility management
- [ ] White-labeling/branding options
- [ ] API for external integrations
- [ ] Audit logging and compliance reports

---

## Department-Specific Features

### Emergency Medicine Module
```
Triage System:
├── ESI (Emergency Severity Index) - 5-level triage
├── Chief Complaint Categorization
├── Vital Signs with Auto-Alert
└── Waiting Time Management

Assessments:
├── HEART Score (Chest Pain)
├── NIHSS (Stroke)
├── GCS (Glasgow Coma Scale)
├── PECARN (Pediatric Head Trauma)
└── Ottawa Rules (Ankle/Knee)

Features:
├── Trauma Activation Protocol
├── Bed Management
├── Department Census View
└── Ambulance Arrival Tracking
```

### Cardiology Module
```
Cardiac Care:
├── Chest Pain Protocol Tracking
├── Cardiac Catheterization Records
├── Pacemaker/ICD Management
└── Heart Failure Clinic

Assessments:
├── GRACE Score (ACS Risk)
├── TIMI Risk Score
├── CHA₂DS₂-VASc (Stroke in AFib)
├── HAS-BLED (Bleeding Risk)
└── Duke Activity Status Index

Features:
├── ECG Attachment & Annotation
├── Cardiac Rehab Tracking
├── Anticoagulation Management
└── Device Clinic Scheduling
```

### Obstetrics Module
```
Prenatal Care:
├── Gestational Age Calculator
├── Prenatal Visit Schedule
├── Ultrasound Records
└── Lab Tracking (Prenatal Panel)

Labor & Delivery:
├── Partogram (Labor Progress)
├── Fetal Monitoring Integration
├── Bishop Score
├── Delivery Documentation
└── APGAR Scoring (Newborn)

Postpartum:
├── Maternal Recovery Tracking
├── Newborn Care Records
├── Breastfeeding Support
└── Postpartum Depression Screening
```

### Oncology Module
```
Cancer Care:
├── TNM Staging Documentation
├── Chemotherapy Protocol Tracking
├── Radiation Therapy Records
└── Clinical Trial Enrollment

Assessments:
├── ECOG Performance Status
├── Karnofsky Performance Scale
├── Palliative Prognostic Score
└── Symptom Assessment Scales

Features:
├── Treatment Cycle Calendar
├── Toxicity Monitoring
├── Tumor Board Preparation
└── Survivorship Care Plans
```

---

## Database Schema Changes

### New CoreData Entities

```
Organization
├── id: UUID
├── name: String
├── type: String (hospital, clinic, health_system)
├── subscriptionTier: String
├── logoData: Data?
├── primaryColor: String?
├── facilities: [Facility]
├── createdAt: Date

Facility
├── id: UUID
├── name: String
├── address: String
├── organization: Organization
├── departments: [Department]
├── isActive: Bool

Department
├── id: UUID
├── name: String
├── type: String (specialty enum)
├── facility: Facility
├── staff: [StaffMember]
├── settings: Data (JSON)
├── isActive: Bool

StaffMember
├── id: UUID
├── userId: String (Clerk ID)
├── firstName: String
├── lastName: String
├── email: String
├── role: String
├── department: Department
├── permissions: Data (JSON)
├── isActive: Bool

Encounter
├── id: UUID
├── patient: Patient
├── department: Department
├── type: String (admission, outpatient, etc.)
├── status: String
├── admissionDate: Date
├── dischargeDate: Date?
├── attendingProvider: StaffMember
├── chiefComplaint: String?
├── notes: [ClinicalNote]

Referral
├── id: UUID
├── patient: Patient
├── fromDepartment: Department
├── toDepartment: Department
├── referringProvider: StaffMember
├── reason: String
├── priority: String
├── status: String
├── createdAt: Date
├── acceptedAt: Date?

AssessmentTemplate
├── id: UUID
├── name: String
├── category: String
├── departmentTypes: [String]
├── schemaJSON: Data
├── scoringLogicJSON: Data
├── version: Int
├── isActive: Bool

AssessmentResult
├── id: UUID
├── template: AssessmentTemplate
├── encounter: Encounter
├── completedBy: StaffMember
├── responsesJSON: Data
├── score: Double?
├── riskLevel: String?
├── completedAt: Date
```

---

## UI/UX Changes

### 1. Organization-Aware Login
- Organization selection/lookup
- Department selection after login
- Quick department switching

### 2. Department Dashboard
- Department-specific metrics
- Today's census/schedule
- Pending actions (assessments, referrals)
- Quick patient search

### 3. Universal Patient View
- Demographics header (consistent)
- Department encounters tabs
- Unified timeline
- Cross-department referral history

### 4. Assessment Library
- Browse by department
- Favorites/frequently used
- Quick-start templates
- Assessment history

---

## Pricing Model (B2B SaaS)

### Tier Structure
```
Starter ($X/month)
├── 1 Facility
├── Up to 3 Departments
├── Up to 25 Staff Members
├── Core Assessment Library
└── Email Support

Professional ($XX/month)
├── Up to 5 Facilities
├── Unlimited Departments
├── Up to 200 Staff Members
├── Full Assessment Library
├── Custom Assessments
├── Analytics Dashboard
└── Priority Support

Enterprise (Custom)
├── Unlimited Facilities
├── Unlimited Staff
├── White-Labeling
├── API Access
├── Custom Integrations
├── Dedicated Support
└── On-Premise Option
```

---

## Success Metrics

### Platform Adoption
- Organizations onboarded
- Departments activated
- Active users per organization
- Assessment completion rate

### Clinical Value
- Time to complete assessments
- Referral response time
- Cross-department visibility utilization
- Patient record completeness

### Business Metrics
- Monthly Recurring Revenue (MRR)
- Customer Acquisition Cost (CAC)
- Net Revenue Retention (NRR)
- Churn Rate

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Scope creep | Phased rollout, MVP per department |
| Data migration complexity | Backward-compatible schema |
| User adoption | Department champions program |
| Compliance (HIPAA) | Audit logging, encryption, access controls |
| Performance at scale | Lazy loading, pagination, background sync |

---

## Next Steps

1. **Approve architecture plan**
2. **Begin Phase 1 implementation**
3. **Identify pilot hospital partner**
4. **Define MVP feature set for initial departments**
5. **Establish compliance review process**

---

*Document Version: 1.0*
*Last Updated: December 26, 2025*
