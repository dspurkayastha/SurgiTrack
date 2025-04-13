import SwiftUI
import CoreData
import Combine

struct ReportsView: View {
    // MARK: - Environment & State
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject var navigationState: ReportsNavigationState

    @State private var searchText = ""
    @State private var showingFilterOptions = false
    @State private var selectedFilter: ReportFilter = .all
    @State private var selectedPatientID: NSManagedObjectID?
    @State private var showingPatientPicker = false
    @State private var showingNewTestSheet = false
    @State private var selectedTestType: TestType?
    @State private var isRefreshing = false
    @State private var showingDateFilter = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var showingAlertMessage = false
    @State private var alertMessage = ""
    @State private var showingRadiologyOptions = false
    @State private var showingEnhancedTrendsView = false
    @State private var navigationActive = false

    // Computed property to get a Patient from selectedPatientID
    private var selectedPatient: Patient? {
        if let id = selectedPatientID {
            return viewContext.object(with: id) as? Patient
        }
        return nil
    }

    // MARK: - Fetched Results with NSPredicate for real-time filtering
    @FetchRequest private var testResults: FetchedResults<MedicalTest>

    init() {
        // Initialize with an empty predicate; it will be updated in onAppear.
        self._testResults = FetchRequest<MedicalTest>(
            sortDescriptors: [NSSortDescriptor(keyPath: \MedicalTest.testDate, ascending: false)],
            predicate: nil,
            animation: .default
        )
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Medical Reports")
                .toolbar { toolbarItems }
                .navigationViewStyle(StackNavigationViewStyle())
                .onAppear(perform: onAppearHandler)
                .onDisappear { print("ReportsView: onDisappear") }
                .onChange(of: searchText) { _ in updatePredicate() }
                .onChange(of: selectedFilter) { _ in updatePredicate() }
                .onChange(of: selectedPatientID) { _ in updatePredicate() }
                .onChange(of: navigationActive) { newValue in
                    if !newValue { navigationState.ensureButtonVisibility() }
                }
                // Sheet presentations
                .sheet(isPresented: $showingPatientPicker) { patientPickerView }
                .sheet(isPresented: $showingNewTestSheet) { newTestSheetView }
                .sheet(isPresented: $showingEnhancedTrendsView) { enhancedTrendsView }
                .sheet(isPresented: $showingDateFilter) { dateFilterView }
                // Action sheets
                .actionSheet(isPresented: $showingFilterOptions) { filterActionSheet }
                .actionSheet(isPresented: $showingRadiologyOptions) { radiologyActionSheet }
                // Alert
                .alert(isPresented: $showingAlertMessage) { alertView }
        }
    }

    // MARK: - Extracted Subviews

    /// Contains the search bar, filter bar, and either the test list or empty state.
    private var contentView: some View {
        VStack(spacing: 0) {
            searchAndFilterBar
            if testResults.isEmpty {
                emptyStateView
            } else {
                mainContentView
            }
        }
    }

    /// Groups toolbar items together.
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarTrailing) { addButton }
            ToolbarItem(placement: .navigationBarLeading) { patientPickerButton }
            ToolbarItem(placement: .navigationBarTrailing) { analysisButton }
            ToolbarItem(placement: .navigationBarTrailing) { dateFilterButton }
        }
    }

    // MARK: - Sheet Views

    private var patientPickerView: some View {
        PatientPickerView(selectedID: $selectedPatientID)
            .environment(\.managedObjectContext, viewContext)
    }

    private var newTestSheetView: some View {
        AddMedicalTestView(patient: selectedPatient, testType: $selectedTestType)
            .environment(\.managedObjectContext, viewContext)
    }

    private var enhancedTrendsView: some View {
        EnhancedTrendsView.createWithPatient(selectedPatient)
            .environment(\.managedObjectContext, viewContext)
            .onDisappear {
                print("EnhancedTrendsView: onDisappear")
                navigationState.ensureButtonVisibility()
            }
    }

    private var dateFilterView: some View {
        DateFilterView(startDate: $startDate, endDate: $endDate, onApply: {
            updatePredicate()
        })
    }

    // MARK: - Action Sheets and Alert

    private var filterActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Filter Reports"),
            buttons: [
                .default(Text("All Reports")) { selectedFilter = .all },
                .default(Text("Abnormal Results")) { selectedFilter = .abnormal },
                .default(Text("Pending Results")) { selectedFilter = .pending },
                .default(Text("Last 7 Days")) { selectedFilter = .recent },
                .cancel()
            ]
        )
    }

    private var radiologyActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Select Radiology Type"),
            buttons: radiologyActionSheetButtons
        )
    }

    private var alertView: Alert {
        Alert(
            title: Text("Information"),
            message: Text(alertMessage),
            dismissButton: .default(Text("OK"))
        )
    }

    // MARK: - Lifecycle Handler

    private func onAppearHandler() {
        print("ReportsView: onAppear")
        updatePredicate()
        navigationState.ensureButtonVisibility()
    }

    // MARK: - Main Content & Buttons

    private var mainContentView: some View {
        ZStack(alignment: .top) {
            if isRefreshing {
                ProgressView()
                    .padding()
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(8)
                    .padding(.top, 20)
                    .zIndex(1)
            }
            testsList
                .refreshable {
                    await refreshData()
                }
        }
    }

    private var addButton: some View {
        Menu {
            Button(action: {
                selectedTestType = nil
                showingNewTestSheet = true
            }) {
                Label("Standard Test", systemImage: "flask.fill")
            }
            Button(action: {
                showingRadiologyOptions = true
            }) {
                Label("Radiological Test", systemImage: "person.and.background.dotted")
            }
        } label: {
            Image(systemName: "plus")
        }
    }

    private var patientPickerButton: some View {
        Button(action: { showingPatientPicker = true }) {
            HStack {
                Image(systemName: "person.crop.circle")
                Text(selectedPatient?.fullName ?? "All Patients")
                    .font(.subheadline)
            }
        }
    }

    private var analysisButton: some View {
        Button(action: {
            if navigationState.showingAnalysisButton {
                showingEnhancedTrendsView = true
            }
        }) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                Text("Analysis")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .onAppear { print("🔹 Analysis Button: onAppear") }
            .onDisappear { print("🔹 Analysis Button: onDisappear") }
        }
        .id("analysisButton")
        .opacity(navigationState.showingAnalysisButton ? 1.0 : 0.0)
        .disabled(!navigationState.showingAnalysisButton)
        .onAppear {
            print("🔷 ReportsView: Rendering Analysis button, showingAnalysisButton=\(navigationState.showingAnalysisButton)")
        }
    }

    private var dateFilterButton: some View {
        Button(action: { showingDateFilter = true }) {
            Image(systemName: "calendar")
        }
    }

    private var testsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(testResults, id: \.objectID) { test in
                    NavigationLink(destination:
                        TestDetailView(test: test)
                            .environmentObject(navigationState)
                            .onAppear { navigationActive = true }
                            .onDisappear { navigationActive = false }
                    ) {
                        TestRow(test: test)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "chart.line.text.clipboard")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.6))
            Text("No Medical Tests Found")
                .font(.title3)
                .fontWeight(.semibold)
            if selectedFilter != .all || selectedPatientID != nil || !searchText.isEmpty || isDateRangeActive() {
                Text("Try changing your filters or search criteria")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                Text("Add a new test to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            HStack(spacing: 16) {
                Button(action: {
                    selectedTestType = nil
                    showingNewTestSheet = true
                }) {
                    HStack {
                        Image(systemName: "flask.fill")
                        Text("Add Lab Test")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                Button(action: { showingRadiologyOptions = true }) {
                    HStack {
                        Image(systemName: "xray")
                        Text("Add Imaging")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.top, 10)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Supporting Subviews

    private func filterChip(title: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.15)))
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
            .foregroundColor(color)
        }
    }

    private func filterBadge(text: String, color: Color, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.15)))
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        .foregroundColor(color)
    }

    // MARK: - Methods

    private func updatePredicate() {
        var predicates: [NSPredicate] = []
        
        // Search text predicate
        if !searchText.isEmpty {
            let testTypePredicate = NSPredicate(format: "testType CONTAINS[cd] %@", searchText)
            let patientNamePredicate = NSPredicate(format: "patient.firstName CONTAINS[cd] %@ OR patient.lastName CONTAINS[cd] %@", searchText, searchText)
            let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [testTypePredicate, patientNamePredicate])
            predicates.append(searchPredicate)
        }
        
        // Patient filter
        if let patientID = selectedPatientID {
            predicates.append(NSPredicate(format: "patient == %@", patientID))
        }
        
        // Status filter
        switch selectedFilter {
        case .abnormal:
            predicates.append(NSPredicate(format: "isAbnormal == YES"))
        case .pending:
            predicates.append(NSPredicate(format: "status == %@", "Pending"))
        case .recent:
            let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            predicates.append(NSPredicate(format: "testDate >= %@", lastWeek as NSDate))
        case .all:
            break
        }
        
        // Date range filter
        if isDateRangeActive() {
            let adjustedEndDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
            predicates.append(NSPredicate(format: "testDate >= %@ AND testDate < %@", startDate as NSDate, adjustedEndDate as NSDate))
        }
        
        let compoundPredicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        testResults.nsPredicate = compoundPredicate
    }

    private func refreshData() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        DispatchQueue.main.async {
            self.updatePredicate()
            self.isRefreshing = false
        }
    }

    private func isDateRangeActive() -> Bool {
        let isDefaultStart = Calendar.current.isDate(startDate, inSameDayAs: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date())
        let isDefaultEnd = Calendar.current.isDate(endDate, inSameDayAs: Date())
        return !(isDefaultStart && isDefaultEnd)
    }

    private func resetDateRange() {
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        endDate = Date()
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
    private var searchAndFilterBar: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search tests or patients", text: $searchText)
                    .autocapitalization(.none)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                Button(action: { showingFilterOptions = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .padding(.leading, 8)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Filter tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    filterChip(title: "Blood Tests", systemImage: "drop.fill", color: .red) {
                        selectedTestType = .blood
                        showingNewTestSheet = true
                    }
                    filterChip(title: "Metabolic Panels", systemImage: "syringe.fill", color: .orange) {
                        selectedTestType = .metabolic
                        showingNewTestSheet = true
                    }
                    filterChip(title: "Imaging", systemImage: "x.square.fill", color: .purple) {
                        showingRadiologyOptions = true
                    }
                    filterChip(title: "Urinalysis", systemImage: "flask.fill", color: .yellow) {
                        selectedTestType = .urinalysis
                        showingNewTestSheet = true
                    }
                    filterChip(title: "Coagulation", systemImage: "bandage.fill", color: .blue) {
                        selectedTestType = .coagulation
                        showingNewTestSheet = true
                    }
                    filterChip(title: "Trend Analysis", systemImage: "chart.bar.doc.horizontal", color: .blue) {
                        showingEnhancedTrendsView = true
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Filter indicator
            if selectedFilter != .all || selectedPatientID != nil || isDateRangeActive() {
                HStack {
                    if selectedFilter != .all {
                        filterBadge(text: selectedFilter.displayName, color: .blue) {
                            selectedFilter = .all
                            updatePredicate()
                        }
                    }
                    if let patient = selectedPatient {
                        filterBadge(text: "Patient: \(patient.fullName)", color: .green) {
                            selectedPatientID = nil
                            updatePredicate()
                        }
                    }
                    if isDateRangeActive() {
                        filterBadge(text: "Date: \(formatShortDate(startDate)) - \(formatShortDate(endDate))", color: .orange) {
                            resetDateRange()
                            updatePredicate()
                        }
                    }
                    Spacer()
                    Button("Clear All") {
                        selectedFilter = .all
                        selectedPatientID = nil
                        resetDateRange()
                        updatePredicate()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            Divider()
        }
    }
    private var radiologyActionSheetButtons: [ActionSheet.Button] {
        [
            .default(Text("USG (Hepatobiliary)")) {
                selectedTestType = .usgHepatobiliary
                showingNewTestSheet = true
            },
            .default(Text("USG (Inguinal)")) {
                selectedTestType = .usgInguinal
                showingNewTestSheet = true
            },
            .default(Text("USG (Whole Abdomen)")) {
                selectedTestType = .usgAbdomen
                showingNewTestSheet = true
            },
            .default(Text("USG (KUBP)")) {
                selectedTestType = .usgKUBP
                showingNewTestSheet = true
            },
            .default(Text("MRCP")) {
                selectedTestType = .mrcp
                showingNewTestSheet = true
            },
            .default(Text("MRI Perineum")) {
                selectedTestType = .mriPerineum
                showingNewTestSheet = true
            },
            .default(Text("MRI Pelvis")) {
                selectedTestType = .mriPelvis
                showingNewTestSheet = true
            },
            .default(Text("CECT (Thorax)")) {
                selectedTestType = .cectThorax
                showingNewTestSheet = true
            },
            .default(Text("CECT (Abdomen)")) {
                selectedTestType = .cectAbdomen
                showingNewTestSheet = true
            },
            .default(Text("CECT (Triphasic)")) {
                selectedTestType = .cectTriphasic
                showingNewTestSheet = true
            },
            .cancel()
        ]
    }
}

// MARK: - TestRow

struct TestRow: View {
    @ObservedObject var test: MedicalTest
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                testTypeIcon
                VStack(alignment: .leading, spacing: 2) {
                    Text(test.testType ?? "Unknown Test")
                        .font(.headline)
                    if let patientName = test.patient?.fullName {
                        Text(patientName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    statusBadge
                }
            }
            if let summary = test.summary, !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.vertical, 4)
            }
            if let attachments = test.attachments as? Set<Attachment>, !attachments.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(attachments.count) attachment\(attachments.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            if test.isAbnormal {
                abnormalResultsPreview
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(test.isAbnormal ? Color.red.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var testTypeIcon: some View {
        let iconName: String
        let color: Color
        
        switch test.testType?.lowercased() ?? "" {
        case let type where type.contains("blood") || type.contains("cbc"):
            iconName = "drop.fill"
            color = .red
        case let type where type.contains("liver") || type.contains("metabolic"):
            iconName = "syringe.fill"
            color = .orange
        case let type where type.contains("xray") || type.contains("ct") || type.contains("mri") || type.contains("imaging") || type.contains("usg") || type.contains("mrcp") || type.contains("cect"):
            iconName = "xray"
            color = .purple
        case let type where type.contains("urine") || type.contains("urinalysis"):
            iconName = "flask.fill"
            color = .yellow
        case let type where type.contains("coagulation") || type.contains("clotting"):
            iconName = "bandage.fill"
            color = .blue
        default:
            iconName = "chart.line.text.clipboard"
            color = .gray
        }
        
        return Image(systemName: iconName)
            .foregroundColor(color)
            .font(.system(size: 24))
            .frame(width: 40)
    }
    
    private var statusBadge: some View {
        let status = test.status ?? "Completed"
        let color: Color
        
        switch status.lowercased() {
        case "pending":
            color = .orange
        case "abnormal":
            color = .red
        case "completed":
            color = .green
        default:
            color = .gray
        }
        
        return Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
    
    private var abnormalResultsPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Abnormal Results")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.bottom, 2)
            let abnormalParams = (test.testParameters as? Set<TestParameter>)?.filter { $0.isAbnormal } ?? []
            if !abnormalParams.isEmpty {
                ForEach(Array(abnormalParams.prefix(3)), id: \.objectID) { param in
                    HStack {
                        Text(param.parameterName ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(param.value ?? "")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        if let unit = param.unit, !unit.isEmpty {
                            Text(unit)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                if abnormalParams.count > 3 {
                    Text("+ \(abnormalParams.count - 3) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding(8)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var formattedDate: String {
        guard let date = test.testDate else { return "Unknown date" }
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today,' h:mm a"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "'Yesterday,' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Date Filter View

struct DateFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var startDate: Date
    @Binding var endDate: Date
    var onApply: () -> Void

    @State private var tempStartDate: Date
    @State private var tempEndDate: Date

    init(startDate: Binding<Date>, endDate: Binding<Date>, onApply: @escaping () -> Void) {
        self._startDate = startDate
        self._endDate = endDate
        self.onApply = onApply
        self._tempStartDate = State(initialValue: startDate.wrappedValue)
        self._tempEndDate = State(initialValue: endDate.wrappedValue)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: $tempStartDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $tempEndDate, in: tempStartDate..., displayedComponents: .date)
                }
                Section {
                    Button("Last 7 Days") {
                        tempStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        tempEndDate = Date()
                    }
                    Button("Last 30 Days") {
                        tempStartDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                        tempEndDate = Date()
                    }
                    Button("Last 90 Days") {
                        tempStartDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
                        tempEndDate = Date()
                    }
                    Button("This Year") {
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.year], from: Date())
                        tempStartDate = calendar.date(from: DateComponents(year: components.year, month: 1, day: 1)) ?? Date()
                        tempEndDate = Date()
                    }
                }
                Section {
                    Button("Apply Filter") {
                        startDate = tempStartDate
                        endDate = tempEndDate
                        onApply()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
                Section {
                    Button("Reset") {
                        tempStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                        tempEndDate = Date()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter by Date")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Apply") {
                    startDate = tempStartDate
                    endDate = tempEndDate
                    onApply()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Supporting Types

enum ReportFilter {
    case all, abnormal, pending, recent
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .abnormal: return "Abnormal Results"
        case .pending: return "Pending Results"
        case .recent: return "Last 7 Days"
        }
    }
}

enum TestType: String, CaseIterable, Identifiable {
    // Standard tests
    case blood = "Complete Blood Count"
    case metabolic = "Comprehensive Metabolic Panel"
    case liver = "Liver Function Test"
    case kidney = "Kidney Function Test"
    case urinalysis = "Urinalysis"
    case coagulation = "Coagulation Profile"
    case lipid = "Lipid Profile"
    
    // Radiological tests
    case usgHepatobiliary = "USG (Hepatobiliary)"
    case usgInguinal = "USG (Inguinal)"
    case usgAbdomen = "USG (Whole Abdomen)"
    case usgKUBP = "USG (KUBP)"
    case mrcp = "MRCP"
    case mriPerineum = "MRI Perineum"
    case mriPelvis = "MRI Pelvis"
    case cectThorax = "CECT (Thorax)"
    case cectAbdomen = "CECT (Abdomen)"
    case cectTriphasic = "CECT (Triphasic)"
    case other = "Other Test"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .blood, .liver, .kidney, .lipid:
            return "drop.fill"
        case .metabolic:
            return "syringe.fill"
        case .urinalysis:
            return "flask.fill"
        case .coagulation:
            return "bandage.fill"
        case .usgHepatobiliary, .usgInguinal, .usgAbdomen, .usgKUBP:
            return "waveform.path.ecg"
        case .mrcp, .mriPerineum, .mriPelvis:
            return "magnifyingglass"
        case .cectThorax, .cectAbdomen, .cectTriphasic:
            return "xray"
        case .other:
            return "doc.text.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .blood, .liver, .kidney, .lipid:
            return .red
        case .metabolic:
            return .orange
        case .urinalysis:
            return .yellow
        case .coagulation:
            return .blue
        case .usgHepatobiliary, .usgInguinal, .usgAbdomen, .usgKUBP:
            return .green
        case .mrcp, .mriPerineum, .mriPelvis:
            return .purple
        case .cectThorax, .cectAbdomen, .cectTriphasic:
            return .purple
        case .other:
            return .gray
        }
    }
}

