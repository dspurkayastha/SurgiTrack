import SwiftUI
import CoreData

struct AccordionPatientDetailView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: PatientDetailViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var patient: Patient
    @EnvironmentObject private var appState: AppState
    
    // MARK: - State
    @State private var expandedSections: Set<AccordionSection> = [.demographics, .clinical]
    @State private var expandedCards: Set<String> = ["Overview"]
    @State private var isAnimating = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isLoading = true
    
    // MARK: - Initialization
    init(patient: Patient) {
        self.patient = patient
        self.viewModel = PatientDetailViewModel(patient: patient, context: patient.managedObjectContext!)
    }
    
    // MARK: - Body
    var body: some View {
        BaseScreenTemplate(
            title: patient.fullName,
            showBackButton: true
        ) {
            ZStack {
                if isLoading {
                    ModernLoadingIndicator(style: .circular, size: .large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        ScrollViewReader { scrollProxy in
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("scrollView")).minY
                                )
                            }
                            .frame(height: 0)
                            
                            VStack(spacing: 16) {
                                // Patient Profile and Status
                                patientBanner()
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .id("top")
                                
                                // Quick stats row
                                quickStatsRow()
                                    .padding(.horizontal, 16)
                                
                                // Accordion sections
                                ForEach(AccordionSection.allCases, id: \.self) { section in
                                    accordionSection(section)
                                        .id(section.rawValue)
                                }
                                
                                // Bottom padding for action bar
                                Spacer(minLength: 100)
                            }
                            .padding(.bottom, 16)
                        }
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                    }
                    
                    // Bottom action bar
                    VStack {
                        Spacer()
                        if patient.isDischargedStatus {
                            dischargedActionBar()
                        } else {
                            activePatientActionBar()
                        }
                    }
                }
            }
        }
        .withThemeBridge(appState: appState, colorScheme: colorScheme)
        .sheet(isPresented: $viewModel.showingAddFollowUp) {
            AddFollowUpView(patient: viewModel.patient)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $viewModel.showingAddOperativeData) {
            AddOperativeDataView(patient: viewModel.patient)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $viewModel.showingAddInitialPresentation) {
            AddInitialPresentationView(patient: viewModel.patient)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $viewModel.showingEditPatient) {
            EditPatientView(patient: viewModel.patient)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $viewModel.showingAttachments) {
            AttachmentView(parent: .patient(viewModel.patient))
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $viewModel.showingEditInitialPresentation) {
            if let presentation = viewModel.patient.initialPresentation {
                EditInitialPresentationView(initialPresentation: presentation)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $viewModel.showingDischargePatient) {
            DischargeFormView(patient: viewModel.patient)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $viewModel.showingDischargeSummary) {
            if let dischargeSummary = viewModel.patient.dischargeSummary {
                DischargeSummaryView(dischargeSummary: dischargeSummary)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .alert(isPresented: $viewModel.showConfirmReadmission) {
            Alert(
                title: Text("Readmit Patient"),
                message: Text("Are you sure you want to readmit \(viewModel.patient.fullName)? This will change their status to active."),
                primaryButton: .default(Text("Readmit")) {
                    viewModel.readmitPatient()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            startAnimations()
            // Simulate loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Components
    
    private func patientBanner() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Patient avatar
                if let imageData = patient.profileImageData, let uiImage = UIImage(data: imageData) {
                    ModernAvatar(
                        image: Image(uiImage: uiImage),
                        size: .large,
                        style: .circle
                    )
                } else {
                    ModernAvatar(
                        initials: patient.initials,
                        size: .large,
                        style: .circle
                    )
                }
                
                // Patient info
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    HStack(spacing: 10) {
                        // Status indicator
                        ModernBadge(
                            text: patient.isDischargedStatus ? "DISCHARGED" : "ACTIVE",
                            style: patient.isDischargedStatus ? .secondary : .success,
                            size: .small
                        )
                        
                        if let mrn = patient.medicalRecordNumber, let dob = patient.dateOfBirth {
                            Text("MRN: \(mrn) • \(calculateAge(from: dob))y • \(patient.gender ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Edit button
                Button(action: {
                    viewModel.showingEditPatient = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .offset(x: isAnimating ? 0 : 20)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
    
    private func quickStatsRow() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Surgeries stat
                quickStatItem(
                    title: "Surgeries",
                    value: "\(viewModel.operativeDataArray.count)",
                    iconName: "scalpel",
                    color: .orange
                )
                .onTapGesture {
                    expandSection(.procedures)
                }
                
                // Follow-ups stat
                quickStatItem(
                    title: "Follow-ups",
                    value: "\(viewModel.followUpsArray.count)",
                    iconName: "calendar.badge.clock",
                    color: .green
                )
                .onTapGesture {
                    expandSection(.followUp)
                }
                
                // Tests stat
                let testCount = (patient.medicalTests as? Set<MedicalTest>)?.count ?? 0
                quickStatItem(
                    title: "Tests",
                    value: "\(testCount)",
                    iconName: "cross.case",
                    color: .purple
                )
                .onTapGesture {
                    expandSection(.clinical)
                    toggleCard("Tests")
                }
                
                // Attachments stat
                let attachmentsCount = (patient.attachments as? Set<Attachment>)?.count ?? 0
                quickStatItem(
                    title: "Files",
                    value: "\(attachmentsCount)",
                    iconName: "paperclip",
                    color: .cyan
                )
                .onTapGesture {
                    expandSection(.documents)
                }
                
                // Length of Stay (for discharged patients)
                if patient.isDischargedStatus {
                    quickStatItem(
                        title: "Stay",
                        value: "\(patient.lengthOfStay) day\(patient.lengthOfStay == 1 ? "" : "s")",
                        iconName: "calendar",
                        color: .gray
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func quickStatItem(title: String, value: String, iconName: String, color: Color) -> some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Value and title
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 80)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func accordionSection(_ section: AccordionSection) -> some View {
        ModernList(style: .insetGrouped) {
            ModernListSection {
                // Section header
                Button(action: {
                    toggleSection(section)
                }) {
                    HStack {
                        // Section icon and left highlight bar
                        Rectangle()
                            .fill(section.color)
                            .frame(width: 4, height: 24)
                            .padding(.trailing, 12)
                        
                        Image(systemName: section.iconName)
                            .foregroundColor(section.color)
                            .font(.system(size: 18))
                        
                        Text(section.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Badge count if applicable
                        if let count = getSectionCount(section), count > 0 {
                            ModernBadge(
                                text: "\(count)",
                                style: .secondary,
                                size: .small
                            )
                        }
                        
                        // Chevron indicator
                        Image(systemName: expandedSections.contains(section) ? "chevron.down" : "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, weight: .semibold))
                            .animation(.spring(), value: expandedSections.contains(section))
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Section content (cards)
                if expandedSections.contains(section) {
                    VStack(spacing: 12) {
                        Group {
                            switch section {
                            case .demographics:
                                demographicsContent()
                            case .clinical:
                                clinicalContent()
                            case .procedures:
                                proceduresContent()
                            case .followUp:
                                followUpContent()
                            case .documents:
                                documentsContent()
                            }
                        }
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.65), value: expandedSections.contains(section))
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func accordionCard(title: String, icon: String, color: Color, hasContent: Bool = true, badgeCount: Int? = nil, badgeText: String? = nil, badgeColor: Color = .clear) -> some View {
        VStack(spacing: 0) {
            // Card header
            Button(action: {
                toggleCard(title)
            }) {
                HStack {
                    // Icon in circle
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(color)
                    }
                    
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                    
                    Spacer()
                    
                    // Badge if needed
                    if let count = badgeCount, count > 0 {
                        ModernBadge(
                            text: "\(count)",
                            style: .secondary,
                            size: .small
                        )
                    }
                    
                    if let text = badgeText, !text.isEmpty {
                        ModernBadge(
                            text: text,
                            style: .error,
                            size: .small
                        )
                    }
                    
                    // Chevron
                    Image(systemName: expandedCards.contains(title) ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!hasContent)
            
            // Card content
            if expandedCards.contains(title) {
                VStack {
                    VStack {
                        cardContent(for: title)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                    )
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.25), value: expandedCards.contains(title))
            }
        }
    }
    
    // MARK: - Section Contents
    
    @ViewBuilder
    private func demographicsContent() -> some View {
        // Overview Card
        accordionCard(
            title: "Overview",
            icon: "info.circle",
            color: .blue
        )
        
        // Contact Card
        accordionCard(
            title: "Contact Information",
            icon: "phone",
            color: .blue
        )
        
        // Insurance Card
        accordionCard(
            title: "Insurance",
            icon: "shield",
            color: .blue,
            hasContent: patient.insuranceProvider != nil && !(patient.insuranceProvider?.isEmpty ?? true)
        )
        
        if patient.isDischargedStatus, patient.dischargeSummary != nil {
            // Discharge Card
            accordionCard(
                title: "Discharge Information",
                icon: "arrow.up.forward.square",
                color: .gray
            )
        }
    }
    
    @ViewBuilder
    private func clinicalContent() -> some View {
        // Initial Assessment
        let hasInitialPresentation = patient.initialPresentation != nil
        accordionCard(
            title: "Initial Assessment",
            icon: "stethoscope",
            color: .purple,
            hasContent: hasInitialPresentation
        )
        
        // Test Reports
        let tests = getReports()
        let abnormalCount = tests.filter { $0.isAbnormal }.count
        accordionCard(
            title: "Test Reports",
            icon: "chart.bar.doc.horizontal",
            color: .purple,
            badgeCount: tests.count,
            badgeText: abnormalCount > 0 ? "\(abnormalCount) Abnormal" : nil,
            badgeColor: .red
        )
        
        // Risk Assessment
        let calculations = viewModel.fetchRiskCalculations()
        accordionCard(
            title: "Risk Assessment",
            icon: "function",
            color: .purple,
            badgeCount: calculations.count
        )
    }
    
    @ViewBuilder
    private func proceduresContent() -> some View {
        if viewModel.operativeDataArray.isEmpty {
            emptyStateView(
                title: "No Surgical Procedures",
                message: "Add operative data when the patient undergoes a procedure",
                iconName: "scalpel",
                color: .orange,
                actionButtonTitle: "Add Procedure",
                action: {
                    viewModel.showingAddOperativeData = true
                }
            )
        } else {
            ForEach(viewModel.operativeDataArray, id: \.objectID) { procedure in
                NavigationLink(destination: OperativeDataDetailView(operativeData: procedure)) {
                    procedureCard(procedure)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: {
                viewModel.showingAddOperativeData = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Procedure")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.orange, .orange.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.orange.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private func followUpContent() -> some View {
        if viewModel.followUpsArray.isEmpty {
            emptyStateView(
                title: "No Follow-up Records",
                message: "Add follow-up visits to track patient progress",
                iconName: "calendar.badge.clock",
                color: .green,
                actionButtonTitle: "Add Follow-up",
                action: {
                    viewModel.showingAddFollowUp = true
                }
            )
        } else {
            // Upcoming appointments
            if !viewModel.upcomingAppointmentsArray.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming Appointments")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.upcomingAppointmentsArray, id: \.objectID) { appointment in
                                appointmentCard(appointment)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                }
            }
            
            // Follow-up visits
            VStack(alignment: .leading, spacing: 8) {
                Text("Follow-up Visits")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                
                ForEach(viewModel.followUpsArray, id: \.objectID) { followUp in
                    followUpRow(followUp)
                }
                
                Button(action: {
                    viewModel.showingAddFollowUp = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Follow-up")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.green.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .padding(.top, 8)
            }
        }
        
        // Prescriptions card
        accordionCard(
            title: "Prescriptions",
            icon: "pills",
            color: .green,
            badgeCount: getPrescriptions().count
        )
    }
    
    @ViewBuilder
    private func documentsContent() -> some View {
        // Attachments
        let attachments = getAttachments()
        accordionCard(
            title: "Attachments",
            icon: "paperclip",
            color: .cyan,
            badgeCount: attachments.count
        )
        
        // Timeline
        accordionCard(
            title: "Timeline",
            icon: "clock",
            color: .cyan,
            badgeCount: viewModel.timelineEvents.count
        )
    }
    
    // MARK: - Card Contents
    
    @ViewBuilder
    private func cardContent(for title: String) -> some View {
        switch title {
        case "Overview":
            overviewCardContent()
        case "Contact Information":
            contactCardContent()
        case "Insurance":
            insuranceCardContent()
        case "Discharge Information":
            dischargeCardContent()
        case "Initial Assessment":
            initialAssessmentCardContent()
        case "Test Reports":
            testReportsCardContent()
        case "Risk Assessment":
            riskAssessmentCardContent()
        case "Prescriptions":
            prescriptionsCardContent()
        case "Attachments":
            attachmentsCardContent()
        case "Timeline":
            timelineCardContent()
        default:
            EmptyView()
        }
    }
    
    private func overviewCardContent() -> some View {
        VStack(spacing: 16) {
            // Height and Weight
            if patient.height > 0 || patient.weight > 0 {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if patient.height > 0 {
                        metricCard(
                            title: "Height",
                            value: String(format: "%.1f cm", patient.height),
                            icon: "ruler",
                            color: .blue
                        )
                    }
                    
                    if patient.weight > 0 {
                        metricCard(
                            title: "Weight",
                            value: String(format: "%.1f kg", patient.weight),
                            icon: "scalemass",
                            color: .blue
                        )
                    }
                    
                    if patient.height > 0 && patient.weight > 0 {
                        metricCard(
                            title: "BMI",
                            value: viewModel.calculateBMI(),
                            icon: "figure.arms.open",
                            color: .blue
                        )
                    }
                    
                    if let bloodType = patient.bloodType, !bloodType.isEmpty && bloodType != "Unknown" {
                        metricCard(
                            title: "Blood Type",
                            value: bloodType,
                            icon: "drop",
                            color: .blue
                        )
                    }
                    
                    if let dob = patient.dateOfBirth {
                        metricCard(
                            title: "Age",
                            value: calculateAge(from: dob),
                            icon: "calendar", // Changed icon from "drop" to "calendar" for age
                            color: .blue
                        )
                    }
                }
            }
        }
    }
    
    private func contactCardContent() -> some View {
        VStack(spacing: 12) {
            InfoRowView(
                label: "Phone",
                value: patient.phone ?? patient.contactInfo ?? "Not provided",
                iconName: "phone",
                accentColor: .blue
            )
            
            if let email = patient.contactInfo, email != patient.phone {
                InfoRowView(
                    label: "Email",
                    value: email,
                    iconName: "envelope",
                    accentColor: .blue
                )
            }
            
            InfoRowView(
                label: "Address",
                value: patient.address ?? "Not provided",
                iconName: "location",
                accentColor: .blue
            )
            
            // Emergency Contact
            if let emergencyName = patient.emergencyContactName, !emergencyName.isEmpty {
                Divider()
                    .padding(.vertical, 8)
                
                Text("Emergency Contact")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                InfoRowView(
                    label: "Name",
                    value: emergencyName,
                    iconName: "person",
                    accentColor: .blue
                )
                
                InfoRowView(
                    label: "Phone",
                    value: patient.emergencyContactPhone ?? "Not provided",
                    iconName: "phone",
                    accentColor: .blue
                )
            }
        }
    }
    
    private func insuranceCardContent() -> some View {
        VStack(spacing: 12) {
            InfoRowView(
                label: "Provider",
                value: patient.insuranceProvider ?? "Not provided",
                iconName: "shield",
                accentColor: .blue
            )
            
            InfoRowView(
                label: "Policy Number",
                value: patient.insurancePolicyNumber ?? "Not provided",
                iconName: "number",
                accentColor: .blue
            )
            
            if let details = patient.insuranceDetails, !details.isEmpty {
                InfoRowView(
                    label: "Details",
                    value: details,
                    iconName: "doc.text",
                    accentColor: .blue,
                    isMultiline: true
                )
            }
        }
    }
    
    private func dischargeCardContent() -> some View {
        VStack(spacing: 12) {
            if let dischargeSummary = patient.dischargeSummary {
                InfoRowView(
                    label: "Date",
                    value: formatDate(dischargeSummary.dischargeDate),
                    iconName: "calendar",
                    accentColor: .gray
                )
                
                InfoRowView(
                    label: "Physician",
                    value: dischargeSummary.dischargingPhysician ?? "Unknown",
                    iconName: "person.text.rectangle",
                    accentColor: .gray
                )
                
                Button(action: {
                    viewModel.showingDischargeSummary = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("View Full Discharge Summary")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func initialAssessmentCardContent() -> some View {
        VStack(spacing: 12) {
            if let presentation = patient.initialPresentation {
                InfoRowView(
                    label: "Date",
                    value: formatDate(presentation.presentationDate),
                    iconName: "calendar",
                    accentColor: .purple
                )
                
                // Chief Complaint
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chief Complaint")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(presentation.chiefComplaint ?? "Not specified")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }
                
                // Initial Diagnosis
                VStack(alignment: .leading, spacing: 4) {
                    Text("Initial Diagnosis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(presentation.initialDiagnosis ?? "Not specified")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }
                
                Button(action: {
                    viewModel.showingEditInitialPresentation = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Details")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.purple.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .padding(.top, 8)
            } else {
                Button(action: {
                    viewModel.showingAddInitialPresentation = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Initial Assessment")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.purple.opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
        }
    }
    
    private func testReportsCardContent() -> some View {
        VStack(spacing: 12) {
            let reports = getReports()
            
            if reports.isEmpty {
                emptyStateView(
                    title: "No Test Reports",
                    message: "No lab or imaging tests recorded yet",
                    iconName: "chart.bar.doc.horizontal",
                    color: .purple
                )
            } else {
                ForEach(reports.prefix(5), id: \.objectID) { test in
                    NavigationLink(destination: TestDetailView(test: test)) {
                        reportRow(test)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if reports.count > 5 {
                    Text("+ \(reports.count - 5) more reports")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            
            NavigationLink(destination: ReportsView()) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                    Text("View All Reports")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.purple.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func riskAssessmentCardContent() -> some View {
        VStack(spacing: 12) {
            let calculations = viewModel.fetchRiskCalculations()
            
            if calculations.isEmpty {
                emptyStateView(
                    title: "No Risk Assessments",
                    message: "Perform risk calculations to help with clinical decision-making",
                    iconName: "function",
                    color: .purple
                )
            } else {
                ForEach(calculations.prefix(3), id: \.objectID) { calculation in
                    NavigationLink(destination: CalculationDetailView(calculation: calculation)) {
                        riskAssessmentRow(calculation)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if calculations.count > 3 {
                    Text("+ \(calculations.count - 3) more assessments")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            
            NavigationLink(destination: RiskCalculatorListView(patient: patient)) {
                HStack {
                    Image(systemName: "function")
                    Text("Perform Risk Assessment")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.purple.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func prescriptionsCardContent() -> some View {
        VStack(spacing: 12) {
            let prescriptions = getPrescriptions()
            
            if prescriptions.isEmpty {
                emptyStateView(
                    title: "No Prescriptions",
                    message: "No medications have been prescribed yet",
                    iconName: "pills",
                    color: .green
                )
            } else {
                ForEach(prescriptions, id: \.self) { prescription in
                    HStack {
                        Image(systemName: "pills")
                            .foregroundColor(.green)
                            .frame(width: 40, height: 40)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prescription)
                                .font(.system(size: 15, weight: .medium))
                                .lineLimit(1)
                            
                            Text("Active")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
            
            NavigationLink(destination: PrescriptionsView().environment(\.managedObjectContext, viewContext)) {
                HStack {
                    Image(systemName: "plus")
                    Text("Manage Prescriptions")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.green.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func attachmentsCardContent() -> some View {
        VStack(spacing: 12) {
            let attachments = getAttachments()
            
            if attachments.isEmpty {
                emptyStateView(
                    title: "No Attachments",
                    message: "Add files, images, or documents to this patient's record",
                    iconName: "doc.fill",
                    color: .cyan
                )
            } else {
                // Grid of attachments
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(attachments.prefix(4), id: \.self) { attachment in
                        Button(action: {
                            // View attachment
                        }) {
                            VStack {
                                if let contentType = attachment.contentType, contentType.hasPrefix("image"),
                                   let data = attachment.data, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                } else {
                                    Image(systemName: getAttachmentIcon(for: attachment.contentType ?? ""))
                                        .font(.system(size: 30))
                                        .foregroundColor(.cyan)
                                        .frame(width: 80, height: 80)
                                        .background(Color.cyan.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                                
                                Text(attachment.filename ?? "File")
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: 100)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if attachments.count > 4 {
                    Text("+ \(attachments.count - 4) more files")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            
            Button(action: {
                viewModel.showingAttachments = true
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("Manage Attachments")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.cyan, .cyan.opacity(0.7)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.cyan.opacity(0.3), radius: 3, x: 0, y: 2)
            }
        }
    }
    
    private func timelineCardContent() -> some View {
        VStack(spacing: 12) {
            let events = viewModel.timelineEvents
            
            if events.isEmpty {
                emptyStateView(
                    title: "No Timeline Data",
                    message: "This patient has no recorded events to display on the timeline",
                    iconName: "clock",
                    color: .cyan
                )
            } else {
                ForEach(events.prefix(5), id: \.id) { event in
                    timelineEventRow(event)
                }
                
                if events.count > 5 {
                    Text("+ \(events.count - 5) more events")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Component Row Views
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func procedureCard(_ procedure: OperativeData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(procedure.procedureName ?? "Unknown procedure")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                    
                    if let date = procedure.operationDate {
                        Text(formatDate(date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Operation duration badge
                if procedure.duration > 0 {
                    VStack {
                        Text("\(Int(procedure.duration))")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("min")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .orange.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.orange.opacity(0.3), radius: 3, x: 0, y: 2)
                }
            }
            
            Divider()
            
            HStack(spacing: 8) {
                // Surgeon
                VStack(alignment: .leading, spacing: 2) {
                    Text("Surgeon")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    if let surgeon = procedure.surgeon {
                        Text("\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")")
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    } else if let surgeonName = procedure.surgeonName {
                        Text(surgeonName)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    } else {
                        Text("Unknown")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Anesthesia
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anesthesia")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    if let anesthesia = procedure.anaesthesiaType {
                        Text(anesthesia)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    } else {
                        Text("Not specified")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Blood loss
                VStack(alignment: .leading, spacing: 2) {
                    Text("Blood Loss")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        Text("\(Int(procedure.estimatedBloodLoss))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                        
                        Text("mL")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func appointmentCard(_ appointment: Appointment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Calendar icon with date number
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(getAppointmentColor(type: appointment.appointmentType ?? "").opacity(0.15))
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 0) {
                    Text(getMonthAbbreviation(date: appointment.startTime))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(getAppointmentColor(type: appointment.appointmentType ?? ""))
                    
                    Text(getDayOfMonth(date: appointment.startTime))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(getAppointmentColor(type: appointment.appointmentType ?? ""))
                }
            }
            
            Text(appointment.title ?? "Appointment")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            if let type = appointment.appointmentType {
                Text(type)
                    .font(.system(size: 12))
                    .foregroundColor(getAppointmentColor(type: type))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(getAppointmentColor(type: type).opacity(0.1))
                    .cornerRadius(4)
            }
            
            if let time = appointment.startTime {
                Text(formatTime(time))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 140)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func followUpRow(_ followUp: FollowUp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.green.opacity(0.3), radius: 2, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(followUp.followUpDate))
                        .font(.system(size: 16, weight: .semibold))
                    
                    if let nextAppointment = followUp.nextAppointment {
                        HStack {
                            Text("Next appointment:")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text(formatDate(nextAppointment))
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                }
                
                Spacer()
            }
            
            if let assessment = followUp.outcomeAssessment, !assessment.isEmpty {
                HStack(alignment: .top) {
                    Text("Assessment:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(assessment)
                        .font(.system(size: 14))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if let notes = followUp.followUpNotes, !notes.isEmpty {
                HStack(alignment: .top) {
                    Text("Notes:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.system(size: 14))
                        .lineLimit(3)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func reportRow(_ test: MedicalTest) -> some View {
        HStack {
            // Test type icon
            testTypeIcon(for: test)
                .foregroundColor(getTestColor(for: test))
                .frame(width: 40, height: 40)
                .background(getTestColor(for: test).opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(test.testType ?? "Unknown")
                    .font(.system(size: 15, weight: .medium))
                
                HStack {
                    if test.isAbnormal {
                        Text("Abnormal")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text(formatDate(test.testDate))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func riskAssessmentRow(_ calculation: StoredCalculation) -> some View {
        let riskLevel = getRiskLevel(for: calculation)
        let riskColor = getRiskColor(for: calculation)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "function")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .purple.opacity(0.7)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.purple.opacity(0.3), radius: 2, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(calculation.calculatorName ?? "Risk Assessment")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                    
                    if let date = calculation.calculationDate {
                        Text(formatDate(date))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Risk level badge
                Text(riskLevel.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(riskColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(riskColor.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                // Only show "Score" if it's a calculation that sets a resultScore > 0
                if calculation.resultScore > 0 {
                    VStack(alignment: .center, spacing: 4) {
                        Text("Score")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.0f", calculation.resultScore))
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Display numeric percentage
                VStack(alignment: .center, spacing: 4) {
                    Text("Risk")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", calculation.resultPercentage))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(riskColor)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func timelineEventRow(_ event: TimelineEvent) -> some View {
        HStack(spacing: 16) {
            // Timeline line with circle
            VStack(spacing: 0) {
                Rectangle()
                    .fill(event.color.opacity(0.3))
                    .frame(width: 2)
                    .frame(height: 20)
                    .opacity(0)
                
                Circle()
                    .fill(event.color)
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(event.color.opacity(0.3))
                    .frame(width: 2)
            }
            .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(1)
                        
                        Text(formatDate(event.date))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Event type badge
                    HStack(spacing: 4) {
                        Image(systemName: event.type.iconName)
                            .font(.system(size: 10))
                        
                        Text(event.type.displayName)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(event.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(event.color.opacity(0.1))
                    .cornerRadius(8)
                }
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func emptyStateView(title: String, message: String, iconName: String, color: Color, actionButtonTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(color.opacity(0.6))
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionButtonTitle = actionButtonTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus")
                        Text(actionButtonTitle)
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : color.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemBackground).opacity(0.3) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Bottom Action Bars
    
    private func dischargedActionBar() -> some View {
        let buttonHeight: CGFloat = 44
        return HStack(spacing: 12) {
            Button(action: {
                        viewModel.showConfirmReadmission = true
                    }) {
                        Label("Readmit", systemImage: "arrow.uturn.backward.circle.fill")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(ModernButtonStyle(backgroundColor: .orange))
                    .frame(height: buttonHeight)
                    
                    Button(action: {
                        viewModel.showingDischargeSummary = true
                    }) {
                        // Allow Summary text to be on two lines if needed
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("Discharge\nSummary")
                                .multilineTextAlignment(.leading)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(ModernButtonStyle(backgroundColor: .blue))
                    .frame(height: buttonHeight)
                }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            ZStack(alignment: .top) {
                // Main background with shadow
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .frame(height: 35) // This part gets the shadow
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: -3)
                        .zIndex(1)
                    
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .frame(maxHeight: .infinity)
                }
                
                // Overlay for material effect
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.regularMaterial)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
            }
        )
        .frame(maxWidth: .infinity)
    }
        
    private func activePatientActionBar() -> some View {
        HStack(spacing: 12) {
            Button(action: {
                viewModel.dischargePatient()
            }) {
                Label("Discharge", systemImage: "arrow.up.forward.square.fill")
            }
            .buttonStyle(ModernButtonStyle(backgroundColor: .blue))
            
            Menu {
                Button(action: {
                    viewModel.showingAddOperativeData = true
                }) {
                    Label("Add Surgery", systemImage: "scalpel")
                }
                
                Button(action: {
                    viewModel.showingAddFollowUp = true
                }) {
                    Label("Add Follow-up", systemImage: "calendar.badge.clock")
                }
                
                NavigationLink(destination: ReportsView()) {
                    Label("View Reports", systemImage: "doc.text.magnifyingglass")
                }
                
                NavigationLink(destination: RiskCalculatorListView(patient: patient)) {
                    Label("Risk Assessment", systemImage: "function")
                }
            } label: {
                Label("Quick Actions", systemImage: "ellipsis.circle.fill")
            }
            .buttonStyle(ModernButtonStyle(backgroundColor: .gray))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            // Frosted glass effect
            ZStack {
                if colorScheme == .dark {
                    Color.black.opacity(0.8)
                } else {
                    Color.white.opacity(0.9)
                }
                Rectangle()
                    .fill(Material.regularMaterial)
            }
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
        )
    }
    
    // MARK: - Helper Methods
    
    private func toggleSection(_ section: AccordionSection) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
    
    private func expandSection(_ section: AccordionSection) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            expandedSections.insert(section)
        }
    }
    
    private func toggleCard(_ cardTitle: String) {
        withAnimation {
            if expandedCards.contains(cardTitle) {
                expandedCards.remove(cardTitle)
            } else {
                expandedCards.insert(cardTitle)
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeIn(duration: 0.4)) {
            isAnimating = true
        }
    }
    
    private func getSectionCount(_ section: AccordionSection) -> Int? {
        switch section {
        case .procedures:
            return viewModel.operativeDataArray.count > 0 ? viewModel.operativeDataArray.count : nil
        case .followUp:
            return viewModel.followUpsArray.count > 0 ? viewModel.followUpsArray.count : nil
        case .clinical:
            let testsCount = (patient.medicalTests as? Set<MedicalTest>)?.count ?? 0
            return testsCount > 0 ? testsCount : nil
        case .documents:
            let attachmentsCount = (patient.attachments as? Set<Attachment>)?.count ?? 0
            return attachmentsCount > 0 ? attachmentsCount : nil
        default:
            return nil
        }
    }
    
    private func calculateAge(from dob: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        
        if let age = ageComponents.year {
            return "\(age)"
        } else {
            return "Unknown"
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func getMonthAbbreviation(date: Date?) -> String {
        guard let date = date else { return "?" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func getDayOfMonth(date: Date?) -> String {
        guard let date = date else { return "?" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func getAppointmentColor(type: String?) -> Color {
        guard let type = type else { return .blue }
        
        switch type.lowercased() {
        case "surgery":
            return .red
        case "follow-up":
            return .green
        case "consultation":
            return .blue
        case "pre-operative":
            return .orange
        case "post-operative":
            return .purple
        default:
            return .blue
        }
    }
    
    private func testTypeIcon(for test: MedicalTest) -> some View {
        let iconName: String
        
        switch test.testType?.lowercased() ?? "" {
        case let type where type.contains("blood") || type.contains("cbc"):
            iconName = "drop.fill"
        case let type where type.contains("liver") || type.contains("metabolic"):
            iconName = "waveform.path"
        case let type where type.contains("xray") || type.contains("ct") || type.contains("mri") || type.contains("imaging") || type.contains("usg"):
            iconName = "xray"
        case let type where type.contains("urine") || type.contains("urinalysis"):
            iconName = "flask.fill"
        case let type where type.contains("coagulation") || type.contains("clotting"):
            iconName = "bandage.fill"
        default:
            iconName = "chart.bar.doc.horizontal"
        }
        
        return Image(systemName: iconName)
            .font(.system(size: 16))
    }
    
    private func getTestColor(for test: MedicalTest) -> Color {
        switch test.testType?.lowercased() ?? "" {
        case let type where type.contains("blood") || type.contains("cbc"):
            return .red
        case let type where type.contains("liver") || type.contains("metabolic"):
            return .orange
        case let type where type.contains("xray") || type.contains("ct") || type.contains("mri") || type.contains("imaging") || type.contains("usg"):
            return .purple
        case let type where type.contains("urine") || type.contains("urinalysis"):
            return .yellow
        case let type where type.contains("coagulation") || type.contains("clotting"):
            return .blue
        default:
            return .gray
        }
    }
    
    private func getAttachmentIcon(for contentType: String) -> String {
        switch contentType {
        case _ where contentType.hasPrefix("image"):
            return "photo"
        case _ where contentType.hasPrefix("application/pdf"):
            return "doc.text.fill"
        case _ where contentType.hasPrefix("text"):
            return "doc.text"
        case _ where contentType.hasPrefix("video"):
            return "film"
        case _ where contentType.hasPrefix("audio"):
            return "waveform"
        case _ where contentType.hasPrefix("application/msword") || contentType.hasPrefix("application/vnd.openxmlformats-officedocument.wordprocessingml"):
            return "doc.fill"
        case _ where contentType.hasPrefix("application/vnd.ms-excel") || contentType.hasPrefix("application/vnd.openxmlformats-officedocument.spreadsheetml"):
            return "chart.bar.doc.horizontal"
        default:
            return "doc.fill"
        }
    }
    
    private func getRiskLevel(for calculation: StoredCalculation) -> RiskLevel {
        switch calculation.resultPercentage {
        case 0..<5:
            return .veryLow
        case 5..<15:
            return .low
        case 15..<30:
            return .moderate
        case 30..<50:
            return .high
        case 50...:
            return .veryHigh
        default:
            return .unknown
        }
    }
    
    private func getRiskColor(for calculation: StoredCalculation) -> Color {
        // Determine color based on risk level
        let riskLevel = getRiskLevel(for: calculation)
        switch riskLevel {
        case .veryLow:
            return .green
        case .low:
            return .mint
        case .moderate:
            return .yellow
        case .high:
            return .orange
        case .veryHigh:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    // MARK: - Data Access
    
    private func getReports() -> [MedicalTest] {
        let set = patient.medicalTests as? Set<MedicalTest> ?? []
        return set.sorted { ($0.testDate ?? Date()) > ($1.testDate ?? Date()) }
    }
    
    private func getPrescriptions() -> [String] {
        [
            "Metformin 500mg BID",
            "Lisinopril 10mg daily"
        ]
    }
    
    private func getAttachments() -> [Attachment] {
        let set = patient.attachments as? Set<Attachment> ?? []
        return set.sorted { ($0.dateCreated ?? Date()) > ($1.dateCreated ?? Date()) }
    }
}

// MARK: - Supporting Types

enum AccordionSection: String, CaseIterable {
    case demographics = "Demographics & Profile"
    case clinical = "Clinical Information"
    case procedures = "Surgical Procedures"
    case followUp = "Follow-up Visits"
    case documents = "Documents & Attachments"
    
    var color: Color {
        switch self {
        case .demographics: return .blue
        case .clinical: return .purple
        case .procedures: return .orange
        case .followUp: return .green
        case .documents: return .cyan
        }
    }
    
    var iconName: String {
        switch self {
        case .demographics: return "person.text.rectangle"
        case .clinical: return "stethoscope"
        case .procedures: return "scalpel"
        case .followUp: return "calendar.badge.clock"
        case .documents: return "doc.fill"
        }
    }
}

enum RiskLevel: String {
    case veryLow = "Very Low"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    case unknown = "Unknown"
}

struct ModernButtonStyle: ButtonStyle {
    var backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [backgroundColor, backgroundColor.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
            .cornerRadius(10)
            .shadow(color: backgroundColor.opacity(0.3), radius: 3, x: 0, y: configuration.isPressed ? 1 : 2)
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct InfoRowView: View {
    let label: String
    let value: String
    let iconName: String?
    let accentColor: Color
    let isMultiline: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        label: String,
        value: String,
        iconName: String? = nil,
        accentColor: Color,
        isMultiline: Bool = false
    ) {
        self.label = label
        self.value = value
        self.iconName = iconName
        self.accentColor = accentColor
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        if isMultiline {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if let iconName = iconName {
                        Image(systemName: iconName)
                            .foregroundColor(accentColor)
                            .frame(width: 18)
                    }
                    
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if value == "N/A" || value.isEmpty {
                    Text("Not provided")
                        .italic()
                        .foregroundColor(.secondary)
                } else {
                    Text(value)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground).opacity(0.7))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }
            }
        } else {
            HStack(alignment: .top, spacing: 10) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(accentColor)
                        .frame(width: 18)
                }
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
                
                if value == "N/A" || value.isEmpty {
                    Text("Not provided")
                        .italic()
                        .foregroundColor(.secondary)
                } else {
                    Text(value)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Supporting Types and Extensions

struct EnhancedStatusBannerView: View {
    @ObservedObject var patient: Patient
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(patient.isDischargedStatus ? Color.gray : Color.green)
                .frame(width: 10, height: 10)
            
            Text(patient.isDischargedStatus ? "DISCHARGED" : "ACTIVE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(patient.isDischargedStatus ? .gray : .green)
            
            Spacer()
            
            Group {
                if !patient.isDischargedStatus, let bedNumber = patient.bedNumber, !bedNumber.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double")
                            .font(.caption)
                        Text("Bed \(bedNumber)")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
                
                if patient.isDischargedStatus && patient.lengthOfStay > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("\(patient.lengthOfStay) day\(patient.lengthOfStay == 1 ? "" : "s")")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            
            if let dob = patient.dateOfBirth {
                Text("Age: \(calculateAge(from: dob)) • \(patient.gender ?? "Unknown")")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(patient.isDischargedStatus ? Color.gray.opacity(0.1) : Color.green.opacity(0.1))
        )
    }
    
    private func calculateAge(from dob: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        if let age = ageComponents.year {
            return "\(age)"
        } else {
            return "Unknown"
        }
    }
}
enum DetailSegment: String, CaseIterable, Hashable {
    case overview = "Overview"
    case initial = "Initial Presentation"
    case reports = "Medical Reports"
    case operative = "Surgical Procedures"
    case followup = "Follow-up Visits"
    case prescriptions = "Prescriptions"
    case riskAssessment = "Risk Assessment"
    case attachments = "Attachments"
    case timeline = "Timeline"
    
    var color: Color {
        switch self {
        case .overview: return Color.blue
        case .initial: return Color.indigo
        case .reports: return Color.teal
        case .operative: return Color.orange
        case .followup: return Color.green
        case .prescriptions: return Color.purple
        case .riskAssessment: return Color.red
        case .attachments: return Color.mint
        case .timeline: return Color.gray
        }
    }
    
    var iconName: String {
        switch self {
        case .overview: return "person.text.rectangle"
        case .initial: return "stethoscope"
        case .reports: return "chart.bar.doc.horizontal"
        case .operative: return "scalpel"
        case .followup: return "calendar.badge.clock"
        case .prescriptions: return "pill"
        case .riskAssessment: return "function"
        case .attachments: return "paperclip"
        case .timeline: return "clock"
        }
    }
}
struct EmptyStateView: View {
    let title: String
    let message: String
    let iconName: String
    let color: Color
    let actionButton: AnyView?
    
    init(
        title: String,
        message: String,
        iconName: String,
        color: Color,
        actionButton: AnyView? = nil
    ) {
        self.title = title
        self.message = message
        self.iconName = iconName
        self.color = color
        self.actionButton = actionButton
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(color.opacity(0.6))
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionButton = actionButton {
                actionButton
                    .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
