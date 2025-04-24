// ClerkProfileSignUpView.swift
// SurgiTrack
// Native SwiftUI Clerk sign-up modal with all UserProfile fields
// Created by Cascade AI

import SwiftUI

struct ClerkProfileSignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: LoginViewModel

    // User profile fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var title = ""
    @State private var unitName = ""
    @State private var departmentName = ""
    @State private var hospitalName = ""
    @State private var hospitalAddress = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var bio = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information").foregroundColor(.gray)) {
                    TextField("First Name", text: $firstName)
                        .autocapitalization(.words)
                    TextField("Last Name", text: $lastName)
                        .autocapitalization(.words)
                }
                Section(header: Text("Professional Details").foregroundColor(.gray)) {
                    TextField("Title", text: $title)
                    TextField("Unit Name", text: $unitName)
                    TextField("Department Name", text: $departmentName)
                    TextField("Hospital Name", text: $hospitalName)
                    TextField("Hospital Address", text: $hospitalAddress)
                }
                Section(header: Text("Contact Information").foregroundColor(.gray)) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                Section(header: Text("Biography").foregroundColor(.gray)) {
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                }
                Section(header: Text("Password").foregroundColor(.gray)) {
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        }
                    }
                    HStack {
                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                        }
                    }
                }
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
            .navigationTitle("Register")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Sign Up") {
                    signUp()
                }
                .disabled(!canSubmit)
            )
        }
    }

    private var canSubmit: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
    }

    private func signUp() {
        guard canSubmit else {
            errorMessage = "Please fill all required fields and ensure passwords match."
            showError = true
            return
        }
        viewModel.signUpWithProfile(
            firstName: firstName,
            lastName: lastName,
            title: title,
            unitName: unitName,
            departmentName: departmentName,
            hospitalName: hospitalName,
            hospitalAddress: hospitalAddress,
            email: email,
            phone: phone,
            bio: bio,
            password: password
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
