import SwiftUI
import CoreData

import SwiftUI
import CoreData

struct EnhancedPatientDetailView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: PatientDetailViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var patient: Patient
    
    // MARK: - State
    @State private var expandedCards: Set<DetailSegment> = []
    @State private var editMode = false
    @State private var isAnimating = false
    @State private var scrollOffset: CGFloat = 0
    @State private var reportsUpdated = false
    @State private var cardAnimations: [String: Bool] = [:]
    @State private var selectedCardID: String? = nil
    
    // MARK: - Animation Properties
    private let cardSpringAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3)
    private let fadeAnimation = Animation.easeInOut(duration: 0.3)
    
    // MARK: - Initialization
    init(patient: Patient) {
        self.patient = patient
        self.viewModel = PatientDetailViewModel(patient: patient, context: patient.managedObjectContext!)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95),
                    Color(.systemBackground).opacity(0.97)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .border(Color.blue)
            
            // Subtle grid pattern
            VStack(spacing: 0) {
                ForEach(0..<30) { _ in
                    HStack(spacing: 0) {
                        ForEach(0..<30) { _ in
                            Rectangle()
                                .fill(Color.blue.opacity(0.02))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .opacity(0.3)
            .border(Color.green)
            
            // Main Content using a flexible layout
            ScrollView(.vertical, showsIndicators: true) {
                ScrollViewReader { scrollProxy in
                    // GeometryReader retained solely for scroll offset tracking
                    
                    VStack(spacing: 20) {
                        profileHeader()
                            .padding(.top, 16)
                            .id("top")
                        
                        // Status banner
                        EnhancedStatusBannerView(patient: viewModel.patient)
                            .transition(.scale.combined(with: .opacity))
                        
                        // Dashboard Cards
                        cardView(segment: .overview, expanded: expandedCards.contains(.overview), content: { overviewCard })
                        cardView(segment: .initial, expanded: expandedCards.contains(.initial), content: { initialPresentationCard })
                        cardView(segment: .reports, expanded: expandedCards.contains(.reports), content: { reportsCard })
                        cardView(segment: .operative, expanded: expandedCards.contains(.operative), content: { operativeDataCard })
                        cardView(segment: .followup, expanded: expandedCards.contains(.followup), content: { followUpCard })
                        cardView(segment: .prescriptions, expanded: expandedCards.contains(.prescriptions), content: { prescriptionCard })
                        cardView(segment: .riskAssessment, expanded: expandedCards.contains(.riskAssessment), content: { riskAssessmentCard })
                        cardView(segment: .attachments, expanded: expandedCards.contains(.attachments), content: { attachmentsCard })
                        cardView(segment: .timeline, expanded: expandedCards.contains(.timeline), content: { timelineCard })
                        
                        // Bottom spacing
                        Spacer(minLength: UIScreen.main.bounds.height * 0.1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                    .onChange(of: expandedCards) { newValue in
                        if let segment = newValue.first, !expandedCards.contains(segment) {
                            withAnimation {
                                scrollProxy.scrollTo(segment.rawValue, anchor: .top)
                            }
                        }
                    }
                    .onAppear {
                        reportsUpdated.toggle() // Triggers UI refresh when the view appears
                    }
                }
            }
            .coordinateSpace(name: "scrollView")
            
            
            // Bottom floating action bar
            VStack {
                Spacer()
                if viewModel.patient.isDischargedStatus {
                    dischargedActionBar()
                } else {
                    activePatientActionBar()
                }
            }
        }
        .navigationTitle(viewModel.patient.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: HStack(spacing: 16) {
                Button(action: {
                    viewModel.showingAttachments = true
                }) {
                    Image(systemName: "paperclip")
                        .imageScale(.medium)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Circle().fill(Color(.secondarySystemBackground)))
                }
                
                Button(action: {
                    withAnimation {
                        editMode.toggle()
                    }
                }) {
                    Image(systemName: editMode ? "checkmark.square.fill" : "square.and.pencil")
                        .imageScale(.medium)
                        .foregroundColor(editMode ? .blue : .primary)
                        .padding(8)
                        .background(Circle().fill(Color(.secondarySystemBackground)))
                }
            }
        )
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
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay(
            ZStack {
                if viewModel.isLoading {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                    
                    ProgressView()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                        .shadow(radius: 10)
                }
            }
        )
        .onAppear {
            animateCards()
        }
    }
// MARK: - View Components
    
    private func profileHeader() -> some View {
        HStack(spacing: 15) {
            // Patient image
            ZStack {
                if let imageData = viewModel.patient.profileImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.5)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    
                    Text(viewModel.patient.initials)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Patient info
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.patient.fullName)
                    .font(.title2)
                    .tracking(-0.2)
                    .lineLimit(1)
                
                if let mrn = viewModel.patient.medicalRecordNumber {
                    Label {
                        Text(mrn)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "number")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                viewModel.showingEditPatient = true
            }) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(x: isAnimating ? 0 : 20)
                    .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 6)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
    
    // MARK: - Card Generator
    private func cardView<Content: View>(
        segment: DetailSegment,
        expanded: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            // Card Header
            HStack {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(segment.color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    // Icon
                    Image(systemName: segment.iconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(segment.color)
                }
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(segment.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .tracking(-0.2)
                        .lineLimit(1)
                    
                    switch segment {
                    case .operative:
                        Text("\(viewModel.operativeDataArray.count) procedure\(viewModel.operativeDataArray.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    case .followup:
                        Text("\(viewModel.followUpsArray.count) visit\(viewModel.followUpsArray.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    case .reports:
                        Text("\(reports.count) report\(reports.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    case .prescriptions:
                        Text("\(prescriptions.count) medication\(prescriptions.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    case .attachments:
                        Text("\(attachments.count) file\(attachments.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    default:
                        if let subtitle = getCardSubtitle(for: segment) {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Expand button
                Button(action: {
                    withAnimation(cardSpringAnimation) {
                        toggleCardExpansion(segment)
                    }
                }) {
                    Image(systemName: expanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(segment.color.opacity(0.7))
                }
            }
            .padding(16)
            .background(
                Color(.systemBackground)
                    .cornerRadius(18, corners: expanded ? [.topLeft, .topRight] : .allCorners)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(cardSpringAnimation) {
                    toggleCardExpansion(segment)
                }
            }
            
            // Card content
            if expanded {
                VStack {
                    content()
                        .padding(16)
                        .frame(maxWidth: .infinity)
                }
                .background(
                    Color(.systemBackground)
                        .cornerRadius(18, corners: [.bottomLeft, .bottomRight])
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.horizontal, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(expanded ? 0.12 : 0.1), radius: expanded ? 10 : 8, x: 0, y: expanded ? 5 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            segment.color.opacity(0.3),
                            segment.color.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: expanded ? 1.5 : 0.5
                )
        )
        // Flexible layout: use maxWidth to fill the parent container
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .scaleEffect(cardAnimations[segment.rawValue] == true ? 1.0 : 0.95)
        .opacity(cardAnimations[segment.rawValue] == true ? 1.0 : 0.0)
        .offset(y: cardAnimations[segment.rawValue] == true ? 0 : 20)
    }
    
    // MARK: - Card Views
    
    private var overviewCard: some View {
        if expandedCards.contains(.overview) {
            return AnyView(
                VStack(spacing: 16) {
                    // Height and weight
                    if viewModel.patient.height > 0 || viewModel.patient.weight > 0 {
                        HStack(spacing: 12) {
                            if viewModel.patient.height > 0 {
                                metricCard(
                                    title: "Height",
                                    value: String(format: "%.1f cm", viewModel.patient.height),
                                    icon: "ruler",
                                    color: CardGradients.overview[0]
                                )
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            if viewModel.patient.weight > 0 {
                                metricCard(
                                    title: "Weight",
                                    value: String(format: "%.1f kg", viewModel.patient.weight),
                                    icon: "scalemass",
                                    color: CardGradients.overview[0]
                                )
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // BMI
                    if viewModel.patient.height > 0 && viewModel.patient.weight > 0 {
                        InfoRowView(
                            label: "BMI",
                            value: viewModel.calculateBMI(),
                            iconName: "figure.arms.open",
                            accentColor: CardGradients.overview[0]
                        )
                    }
                    
                    // Blood type
                    if let bloodType = viewModel.patient.bloodType, !bloodType.isEmpty && bloodType != "Unknown" {
                        InfoRowView(
                            label: "Blood Type",
                            value: bloodType,
                            iconName: "drop",
                            accentColor: CardGradients.overview[0]
                        )
                    }
                    
                    // Contact info
                    sectionTitle("Contact Information")
                    
                    InfoRowView(
                        label: "Phone",
                        value: viewModel.patient.phone ?? viewModel.patient.contactInfo ?? "Not provided",
                        iconName: "phone",
                        accentColor: CardGradients.overview[0]
                    )
                    
                    if let email = viewModel.patient.contactInfo, email != viewModel.patient.phone {
                        InfoRowView(
                            label: "Email",
                            value: email,
                            iconName: "envelope",
                            accentColor: CardGradients.overview[0]
                        )
                    }
                    
                    InfoRowView(
                        label: "Address",
                        value: viewModel.patient.address ?? "Not provided",
                        iconName: "location",
                        accentColor: CardGradients.overview[0]
                    )
                    
                    // Emergency Contact
                    if let emergencyName = viewModel.patient.emergencyContactName, !emergencyName.isEmpty {
                        sectionTitle("Emergency Contact")
                        
                        InfoRowView(
                            label: "Name",
                            value: emergencyName,
                            iconName: "person",
                            accentColor: CardGradients.overview[0]
                        )
                        
                        InfoRowView(
                            label: "Phone",
                            value: viewModel.patient.emergencyContactPhone ?? "Not provided",
                            iconName: "phone",
                            accentColor: CardGradients.overview[0]
                        )
                    }
                    
                    // Insurance
                    if let insurance = viewModel.patient.insuranceProvider, !insurance.isEmpty {
                        sectionTitle("Insurance")
                        
                        InfoRowView(
                            label: "Provider",
                            value: insurance,
                            iconName: "shield",
                            accentColor: CardGradients.overview[0]
                        )
                        
                        InfoRowView(
                            label: "Policy Number",
                            value: viewModel.patient.insurancePolicyNumber ?? "Not provided",
                            iconName: "number",
                            accentColor: CardGradients.overview[0]
                        )
                        
                        if let details = viewModel.patient.insuranceDetails, !details.isEmpty {
                            InfoRowView(
                                label: "Details",
                                value: details,
                                iconName: "doc.text",
                                accentColor: CardGradients.overview[0],
                                isMultiline: true
                            )
                        }
                    }
                    
                    // Discharge info
                    if viewModel.patient.isDischargedStatus, let dischargeSummary = viewModel.patient.dischargeSummary {
                        sectionTitle("Discharge Information")
                        
                        InfoRowView(
                            label: "Date",
                            value: viewModel.formatDate(dischargeSummary.dischargeDate),
                            iconName: "calendar",
                            accentColor: CardGradients.overview[0]
                        )
                        
                        InfoRowView(
                            label: "Physician",
                            value: dischargeSummary.dischargingPhysician ?? "Unknown",
                            iconName: "person.text.rectangle",
                            accentColor: CardGradients.overview[0]
                        )
                        
                        InfoRowView(
                            label: "Length of Stay",
                            value: "\(viewModel.patient.lengthOfStay) day\(viewModel.patient.lengthOfStay == 1 ? "" : "s")",
                            iconName: "hourglass",
                            accentColor: CardGradients.overview[0]
                        )
                        
                        Button(action: {
                            viewModel.showingDischargeSummary = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("View Discharge Summary")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: CardGradients.overview),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                }
            )
        } else {
            return AnyView(
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        InfoRowView(
                            label: "MRN",
                            value: viewModel.patient.medicalRecordNumber ?? "Unknown",
                            accentColor: CardGradients.overview[0]
                        )
                        
                        if let dob = viewModel.patient.dateOfBirth {
                            InfoRowView(
                                label: "Date of Birth",
                                value: viewModel.formatDate(dob),
                                accentColor: CardGradients.overview[0]
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        InfoRowView(
                            label: "Gender",
                            value: viewModel.patient.gender ?? "Not specified",
                            accentColor: CardGradients.overview[0]
                        )
                        
                        if let bloodType = viewModel.patient.bloodType, !bloodType.isEmpty && bloodType != "Unknown" {
                            InfoRowView(
                                label: "Blood Type",
                                value: bloodType,
                                accentColor: CardGradients.overview[0]
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            )
        }
    }
    
    private var initialPresentationCard: some View {
        if let presentation = viewModel.patient.initialPresentation {
            if expandedCards.contains(.initial) {
                return AnyView(
                    VStack(spacing: 16) {
                        // Date and main details
                        InfoRowView(
                            label: "Date",
                            value: viewModel.formatDate(presentation.presentationDate),
                            iconName: "calendar",
                            accentColor: CardGradients.initial[0]
                        )
                        
                        InfoRowView(
                            label: "Chief Complaint",
                            value: presentation.chiefComplaint ?? "N/A",
                            iconName: "exclamationmark.bubble",
                            accentColor: CardGradients.initial[0],
                            isMultiline: true
                        )
                        
                        InfoRowView(
                            label: "Initial Diagnosis",
                            value: presentation.initialDiagnosis ?? "N/A",
                            iconName: "stethoscope",
                            accentColor: CardGradients.initial[0],
                            isMultiline: true
                        )
                        
                        // History
                        sectionTitle("Clinical Assessment", color: CardGradients.initial[0])
                        
                        InfoRowView(
                            label: "History",
                            value: presentation.historyOfPresentIllness ?? "N/A",
                            iconName: "list.bullet.clipboard",
                            accentColor: CardGradients.initial[0],
                            isMultiline: true
                        )
                        
                        InfoRowView(
                            label: "Physical Exam",
                            value: presentation.physicalExamination ?? "N/A",
                            iconName: "person.text.rectangle",
                            accentColor: CardGradients.initial[0],
                            isMultiline: true
                        )
                        
                        // Other details
                        if let pastMedicalHistory = presentation.pastMedicalHistory, !pastMedicalHistory.isEmpty {
                            InfoRowView(
                                label: "Medical History",
                                value: pastMedicalHistory,
                                iconName: "clock.arrow.circlepath",
                                accentColor: CardGradients.initial[0],
                                isMultiline: true
                            )
                        }
                        
                        // Edit button
                        if editMode {
                            Button(action: {
                                viewModel.showingEditInitialPresentation = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit Presentation Details")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: CardGradients.initial),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                            .padding(.top, 8)
                        }
                    }
                )
            } else {
                return AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRowView(
                            label: "Presentation",
                            value: viewModel.formatDate(presentation.presentationDate),
                            accentColor: CardGradients.initial[0]
                        )
                        
                        InfoRowView(
                            label: "Complaint",
                            value: presentation.chiefComplaint ?? "N/A",
                            accentColor: CardGradients.initial[0]
                        )
                        
                        InfoRowView(
                            label: "Diagnosis",
                            value: presentation.initialDiagnosis ?? "N/A",
                            accentColor: CardGradients.initial[0]
                        )
                    }
                )
            }
        } else {
            return AnyView(
                EmptyStateView(
                    title: "No Initial Presentation Data",
                    message: "Add initial presentation details to complete the patient record",
                    iconName: "clipboard.fill",
                    color: CardGradients.initial[0],
                    actionButton: editMode ? AnyView(
                        Button(action: {
                            viewModel.showingAddInitialPresentation = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Initial Presentation")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: CardGradients.initial),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    ) : nil
                )
            )
        }
    }
    
    private var reportsCard: some View {
        if expandedCards.contains(.reports) {
            return AnyView(
                VStack(spacing: 16) {
                    if reports.isEmpty {
                        EmptyStateView(
                            title: "No Reports",
                            message: "No lab or imaging tests recorded yet",
                            iconName: "doc.text.magnifyingglass",
                            color: CardGradients.reports[0]
                        )
                    } else {
                        ForEach(reports.prefix(5), id: \.objectID) { test in
                            NavigationLink(destination: TestDetailView(test: test)) {
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
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemBackground))
                                )
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
                                gradient: Gradient(colors: CardGradients.reports),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            )
        } else {
            return AnyView(
                VStack {
                    if reports.isEmpty {
                        Text("No reports available")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else if let latest = reports.first {
                        HStack {
                            testTypeIcon(for: latest)
                                .foregroundColor(getTestColor(for: latest))
                                .frame(width: 28, height: 28)
                                .background(getTestColor(for: latest).opacity(0.1))
                                .clipShape(Circle())
                            
                            Text(latest.testType ?? "Unknown")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(formatDate(latest.testDate))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                
                            if latest.isAbnormal {
                                Text("Abnormal")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            )
        }
    }
    
    private var operativeDataCard: some View {
        if viewModel.operativeDataArray.isEmpty {
            return AnyView(
                EmptyStateView(
                    title: "No Surgical Procedures",
                    message: "Add operative data when the patient undergoes a procedure",
                    iconName: "scalpel",
                    color: CardGradients.operative[0],
                    actionButton: editMode ? AnyView(
                        Button(action: {
                            viewModel.showingAddOperativeData = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Surgical Procedure")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: CardGradients.operative),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    ) : nil
                )
            )
        } else {
            if expandedCards.contains(.operative) {
                return AnyView(
                    VStack(spacing: 16) {
                        ForEach(viewModel.operativeDataArray, id: \.objectID) { procedure in
                            NavigationLink(destination: OperativeDataDetailView(operativeData: procedure)) {
                                modernOperativeProcedureView(procedure)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if editMode {
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
                                        gradient: Gradient(colors: CardGradients.operative),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                        }
                    }
                )
            } else {
                return AnyView(
                    VStack(spacing: 8) {
                        if let latestProcedure = viewModel.operativeDataArray.first {
                            NavigationLink(destination: OperativeDataDetailView(operativeData: latestProcedure)) {
                                modernOperativeProcedureView(latestProcedure)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if viewModel.operativeDataArray.count > 1 {
                                Text("+ \(viewModel.operativeDataArray.count - 1) more procedure\(viewModel.operativeDataArray.count > 2 ? "s" : "")")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 4)
                            }
                        }
                    }
                )
            }
        }
    }
    
    private var followUpCard: some View {
        if viewModel.followUpsArray.isEmpty {
            return AnyView(
                EmptyStateView(
                    title: "No Follow-up Records",
                    message: "Add follow-up visits to track patient progress",
                    iconName: "calendar.badge.clock",
                    color: CardGradients.followup[0],
                    actionButton: editMode ? AnyView(
                        Button(action: {
                            viewModel.showingAddFollowUp = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Follow-up Visit")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: CardGradients.followup),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    ) : nil
                )
            )
        } else {
            if expandedCards.contains(.followup) {
                return AnyView(
                    VStack(spacing: 16) {
                        // Upcoming appointments
                        if !viewModel.upcomingAppointmentsArray.isEmpty {
                            sectionTitle("Upcoming Appointments", color: CardGradients.followup[0])
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.upcomingAppointmentsArray, id: \.objectID) { appointment in
                                        modernAppointmentCard(appointment)
                                            .frame(width: 140, height: 150) // Fixed size
                                    }
                                }
                                .padding(.horizontal) // Add padding
                            }
                            .frame(height: 170)
                            .border(Color.red)
                            
                            Divider()
                                .padding(.vertical, 8)
                        }
                        
                        // Follow-up visits
                        sectionTitle("Follow-up Visits", color: CardGradients.followup[0])
                        
                        ForEach(viewModel.followUpsArray, id: \.objectID) { followUp in
                            modernFollowUpView(followUp)
                        }
                        
                        // Add button
                        if editMode {
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
                                        gradient: Gradient(colors: CardGradients.followup),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                        }
                    }
                )
            } else {
                return AnyView(
                    VStack(spacing: 8) {
                        if let latestFollowUp = viewModel.followUpsArray.first {
                            modernFollowUpView(latestFollowUp)
                            
                            if viewModel.followUpsArray.count > 1 {
                                Text("+ \(viewModel.followUpsArray.count - 1) more follow-up\(viewModel.followUpsArray.count > 2 ? "s" : "")")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 4)
                            }
                        }
                    }
                )
            }
        }
    }
    
    private var prescriptionCard: some View {
        if expandedCards.contains(.prescriptions) {
            return AnyView(
                VStack(spacing: 16) {
                    if prescriptions.isEmpty {
                        EmptyStateView(
                            title: "No Prescriptions",
                            message: "No medications have been prescribed yet",
                            iconName: "pills.fill",
                            color: CardGradients.prescriptions[0]
                        )
                    } else {
                        ForEach(prescriptions, id: \.self) { prescription in
                            HStack {
                                Image(systemName: "pills.fill")
                                    .foregroundColor(CardGradients.prescriptions[0])
                                    .frame(width: 40, height: 40)
                                    .background(CardGradients.prescriptions[0].opacity(0.1))
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
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }
                    
                    NavigationLink(destination: PrescriptionsView().environment(\.managedObjectContext, viewContext)) {
                        HStack {
                            Image(systemName: "plus.app")
                            Text("Add Prescription")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: CardGradients.prescriptions),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            )
        } else {
            return AnyView(
                VStack {
                    if prescriptions.isEmpty {
                        Text("No medications prescribed")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        Text("\(prescriptions.count) medication\(prescriptions.count == 1 ? "" : "s")")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
            )
        }
    }
    
    private var riskAssessmentCard: some View {
        let calculations = viewModel.fetchRiskCalculations()
        
        if calculations.isEmpty {
            return AnyView(
                EmptyStateView(
                    title: "No Risk Assessments",
                    message: "Perform risk calculations to help with clinical decision-making",
                    iconName: "function",
                    color: CardGradients.risk[0],
                    actionButton: AnyView(
                        NavigationLink(destination: RiskCalculatorListView(patient: viewModel.patient)) {
                            HStack {
                                Image(systemName: "function")
                                Text("Perform Risk Assessment")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: CardGradients.risk),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    )
                )
            )
        } else {
            if expandedCards.contains(.riskAssessment) {
                return AnyView(
                    VStack(spacing: 16) {
                        ForEach(calculations.prefix(3), id: \.objectID) { calculation in
                            NavigationLink(destination: CalculationDetailView(calculation: calculation)) {
                                modernRiskAssessmentView(calculation: calculation)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if calculations.count > 3 {
                            NavigationLink(destination: CalculationHistoryView(patient: viewModel.patient)) {
                                Text("View All Assessments")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(CardGradients.risk[0])
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(CardGradients.risk[0].opacity(0.1))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Calculator buttons
                        sectionTitle("Risk Calculators", color: CardGradients.risk[0])
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            calculatorButton(
                                title: "ASA Classification",
                                iconName: "cross.circle",
                                color: .green,
                                destination: RiskCalculatorInputView(
                                    calculator: RiskCalculatorStore.shared.createASACalculator(),
                                    patient: viewModel.patient
                                )
                            )
                            
                            calculatorButton(
                                title: "RCRI",
                                iconName: "heart.fill",
                                color: .red,
                                destination: RiskCalculatorInputView(
                                    calculator: RiskCalculatorStore.shared.calculators.first(where: { $0.calculationType == .rcri }) ?? RiskCalculatorStore.shared.createRCRICalculator(),
                                    patient: viewModel.patient
                                )
                            )
                            
                            calculatorButton(
                                title: "Surgical Apgar",
                                iconName: "waveform.path.ecg",
                                color: .blue,
                                destination: RiskCalculatorInputView(
                                    calculator: RiskCalculatorStore.shared.calculators.first(where: { $0.calculationType == .apgarScore }) ?? RiskCalculatorStore.shared.createSurgicalApgarCalculator(),
                                    patient: viewModel.patient
                                )
                            )
                            
                            calculatorButton(
                                title: "All Calculators",
                                iconName: "list.bullet",
                                color: .gray,
                                destination: RiskCalculatorListView(patient: viewModel.patient)
                            )
                        }
                    }
                )
            } else {
                return AnyView(
                    VStack(spacing: 8) {
                        if let latestCalculation = calculations.first {
                            NavigationLink(destination: CalculationDetailView(calculation: latestCalculation)) {
                                modernRiskAssessmentView(calculation: latestCalculation)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if calculations.count > 1 {
                                Text("+ \(calculations.count - 1) more assessment\(calculations.count > 2 ? "s" : "")")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 4)
                            }
                        }
                    }
                )
            }
        }
    }
    
    private var attachmentsCard: some View {
        if expandedCards.contains(.attachments) {
            return AnyView(
                VStack(spacing: 16) {
                    if attachments.isEmpty {
                        EmptyStateView(
                            title: "No Attachments",
                            message: "Add files, images, or documents to this patient's record",
                            iconName: "doc.fill",
                            color: CardGradients.attachments[0]
                        )
                    } else {
                        // Display a grid of attachments
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(attachments.prefix(4), id: \.self) { attachment in
                                Button(action: {
                                    // Action to view the attachment
                                }) {
                                    VStack {
                                        if let contentType = attachment.contentType, contentType.hasPrefix("image"),
                                           let data = attachment.data, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        } else {
                                            Image(systemName: getAttachmentIcon(for: attachment.contentType ?? ""))
                                                .font(.system(size: 30))
                                                .foregroundColor(CardGradients.attachments[0])
                                                .frame(width: 80, height: 80)
                                                .background(CardGradients.attachments[0].opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
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
                                gradient: Gradient(colors: CardGradients.attachments),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            )
        } else {
            return AnyView(
                VStack {
                    Text("\(attachments.count) file\(attachments.count == 1 ? "" : "s") attached")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            )
        }
    }
    
    private var timelineCard: some View {
        if viewModel.timelineEvents.isEmpty {
            return AnyView(
                EmptyStateView(
                    title: "No Timeline Data",
                    message: "This patient has no recorded events to display on the timeline",
                    iconName: "clock",
                    color: CardGradients.timeline[0]
                )
            )
        } else {
            return AnyView(
                VStack(spacing: 16) {
                    ForEach(viewModel.timelineEvents.prefix(expandedCards.contains(.timeline) ? viewModel.timelineEvents.count : 2), id: \.id) { event in
                        modernTimelineEventCard(event)
                    }
                    
                    if !expandedCards.contains(.timeline) && viewModel.timelineEvents.count > 2 {
                        Text("+ \(viewModel.timelineEvents.count - 2) more events")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            )
        }
    }
    
    // MARK: - Supporting Components
    
    private func modernOperativeProcedureView(_ procedure: OperativeData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(procedure.procedureName ?? "Unknown procedure")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    if let date = procedure.operationDate {
                        Text(viewModel.formatDate(date))
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
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: CardGradients.operative),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: CardGradients.operative[0].opacity(0.3), radius: 3, x: 0, y: 2)
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
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func modernFollowUpView(_ followUp: FollowUp) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: CardGradients.followup),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Circle())
                
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
                        .lineLimit(expandedCards.contains(.followup) ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if let notes = followUp.followUpNotes, !notes.isEmpty {
                HStack(alignment: .top) {
                    Text("Notes:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.system(size: 14))
                        .lineLimit(expandedCards.contains(.followup) ? nil : 2)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func modernAppointmentCard(_ appointment: Appointment) -> some View {
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
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func modernRiskAssessmentView(calculation: StoredCalculation) -> some View {
        let riskLevel = getRiskLevel(for: calculation)
        let riskColor = getRiskColor(for: calculation)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "function")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: CardGradients.risk),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Circle())
                
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
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
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
    
    enum RiskLevel: String {
        case veryLow = "Very Low"
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case veryHigh = "Very High"
        case unknown = "Unknown"
    }
    
    private func modernTimelineEventCard(_ event: TimelineEvent) -> some View {
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
                        .lineLimit(expandedCards.contains(.timeline) ? nil : 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func sectionTitle(_ text: String, color: Color = CardGradients.overview[0]) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private func calculatorButton<Destination: View>(title: String, iconName: String, color: Color, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 36)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    struct InfoRowView: View {
        let label: String
        let value: String
        let iconName: String?
        let accentColor: Color
        let isMultiline: Bool
        
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
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
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
                        .frame(width: 80, alignment: .leading)
                    
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

    

    private func toggleCardExpansion(_ segment: DetailSegment) {
        // Calculate animation duration based on content complexity
        let animationDuration: Double
        
        // Determine animation duration based on card content size
        switch segment {
        case .overview:
            let hasEmergencyContact = viewModel.patient.emergencyContactName != nil && !viewModel.patient.emergencyContactName!.isEmpty
            let hasInsurance = viewModel.patient.insuranceProvider != nil && !viewModel.patient.insuranceProvider!.isEmpty
            let hasDischargeInfo = viewModel.patient.isDischargedStatus && viewModel.patient.dischargeSummary != nil
            let sectionsCount = [true, hasEmergencyContact, hasInsurance, hasDischargeInfo].filter { $0 }.count
            animationDuration = 0.4 + (Double(sectionsCount) * 0.1)
            
        case .initial:
            if let presentation = viewModel.patient.initialPresentation {
                let hasHistory = presentation.historyOfPresentIllness != nil && !presentation.historyOfPresentIllness!.isEmpty
                let hasExam = presentation.physicalExamination != nil && !presentation.physicalExamination!.isEmpty
                let hasMedicalHistory = presentation.pastMedicalHistory != nil && !presentation.pastMedicalHistory!.isEmpty
                let contentComplexity = [hasHistory, hasExam, hasMedicalHistory].filter { $0 }.count
                animationDuration = 0.4 + (Double(contentComplexity) * 0.1)
            } else {
                animationDuration = 0.4
            }
            
        case .timeline where viewModel.timelineEvents.count > 5:
            animationDuration = 0.8
        case .timeline where viewModel.timelineEvents.count > 2:
            animationDuration = 0.6
        case .timeline:
            animationDuration = 0.5
            
        case .operative where viewModel.operativeDataArray.count > 3:
            animationDuration = 0.7
        case .operative where viewModel.operativeDataArray.count > 0:
            animationDuration = 0.5
            
        case .followup where viewModel.followUpsArray.count > 3:
            animationDuration = 0.7
        case .followup where viewModel.followUpsArray.count > 0:
            animationDuration = 0.5
            
        case .reports where reports.count > 5:
            animationDuration = 0.7
        case .reports where reports.count > 0:
            animationDuration = 0.5
            
        case .attachments where attachments.count > 4:
            animationDuration = 0.6
            
        case .prescriptions where prescriptions.count > 2:
            animationDuration = 0.6
            
        case .riskAssessment:
            let calculations = viewModel.fetchRiskCalculations()
            animationDuration = calculations.count > 2 ? 0.6 : 0.5
            
        default:
            animationDuration = 0.5
        }

        withAnimation(.spring(response: animationDuration, dampingFraction: 0.7)) {
            if expandedCards.contains(segment) {
                expandedCards.remove(segment)
            } else {
                expandedCards.insert(segment)
            }
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
    
    private func getCardSubtitle(for segment: DetailSegment) -> String? {
        switch segment {
        case .overview:
            return "Demographics and basic information"
        case .initial:
            return "Assessment and diagnosis details"
        case .riskAssessment:
            return "Surgical risk evaluation tools"
        case .timeline:
            return "Chronological view of key events"
        default:
            return nil
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
    
    // MARK: - Action Bars
        private func dischargedActionBar() -> some View {
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.showConfirmReadmission = true
                }) {
                    Label("Readmit", systemImage: "arrow.uturn.backward.circle.fill")
                }
                .buttonStyle(ModernButtonStyle(backgroundColor: .orange))
                
                Button(action: {
                    viewModel.showingDischargeSummary = true
                }) {
                    Label("Discharge Summary", systemImage: "doc.text.fill")
                }
                .buttonStyle(ModernButtonStyle(backgroundColor: .blue))
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
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
                    
                    NavigationLink(destination: RiskCalculatorListView(patient: viewModel.patient)) {
                        Label("Risk Assessment", systemImage: "function")
                    }
                } label: {
                    Label("Quick Actions", systemImage: "ellipsis.circle.fill")
                }
                .buttonStyle(ModernButtonStyle(backgroundColor: .gray))
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
    
    // MARK: - Animations
    
    private func animateCards() {
        // Clear animations
        cardAnimations = [:]
        
        // Schedule animations for each card with a short delay between them
        let segments: [DetailSegment] = [.overview, .initial, .reports, .operative, .followup, .prescriptions, .riskAssessment, .attachments, .timeline]
        
        for (index, segment) in segments.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 * Double(index)) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    cardAnimations[segment.rawValue] = true
                }
            }
        }
    }
    
    // MARK: - Data Access
    
    private var reports: [MedicalTest] {
        let set = viewModel.patient.medicalTests as? Set<MedicalTest> ?? []
        return set.sorted { ($0.testDate ?? Date()) > ($1.testDate ?? Date()) }
    }
    
    private var prescriptions: [String] {
        [
            "Metformin 500mg BID",
            "Lisinopril 10mg daily"
        ]
    }
    
    private var attachments: [Attachment] {
        let set = viewModel.patient.attachments as? Set<Attachment> ?? []
        return set.sorted { ($0.dateCreated ?? Date()) > ($1.dateCreated ?? Date()) }
    }
}

// MARK: - Supporting Types and Extensions

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
