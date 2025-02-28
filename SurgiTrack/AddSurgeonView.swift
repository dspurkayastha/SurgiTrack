//
//  AddSurgeonView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 14/03/25.
//

import SwiftUI
import CoreData
import PhotosUI

struct AddSurgeonView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    // Surgeon details
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var contactInfo: String = ""
    @State private var licenseNumber: String = ""
    @State private var specialty: String = ""
    @State private var profileImage: UIImage? = nil
    
    // Photo picker
    @State private var isShowingPhotoPicker = false
    
    // Validation
    @State private var isFormValid = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Available specialties
    private let specialties = [
        "General Surgery",
        "Orthopedic Surgery",
        "Neurosurgery",
        "Cardiothoracic Surgery",
        "Vascular Surgery",
        "Plastic Surgery",
        "Pediatric Surgery",
        "Transplant Surgery",
        "Trauma Surgery",
        "Urological Surgery",
        "Colorectal Surgery",
        "Surgical Oncology",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Profile image section
                Section {
                    HStack {
                        Spacer()
                        
                        ZStack {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            }
                            
                            // Camera icon overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "camera.fill")
                                        .padding(8)
                                        .background(Circle().fill(Color.blue))
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                            }
                            .frame(width: 120, height: 120)
                        }
                        .contentShape(Circle())
                        .onTapGesture {
                            isShowingPhotoPicker = true
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                
                // Basic information section
                Section(header: Text("Basic Information")) {
                    formTextField(title: "First Name", text: $firstName, isRequired: true)
                    formTextField(title: "Last Name", text: $lastName, isRequired: true)
                    formTextField(title: "Contact Information", text: $contactInfo, placeholder: "Phone or Email")
                }
                
                // Professional details section
                Section(header: Text("Professional Details")) {
                    formTextField(title: "License Number", text: $licenseNumber)
                    
                    formPicker(title: "Specialty", selection: $specialty, options: specialties)
                }
                
                // Actions section
                Section {
                    Button(action: {
                        addSurgeon()
                    }) {
                        Text("Save Surgeon")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Surgeon")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onChange(of: firstName) { _ in validateForm() }
            .onChange(of: lastName) { _ in validateForm() }
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotoPicker(selectedImage: $profileImage)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                validateForm()
            }
        }
    }
    
    // MARK: - Form Components
    
    private func formTextField(title: String, text: Binding<String>, placeholder: String = "", isRequired: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            
            TextField(placeholder, text: text)
                .padding(10)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.vertical, 4)
    }
    
    private func formPicker<T: Hashable>(title: String, selection: Binding<T>, options: [T]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker(title, selection: selection) {
                Text("Select Specialty").tag("" as! T)
                ForEach(options, id: \.self) { option in
                    Text(String(describing: option)).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(10)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Methods
    
    private func validateForm() {
        isFormValid = !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
                      !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func addSurgeon() {
        let newSurgeon = Surgeon(context: viewContext)
        newSurgeon.id = UUID()
        newSurgeon.firstName = firstName.trimmingCharacters(in: .whitespaces)
        newSurgeon.lastName = lastName.trimmingCharacters(in: .whitespaces)
        newSurgeon.contactInfo = contactInfo.trimmingCharacters(in: .whitespaces)
        newSurgeon.licenseNumber = licenseNumber.trimmingCharacters(in: .whitespaces)
        newSurgeon.specialty = specialty
        
        // Save profile image if available
        if let profileImage = profileImage, let imageData = profileImage.jpegData(compressionQuality: 0.8) {
            newSurgeon.profileImageData = imageData
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Error saving new surgeon: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// MARK: - Photo Picker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                    }
                }
            }
        }
    }
}

struct AddSurgeonView_Previews: PreviewProvider {
    static var previews: some View {
        AddSurgeonView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
