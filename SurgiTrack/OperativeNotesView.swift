import SwiftUI
import CoreData

struct OperativeNotesView: View {
    // MARK: - Environment & State
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Patient selection state
    @State private var selectedPatient: Patient? = nil
    @State private var isShowingPatientPicker: Bool = false
    
    // Search and filter states
    @State private var searchText: String = ""
    @State private var selectedFilter: OperativeFilter = .all
    @State private var showFilters: Bool = false
    
    // UI state
    @State private var isLoading = false
    @State private var showingAddSheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var animateList = false
    
    // Fetch operative records
    @FetchRequest private var operativeRecords: FetchedResults<OperativeData>
    
    // MARK: - Initialization
    
    init() {
        // Basic fetch request that will be filtered by the selectedPatient
        _operativeRecords = FetchRequest(
            entity: OperativeData.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \OperativeData.operationDate, ascending: false)],
            predicate: nil
        )
    }
    
    // MARK: - Computed Properties
    
    var filteredOperativeRecords: [OperativeData] {
        if selectedPatient == nil {
            return []
        }
        
        return operativeRecords.filter { record in
            // Filter by patient
            guard record.patient == selectedPatient else { return false }
            
            // Filter by search text
            if !searchText.isEmpty {
                let procedureName = record.procedureName?.lowercased() ?? ""
                let surgeonName = record.surgeonName?.lowercased() ?? ""
                return procedureName.contains(searchText.lowercased()) ||
                       surgeonName.contains(searchText.lowercased())
            }
            
            // Filter by type
            if selectedFilter != .all {
                guard let operationType = record.operationType else { return false }
                switch selectedFilter {
                case .laparoscopic:
                    return operationType.lowercased().contains("laparoscopic")
                case .open:
                    return operationType.lowercased().contains("open")
                case .all:
                    return true
                }
            }
            
            return true
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background color
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search and filter bar (visible only when patient is selected)
                if selectedPatient != nil {
                    searchAndFilterBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Main content
                ZStack {
                    if selectedPatient == nil {
                        patientSelectionView
                            .transition(.opacity)
                    } else if isLoading {
                        loadingView
                    } else if filteredOperativeRecords.isEmpty {
                        emptyRecordsView
                            .transition(.opacity)
                    } else {
                        operativeRecordsList
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: selectedPatient)
                .animation(.easeInOut, value: isLoading)
                .animation(.easeInOut, value: filteredOperativeRecords.isEmpty)
            }
            
            // Floating action button
            if selectedPatient != nil {
                floatingActionButton
            }
        }
        .navigationTitle("Operative Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Only show patient selector in toolbar when a patient is selected
            if selectedPatient != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingPatientPicker = true
                    }) {
                        HStack {
                            Text(selectedPatient?.fullName ?? "")
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingPatientPicker) {
            PatientPickerView { patient in
                withAnimation {
                    selectedPatient = patient
                    updateFilters()
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            if let patient = selectedPatient {
                AddOperativeDataView(patient: patient)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onAppear {
            // Animate the list with a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    animateList = true
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search procedures or surgeons", text: $searchText)
                    .disableAutocorrection(true)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                // Filter button
                Button(action: {
                    withAnimation {
                        showFilters.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(selectedFilter != .all ? .blue : .gray)
                        if selectedFilter != .all {
                            Text(selectedFilter.title)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Filter chips - shown when showFilters is true
            if showFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(OperativeFilter.allCases, id: \.self) { filter in
                            filterChip(filter)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 5)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Patient info banner
            if let patient = selectedPatient {
                patientInfoBanner(patient)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
            }
            
            Divider()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func filterChip(_ filter: OperativeFilter) -> some View {
        Button(action: {
            withAnimation {
                selectedFilter = filter
            }
        }) {
            HStack(spacing: 4) {
                Text(filter.title)
                    .font(.caption)
                    .fontWeight(selectedFilter == filter ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selectedFilter == filter ?
                          Color.blue.opacity(0.2) : Color(.systemGray6))
            )
            .foregroundColor(selectedFilter == filter ? .blue : .primary)
        }
    }
    
    private func patientInfoBanner(_ patient: Patient) -> some View {
        HStack {
            // Patient initials or image
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text(patient.initials)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Patient details
            VStack(alignment: .leading, spacing: 2) {
                Text(patient.fullName)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    if let mrn = patient.medicalRecordNumber {
                        Text("MRN: \(mrn)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let dob = patient.dateOfBirth {
                        Text(calculateAge(from: dob))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Record count indicator
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Text("\(filteredOperativeRecords.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private var patientSelectionView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("Select a Patient to Begin")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("View and manage operative notes for your patients")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                isShowingPatientPicker = true
            }) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Select Patient")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading records...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyRecordsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No Operative Records Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if !searchText.isEmpty || selectedFilter != .all {
                Text("Try changing your search or filter criteria")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    searchText = ""
                    selectedFilter = .all
                }) {
                    Text("Clear Filters")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            } else {
                Text("Tap the + button to add an operative record")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var operativeRecordsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredOperativeRecords.enumerated()), id: \.element.objectID) { index, record in
                    NavigationLink(destination: EditOperativeDataView(operativeData: record)) {
                        OperativeRecordCard(record: record)
                            .padding(.horizontal)
                            .offset(y: animateList ? 0 : 50)
                            .opacity(animateList ? 1 : 0)
                            .animation(
                                Animation.spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.05),
                                value: animateList
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 100) // Space for FAB
                .padding(.top, 8)
            }
        }
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateFilters() {
        isLoading = true
        
        // Simulate loading for a better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoading = false
        }
    }
    
    private func calculateAge(from dob: Date) -> String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        
        if let age = ageComponents.year {
            return "\(age) years"
        } else {
            return "Unknown age"
        }
    }
}

// MARK: - Supporting Types

enum OperativeFilter: String, CaseIterable {
    case all = "All"
    case laparoscopic = "Laparoscopic"
    case open = "Open"
    
    var title: String {
        return self.rawValue
    }
}

// MARK: - Enhanced Card View

struct OperativeRecordCard: View {
    let record: OperativeData
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(record.procedureName ?? "Unnamed Procedure")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formattedDate(record.operationDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            
            Divider()
            
            // Details
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    detailRow(icon: "circle.dashed", label: "Type", value: record.operationType ?? "N/A")
                    
                    if let anesthesia = record.anaesthesiaType, !anesthesia.isEmpty {
                        detailRow(icon: "lungs.fill", label: "Anesthesia", value: anesthesia)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 6) {
                    if let surgeon = record.surgeonName, !surgeon.isEmpty {
                        detailRow(icon: "person.crop.rectangle", label: "Surgeon", value: surgeon)
                    }
                    
                    if record.duration > 0 {
                        detailRow(icon: "clock", label: "Duration", value: "\(Int(record.duration)) min")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Preview of findings if available
            if let findings = record.operativeFindings, !findings.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Findings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(findings)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Footer with metadata and actions
            HStack {
                // Attachments indicator if applicable
                if let attachments = record.attachments as? Set<Attachment>, !attachments.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "paperclip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(attachments.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                }
                
                Spacer()
                
                // Edit indicator
                Text("Tap to edit")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
            }
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct OperativeNotesView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview, create dummy patient and operative data
        let context = PersistenceController.preview.container.viewContext
        let dummyPatient = Patient(context: context)
        dummyPatient.firstName = "Sally"
        dummyPatient.lastName = "Smith"
        dummyPatient.dateOfBirth = Date(timeIntervalSince1970: 0)
        dummyPatient.medicalRecordNumber = "12345"
        
        let dummyOpData = OperativeData(context: context)
        dummyOpData.procedureName = "Laparoscopic Cholecystectomy"
        dummyOpData.operationType = "Laparoscopic"
        dummyOpData.operationDate = Date()
        dummyOpData.surgeonName = "Dr. John Doe"
        dummyOpData.anaesthesiaType = "General"
        dummyOpData.duration = 120
        dummyOpData.operativeFindings = "Inflamed gallbladder with multiple stones. No evidence of bile duct injury."
        dummyOpData.patient = dummyPatient
        
        return NavigationView {
            OperativeNotesView()
                .environment(\.managedObjectContext, context)
        }
    }
}
