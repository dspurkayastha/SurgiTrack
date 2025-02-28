import SwiftUI
import CoreData
import Combine

// MARK: - Supporting Structures

struct PrescriptionItemModel: Identifiable {
    let id = UUID()
    var drugName: String
    var strength: String
    var dosage: String
    var frequency: String
    var route: String
    var duration: String
    var specialInstructions: String
    var productID: NSManagedObjectID?
}

// MARK: - Main View

struct PrescriptionsView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    // Main state
    @State private var selectedPatient: Patient? = nil
    @State private var prescriptionItems: [PrescriptionItemModel] = []
    @State private var generalInstructions: String = ""
    
    // UI States
    @State private var isShowingPatientPicker = false
    @State private var isShowingAddMedicationSheet = false
    @State private var isShowingConfirmation = false
    @State private var isLoading = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    
    // Current view state
    @State private var activeStep = 1
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                (colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressView(value: Double(activeStep), total: 3)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                        .padding()
                    
                    // Progress steps
                    HStack {
                        progressStep(number: 1, title: "Patient", isActive: activeStep >= 1)
                        Spacer()
                        progressStep(number: 2, title: "Medications", isActive: activeStep >= 2)
                        Spacer()
                        progressStep(number: 3, title: "Review", isActive: activeStep >= 3)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    // Content based on current step
                    ScrollView {
                        VStack(spacing: 20) {
                            // Step 1: Select Patient
                            if activeStep == 1 {
                                patientSelectionView
                            }
                            
                            // Step 2: Add Medications
                            else if activeStep == 2 {
                                medicationsView
                            }
                            
                            // Step 3: Review and Finalize
                            else if activeStep == 3 {
                                reviewView
                            }
                        }
                        .padding()
                    }
                }
                
                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            }
            .navigationTitle("New Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if activeStep > 1 {
                        Button("Back") {
                            withAnimation {
                                activeStep -= 1
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if activeStep < 3 {
                        Button("Next") {
                            proceedToNextStep()
                        }
                        .disabled(!canProceedToNextStep())
                    } else {
                        Button("Save") {
                            savePrescription()
                        }
                        .disabled(prescriptionItems.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isShowingPatientPicker) {
                PatientPickerView(selectedID: Binding(
                    get: { selectedPatient?.objectID },
                    set: { newValue in
                        if let id = newValue, let patient = try? viewContext.existingObject(with: id) as? Patient {
                            selectedPatient = patient
                        }
                    }
                ))
                .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isShowingAddMedicationSheet) {
                AddMedicationView { item in
                    if let item = item {
                        prescriptionItems.append(item)
                    }
                }
                .environment(\.managedObjectContext, viewContext)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Message"),
                    message: Text(alertMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: selectedPatient) { newValue in
                if newValue != nil && activeStep == 1 {
                    // Automatically proceed to step 2 when patient is selected
                    withAnimation {
                        activeStep = 2
                    }
                }
            }
        }
    }
    
    // MARK: - Step 1: Patient Selection
    
    private var patientSelectionView: some View {
        VStack(spacing: 20) {
            // Header
            Text("Select a patient for this prescription")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Patient selector
            if let patient = selectedPatient {
                PatientInfoCard(patient: patient) {
                    isShowingPatientPicker = true
                }
            } else {
                Button(action: {
                    isShowingPatientPicker = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        
                        Text("Select Patient")
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Step 2: Medications
    
    private var medicationsView: some View {
        VStack(spacing: 20) {
            // Header with patient summary
            if let patient = selectedPatient {
                PatientSummaryStrip(patient: patient)
            }
            
            // Medications list
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Medications")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        isShowingAddMedicationSheet = true
                    }) {
                        Label("Add", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                }
                
                if prescriptionItems.isEmpty {
                    emptyMedicationsView
                } else {
                    ForEach(prescriptionItems.indices, id: \.self) { index in
                        MedicationItemCard(item: prescriptionItems[index]) {
                            prescriptionItems.remove(at: index)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // General instructions
            VStack(alignment: .leading, spacing: 12) {
                Text("General Instructions")
                    .font(.headline)
                
                TextEditor(text: $generalInstructions)
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if generalInstructions.isEmpty {
                                Text("Enter any general instructions for this prescription (optional)")
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .allowsHitTesting(false)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private var emptyMedicationsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "pills.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No medications added yet")
                .font(.headline)
            
            Text("Tap the Add button to add medications to this prescription")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                isShowingAddMedicationSheet = true
            }) {
                Text("Add Medication")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Step 3: Review
    
    private var reviewView: some View {
        VStack(spacing: 20) {
            // Patient info
            if let patient = selectedPatient {
                PatientSummaryStrip(patient: patient)
            }
            
            // Prescription details
            VStack(alignment: .leading, spacing: 12) {
                Text("Prescription Details")
                    .font(.headline)
                
                Divider()
                
                // Date and status
                HStack {
                    Label("Date: \(formattedDate(Date()))", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Status: Active")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // General instructions
                if !generalInstructions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("General Instructions:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(generalInstructions)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
                
                // Medications
                Text("Medications (\(prescriptionItems.count))")
                    .font(.headline)
                    .padding(.top, 8)
                
                Divider()
                
                ForEach(prescriptionItems.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prescriptionItems[index].drugName)
                                    .font(.headline)
                                
                                if !prescriptionItems[index].strength.isEmpty {
                                    Text(prescriptionItems[index].strength)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("\(prescriptionItems[index].dosage), \(prescriptionItems[index].frequency), \(prescriptionItems[index].route)")
                                    .font(.subheadline)
                                
                                if !prescriptionItems[index].duration.isEmpty {
                                    Text("Duration: \(prescriptionItems[index].duration)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !prescriptionItems[index].specialInstructions.isEmpty {
                                    Text(prescriptionItems[index].specialInstructions)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                }
                            }
                        }
                        
                        if index < prescriptionItems.count - 1 {
                            Divider()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Finalize button
            Button(action: {
                savePrescription()
            }) {
                HStack {
                    Spacer()
                    Text("Save Prescription")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .disabled(prescriptionItems.isEmpty)
            .padding(.vertical)
        }
    }
    
    // MARK: - Helper Methods
    
    private func proceedToNextStep() {
        if canProceedToNextStep() {
            withAnimation {
                activeStep += 1
            }
        }
    }
    
    private func canProceedToNextStep() -> Bool {
        switch activeStep {
        case 1:
            return selectedPatient != nil
        case 2:
            return !prescriptionItems.isEmpty
        default:
            return true
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func savePrescription() {
        guard let patient = selectedPatient, !prescriptionItems.isEmpty else {
            alertMessage = "Please add at least one medication to the prescription."
            showAlert = true
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                // Create the prescription
                let prescription = Prescription(context: viewContext)
                prescription.id = UUID()
                prescription.dateCreated = Date()
                prescription.status = "active"
                prescription.generalInstructions = generalInstructions
                prescription.patient = patient
                
                // Add prescription items
                for itemModel in prescriptionItems {
                    let item = PrescriptionItem(context: viewContext)
                    item.id = UUID()
                    item.drugName = itemModel.drugName
                    item.strength = itemModel.strength
                    item.dosage = itemModel.dosage
                    item.frequency = itemModel.frequency
                    item.route = itemModel.route
                    item.duration = itemModel.duration
                    item.specialInstructions = itemModel.specialInstructions
                    item.prescription = prescription
                    
                    // Link to product if available
                    if let productID = itemModel.productID {
                        let productFetch: NSFetchRequest<Product> = Product.fetchRequest()
                        productFetch.predicate = NSPredicate(format: "SELF == %@", productID)
                        if let product = try? viewContext.fetch(productFetch).first {
                            item.product = product
                        }
                    }
                }
                
                // Save to Core Data
                try viewContext.save()
                
                // Show success and reset
                isLoading = false
                alertMessage = "Prescription saved successfully."
                showAlert = true
                
                // Reset form
                resetForm()
            } catch {
                // Show error
                isLoading = false
                alertMessage = "Error saving prescription: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func resetForm() {
        selectedPatient = nil
        prescriptionItems = []
        generalInstructions = ""
        activeStep = 1
    }
    
    // MARK: - Supporting Views
    
    private func progressStep(number: Int, title: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(isActive ? .primary : .secondary)
        }
    }
}

// MARK: - Supporting View Components

struct PatientInfoCard: View {
    let patient: Patient
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(patient.initials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.fullName)
                        .font(.headline)
                    
                    HStack {
                        if let mrn = patient.medicalRecordNumber {
                            Text("MRN: \(mrn)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let dob = patient.dateOfBirth {
                            Text("DOB: \(formatDate(dob))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct PatientSummaryStrip: View {
    let patient: Patient
    
    var body: some View {
        HStack {
            Text(patient.initials)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.blue))
            
            Text(patient.fullName)
                .font(.headline)
            
            Spacer()
            
            if let mrn = patient.medicalRecordNumber {
                Text("MRN: \(mrn)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct MedicationItemCard: View {
    let item: PrescriptionItemModel
    let onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.drugName)
                    .font(.headline)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            if !item.strength.isEmpty {
                Text(item.strength)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Dosage:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.dosage)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Frequency:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.frequency)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Route:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.route)
                            .font(.caption)
                    }
                    
                    if !item.duration.isEmpty {
                        HStack {
                            Text("Duration:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(item.duration)
                                .font(.caption)
                        }
                    }
                }
            }
            
            if !item.specialInstructions.isEmpty {
                Text(item.specialInstructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        )
    }
}

// MARK: - Add Medication View

struct AddMedicationView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Callback for when a medication is added
    var onAddMedication: (PrescriptionItemModel?) -> Void
    
    // Search state
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchCancellable: AnyCancellable?
    @State private var isSearching = false
    
    // Form state
    @State private var selectedProduct: Product?
    @State private var drugName = ""
    @State private var strength = ""
    @State private var dosage = ""
    @State private var frequency = ""
    @State private var route = ""
    @State private var duration = ""
    @State private var specialInstructions = ""
    
    // UI state
    @State private var showProductList = false
    
    @FetchRequest private var filteredProducts: FetchedResults<Product>
    
    init(onAddMedication: @escaping (PrescriptionItemModel?) -> Void) {
        self.onAddMedication = onAddMedication
        
        // Initialize with empty predicate
        _filteredProducts = FetchRequest<Product>(
            entity: Product.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Product.drugName, ascending: true)],
            predicate: NSPredicate(format: "drugName CONTAINS[cd] %@", ""),
            animation: .default
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Drug selection section
                Section(header: Text("Medication")) {
                    if selectedProduct != nil {
                        selectedProductView
                    } else {
                        drugSearchField
                        
                        if showProductList && debouncedSearchText.count >= 3 {
                            if isSearching {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                                .padding()
                            } else if filteredProducts.isEmpty {
                                Text("No products found")
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                List {
                                    ForEach(filteredProducts.prefix(10), id: \.objectID) { product in
                                        Button(action: {
                                            selectProduct(product)
                                        }) {
                                            VStack(alignment: .leading) {
                                                Text(product.drugName ?? "")
                                                    .foregroundColor(.primary)
                                                
                                                if let strength = product.strength, !strength.isEmpty {
                                                    Text(strength)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                if let form = product.form, !form.isEmpty {
                                                    Text(form)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .frame(height: 200)
                            }
                        }
                        
                        if searchText.count > 0 && searchText.count < 3 {
                            Text("Enter at least 3 characters")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            showProductList.toggle()
                        }) {
                            HStack {
                                Text(showProductList ? "Hide Results" : "Show Results")
                                Image(systemName: showProductList ? "chevron.up" : "chevron.down")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        // Manual drug name entry
                        if !showProductList || debouncedSearchText.count < 3 {
                            TextField("Drug Name", text: $drugName)
                            
                            TextField("Strength (optional)", text: $strength)
                        }
                    }
                }
                
                // Prescription details
                Section(header: Text("Prescription Details")) {
                    TextField("Dosage (e.g., 1 tablet)", text: $dosage)
                    
                    TextField("Frequency (e.g., twice daily)", text: $frequency)
                    
                    TextField("Route (e.g., oral)", text: $route)
                    
                    TextField("Duration (e.g., 7 days)", text: $duration)
                }
                
                // Special instructions
                Section(header: Text("Special Instructions (optional)")) {
                    TextEditor(text: $specialInstructions)
                        .frame(minHeight: 100)
                }
                
                // Action buttons section
                Section {
                    Button(action: {
                        addMedication()
                    }) {
                        HStack {
                            Spacer()
                            Text("Add to Prescription")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid())
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    addMedication()
                }
                .disabled(!isFormValid())
            )
            .onAppear {
                // Ensure product data is loaded
                DispatchQueue.global(qos: .background).async {
                    ProductImporter(context: viewContext).importProductsIfNeeded()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var selectedProductView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedProduct?.drugName ?? "")
                        .font(.headline)
                    
                    if let strength = selectedProduct?.strength, !strength.isEmpty {
                        Text(strength)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let form = selectedProduct?.form, !form.isEmpty {
                        Text(form)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    selectedProduct = nil
                    drugName = ""
                    strength = ""
                    route = selectedProduct?.form ?? ""
                    showProductList = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var drugSearchField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Drug Database")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search drug name", text: $searchText)
                    .onChange(of: searchText) { newValue in
                        showProductList = !newValue.isEmpty
                        
                        // Cancel existing debounce timer
                        searchCancellable?.cancel()
                        
                        // Show loading indicator immediately
                        if !newValue.isEmpty && newValue.count >= 3 {
                            isSearching = true
                        }
                        
                        // Debounce search input (wait 0.5 seconds after typing stops)
                        searchCancellable = Just(newValue)
                            .delay(for: .seconds(0.5), scheduler: RunLoop.main)
                            .sink { value in
                                updateSearch(value)
                            }
                    }
                
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(0.8)
                }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        updateSearch("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateSearch(_ searchText: String) {
        // Only search with 3+ characters
        if searchText.count >= 3 {
            debouncedSearchText = searchText
            
            // Update the fetch request predicate
            filteredProducts.nsPredicate = NSPredicate(format: "drugName CONTAINS[cd] %@", searchText)
        } else {
            debouncedSearchText = ""
            filteredProducts.nsPredicate = NSPredicate(format: "drugName CONTAINS[cd] %@", "")
        }
        
        // Hide loading indicator
        isSearching = false
    }
    
    private func selectProduct(_ product: Product) {
        selectedProduct = product
        drugName = product.drugName ?? ""
        strength = product.strength ?? ""
        route = product.form ?? ""
        showProductList = false
    }
    
    private func isFormValid() -> Bool {
        let nameValid = !drugName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedProduct != nil
        let dosageValid = !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let frequencyValid = !frequency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let routeValid = !route.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        return nameValid && dosageValid && frequencyValid && routeValid
    }
    
    private func addMedication() {
        guard isFormValid() else { return }
        
        // Create a new prescription item model
        let item = PrescriptionItemModel(
            drugName: selectedProduct?.drugName ?? drugName,
            strength: selectedProduct?.strength ?? strength,
            dosage: dosage,
            frequency: frequency,
            route: route,
            duration: duration,
            specialInstructions: specialInstructions,
            productID: selectedProduct?.objectID
        )
        
        // Call the callback with the new item
        onAddMedication(item)
        
        // Dismiss this view
        presentationMode.wrappedValue.dismiss()
    }
}
