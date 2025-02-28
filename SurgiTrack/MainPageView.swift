import SwiftUI
import CoreData

// Combined quick action enum for all 7 items.
enum CombinedQuickAction: String, CaseIterable, Hashable {
    case schedule, newPatient, reports, riskCalculators, prescriptions, trends, operativeNotes
    
    var title: String {
        switch self {
        case .schedule: return "Schedule"
        case .newPatient: return "Add Patient"
        case .reports: return "Reports"
        case .riskCalculators: return "Assess Risk"
        case .prescriptions: return "Prescriptions"
        case .trends: return "Trends"
        case .operativeNotes: return "Operative Notes"
        }
    }
    
    var iconName: String {
        switch self {
        case .schedule: return "calendar"
        case .newPatient: return "person.badge.plus"
        case .reports: return "clipboard.fill"
        case .riskCalculators: return "function"
        case .prescriptions: return "doc.text.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .operativeNotes: return "pencil.and.outline"
        }
    }
    
    // Unique color for each quick action.
    var color: Color {
        switch self {
        case .schedule:
            return Color(red: 0.25, green: 0.52, blue: 0.74)  // Steel blue - organized, structured
        case .newPatient:
            return Color(red: 0.33, green: 0.62, blue: 0.57)  // Sea green - nurturing, growth
        case .reports:
            return Color(red: 0.76, green: 0.56, blue: 0.35)  // Burnished copper - archival, informative
        case .riskCalculators:
            return Color(red: 0.55, green: 0.35, blue: 0.64)  // Amethyst - analytical, thoughtful
        case .prescriptions:
            return Color(red: 0.65, green: 0.31, blue: 0.35)  // Burgundy - clinical, important
        case .trends:
            return Color(red: 0.42, green: 0.44, blue: 0.68)  // Dusty blue - insightful, reflective
        case .operativeNotes:
            return Color(red: 0.67, green: 0.58, blue: 0.32)  // Olive gold - precision, technical
        }
    }
    
    // Gradient for button background (from full color to a lighter version).
    var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [color, color.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}


struct MainPageView: View {
    // MARK: - Environment & State
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    
    // Fetch current user profile (assuming there's only one current user)
    @FetchRequest(
        entity: UserProfile.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "isCurrentUser == YES")
    ) private var currentUserProfiles: FetchedResults<UserProfile>
    
    // State variables
    @State private var selectedTab = 0
    @State private var isShowingSettings = false
    @State private var isShowingProfile = false
    @State private var isShowingNotifications = false
    @State private var isShowingAddPatient = false
    
    // Animation states
    @State private var headerLoaded = false
    @State private var statsLoaded = false
    @State private var actionsLoaded = false
    @State private var recentLoaded = false
    
    // Statistics fetching
    @State private var stats = DashboardStats()
    
    // Reports Navigation
    @StateObject private var reportsNavState = ReportsNavigationState()
    
    // Recent data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Patient.dateModified, ascending: false)]
    ) private var recentPatients: FetchedResults<Patient>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \OperativeData.operationDate, ascending: false)]
    ) private var recentProcedures: FetchedResults<OperativeData>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Appointment.startTime, ascending: true)],
        predicate: NSPredicate(format: "startTime >= %@ AND isCompleted == NO", Date() as NSDate)
    ) private var upcomingAppointments: FetchedResults<Appointment>
    
    // Constants
    private let animationDelay: Double = 0.2
    private let headerHeight: CGFloat = 120
    
    // MARK: - Main Body
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced Background
                enhancedBackground
                
                // Main ScrollView Content
                ScrollView {
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named("scrollView")).minY
                        )
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 28) {
                        // Redesigned Header Section (Welcome first, then username, then date)
                        welcomeHeader
                            .offset(y: parallaxOffset * -0.3) // Parallax effect
                        
                        // Dashboard Stats
                        dashboardStatsView
                        
                        // Quick Actions Grid
                        quickActionGrid
                        
                        // Recent Activity
                        recentActivitySection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
                .coordinateSpace(name: "scrollView")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation(.easeOut(duration: 0.3)) {
                        parallaxOffset = min(0, value)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isShowingProfile = true
                        hapticFeedback(style: .light)
                    }) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("SurgiTrack")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingNotifications = true
                        hapticFeedback(style: .light)
                    }) {
                        Image(systemName: "bell")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .overlay(
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 5, y: -5)
                                    .opacity(appState.notifications.contains(where: { !$0.isRead }) ? 1 : 0)
                            )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingSettings = true
                        hapticFeedback(style: .light)
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                animate()
                fetchDashboardStats()
                startHeaderAnimation()
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $isShowingProfile) {
                UserProfileView()
            }
            .sheet(isPresented: $isShowingNotifications) {
                NotificationsView(notifications: $appState.notifications)
            }
            .sheet(isPresented: $isShowingAddPatient) {
                AddPatientView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Animation State
    @State private var parallaxOffset: CGFloat = 0
    
    // MARK: - Computed Properties
    // Computed property for today's formatted date.
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    // Computed property to get the current user profile (if available).
    private var currentUserProfile: UserProfile? {
        return currentUserProfiles.first
    }
    
    // MARK: - Component Views
    
    // New Enhanced Background
    private var enhancedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    appState.currentTheme.primaryColor.opacity(0.95),
                    appState.currentTheme.secondaryColor.opacity(0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated floating orbs for depth
            Circle()
                .fill(appState.currentTheme.primaryColor.opacity(0.4))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: -120, y: parallaxOffset * 0.4 - 100)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: headerLoaded)
            
            Circle()
                .fill(appState.currentTheme.secondaryColor.opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 150, y: parallaxOffset * 0.3 + 280)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: headerLoaded)
            
            // Light gradient overlay for better text contrast
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.5), value: parallaxOffset)
    }
    
    // Redesigned Welcome Header (welcome, then username, then date)
    private var welcomeHeader: some View {
        VStack(spacing: 10) {
            // Welcome message at the top
            Text("Welcome!")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 20)
                .opacity(headerLoaded ? 1 : 0)
                .offset(y: headerLoaded ? 0 : -20)
            
            // User name in the middle
            if let firstName = currentUserProfile?.firstName, !firstName.isEmpty {
                Text("Dr. \(firstName)")
                    .font(.system(size: 26, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(headerLoaded ? 1 : 0)
                    .offset(y: headerLoaded ? 0 : -15)
            }
            
            // Date at the bottom
            Text("Today is \(formattedDate)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .opacity(headerLoaded ? 1 : 0)
                .offset(y: headerLoaded ? 0 : -10)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }
    
    // Redesigned Dashboard Stats View with 3D Card Effect
    private var dashboardStatsView: some View {
        VStack(spacing: 20) {
            Text("Dashboard")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .opacity(statsLoaded ? 1 : 0)
            
            HStack(spacing: 16) {
                statsCard(title: "Patients", value: "\(stats.patientCount)", icon: "person.3.fill", color: Color.blue)
                statsCard(title: "Surgeries", value: "\(stats.surgeryCount)", icon: "cross.case.fill", color: Color.orange)
            }
            .opacity(statsLoaded ? 1 : 0)
            .offset(y: statsLoaded ? 0 : 20)
            
            HStack(spacing: 16) {
                statsCard(title: "Today", value: "\(stats.todayAppointments)", icon: "calendar", color: Color.green)
                statsCard(title: "Follow-ups", value: "\(stats.pendingFollowUps)", icon: "list.bullet.clipboard", color: Color.purple)
            }
            .opacity(statsLoaded ? 1 : 0)
            .offset(y: statsLoaded ? 0 : 20)
        }
    }
    
    // Redesigned Quick Action Grid with 3D Effect and Proper Layout
    private var quickActionGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .opacity(actionsLoaded ? 1 : 0)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(CombinedQuickAction.allCases, id: \.self) { action in
                    NavigationLink(destination: destinationView(for: action)) {
                        EnhancedQuickActionCell(title: action.title, iconName: action.iconName, gradient: action.gradient)
                            .environmentObject(appState)
                    }
                    .buttonStyle(ButtonPressingStyle()) // Add a custom button style to handle pressing animation
                    .opacity(actionsLoaded ? 1 : 0)
                    .offset(y: actionsLoaded ? 0 : 25)
                    .animation(.easeOut.delay(Double(CombinedQuickAction.allCases.firstIndex(of: action)!) * 0.1), value: actionsLoaded)
                }
            }
        }
    }
    struct ButtonPressingStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: configuration.isPressed)
        }
    }
    
    // Enhanced Quick Action Cell with 3D Effect
    struct EnhancedQuickActionCell: View {
        let title: String
        let iconName: String
        let gradient: LinearGradient
        @State private var isPressed = false
        
        var body: some View {
            VStack(spacing: 6) {
                // Icon with enhanced background
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        ZStack {
                            // Layered circles for 3D effect
                            Circle()
                                .fill(gradient)
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 4)
                            
                            // Inner highlight for depth
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                                .scaleEffect(0.85)
                        }
                    )
                
                // Title with better typography
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                // Card background with better lighting effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradient.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
            )
            // 3D button press effect - KEEP THIS ANIMATION BUT REMOVE THE TAP GESTURE
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPressed)
            // REMOVE THE onTapGesture MODIFIER FROM HERE
        }
    }
    
    // Redesigned Recent Activity Section
    private var recentActivitySection: some View {
        VStack(spacing: 20) {
            if !upcomingAppointments.isEmpty {
                sectionHeader(title: "Upcoming Appointments", seeAllDestination: AppointmentListView())
                ForEach(Array(upcomingAppointments.prefix(3)), id: \.objectID) { appointment in
                    NavigationLink(destination: AppointmentDetailView(appointment: appointment)) {
                        enhancedAppointmentCard(appointment: appointment)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(recentLoaded ? 1 : 0)
                    .offset(y: recentLoaded ? 0 : 30)
                    .animation(.easeOut.delay(0.2 + Double(upcomingAppointments.firstIndex(of: appointment)!) * 0.1), value: recentLoaded)
                }
            }
            
            if !recentPatients.isEmpty {
                sectionHeader(title: "Recent Patients", seeAllDestination: PatientListView())
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(recentPatients.prefix(5)), id: \.objectID) { patient in
                            NavigationLink(destination: AccordionPatientDetailView(patient: patient)) {
                                enhancedPatientCard(patient: patient)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(recentLoaded ? 1 : 0)
                            .offset(y: recentLoaded ? 0 : 30)
                            .animation(.easeOut.delay(0.3 + Double(recentPatients.firstIndex(of: patient)!) * 0.1), value: recentLoaded)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
                }
            }
            
            if !recentProcedures.isEmpty {
                sectionHeader(title: "Recent Procedures", seeAllDestination: Text("All Procedures"))
                ForEach(Array(recentProcedures.prefix(3)), id: \.objectID) { procedure in
                    NavigationLink(destination: OperativeDataDetailView(operativeData: procedure)) {
                        enhancedProcedureCard(procedure: procedure)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(recentLoaded ? 1 : 0)
                    .offset(y: recentLoaded ? 0 : 30)
                    .animation(.easeOut.delay(0.4 + Double(recentProcedures.firstIndex(of: procedure)!) * 0.1), value: recentLoaded)
                }
            }
            
            // Enhanced Patient List Button
            enhancedPatientListButton
                .padding(.top, 20)
                .opacity(recentLoaded ? 1 : 0)
                .offset(y: recentLoaded ? 0 : 30)
                .animation(.easeOut.delay(0.6), value: recentLoaded)
        }
    }
    
    // Enhanced Section Header
    private func sectionHeader<Destination: View>(title: String, seeAllDestination: Destination) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            NavigationLink(destination: seeAllDestination) {
                HStack(spacing: 4) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
        .opacity(recentLoaded ? 1 : 0)
        .offset(y: recentLoaded ? 0 : 20)
    }
    
    // Enhanced Appointment Card
    private func enhancedAppointmentCard(appointment: Appointment) -> some View {
        HStack(spacing: 15) {
            // Time section with enhanced design
            VStack(spacing: 4) {
                Text(formatTime(appointment.startTime))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(formatDate(appointment.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)
            .padding(.vertical, 4)
            
            // Accent line with proper color
            RoundedRectangle(cornerRadius: 2)
                .fill(getAppointmentColor(type: appointment.appointmentType))
                .frame(width: 4, height: 60)
            
            // Content section
            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.title ?? "Untitled Appointment")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let patient = appointment.patient {
                    Text(patient.fullName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let type = appointment.appointmentType {
                    Text(type)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(getAppointmentColor(type: type).opacity(0.2))
                        .foregroundColor(getAppointmentColor(type: type))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(
            // 3D Card effect
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    private func formatDate(_ date: Date?) -> String {
            guard let date = date else { return "Unknown" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
    }
    
    // Enhanced Patient Card
    private func enhancedPatientCard(patient: Patient) -> some View {
        VStack(alignment: .center, spacing: 12) {
            // Patient image with enhanced styling
            ZStack {
                if let imageData = patient.profileImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .opacity(0.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                } else {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Text(patient.initials)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .opacity(0.5)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
            }
            
            // Patient info with better typography
            Text(patient.fullName)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 100)
            
            if let mrn = patient.medicalRecordNumber {
                Text("MRN: \(mrn)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 150, height: 180)
        .background(
            // 3D card effect
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    // Enhanced Procedure Card
    private func enhancedProcedureCard(procedure: OperativeData) -> some View {
        HStack(spacing: 15) {
            // Date section
            VStack(spacing: 4) {
                Text(formatDate(procedure.operationDate))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(width: 70)
            .padding(.vertical, 4)
            
            // Accent line
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.orange)
                .frame(width: 4, height: 60)
            
            // Content section
            VStack(alignment: .leading, spacing: 6) {
                Text(procedure.procedureName ?? "Unnamed Procedure")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let patient = procedure.patient {
                    Text(patient.fullName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(procedure.anaesthesiaType ?? "Unknown")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(
            // 3D card effect
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    // Enhanced Patient List Button
    private var enhancedPatientListButton: some View {
        NavigationLink(destination: PatientListView()) {
            HStack {
                Image(systemName: "rectangle.stack.person.crop")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.trailing, 5)
                
                Text("Patient List")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity)
            .background(
                // Enhanced 3D button effect
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                appState.currentTheme.primaryColor.opacity(0.8),
                                appState.currentTheme.primaryColor.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
            )
        }
        .padding(.top, 10)
    }
    
    // MARK: - Enhanced Stats Card
    private func statsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Enhanced icon design
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            // Inner highlight for 3D depth
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                .scaleEffect(0.85)
                        }
                    )
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .gray)
            }
            
            // Enhanced value display
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            // 3D Card effect with proper styling
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ?
                      Color.black.opacity(0.6) :
                      Color.white.opacity(0.97))
                .shadow(color: Color.black.opacity(0.18), radius: 15, x: 0, y: 8)
                .overlay(
                    // Subtle border for depth
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            colorScheme == .dark ?
                            Color.white.opacity(0.15) :
                            Color.black.opacity(0.05),
                            lineWidth: 0.5
                        )
                )
        )
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Functions
    // Enhanced appointment color function with richer colors to match the new UI
    // Refined appointment color function with sophisticated palette
    private func getAppointmentColor(type: String?) -> Color {
        guard let type = type else { return Color(red: 0.28, green: 0.46, blue: 0.67) } // Sophisticated slate blue
        
        switch type.lowercased() {
        case "surgery":
            return Color(red: 0.73, green: 0.27, blue: 0.33) // Merlot red - deep and professional
        case "follow-up":
            return Color(red: 0.22, green: 0.59, blue: 0.66) // Teal blue - calming and trustworthy
        case "consultation":
            return Color(red: 0.41, green: 0.42, blue: 0.74) // Periwinkle blue - professional yet approachable
        case "pre-operative":
            return Color(red: 0.82, green: 0.65, blue: 0.28) // Antique gold - warm and reassuring
        case "post-operative":
            return Color(red: 0.58, green: 0.41, blue: 0.69) // Muted lavender - soothing and restorative
        default:
            return Color(red: 0.28, green: 0.46, blue: 0.67) // Slate blue - balanced and professional
        }
    }
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func fetchDashboardStats() {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        let patientRequest: NSFetchRequest<Patient> = Patient.fetchRequest()
        stats.patientCount = (try? viewContext.count(for: patientRequest)) ?? 0
        
        let surgeryRequest: NSFetchRequest<OperativeData> = OperativeData.fetchRequest()
        stats.surgeryCount = (try? viewContext.count(for: surgeryRequest)) ?? 0
        
        let todayAppointmentsRequest: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        todayAppointmentsRequest.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@ AND isCompleted == NO", startOfToday as NSDate, endOfToday as NSDate)
        stats.todayAppointments = (try? viewContext.count(for: todayAppointmentsRequest)) ?? 0
        
        let followUpsRequest: NSFetchRequest<FollowUp> = FollowUp.fetchRequest()
        followUpsRequest.predicate = NSPredicate(format: "followUpDate <= %@", Date() as NSDate)
        stats.pendingFollowUps = (try? viewContext.count(for: followUpsRequest)) ?? 0
    }
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func animate() {
        // Additional animations can be added here if desired.
    }
    
    private func startHeaderAnimation() {
        withAnimation(.easeOut(duration: 0.7).delay(animationDelay)) {
            headerLoaded = true
        }
        withAnimation(.easeOut(duration: 0.7).delay(animationDelay + 0.2)) {
            statsLoaded = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(animationDelay + 0.3)) {
            actionsLoaded = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(animationDelay + 0.4)) {
            recentLoaded = true
        }
    }
    
    private func destinationView(for action: CombinedQuickAction) -> some View {
        switch action {
        case .schedule:
            return AnyView(AppointmentListView())
        case .newPatient:
            return AnyView(AddPatientView())
        case .reports:
            return AnyView(ReportsView().environmentObject(reportsNavState))
        case .riskCalculators:
            return AnyView(RiskCalculatorListView())
        case .prescriptions:
            return AnyView(PrescriptionsView())
        case .trends:
            return AnyView(EnhancedTrendsView().environmentObject(appState))
        case .operativeNotes:
            return AnyView(OperativeNotesView())
        }
    }
}

struct MainPageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainPageView()
                .environmentObject(AppState())
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDisplayName("Light Mode")
            MainPageView()
                .environmentObject(AppState())
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
