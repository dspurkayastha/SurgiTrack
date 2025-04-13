import SwiftUI
import CoreData

struct AddPatientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    // Form navigation state
    @State private var currentStep = 0
    @State private var showingSaveConfirmation = false
    @State private var isSaving = false
    
    // MARK: - Patient Basic Info
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var gender = ""
    @State private var medicalRecordNumber = ""
    @State private var bloodType = ""
    @State private var height: Double = 170
    @State private var weight: Double = 70
    @State private var bedNumber = ""
    
    // MARK: - Contact Information
    @State private var phone = ""
    @State private var contactInfo = "" // Email
    @State private var address = ""
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""
    
    // MARK: - Insurance Information
    @State private var insuranceProvider = ""
    @State private var insurancePolicyNumber = ""
    @State private var insuranceDetails = ""
    
    // MARK: - Initial Presentation
    @State private var presentationDate = Date()
    @State private var chiefComplaint = ""
    @State private var historyOfPresentIllness = ""
    @State private var pastMedicalHistory = ""
    @State private var physicalExamination = ""
    @State private var initialDiagnosis = ""
    @State private var labTests = ""
    @State private var imagingReports = ""
    @State private var medications = ""
    @State private var allergies = ""
    
    // MARK: - Profile Image
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    
    // Form section data
    private let formSections = ["Patient Information", "Contact Information", "Insurance Information", "Initial Presentation"]
    private let genderOptions = ["Male", "Female", "Non-binary", "Other", "Prefer not to say"]
    private let bloodTypeOptions = ["Unknown", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    var body: some View {
        // Wrap entire content in BaseScreenTemplate
        BaseScreenTemplate(title: "Add Patient") { 
            VStack(spacing: 20) {
                    // Progress indicators
                    HStack(spacing: 4) {
                        ForEach(0..<formSections.count, id: \.self) { index in
                        ModernProgressIndicator(
                            progress: index == currentStep ? 1 : (index < currentStep ? 1 : 0),
                            style: .linear,
                            size: .medium
                        )
                        .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                // TabView now sits inside BaseScreenTemplate's content
                    TabView(selection: $currentStep) {
                    basicInformationTab
                        .tag(0)
                    contactInformationTab
                        .tag(1)
                    insuranceInformationTab
                        .tag(2)
                    initialPresentationTab
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                // Give the TabView flexible height to fill available space
                .frame(maxHeight: .infinity) 
                
                // Navigation buttons at the bottom
                HStack {
                    if currentStep > 0 {
                        ModernButton(
                            "Previous",
                            style: .secondary
                        ) {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }
                    
                    if currentStep < formSections.count - 1 {
                        ModernButton(
                            "Next",
                            style: .primary
                        ) {
                            withAnimation {
                                    currentStep += 1
                            }
                        }
                    } else {
                        ModernButton(
                            "Save Patient",
                            style: .primary,
                            isLoading: isSaving
                        ) {
                            savePatient()
                        }
                        .disabled(isSaving)
                    }
                }
                .padding(.bottom) // Add padding to keep buttons off edge
                .padding(.horizontal)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
        }
        // Apply theme bridge to the BaseScreenTemplate
        .withThemeBridge(appState: appState, colorScheme: colorScheme)
        // Ignore keyboard safe area for the whole screen
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: - Tab Views
    // Add ScrollView INSIDE each tab view if content might overflow
    private var basicInformationTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Image Selector
                ModernCard {
                    VStack(spacing: 16) {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                                .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        ModernButton(
                            profileImage == nil ? "Add Photo" : "Change Photo",
                            style: .secondary
                        ) {
                            showingImagePicker = true
                        }
                    }
                    .padding()
                }
                
                ModernFormSection(title: "Personal Details") {
                    VStack(spacing: 16) {
                        ModernFormField(
                            title: "First Name",
                            text: $firstName,
                            icon: "person.fill",
                            isRequired: true
                        )
                        
                        ModernFormField(
                            title: "Last Name",
                            text: $lastName,
                            icon: "person.fill",
                            isRequired: true
                        )
                        
                        ModernFormDatePicker(
                            title: "Date of Birth",
                            selection: $dateOfBirth
                        )
                        
                        ModernFormPicker(
                            title: "Gender",
                            selection: $gender,
                            isRequired: false
                        ) {
                            ForEach(genderOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        
                        ModernFormField(
                            title: "Medical Record Number",
                            text: $medicalRecordNumber,
                            icon: "number",
                            isRequired: true
                        )
                        
                        ModernFormPicker(
                            title: "Blood Type",
                            selection: $bloodType,
                            isRequired: false
                        ) {
                            ForEach(bloodTypeOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        
            HStack {
                            VStack(alignment: .leading) {
                                Text("Height (cm)")
                                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                                ModernTextField(
                                    title: "Height",
                                    placeholder: "Height",
                                    text: Binding(
                                        get: { String(format: "%.1f", height) },
                                        set: { if let value = Double($0) { height = value } }
                                    ),
                                    icon: "ruler"
                                )
                                .keyboardType(.decimalPad)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Weight (kg)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ModernTextField(
                                    title: "Weight",
                                    placeholder: "Weight",
                                    text: Binding(
                                        get: { String(format: "%.1f", weight) },
                                        set: { if let value = Double($0) { weight = value } }
                                    ),
                                    icon: "scalemass"
                                )
                                .keyboardType(.decimalPad)
                            }
                        }
                        
                        ModernFormField(
                            title: "Bed Number",
                            text: $bedNumber,
                            icon: "bed.double"
                        )
                    }
                }
            }
            .padding() // Padding for the ScrollView content
        }
    }
    
    private var contactInformationTab: some View {
        ScrollView { // Add ScrollView
            VStack(spacing: 20) {
                ModernFormSection(title: "Contact Information") {
                    VStack(spacing: 16) {
                        ModernFormField(
                            title: "Phone Number",
                            text: $phone,
                            icon: "phone.fill",
                            keyboardType: .phonePad
                        )
                        
                        ModernFormField(
                            title: "Email",
                            text: $contactInfo,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )
                        
                        ModernFormField(
                            title: "Home Address",
                            text: $address,
                            icon: "house.fill",
                            isMultiline: true
                        )
                    }
                }
                
                ModernFormSection(title: "Emergency Contact") {
                    VStack(spacing: 16) {
                        ModernFormField(
                            title: "Contact Name",
                            text: $emergencyContactName,
                            icon: "person.crop.circle.fill.badge.exclamationmark"
                        )
                        
                        ModernFormField(
                            title: "Contact Phone",
                            text: $emergencyContactPhone,
                            icon: "phone.fill",
                            keyboardType: .phonePad
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var insuranceInformationTab: some View {
        ScrollView { // Add ScrollView
            VStack(spacing: 20) {
                ModernFormSection(title: "Insurance Details") {
                    VStack(spacing: 16) {
                        ModernFormField(
                            title: "Insurance Provider",
                            text: $insuranceProvider,
                            icon: "shield.fill"
                        )
                        
                        ModernFormField(
                            title: "Policy Number",
                            text: $insurancePolicyNumber,
                            icon: "number"
                        )
                        
                        ModernFormField(
                            title: "Additional Details",
                            text: $insuranceDetails,
                            icon: "doc.text.fill",
                            isMultiline: true
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var initialPresentationTab: some View {
        ScrollView { // Add ScrollView
            VStack(spacing: 20) {
                ModernFormSection(title: "Initial Presentation") {
                    VStack(spacing: 16) {
                        ModernFormDatePicker(
                            title: "Presentation Date",
                            selection: $presentationDate
                        )
                        
                        ModernFormField(
                            title: "Chief Complaint",
                            text: $chiefComplaint,
                            icon: "exclamationmark.triangle.fill",
                            isMultiline: true
                        )
                        
                        ModernFormField(
                            title: "History of Present Illness",
                            text: $historyOfPresentIllness,
                            icon: "clock.fill",
                            isMultiline: true
                        )
                        
                        ModernFormField(
                            title: "Past Medical History",
                            text: $pastMedicalHistory,
                            icon: "list.bullet.clipboard.fill",
                            isMultiline: true
                        )
                        
                        ModernFormField(
                            title: "Physical Examination",
                            text: $physicalExamination,
                            icon: "stethoscope",
                            isMultiline: true
                        )
                        
                        ModernFormField(
                            title: "Initial Diagnosis",
                            text: $initialDiagnosis,
                            icon: "cross.case.fill",
                            isMultiline: true
                        )
                        
                        ModernFormField(
                            title: "Lab Tests",
                            text: $labTests,
                            icon: "testtube.2",
                            isMultiline: true
                        )
                        
                        ModernFormField(
                            title: "Imaging Reports",
                            text: $imagingReports,
                            icon: "photo.fill",
                            isMultiline: true
                        )
                        
                        ModernFormField(
                            title: "Medications",
                            text: $medications,
                            icon: "pills.fill",
                            isMultiline: true
                        )
                        
                        ModernFormField(
                            title: "Allergies",
                            text: $allergies,
                            icon: "allergens",
                            isMultiline: true
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func savePatient() {
        isSaving = true
        
        // Validate required fields
        guard !firstName.isEmpty, !lastName.isEmpty, !medicalRecordNumber.isEmpty else {
            appState.showError("Please fill in all required fields")
            isSaving = false
            return
        }
        
        // Create new patient
        let patient = Patient(context: viewContext)
        patient.firstName = firstName
        patient.lastName = lastName
        patient.dateOfBirth = dateOfBirth
        patient.gender = gender
        patient.medicalRecordNumber = medicalRecordNumber
        patient.bloodType = bloodType
        patient.height = height
        patient.weight = weight
        patient.bedNumber = bedNumber
        patient.phone = phone
        patient.contactInfo = contactInfo
        patient.address = address
        patient.emergencyContactName = emergencyContactName
        patient.emergencyContactPhone = emergencyContactPhone
        patient.insuranceProvider = insuranceProvider
        patient.insurancePolicyNumber = insurancePolicyNumber
        patient.insuranceDetails = insuranceDetails
        
        // Save profile image
        if let imageData = profileImage?.jpegData(compressionQuality: 0.8) {
            patient.profileImageData = imageData
        }
        
        // Create initial presentation
        let presentation = InitialPresentation(context: viewContext)
        presentation.presentationDate = presentationDate
        presentation.chiefComplaint = chiefComplaint
        presentation.historyOfPresentIllness = historyOfPresentIllness
        presentation.pastMedicalHistory = pastMedicalHistory
        presentation.physicalExamination = physicalExamination
        presentation.initialDiagnosis = initialDiagnosis
        presentation.labTests = labTests
        presentation.imagingReports = imagingReports
        presentation.medications = medications
        presentation.allergies = allergies
        presentation.patient = patient
        
        // Save context
                do {
                    try viewContext.save()
            appState.showSuccess("Patient added successfully")
            dismiss()
                } catch {
            appState.showError("Failed to save patient: \(error.localizedDescription)")
                    isSaving = false
        }
    }
}

#Preview {
    AddPatientView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .withThemeBridge(appState: AppState(), colorScheme: .light)
}
