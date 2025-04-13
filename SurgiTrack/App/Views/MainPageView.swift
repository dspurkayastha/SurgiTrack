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
    
    // Particle State
    @State private var particles: [MainPageParticle] = []
    private let particleCount: Int = 25
    @State private var particleOpacity: Double = 0

    // Tap Interaction State
    @State private var lastTapLocation: CGPoint? = nil
    @State private var attractionActive: Bool = false
    @State private var attractTimer: Timer? // To reset attraction

    // Timer for Particle Updates
    @State private var particleUpdateTimer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect() 

    // MARK: - Main Body
    var body: some View {
        NavigationView {
            ZStack {
                // Use the NEW Enhanced Animated Background
                EnhancedAnimatedGradientBackground() // Updated usage
                    .environmentObject(appState) // Pass the environment object

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

// MARK: - Particle Model (Keep MainPageParticle as is)

/// Represents a single particle for the background effect
struct MainPageParticle: Identifiable {
    var id: UUID = UUID()
    // Current animated state
    var position: CGPoint
    var scale: Double
    var rotation: Double
    var blur: CGFloat
    // Target for drifting
    var driftTargetPosition: CGPoint?
    // Base properties
    var content: String // SF Symbol name or "" for Circle
    var color: Color
    var size: CGFloat
    var opacity: Double
    // Animation timing helper - ADD BACK
    var duration: Double // Approx time to reach drift target
}

// MARK: - Original Animated Background View Definition (Commented out or removed)
/*
struct AnimatedGradientBackground: View {
    // ... original implementation ...
}
*/

// MARK: - Enhanced Animated Background View Definition

struct EnhancedAnimatedGradientBackground: View {
    @EnvironmentObject private var appState: AppState
    @State private var startPoint = UnitPoint.topLeading // Fixed startPoint
    @State private var endPoint = UnitPoint.bottomTrailing // Fixed endpoint
    @State private var animatedGradientColors: [Color] = [] // Colors set once

    // Particle State
    @State private var particles: [MainPageParticle] = []
    private let particleCount: Int = 25
    @State private var particleOpacity: Double = 0

    // Tap Interaction State
    @State private var lastTapLocation: CGPoint? = nil
    @State private var attractionActive: Bool = false
    @State private var attractTimer: Timer? // To reset attraction

    // Timer for Particle Updates
    @State private var particleUpdateTimer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect() 

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                // Base Gradient Layer
                LinearGradient(
                    gradient: Gradient(colors: animatedGradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blur(radius: 5)

                // Particle Layer
                ZStack {
                    ForEach(particles) { particle in
                        renderParticle(particle)
                    }
                }
                .opacity(particleOpacity)
                // REMOVED .onChange(of: timelineContext.date)
                // .drawingGroup() // Keep commented out for now

            }
            .edgesIgnoringSafeArea(.all)
            // --- Tap Gesture ---
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        // Removed context parameter
                        handleTap(at: value.location, in: size)
                    }
            )
            // --- Lifecycle & Timer ---
            .onAppear {
                // Removed context parameter
                setupInitialState(in: size)
            }
            .onChange(of: appState.currentTheme.id) { _ in
                 // Removed context parameter
                 handleThemeChange(in: size)
            }
            // Reinstate timer receiver
            .onReceive(particleUpdateTimer) { _ in
                updateParticles(in: size)
            }
            .onDisappear {
                // Invalidate attraction timer if view disappears
                attractTimer?.invalidate()
                attractTimer = nil
            }
            // END OF ZStack, REMOVED closing brace for TimelineView
        }
    }

    // Renders a single particle view
    @ViewBuilder
    private func renderParticle(_ particle: MainPageParticle) -> some View {
        // Simple rendering, ensure NO animation modifiers here
        Group {
            if particle.content.isEmpty { // Render Circle
                 Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            } else { // Render SF Symbol
                Image(systemName: particle.content)
                    .font(.system(size: particle.size))
                    .foregroundColor(particle.color)
            }
        }
        .opacity(particle.opacity) // Use particle's base opacity
        .blur(radius: particle.blur)
        .position(particle.position)
    }

    // MARK: - Setup and State Management

    private func setupInitialState(in size: CGSize) {
        updateAnimatedGradientColors()
        generateParticles(in: size)
        // Assign initial drift targets
        startDriftingAnimation(in: size)
        // Fade in particles
        withAnimation(.easeIn(duration: 1.5).delay(0.5)) {
            particleOpacity = 1.0
        }
    }

    private func handleThemeChange(in size: CGSize) {
        updateAnimatedGradientColors()
        // Fade out, regenerate, fade in
        withAnimation(.easeOut(duration: 0.6)) {
            particleOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.generateParticles(in: size)
            // Start new animation
            self.startDriftingAnimation(in: size)
            withAnimation(.easeIn(duration: 1.2)) {
                self.particleOpacity = 1.0
            }
        }
    }

    // MARK: - Gradient - Static Gradient Logic (Unchanged)

    private func updateAnimatedGradientColors() {
        let theme = appState.currentTheme
        // Set a fixed, non-shuffled array of colors
        self.animatedGradientColors = [
            theme.primaryColor.opacity(0.85), // Slightly more opaque start
            theme.secondaryColor.opacity(0.7),
            theme.primaryColor.opacity(0.5)
            // Removed shuffling and the 4th color for simplicity
        ]
        // No animation block needed as gradient is static
    }

    // MARK: - Particle Generation and Regeneration

    private func generateParticles(in size: CGSize) {
        let theme = appState.currentTheme
        let possibleContent = ["circle.fill", ""] 
        var newParticles: [MainPageParticle] = []

        for _ in 0..<particleCount {
            let content = possibleContent.randomElement()!
            let isSymbol = !content.isEmpty
            let particleSize = CGFloat.random(in: isSymbol ? 18...40 : 15...35)
            let initialPosition = randomPosition(in: size, edgeAffinity: 0.3)
            let initialScale = Double.random(in: 0.6...1.4)
            let initialRotation = Double.random(in: -30...30)
            let initialBlur = CGFloat.random(in: 1...4)

            let particle = MainPageParticle(
                position: initialPosition,
                scale: initialScale,
                rotation: initialRotation,
                blur: initialBlur,
                driftTargetPosition: nil,
                content: content,
                color: [theme.primaryColor, theme.secondaryColor, theme.primaryColor.opacity(0.8), theme.secondaryColor.opacity(0.8), Color.white, Color.white.opacity(0.7)]
                    .randomElement()!
                    .opacity(Double.random(in: 0.3...0.7)),
                size: particleSize,
                opacity: 1.0,
                duration: 0.0 // Assuming a default duration
            )
            newParticles.append(particle)
        }
        self.particles = newParticles
    }

    // MARK: - Particle Animation Logic (Manual Timer Based)

    // Assigns initial drift targets
    private func startDriftingAnimation(in size: CGSize) {
        print("DEBUG: Assigning Drift Targets")
        for i in particles.indices {
            particles[i].driftTargetPosition = randomPosition(in: size)
            // Removed setting animationStartTime
        }
    }
    
    // Called frequently by the timer
    private func updateParticles(in size: CGSize) {
        let timeInterval: Double = 0.02 // Match timer interval
        
        for i in particles.indices {
            // Target values for this frame - use temporary vars
            var nextPosition = particles[i].position
            var nextScale = particles[i].scale
            var nextRotation = particles[i].rotation
            var nextBlur = particles[i].blur
            
            if attractionActive, let tapLocation = lastTapLocation {
                // --- Attraction Logic --- 
                let attractionSpeedFactor: CGFloat = 0.1 // How fast it moves towards tap per frame
                
                // Use particle's actual current position for calculation
                let dx = tapLocation.x - particles[i].position.x 
                let dy = tapLocation.y - particles[i].position.y
                
                // Update temporary position
                nextPosition.x += dx * attractionSpeedFactor
                nextPosition.y += dy * attractionSpeedFactor
                
                // Interpolate temporary scale towards target
                let targetScale = 1.4 
                nextScale += (targetScale - particles[i].scale) * attractionSpeedFactor // Use temporary var
                
                // Interpolate temporary rotation towards target
                let targetRotation: Double = 0
                let rotationDiff = (targetRotation - particles[i].rotation).truncatingRemainder(dividingBy: 360) // Use temporary var
                let shortestRotation = rotationDiff > 180 ? rotationDiff - 360 : (rotationDiff < -180 ? rotationDiff + 360 : rotationDiff)
                nextRotation += shortestRotation * attractionSpeedFactor
                
                // Interpolate temporary blur towards target
                let targetBlur: CGFloat = 0.5
                nextBlur += (targetBlur - particles[i].blur) * attractionSpeedFactor // Use temporary var
                
            } else {
                // --- Drifting Logic --- 
                guard let targetPosition = particles[i].driftTargetPosition else {
                    particles[i].driftTargetPosition = randomPosition(in: size)
                    continue // Skip update this frame if target was missing
                }
                
                // Calculate distance from the ACTUAL current position
                let currentActualPosition = particles[i].position 
                let dx = targetPosition.x - currentActualPosition.x
                let dy = targetPosition.y - currentActualPosition.y
                let distance = sqrt(dx*dx + dy*dy) // Use distance calculated from actual position
                
                // Calculate speed based on duration (points per second)
                let speed = (particles[i].duration > 0) ? (distance / CGFloat(particles[i].duration)) : 0
                let stepDistance = speed * CGFloat(timeInterval)
                
                if distance < 5 { // Close enough to target, assign a new one
                    particles[i].driftTargetPosition = randomPosition(in: size)
                     // Move temporary vars towards neutral state
                     nextScale += (1.0 - particles[i].scale) * 0.02 // Use temporary var
                     nextRotation += (0.0 - particles[i].rotation).truncatingRemainder(dividingBy: 360) * 0.02 // Use temporary var
                     nextBlur += (2.0 - particles[i].blur) * 0.02 // Use temporary var
                     // Keep nextPosition as is for this frame
                } else {
                    // Move towards target
                    if distance > 0 { // Avoid division by zero
                        let moveFactor = min(1.0, stepDistance / distance)
                        // Update the TEMPORARY position variable
                        nextPosition.x += dx * moveFactor
                        nextPosition.y += dy * moveFactor
                    }
                    
                    // Slowly vary TEMPORARY scale/rotation/blur while drifting
                    nextScale += Double.random(in: -0.005...0.005)
                    nextRotation += Double.random(in: -0.2...0.2)
                    nextBlur += CGFloat.random(in: -0.02...0.02)
                }
                // Clamp drifting values (applied to TEMPORARY variables)
                nextScale = max(0.5, min(1.5, nextScale))
                nextRotation = nextRotation.truncatingRemainder(dividingBy: 360)
                nextBlur = max(0.5, min(5.0, nextBlur))
            }
            
            // Update actual particle state from temporary variables for the next frame
            particles[i].position = nextPosition
            particles[i].scale = nextScale
            particles[i].rotation = nextRotation
            particles[i].blur = nextBlur
        }
    }

    // Handles tap gesture, initiates attraction
    private func handleTap(at location: CGPoint, in size: CGSize) {
        guard !attractionActive else { return } 

        lastTapLocation = location
        attractionActive = true 
        Haptics.shared.play(.light)
        print("DEBUG: Tap detected at \(location), Attraction ACTIVE")
        
        // Removed resetting animationStartTime

        attractTimer?.invalidate()
        attractTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [self] _ in
             guard self.attractionActive else { return } 
             print("DEBUG: Attraction timer finished, Attraction INACTIVE")
             self.attractionActive = false
             self.lastTapLocation = nil
             // Assign new drift targets when attraction ends
             self.startDriftingAnimation(in: size)
        }
    }

    // MARK: - Position Helper

    private func randomPosition(in size: CGSize, edgeAffinity: CGFloat = 0.0) -> CGPoint {
         // edgeAffinity: 0 = purely random, 1 = strongly towards edges
         let padding: CGFloat = 50 // How far off-screen particles can go
         let coreWidth = size.width + 2 * padding
         let coreHeight = size.height + 2 * padding

         let randomX = CGFloat.random(in: -padding...(size.width + padding))
         let randomY = CGFloat.random(in: -padding...(size.height + padding))

         // Basic random position for now, can add edge affinity later if needed
         return CGPoint(x: randomX, y: randomY)
    }
}

// MARK: - Helper Struct for Animation Targets - REMOVED
/*
struct ParticleTargetState {
    ...
}
*/


#Preview {
    // Ensure preview has necessary environment objects
    NavigationView {
        MainPageView()
            .withThemeBridge(appState: AppState(), colorScheme: .light)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
