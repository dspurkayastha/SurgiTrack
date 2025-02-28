//
//  PatientListView.swift
//  SurgiTrack
//
//  Created by Devraj Shome Purkayastha on 28/02/25.
//  Updated on 10/03/25.
//

import SwiftUI
import CoreData

struct PatientListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    
    // Search and filter state
    @State private var searchText = ""
    @State private var showingAdvancedFilters = false
    @State private var selectedStatusFilter: PatientStatusFilter = .all
    @State private var selectedSortOption: PatientSortOption = .nameAsc
    @State private var showingAddPatient = false
    @State private var alertItem: AlertItem?
    
    // Animation states
    @State private var isLoading = true
    @State private var listOpacity = 0.0
    
    // Environment values for adaptability
    @Environment(\.colorScheme) private var colorScheme
    
    // Fetch request and predicate building
    @FetchRequest private var patients: FetchedResults<Patient>
    
    // Namespace for transitions
    @Namespace private var listNamespace
    
    // MARK: - Initialization with advanced filtering
    
    init(searchString: String = "", statusFilter: PatientStatusFilter = .all, sortOption: PatientSortOption = .nameAsc) {
        // Build complex predicate based on filters
        var predicates: [NSPredicate] = []
        
        // Search predicate
        if !searchString.isEmpty {
            let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "firstName CONTAINS[cd] %@", searchString),
                NSPredicate(format: "lastName CONTAINS[cd] %@", searchString),
                NSPredicate(format: "medicalRecordNumber CONTAINS[cd] %@", searchString)
            ])
            predicates.append(searchPredicate)
        }
        
        // Status filter predicate
        switch statusFilter {
        case .active:
            predicates.append(NSPredicate(format: "isDischargedStatus == NO"))
        case .discharged:
            predicates.append(NSPredicate(format: "isDischargedStatus == YES"))
        case .all:
            break // No additional predicate needed
        }
        
        let combinedPredicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // Initialize the fetch request with the built predicate and sort descriptors
        _patients = FetchRequest(
            sortDescriptors: sortOption.sortDescriptors,
            predicate: combinedPredicate,
            animation: .spring()
        )
        
        // Initialize with provided filters
        _searchText = State(initialValue: searchString)
        _selectedStatusFilter = State(initialValue: statusFilter)
        _selectedSortOption = State(initialValue: sortOption)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background color
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Search and filter bar
                searchAndFilterBar
                    .zIndex(1) // Keep above list during animations
                
                if isLoading {
                    loadingView
                } else if patients.isEmpty {
                    emptyStateView
                } else {
                    // Patient list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(patients, id: \.objectID) { patient in
                                NavigationLink(destination: AccordionPatientDetailView(patient: patient)) {
                                    EnhancedPatientCard(patient: patient)
                                        .matchedGeometryEffect(id: patient.id ?? UUID(), in: listNamespace, isSource: true)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                            .padding(.bottom, 8)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .opacity(listOpacity)
                    .animation(.easeInOut(duration: 0.4), value: listOpacity)
                }
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddPatient = true
                        hapticFeedback(style: .medium)
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(appState.currentTheme.primaryColor))
                            .shadow(color: appState.currentTheme.primaryColor.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Patients")
        .navigationBarItems(
            leading: EditButton()
                .disabled(patients.isEmpty),
            trailing: sortButton
        )
        .sheet(isPresented: $showingAddPatient) {
            AddPatientView()
                .environment(\.managedObjectContext, viewContext)
        }
        .alert(item: $alertItem) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingAdvancedFilters) {
            AdvancedFiltersView(
                statusFilter: $selectedStatusFilter,
                sortOption: $selectedSortOption
            )
        }
        .onAppear {
            startLoadingAnimation()
        }
        .onChange(of: searchText) { newValue in
            updateSearchResults(searchString: newValue)
        }
        .onChange(of: selectedStatusFilter) { newValue in
            updateSearchResults(statusFilter: newValue)
        }
        .onChange(of: selectedSortOption) { newValue in
            updateSearchResults(sortOption: newValue)
        }
    }
    
    // MARK: - Component Views
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search name or MRN", text: $searchText)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Filter buttons row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PatientStatusFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            selectedStatusFilter = filter
                        }) {
                            HStack(spacing: 5) {
                                if let iconName = filter.iconName {
                                    Image(systemName: iconName)
                                        .font(.system(size: 12))
                                }
                                
                                Text(filter.title)
                                    .font(.subheadline)
                                    .fontWeight(selectedStatusFilter == filter ? .semibold : .regular)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedStatusFilter == filter ?
                                          filter.color.opacity(0.2) :
                                          Color(.secondarySystemBackground))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedStatusFilter == filter ?
                                            filter.color : Color.clear,
                                            lineWidth: 1)
                            )
                            .foregroundColor(selectedStatusFilter == filter ?
                                             filter.color : .secondary)
                        }
                    }
                    
                    // Advanced filters button
                    Button(action: {
                        showingAdvancedFilters = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 12))
                            Text("More")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(.secondarySystemBackground))
                        )
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(
            Rectangle()
                .fill(Color(UIColor.systemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ForEach(0..<5) { _ in
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(height: 100)
                    .shimmer(isAnimating: true)
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedStatusFilter.emptyStateImage)
                .font(.system(size: 60))
                .foregroundColor(selectedStatusFilter.color.opacity(0.6))
            
            Text(getEmptyStateTitle())
                .font(.title2)
                .fontWeight(.medium)
            
            Text(getEmptyStateMessage())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if selectedStatusFilter != .all && !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    selectedStatusFilter = .all
                }) {
                    Text("Clear Filters")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(appState.currentTheme.primaryColor)
                        .cornerRadius(8)
                }
                .padding(.top)
            } else if selectedStatusFilter == .all && searchText.isEmpty {
                Button(action: {
                    showingAddPatient = true
                }) {
                    Text("Add Patient")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(appState.currentTheme.primaryColor)
                        .cornerRadius(8)
                }
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var sortButton: some View {
        Menu {
            ForEach(PatientSortOption.allCases, id: \.self) { option in
                Button(action: {
                    selectedSortOption = option
                }) {
                    HStack {
                        Text(option.title)
                        if selectedSortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16))
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateSearchResults(
        searchString: String? = nil,
        statusFilter: PatientStatusFilter? = nil,
        sortOption: PatientSortOption? = nil
    ) {
        // Get the new search parameters, defaulting to current values if not provided
        let newSearchString = searchString ?? searchText
        let newStatusFilter = statusFilter ?? selectedStatusFilter
        let newSortOption = sortOption ?? selectedSortOption
        
        // Build the predicate based on search and filter
        var predicates: [NSPredicate] = []
        
        // Search predicate
        if !newSearchString.isEmpty {
            let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "firstName CONTAINS[cd] %@", newSearchString),
                NSPredicate(format: "lastName CONTAINS[cd] %@", newSearchString),
                NSPredicate(format: "medicalRecordNumber CONTAINS[cd] %@", newSearchString)
            ])
            predicates.append(searchPredicate)
        }
        
        // Status filter predicate
        switch newStatusFilter {
        case .active:
            predicates.append(NSPredicate(format: "isDischargedStatus == NO"))
        case .discharged:
            predicates.append(NSPredicate(format: "isDischargedStatus == YES"))
        case .all:
            break // No additional predicate needed
        }
        
        // Combine predicates
        let combinedPredicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // Update the fetch request predicate
        patients.nsPredicate = combinedPredicate
        
        // Update the sort descriptors
        patients.sortDescriptors = newSortOption.sortDescriptors
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            alertItem = AlertItem(
                title: "Error Saving",
                message: "Could not save changes. \(nsError.localizedDescription)"
            )
        }
    }
    
    private func startLoadingAnimation() {
        // Simulate loading state
        isLoading = true
        
        // After a short delay, show the list with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            withAnimation(.easeIn(duration: 0.4)) {
                listOpacity = 1.0
            }
        }
    }
    
    private func getEmptyStateTitle() -> String {
        if !searchText.isEmpty {
            return "No Matches Found"
        } else {
            switch selectedStatusFilter {
            case .all:
                return "No Patients"
            case .active:
                return "No Active Patients"
            case .discharged:
                return "No Discharged Patients"
            }
        }
    }
    
    private func getEmptyStateMessage() -> String {
        if !searchText.isEmpty {
            return "No patients match your search criteria"
        } else {
            switch selectedStatusFilter {
            case .all:
                return "Tap the + button to add your first patient"
            case .active:
                return "There are no active patients in the system"
            case .discharged:
                return "There are no discharged patients in the system"
            }
        }
    }
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Enhanced Patient Card

struct EnhancedPatientCard: View {
    @ObservedObject var patient: Patient
    @Environment(\.colorScheme) private var colorScheme
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Patient info section
            HStack(spacing: 16) {
                // Profile image or initials
                ZStack {
                    if let imageData = patient.profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(patient.initials)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.blue)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(patient.fullName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        patientStatusBadge
                    }
                    
                    if let mrn = patient.medicalRecordNumber {
                        Text("MRN: \(mrn)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 15) {
                        if let dob = patient.dateOfBirth {
                            Text("\(dateFormatter.string(from: dob)) • \(calculateAge(from: dob)) yrs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if patient.isDischargedStatus == false, let bed = patient.bedNumber, !bed.isEmpty {
                            Text("Bed: \(bed)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
            // Stats bar (visible only for active patients)
            if !patient.isDischargedStatus {
                Divider()
                
                HStack(spacing: 0) {
                    patientStatItem(
                        value: "\(getOperativeCount())",
                        label: "Surgeries",
                        icon: "scalpel",
                        color: .orange
                    )
                    
                    Divider()
                        .frame(height: 25)
                    
                    patientStatItem(
                        value: "\(getFollowUpCount())",
                        label: "Follow-ups",
                        icon: "calendar.badge.clock",
                        color: .green
                    )
                    
                    Divider()
                        .frame(height: 25)
                    
                    patientStatItem(
                        value: "\(getAbnormalTestCount())/\(getTestCount())",
                        label: "Tests",
                        icon: "cross.case",
                        color: .red
                    )
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(height: 44)
            } else if patient.dischargeSummary != nil {
                // For discharged patients with discharge summary
                Divider()
                
                HStack {
                    Text("Discharged: \(getDischargeDate())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if patient.lengthOfStay > 0 {
                        Text("Length of stay: \(patient.lengthOfStay) day\(patient.lengthOfStay == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    patient.isDischargedStatus ?
                        Color.gray.opacity(0.2) :
                        Color.blue.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
    
    // Patient status badge
    private var patientStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(patient.isDischargedStatus ? Color.gray : Color.green)
                .frame(width: 8, height: 8)
            
            Text(patient.isDischargedStatus ? "Discharged" : "Active")
                .font(.caption)
                .foregroundColor(patient.isDischargedStatus ? .gray : .green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(patient.isDischargedStatus ?
                      Color.gray.opacity(0.1) :
                      Color.green.opacity(0.1))
        )
    }
    
    // Helper functions for patient stats
    private func getOperativeCount() -> Int {
        return (patient.operativeData as? Set<OperativeData>)?.count ?? 0
    }
    
    private func getFollowUpCount() -> Int {
        return (patient.followUps as? Set<FollowUp>)?.count ?? 0
    }
    
    private func getTestCount() -> Int {
        return (patient.medicalTests as? Set<MedicalTest>)?.count ?? 0
    }
    
    private func getAbnormalTestCount() -> Int {
        return (patient.medicalTests as? Set<MedicalTest>)?.filter { $0.isAbnormal }.count ?? 0
    }
    
    private func getDischargeDate() -> String {
        guard let dischargeSummary = patient.dischargeSummary,
              let dischargeDate = dischargeSummary.dischargeDate else {
            return "Unknown"
        }
        return dateFormatter.string(from: dischargeDate)
    }
    
    private func calculateAge(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
    }
    
    // Stats item view
    private func patientStatItem(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Advanced Filters View

struct AdvancedFiltersView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var statusFilter: PatientStatusFilter
    @Binding var sortOption: PatientSortOption
    
    @State private var tempStatusFilter: PatientStatusFilter
    @State private var tempSortOption: PatientSortOption
    
    init(statusFilter: Binding<PatientStatusFilter>, sortOption: Binding<PatientSortOption>) {
        self._statusFilter = statusFilter
        self._sortOption = sortOption
        self._tempStatusFilter = State(initialValue: statusFilter.wrappedValue)
        self._tempSortOption = State(initialValue: sortOption.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient Status")) {
                    ForEach(PatientStatusFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            tempStatusFilter = filter
                        }) {
                            HStack {
                                if let iconName = filter.iconName {
                                    Image(systemName: iconName)
                                        .foregroundColor(filter.color)
                                }
                                
                                Text(filter.title)
                                
                                Spacer()
                                
                                if tempStatusFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                Section(header: Text("Sort Order")) {
                    ForEach(PatientSortOption.allCases, id: \.self) { option in
                        Button(action: {
                            tempSortOption = option
                        }) {
                            HStack {
                                Text(option.title)
                                
                                Spacer()
                                
                                if tempSortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Apply") {
                    statusFilter = tempStatusFilter
                    sortOption = tempSortOption
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Filter and Sort Options

enum PatientStatusFilter: String, CaseIterable, Identifiable {
    case all
    case active
    case discharged
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .all: return "All Patients"
        case .active: return "Active"
        case .discharged: return "Discharged"
        }
    }
    
    var iconName: String? {
        switch self {
        case .all: return "person.3"
        case .active: return "bed.double"
        case .discharged: return "arrow.up.forward.square"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .active: return .green
        case .discharged: return .gray
        }
    }
    
    var emptyStateImage: String {
        switch self {
        case .all: return "person.3"
        case .active: return "bed.double"
        case .discharged: return "arrow.up.forward.square"
        }
    }
}

enum PatientSortOption: String, CaseIterable, Identifiable {
    case nameAsc
    case nameDesc
    case newest
    case oldest
    case recentlyActive
    case activeFirst
    case dischargedFirst
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .nameAsc: return "Name (A-Z)"
        case .nameDesc: return "Name (Z-A)"
        case .newest: return "Newest First"
        case .oldest: return "Oldest First"
        case .recentlyActive: return "Recently Active"
        case .activeFirst: return "Active First"
        case .dischargedFirst: return "Discharged First"
        }
    }
    
    var sortDescriptors: [SortDescriptor<Patient>] {
        switch self {
        case .nameAsc:
            return [
                SortDescriptor(\Patient.lastName, order: .forward),
                SortDescriptor(\Patient.firstName, order: .forward)
            ]
        case .nameDesc:
            return [
                SortDescriptor(\Patient.lastName, order: .reverse),
                SortDescriptor(\Patient.firstName, order: .reverse)
            ]
        case .newest:
            return [SortDescriptor(\Patient.dateCreated, order: .reverse)]
        case .oldest:
            return [SortDescriptor(\Patient.dateCreated, order: .forward)]
        case .recentlyActive:
            return [SortDescriptor(\Patient.dateModified, order: .reverse)]
        case .activeFirst:
            return [
                SortDescriptor(\Patient.isDischargedStatus, order: .forward),
                SortDescriptor(\Patient.lastName, order: .forward)
            ]
        case .dischargedFirst:
            return [
                SortDescriptor(\Patient.isDischargedStatus, order: .reverse),
                SortDescriptor(\Patient.lastName, order: .forward)
            ]
        }
    }
}

// MARK: - Support Types

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    var isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isAnimating {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .clear,
                                        .white.opacity(0.2),
                                        .clear
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .rotationEffect(.degrees(70))
                            .frame(width: geometry.size.width * 2)
                            .offset(x: -geometry.size.width)
                            .animation(
                                Animation.linear(duration: 1.5)
                                    .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                }
            )
            .mask(content)
    }
}
extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ShimmerEffect(isAnimating: isAnimating))
    }
}

