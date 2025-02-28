import SwiftUI
import CoreData

struct UserProfileEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userProfile: UserProfile

    @State private var firstName: String
    @State private var lastName: String
    @State private var title: String
    @State private var unitName: String
    @State private var departmentName: String
    @State private var hospitalName: String
    @State private var hospitalAddress: String
    @State private var email: String
    @State private var phone: String
    @State private var bio: String
    @State private var profileImage: UIImage?

    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        _firstName = State(initialValue: userProfile.firstName!)
        _lastName = State(initialValue: userProfile.lastName ?? "")
        _title = State(initialValue: userProfile.title ?? "")
        _unitName = State(initialValue: userProfile.unitName ?? "")
        _departmentName = State(initialValue: userProfile.departmentName ?? "")
        _hospitalName = State(initialValue: userProfile.hospitalName ?? "")
        _hospitalAddress = State(initialValue: userProfile.hospitalAddress ?? "")
        _email = State(initialValue: userProfile.email ?? "")
        _phone = State(initialValue: userProfile.phone ?? "")
        _bio = State(initialValue: userProfile.bio ?? "")
        
        if let imageData = userProfile.profileImageData {
            _profileImage = State(initialValue: UIImage(data: imageData))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information").foregroundColor(.gray)) {
                    TextField("", text: $firstName)
                        .placeholder(when: firstName.isEmpty) {
                            Text("First Name").foregroundColor(.gray)
                        }
                        .autocapitalization(.words)
                    
                    TextField("", text: $lastName)
                        .placeholder(when: lastName.isEmpty) {
                            Text("Last Name").foregroundColor(.gray)
                        }
                        .autocapitalization(.words)
                }
                
                Section(header: Text("Professional Details").foregroundColor(.gray)) {
                    TextField("", text: $title)
                        .placeholder(when: title.isEmpty) {
                            Text("Title").foregroundColor(.gray)
                        }
                    TextField("", text: $unitName)
                        .placeholder(when: unitName.isEmpty) {
                            Text("Unit Name").foregroundColor(.gray)
                        }
                    TextField("", text: $departmentName)
                        .placeholder(when: departmentName.isEmpty) {
                            Text("Department Name").foregroundColor(.gray)
                        }
                    TextField("", text: $hospitalName)
                        .placeholder(when: hospitalName.isEmpty) {
                            Text("Hospital Name").foregroundColor(.gray)
                        }
                    TextField("", text: $hospitalAddress)
                        .placeholder(when: hospitalAddress.isEmpty) {
                            Text("Hospital Address").foregroundColor(.gray)
                        }
                }
                
                Section(header: Text("Contact Information").foregroundColor(.gray)) {
                    TextField("", text: $email)
                        .placeholder(when: email.isEmpty) {
                            Text("Email").foregroundColor(.gray)
                        }
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("", text: $phone)
                        .placeholder(when: phone.isEmpty) {
                            Text("Phone").foregroundColor(.gray)
                        }
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Biography").foregroundColor(.gray)) {
                    TextEditor(text: $bio)
                        .frame(height: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
                .buttonStyle(ModernButtonStyle(backgroundColor: .blue))
            )
        }
    }
    
    private func saveProfile() {
        userProfile.firstName = firstName
        userProfile.lastName = lastName
        userProfile.title = title
        userProfile.unitName = unitName
        userProfile.departmentName = departmentName
        userProfile.hospitalName = hospitalName
        userProfile.hospitalAddress = hospitalAddress
        userProfile.email = email
        userProfile.phone = phone
        userProfile.bio = bio
        userProfile.dateModified = Date()
        
        if let image = profileImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            userProfile.profileImageData = imageData
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

struct UserProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let profile = UserProfile(context: context)
        profile.firstName = "Jane"
        profile.lastName = "Doe"
        profile.title = "Surgeon"
        profile.unitName = "Unit A"
        profile.departmentName = "General Surgery"
        profile.hospitalName = "City Hospital"
        profile.hospitalAddress = "123 Main St, Anytown, USA"
        profile.email = "jane.doe@example.com"
        profile.phone = "555-1234"
        profile.bio = "Passionate about patient care and research."
        return NavigationView {
            UserProfileEditView(userProfile: profile)
                .environment(\.managedObjectContext, context)
        }
    }
}

