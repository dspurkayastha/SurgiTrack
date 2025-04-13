import SwiftUI
import CoreData
import Darwin

struct UserProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var userProfile: UserProfile?
    @State private var showingEditProfile = false
    @State private var animateHeader = false

    var body: some View {
        NavigationView {
            Group {
                if let profile = userProfile {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Refined header with subtle animation - broken into smaller components
                            profileHeaderContainer(profile)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        animateHeader = true
                                    }
                                }
                            
                            // Content cards with consistent styling
                            professionalInfoCard(profile)
                            contactInfoCard(profile)
                            bioSection(profile)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .navigationTitle("Profile")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showingEditProfile = true
                            }) {
                                Text("Edit")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .sheet(isPresented: $showingEditProfile) {
                        UserProfileEditView(userProfile: profile)
                            .environment(\.managedObjectContext, viewContext)
                    }
                } else {
                    // Improved empty state
                    emptyProfileView()
                }
            }
        }
        .onAppear(perform: fetchUserProfile)
    }
    
    // MARK: - Data Methods
    
    private func fetchUserProfile() {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "isCurrentUser == YES")
        do {
            let profiles = try viewContext.fetch(request)
            userProfile = profiles.first
        } catch {
            print("Error fetching user profile: \(error)")
        }
    }
    
    private func createUserProfile() {
        let newProfile = UserProfile(context: viewContext)
        newProfile.id = UUID()
        newProfile.isCurrentUser = true
        newProfile.dateCreated = Date()
        // Set empty strings so the edit view shows blank inputs
        newProfile.firstName = ""
        newProfile.lastName = ""
        newProfile.title = ""
        newProfile.unitName = ""
        newProfile.departmentName = ""
        newProfile.hospitalName = ""
        newProfile.hospitalAddress = ""
        newProfile.email = ""
        newProfile.phone = ""
        newProfile.bio = ""
        
        do {
            try viewContext.save()
            userProfile = newProfile
            showingEditProfile = true
        } catch {
            print("Error creating user profile: \(error)")
        }
    }
    
    // MARK: - Header Components - Broken Down
    
    // Container for the header that incorporates all sub-components
    private func profileHeaderContainer(_ profile: UserProfile) -> some View {
        ZStack {
            // Background gradient - broken out as separate component
            headerBackgroundView()
            
            // Content - broken out as separate component
            profileHeaderContentView(profile)
        }
        .frame(height: 250)
        .padding(.bottom, 10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 4)
    }
    
    // Background with gradient and animations
    private func headerBackgroundView() -> some View {
        ZStack {
            // Base gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.05, green: 0.4, blue: 0.65),
                            Color(red: 0.0, green: 0.3, blue: 0.55)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Animated background circles
            ForEach(0..<3, id: \.self) { i in
                animatedCircle(index: i)
            }
            
            // Border stroke
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
    }
    
    // Single animated circle - extracted to reduce complexity
    private func animatedCircle(index: Int) -> some View {
        Circle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 200, height: 200)
            .offset(
                x: animateHeader ? CGFloat(index * 50 - 100) : -200,
                y: CGFloat(index * 20 - 100)
            )
            .blur(radius: 30)
    }
    
    // Content portion of the header
    private func profileHeaderContentView(_ profile: UserProfile) -> some View {
        VStack(spacing: 24) {
            // Profile image section - extracted to separate component
            profileImageSection(profile)
                .padding(.top, 20)
            
            // Name and title section - extracted to separate component
            profileNameSection(profile)
                .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
    
    // Profile image component - extracted
    private func profileImageSection(_ profile: UserProfile) -> some View {
        ZStack {
            if let imageData = profile.profileImageData, let uiImage = UIImage(data: imageData) {
                // User uploaded photo with nice border
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
            } else {
                // Caduceus symbol with animated glints
                profileImagePlaceholder(profile)
            }
        }
    }
    
    // Name and title component - extracted
    private func profileNameSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 4) {
            Text((profile.firstName?.isEmpty ?? true) && (profile.lastName?.isEmpty ?? true) ? "Doctor" : "Dr. \(profile.fullName)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            if let profTitle = profile.title, !profTitle.isEmpty {
                Text(profTitle)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    // MARK: - UI Components
    
    // Extracted caduceus profile image placeholder
    private func profileImagePlaceholder(_ profile: UserProfile) -> some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.1, green: 0.5, blue: 0.7),
                            Color(red: 0.05, green: 0.35, blue: 0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            // Use caduceus asset
            Image("caduceus")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .foregroundColor(.white)
                .opacity(0.85)
            
            // Subtle metallic highlight
            Circle()
                .trim(from: 0.0, to: 0.5)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 100, height: 100)
                .offset(y: -5)
            
            // Animated glints
            ForEach(0..<5, id: \.self) { index in
                GlintView(index: index)
            }
            
            // Initials with subtle shadow
            Text(profile.initials)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
        }
    }
    
    // Empty state view with clean design
    private func emptyProfileView() -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.7))
            
            Text("Complete Your Profile")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add your professional details to help colleagues identify you")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: {
                createUserProfile()
            }) {
                Text("Set Up Profile")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(minWidth: 200)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.1, green: 0.5, blue: 0.7),
                                Color(red: 0.0, green: 0.4, blue: 0.6)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color(red: 0.0, green: 0.4, blue: 0.6).opacity(0.3), radius: 5, x: 0, y: 3)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // Info card with consistent styling
    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(red: 0.0, green: 0.4, blue: 0.6))
            
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
    
    // Reusable info row with icon
    private func infoRow(icon: String, iconColor: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 16))
        }
        .padding(.vertical, 4)
    }
    
    private func professionalInfoCard(_ profile: UserProfile) -> some View {
        infoCard(title: "Professional Details") {
            VStack(alignment: .leading, spacing: 8) {
                if let unit = profile.unitName, !unit.isEmpty {
                    infoRow(icon: "building.2.fill", iconColor: Color(red: 0.0, green: 0.5, blue: 0.8), text: "Unit: \(unit)")
                }
                
                if let dept = profile.departmentName, !dept.isEmpty {
                    infoRow(icon: "person.2.fill", iconColor: Color(red: 0.0, green: 0.6, blue: 0.5), text: "Department: \(dept)")
                }
                
                if let hospital = profile.hospitalName, !hospital.isEmpty {
                    infoRow(icon: "building.2.crop.circle.fill", iconColor: Color(red: 0.2, green: 0.4, blue: 0.7), text: "Hospital: \(hospital)")
                }
                
                if let address = profile.hospitalAddress, !address.isEmpty {
                    infoRow(icon: "location.fill", iconColor: Color(red: 0.3, green: 0.5, blue: 0.8), text: "Address: \(address)")
                }
                
                if (profile.unitName == nil || profile.unitName?.isEmpty == true) &&
                   (profile.departmentName == nil || profile.departmentName?.isEmpty == true) &&
                   (profile.hospitalName == nil || profile.hospitalName?.isEmpty == true) &&
                   (profile.hospitalAddress == nil || profile.hospitalAddress?.isEmpty == true) {
                    Text("No professional details added yet")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func contactInfoCard(_ profile: UserProfile) -> some View {
        infoCard(title: "Contact Information") {
            VStack(alignment: .leading, spacing: 8) {
                if let email = profile.email, !email.isEmpty {
                    infoRow(icon: "envelope.fill", iconColor: Color(red: 0.4, green: 0.3, blue: 0.8), text: email)
                }
                
                if let phone = profile.phone, !phone.isEmpty {
                    infoRow(icon: "phone.fill", iconColor: Color(red: 0.2, green: 0.6, blue: 0.4), text: phone)
                }
                
                if (profile.email == nil || profile.email?.isEmpty == true) &&
                   (profile.phone == nil || profile.phone?.isEmpty == true) {
                    Text("No contact information added yet")
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func bioSection(_ profile: UserProfile) -> some View {
        infoCard(title: "Biography") {
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            } else {
                Text("No biography available")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical, 8)
            }
        }
    }
}

// Glint animation component - keeping this as requested
struct GlintView: View {
    @State private var animating = false
    let index: Int
    let range: CGFloat
    
    // Init with default range of 50 (for icon glints) or custom range (for background glints)
    init(index: Int, range: CGFloat = 50) {
        self.index = index
        self.range = range
    }
    
    var body: some View {
        // Glint
        Circle()
            .fill(Color.white.opacity(Double(0.5 + Double(index) / 10.0)))
            .frame(width: CGFloat(3 + index % 3), height: CGFloat(3 + index % 3))
            .blur(radius: CGFloat(0.5 + Double(index) / 10.0))
            .offset(x: animating ? endPosition.x : startPosition.x,
                    y: animating ? endPosition.y : startPosition.y)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5 + Double(index) / 2.0)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) / 5.0)) {
                    animating.toggle()
                }
            }
    }
    
    // Random start position
    private var startPosition: CGPoint {
        let angle = Double(index) * 0.7
        return CGPoint(
            x: Darwin.cos(angle) * range * 0.8,
            y: Darwin.sin(angle) * range * 0.8
        )
    }
    
    // Different end position
    private var endPosition: CGPoint {
        let angle = Double(index) * 0.7 + .pi
        return CGPoint(
            x: Darwin.cos(angle) * range * 0.6,
            y: Darwin.sin(angle) * range * 0.6
        )
    }
}

