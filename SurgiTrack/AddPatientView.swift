import SwiftUI

struct AddPatientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Form navigation state
    @State private var currentStep = 0
    @State private var showingSaveConfirmation = false
    @State private var animated = false
    
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
    
    // MARK: - State management
    @State private var showingAlert = false
    @State private var errorMessage = ""
    @State private var isFormValid = false
    @State private var isSaving = false
    
    // Form section data
    private let formSections = ["Patient Information", "Contact Information", "Insurance Information", "Initial Presentation"]
    private let genderOptions = ["Male", "Female", "Non-binary", "Other", "Prefer not to say"]
    private let bloodTypeOptions = ["Unknown", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main form content
                VStack(spacing: 0) {
                    // Progress indicators
                    HStack(spacing: 4) {
                        ForEach(0..<formSections.count, id: \.self) { index in
                            ProgressIndicator(
                                isActive: index == currentStep,
                                isCompleted: index < currentStep,
                                text: formSections[index]
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    TabView(selection: $currentStep) {
                        // MARK: Tab 1 - Basic Information
                        ScrollView {
                            VStack(spacing: 20) {
                                // Profile Image Selector
                                profileImageView
                                
                                // Basic Information Form
                                GroupBox(label: groupLabel("PERSONAL DETAILS")) {
                                    VStack(spacing: 16) {
                                        formField(title: "First Name", text: $firstName, required: true, iconName: "person.fill")
                                        formField(title: "Last Name", text: $lastName, required: true, iconName: "person.fill")
                                        
                                        datePickerField(title: "Date of Birth", date: $dateOfBirth, iconName: "calendar")
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Gender")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            HStack {
                                                Image(systemName: "person.fill.questionmark")
                                                    .foregroundColor(.blue)
                                                
                                                Picker("Gender", selection: $gender) {
                                                    Text("Select Gender").tag("")
                                                    ForEach(genderOptions, id: \.self) { option in
                                                        Text(option).tag(option)
                                                    }
                                                }
                                                .pickerStyle(MenuPickerStyle())
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(10)
                                            .background(Color(UIColor.systemBackground))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                        
                                        formField(title: "Medical Record Number", text: $medicalRecordNumber, required: true, iconName: "number")
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Blood Type")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            HStack {
                                                Image(systemName: "drop.fill")
                                                    .foregroundColor(.blue)
                                                
                                                Picker("Blood Type", selection: $bloodType) {
                                                    Text("Select Blood Type").tag("")
                                                    ForEach(bloodTypeOptions, id: \.self) { option in
                                                        Text(option).tag(option)
                                                    }
                                                }
                                                .pickerStyle(MenuPickerStyle())
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(10)
                                            .background(Color(UIColor.systemBackground))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                        
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("Height (cm)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                HStack {
                                                    Image(systemName: "ruler")
                                                        .foregroundColor(.blue)
                                                    
                                                    TextField("Height", value: $height, formatter: NumberFormatter())
                                                        .keyboardType(.decimalPad)
                                                        .padding(10)
                                                        .background(Color(UIColor.systemBackground))
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                        )
                                                }
                                            }
                                            
                                            VStack(alignment: .leading) {
                                                Text("Weight (kg)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                HStack {
                                                    Image(systemName: "scalemass")
                                                        .foregroundColor(.blue)
                                                    
                                                    TextField("Weight", value: $weight, formatter: NumberFormatter())
                                                        .keyboardType(.decimalPad)
                                                        .padding(10)
                                                        .background(Color(UIColor.systemBackground))
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8)
                                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                        )
                                                }
                                            }
                                        }
                                        
                                        formField(title: "Bed Number", text: $bedNumber, iconName: "bed.double")
                                    }
                                    .padding()
                                }
                                
                                nextButton(text: "Contact Information")
                            }
                            .padding()
                        }
                        .tag(0)
                        
                        // MARK: Tab 2 - Contact Information
                        ScrollView {
                            VStack(spacing: 20) {
                                GroupBox(label: groupLabel("CONTACT INFORMATION")) {
                                    VStack(spacing: 16) {
                                        formField(title: "Phone Number", text: $phone, iconName: "phone.fill")
                                            .keyboardType(.phonePad)
                                        
                                        formField(title: "Email", text: $contactInfo, iconName: "envelope.fill")
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .textInputAutocapitalization(.never)
                                        
                                        formField(title: "Home Address", text: $address, multiline: true, iconName: "house.fill")
                                    }
                                    .padding()
                                }
                                
                                GroupBox(label: groupLabel("EMERGENCY CONTACT")) {
                                    VStack(spacing: 16) {
                                        formField(title: "Contact Name", text: $emergencyContactName, iconName: "person.crop.circle.fill.badge.exclamationmark")
                                        
                                        formField(title: "Contact Phone", text: $emergencyContactPhone, iconName: "phone.fill")
                                            .keyboardType(.phonePad)
                                    }
                                    .padding()
                                }
                                
                                HStack {
                                    backButton()
                                    nextButton(text: "Insurance Information")
                                }
                            }
                            .padding()
                        }
                        .tag(1)
                        
                        // MARK: Tab 3 - Insurance Information
                        ScrollView {
                            VStack(spacing: 20) {
                                GroupBox(label: groupLabel("INSURANCE DETAILS")) {
                                    VStack(spacing: 16) {
                                        formField(title: "Insurance Provider", text: $insuranceProvider, iconName: "shield.fill")
                                        
                                        formField(title: "Policy Number", text: $insurancePolicyNumber, iconName: "doc.text.fill")
                                        
                                        formField(title: "Additional Details", text: $insuranceDetails, multiline: true, iconName: "doc.text.fill")
                                    }
                                    .padding()
                                }
                                
                                HStack {
                                    backButton()
                                    nextButton(text: "Initial Presentation")
                                }
                            }
                            .padding()
                        }
                        .tag(2)
                        
                        // MARK: Tab 4 - Initial Presentation
                        ScrollView {
                            VStack(spacing: 20) {
                                GroupBox(label: groupLabel("INITIAL ASSESSMENT")) {
                                    VStack(spacing: 16) {
                                        datePickerField(title: "Presentation Date", date: $presentationDate, iconName: "calendar")
                                        
                                        formField(title: "Chief Complaint", text: $chiefComplaint, multiline: true, iconName: "exclamationmark.bubble.fill")
                                        
                                        formField(title: "History of Present Illness", text: $historyOfPresentIllness, multiline: true, iconName: "text.book.closed.fill")
                                        
                                        formField(title: "Physical Examination", text: $physicalExamination, multiline: true, iconName: "stethoscope")
                                        
                                        formField(title: "Initial Diagnosis", text: $initialDiagnosis, multiline: true, iconName: "cross.case.fill")
                                    }
                                    .padding()
                                }
                                
                                GroupBox(label: groupLabel("MEDICAL HISTORY")) {
                                    VStack(spacing: 16) {
                                        formField(title: "Past Medical History", text: $pastMedicalHistory, multiline: true, iconName: "heart.text.square.fill")
                                        
                                        formField(title: "Allergies", text: $allergies, multiline: true, iconName: "allergens")
                                        
                                        formField(title: "Current Medications", text: $medications, multiline: true, iconName: "pills.fill")
                                    }
                                    .padding()
                                }
                                
                                GroupBox(label: groupLabel("DIAGNOSTIC TESTS")) {
                                    VStack(spacing: 16) {
                                        formField(title: "Laboratory Tests", text: $labTests, multiline: true, iconName: "flask.fill")
                                        
                                        formField(title: "Imaging Reports", text: $imagingReports, multiline: true, iconName: "xray")
                                    }
                                    .padding()
                                }
                                
                                HStack {
                                    backButton()
                                    
                                    Button(action: {
                                        validateAndSave()
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Save Patient")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue)
                                        )
                                        .foregroundColor(.white)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                        .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                }
                
                // Loading overlay
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("Saving patient data...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding(25)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.gray.opacity(0.7))
                        )
                    }
                }
            }
            .navigationTitle("Add New Patient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep < 3 {
                        Button("Next") {
                            withAnimation {
                                if validateCurrentStep() {
                                    currentStep += 1
                                }
                            }
                        }
                    } else {
                        Button("Save") {
                            validateAndSave()
                        }
                    }
                }
            }
            .onAppear {
                // Delay animation to avoid initial layout issues
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        animated = true
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
            .sheet(isPresented: $showingSaveConfirmation) {
                saveConfirmationView
            }
        }
    }
    
    // MARK: - Subviews
    
    private var profileImageView: some View {
        VStack {
            ZStack {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                        .shadow(radius: 5)
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .padding(30)
                                .foregroundColor(.blue)
                        )
                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                }
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                }
                .offset(x: 40, y: 40)
            }
            .padding(.bottom, 10)
            
            Text("Profile Photo")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var saveConfirmationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            Text("Patient Added Successfully")
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(firstName) \(lastName) has been added to the system.")
                .multilineTextAlignment(.center)
            
            Divider()
                .padding(.vertical)
            
            Button(action: {
                showingSaveConfirmation = false
                dismiss()
            }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: 400)
    }
    
    // MARK: - Form Components
    
    private func groupLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    private func formField(title: String, text: Binding<String>, required: Bool = false, multiline: Bool = false, iconName: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if required {
                    Text("*")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            
            HStack {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(.blue)
                }
                
                if multiline {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: text)
                            .frame(minHeight: 100, maxHeight: 200)
                            .padding(2)
                        
                        if text.wrappedValue.isEmpty {
                            Text("Enter \(title.lowercased())")
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    TextField("Enter \(title.lowercased())", text: text)
                        .padding(10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private func datePickerField(title: String, date: Binding<Date>, iconName: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(.blue)
                }
                
                DatePicker(
                    "",
                    selection: date,
                    in: title.contains("Birth") ? ...Date() : ...Date(),
                    displayedComponents: .date
                )
                .labelsHidden()
            }
            .padding(10)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func nextButton(text: String) -> some View {
        Button(action: {
            if validateCurrentStep() {
                withAnimation {
                    currentStep += 1
                }
            }
        }) {
            HStack {
                Text(" \(text)")
                Image(systemName: "arrow.right.circle.fill")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.blue)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func backButton() -> some View {
        Button(action: {
            withAnimation {
                currentStep -= 1
            }
        }) {
            HStack {
                Image(systemName: "arrow.left.circle.fill")
                Text("Back")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.gray.opacity(0.2))
            )
            .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 0:
            // Check required fields in personal info
            if firstName.trim().isEmpty {
                showError("First name is required")
                return false
            }
            if lastName.trim().isEmpty {
                showError("Last name is required")
                return false
            }
            if medicalRecordNumber.trim().isEmpty {
                showError("Medical Record Number is required")
                return false
            }
            return true
            
        case 1, 2:
            // Contact and insurance info have no required fields
            return true
            
        case 3:
            // Initial presentation validation
            return true
            
        default:
            return true
        }
    }
    
    private func validateAndSave() {
        // Final validation before saving
        if !validateCurrentStep() {
            return
        }
        
        // Start saving process
        isSaving = true
        
        // Perform save on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let newPatient = Patient(context: viewContext)
            newPatient.id = UUID()
            
            // Basic information
            newPatient.firstName = firstName.trim()
            newPatient.lastName = lastName.trim()
            newPatient.dateOfBirth = dateOfBirth
            newPatient.gender = gender
            newPatient.medicalRecordNumber = medicalRecordNumber.trim()
            newPatient.bloodType = bloodType
            newPatient.height = height
            newPatient.weight = weight
            newPatient.bedNumber = bedNumber.trim()
            
            // Contact information
            newPatient.phone = phone.trim()
            newPatient.contactInfo = contactInfo.trim()
            newPatient.address = address.trim()
            newPatient.emergencyContactName = emergencyContactName.trim()
            newPatient.emergencyContactPhone = emergencyContactPhone.trim()
            
            // Insurance information
            newPatient.insuranceProvider = insuranceProvider.trim()
            newPatient.insurancePolicyNumber = insurancePolicyNumber.trim()
            newPatient.insuranceDetails = insuranceDetails.trim()
            
            // Date stamps
            newPatient.dateCreated = Date()
            newPatient.dateModified = Date()
            newPatient.isDischargedStatus = false
            
            // Profile image
            if let image = profileImage, let imageData = image.jpegData(compressionQuality: 0.8) {
                newPatient.profileImageData = imageData
            }
            
            // Create initial presentation record if we have at least some data
            if !chiefComplaint.trim().isEmpty || !historyOfPresentIllness.trim().isEmpty || !initialDiagnosis.trim().isEmpty {
                let initialPresentation = InitialPresentation(context: viewContext)
                initialPresentation.id = UUID()
                initialPresentation.presentationDate = presentationDate
                initialPresentation.chiefComplaint = chiefComplaint.trim()
                initialPresentation.historyOfPresentIllness = historyOfPresentIllness.trim()
                initialPresentation.pastMedicalHistory = pastMedicalHistory.trim()
                initialPresentation.physicalExamination = physicalExamination.trim()
                initialPresentation.initialDiagnosis = initialDiagnosis.trim()
                initialPresentation.labTests = labTests.trim()
                initialPresentation.imagingReports = imagingReports.trim()
                initialPresentation.medications = medications.trim()
                initialPresentation.allergies = allergies.trim()
                
                newPatient.initialPresentation = initialPresentation
                initialPresentation.patient = newPatient
            }
            
            // Save on main thread
            DispatchQueue.main.async {
                do {
                    try viewContext.save()
                    isSaving = false
                    showingSaveConfirmation = true
                } catch {
                    isSaving = false
                    showError("Error saving patient: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingAlert = true
    }
}

// MARK: - Supporting Views

struct ProgressIndicator: View {
    let isActive: Bool
    let isCompleted: Bool
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(isCompleted ? Color.green : (isActive ? Color.blue : Color.gray.opacity(0.3)), lineWidth: 3)
                    .frame(width: 30, height: 30)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                } else if isActive {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                }
            }
            
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(isActive ? .primary : .secondary)
                .fixedSize()
                .frame(width: 0)
                .opacity(0) // Hide text to save space
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Extensions

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
