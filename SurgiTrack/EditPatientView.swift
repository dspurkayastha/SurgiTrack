//
//  EditPatientView.swift
//  SurgiTrack
//
//  Created for SurgiTrack App on 02/03/25.
//

import SwiftUI
import CoreData

struct EditPatientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var patient: Patient
    
    // Patient Info
    @State private var firstName: String
    @State private var lastName: String
    @State private var dateOfBirth: Date
    @State private var gender: String
    @State private var contactInfo: String
    @State private var phone: String
    @State private var address: String
    @State private var medicalRecordNumber: String
    
    // Health Info
    @State private var bloodType: String
    @State private var height: Double
    @State private var weight: Double
    
    // Emergency Contact
    @State private var emergencyContactName: String
    @State private var emergencyContactPhone: String
    
    // Insurance
    @State private var insuranceProvider: String
    @State private var insurancePolicyNumber: String
    @State private var insuranceDetails: String
    
    // Image Picker
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var profileImage: Image?
    @State private var hasImageChanged = false
    
    // Form validation
    @State private var isFormValid = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Gender options for picker
    private let genderOptions = ["Male", "Female", "Other", "Prefer not to say"]
    private let bloodTypeOptions = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Unknown"]
    
    // Initialize with patient data
    init(patient: Patient) {
        self.patient = patient
        
        // Initialize state from patient
        _firstName = State(initialValue: patient.firstName ?? "")
        _lastName = State(initialValue: patient.lastName ?? "")
        _dateOfBirth = State(initialValue: patient.dateOfBirth ?? Date())
        _gender = State(initialValue: patient.gender ?? "")
        _contactInfo = State(initialValue: patient.contactInfo ?? "")
        _phone = State(initialValue: patient.phone ?? "")
        _address = State(initialValue: patient.address ?? "")
        _medicalRecordNumber = State(initialValue: patient.medicalRecordNumber ?? "")
        
        // Health info
        _bloodType = State(initialValue: patient.bloodType ?? "Unknown")
        _height = State(initialValue: patient.height)
        _weight = State(initialValue: patient.weight)
        
        // Emergency contact
        _emergencyContactName = State(initialValue: patient.emergencyContactName ?? "")
        _emergencyContactPhone = State(initialValue: patient.emergencyContactPhone ?? "")
        
        // Insurance
        _insuranceProvider = State(initialValue: patient.insuranceProvider ?? "")
        _insurancePolicyNumber = State(initialValue: patient.insurancePolicyNumber ?? "")
        _insuranceDetails = State(initialValue: patient.insuranceDetails ?? "")
        
        // Set profile image if exists
        if let imageData = patient.profileImageData, let uiImage = UIImage(data: imageData) {
            _profileImage = State(initialValue: Image(uiImage: uiImage))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Photo Section
                Section(header: Text("Profile Photo")) {
                    HStack {
                        Spacer()
                        ZStack {
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Text(patient.initials)
                                            .font(.system(size: 48, weight: .medium))
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)
                                    .background(Circle().fill(Color.white))
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                            .offset(x: 40, y: 40)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                
                // Patient Information Section
                Section(header: Text("Patient Information")) {
                    TextField("First Name", text: $firstName)
                        .autocapitalization(.words)
                        .onChange(of: firstName) { _ in validateForm() }
                    
                    TextField("Last Name", text: $lastName)
                        .autocapitalization(.words)
                        .onChange(of: lastName) { _ in validateForm() }
                    
                    DatePicker("Date of Birth", selection: $dateOfBirth,
                              in: ...Date(), displayedComponents: .date)
                    
                    Picker("Gender", selection: $gender) {
                        Text("Select Gender").tag("")
                        ForEach(genderOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    TextField("Medical Record Number", text: $medicalRecordNumber)
                        .autocapitalization(.allCharacters)
                        .onChange(of: medicalRecordNumber) { _ in validateForm() }
                }
                
                // Health Information
                Section(header: Text("Health Information")) {
                    Picker("Blood Type", selection: $bloodType) {
                        ForEach(bloodTypeOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("Height", value: $height, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("Weight", value: $weight, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                // Contact Information Section
                Section(header: Text("Contact Information")) {
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    
                    TextField("Email", text: $contactInfo)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Address", text: $address)
                        .autocapitalization(.words)
                }
                
                // Emergency Contact
                Section(header: Text("Emergency Contact")) {
                    TextField("Name", text: $emergencyContactName)
                        .autocapitalization(.words)
                    
                    TextField("Phone", text: $emergencyContactPhone)
                        .keyboardType(.phonePad)
                }
                
                // Insurance Information
                Section(header: Text("Insurance")) {
                    TextField("Provider", text: $insuranceProvider)
                        .autocapitalization(.words)
                    
                    TextField("Policy Number", text: $insurancePolicyNumber)
                    
                    TextField("Additional Details", text: $insuranceDetails)
                        .autocapitalization(.sentences)
                }
            }
            .navigationTitle("Edit Patient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { _ in
                loadImage()
            }
        }
        .onAppear {
            validateForm()
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
        hasImageChanged = true
    }
    
    private func validateForm() {
        isFormValid = !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                      !medicalRecordNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveChanges() {
        guard isFormValid else {
            alertMessage = "Please complete all required fields"
            showingAlert = true
            return
        }
        
        // Update patient data
        patient.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.dateOfBirth = dateOfBirth
        patient.gender = gender
        patient.contactInfo = contactInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.medicalRecordNumber = medicalRecordNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Health info
        patient.bloodType = bloodType
        patient.height = height
        patient.weight = weight
        
        // Emergency contact
        patient.emergencyContactName = emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.emergencyContactPhone = emergencyContactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Insurance
        patient.insuranceProvider = insuranceProvider.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.insurancePolicyNumber = insurancePolicyNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.insuranceDetails = insuranceDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Image data
        if hasImageChanged, let inputImage = inputImage, let imageData = inputImage.jpegData(compressionQuality: 0.8) {
            patient.profileImageData = imageData
        }
        
        // Update modification timestamp
        patient.dateModified = Date()
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Error saving changes: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
