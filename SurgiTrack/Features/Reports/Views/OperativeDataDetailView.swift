import SwiftUI
import CoreData

struct OperativeDataDetailView: View {
    // MARK: - Environment & Objects
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var operativeData: OperativeData
    
    // MARK: - State
    @State private var activeSheet: ActiveSheet?
    @State private var isShowingDeleteConfirmation = false
    @State private var showingRiskCalculatorSelector = false
    
    // Enum to track which sheet is active
    enum ActiveSheet: Identifiable {
        case edit, attachments, addFollowUp
        
        var id: Int {
            switch self {
            case .edit: return 0
            case .attachments: return 1
            case .addFollowUp: return 2
            }
        }
    }
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // Computed property: check if attachments exist
    private var hasAttachments: Bool {
        if let attachments = operativeData.attachments as? Set<Attachment> {
            return !attachments.isEmpty
        }
        return false
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with procedure name and date
                procedureHeader
                
                // Basic Information Card
                infoCard(title: "Procedure Information") {
                    if let surgeon = operativeData.surgeon {
                        infoRow(label: "Surgeon", value: "\(surgeon.firstName ?? "") \(surgeon.lastName ?? "")")
                    } else if let name = operativeData.surgeonName, !name.isEmpty {
                        infoRow(label: "Surgeon", value: name)
                    }
                    
                    infoRow(label: "Date", value: dateFormatter.string(from: operativeData.operationDate ?? Date()))
                    infoRow(label: "Anaesthesia", value: operativeData.anaesthesiaType ?? "Not specified")
                    infoRow(label: "Duration", value: "\(Int(operativeData.duration)) minutes")
                    infoRow(label: "Blood Loss", value: "\(Int(operativeData.estimatedBloodLoss)) mL")
                    
                    if let assistants = operativeData.assistants, !assistants.isEmpty {
                        infoRow(label: "Assistants", value: assistants)
                    }
                }
                
                // Indication
                if let indication = operativeData.indication, !indication.isEmpty {
                    detailCard(title: "Indications", content: indication)
                }
                
                // Procedure Details
                if let details = operativeData.procedureDetails, !details.isEmpty {
                    detailCard(title: "Procedure Details", content: details)
                }
                
                // Findings & Complications
                VStack(spacing: 16) {
                    if let findings = operativeData.operativeFindings, !findings.isEmpty {
                        detailCard(title: "Operative Findings", content: findings)
                    }
                    
                    if let complications = operativeData.intraoperativeComplications, !complications.isEmpty {
                        detailCard(title: "Complications", content: complications)
                    }
                }
                
                // Operative Notes & Postoperative Orders
                VStack(spacing: 16) {
                    if let notes = operativeData.operativeNotes, !notes.isEmpty {
                        detailCard(title: "Operative Notes", content: notes)
                    }
                    
                    if let orders = operativeData.postoperativeOrders, !orders.isEmpty {
                        detailCard(title: "Postoperative Orders", content: orders)
                    }
                }
                
                // Attachments Button
                Button(action: {
                    activeSheet = .attachments
                }) {
                    HStack {
                        Image(systemName: "paperclip")
                        Text(hasAttachments ? "View Attachments" : "Add Attachments")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
                
                // Follow-up Button
                Button(action: {
                    activeSheet = .addFollowUp
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Schedule Follow-up")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .padding(.top, 4)
                
                // Risk Assessment Button
                Button(action: {
                    showingRiskCalculatorSelector = true
                }) {
                    HStack {
                        Image(systemName: "function")
                        Text("Risk Assessment")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .cornerRadius(10)
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Surgical Procedure")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { activeSheet = .edit }) {
                        Label("Edit Procedure", systemImage: "pencil")
                    }
                    Button(action: { isShowingDeleteConfirmation = true }) {
                        Label("Delete Procedure", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $activeSheet) { item in
            content(for: item)
        }
        .sheet(isPresented: $showingRiskCalculatorSelector) {
            NavigationView {
                RiskCalculatorSelectorView(operativeData: operativeData)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .alert("Delete Procedure", isPresented: $isShowingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteProcedure()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this surgical record? This action cannot be undone.")
        }
    }
    
    // MARK: - Helper View Builders
    
    private func content(for item: ActiveSheet) -> some View {
        switch item {
        case .edit:
            return AnyView(
                EditOperativeDataView(operativeData: operativeData)
                    .environment(\.managedObjectContext, viewContext)
            )
        case .attachments:
            return AnyView(
                AttachmentView(parent: .operativeData(operativeData))
                    .environment(\.managedObjectContext, viewContext)
            )
        case .addFollowUp:
            if let patient = operativeData.patient {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                let procName = operativeData.procedureName ?? "surgery"
                let dateStr = formatter.string(from: operativeData.operationDate ?? Date())
                let initialNote = "Post-operative follow-up for \(procName) performed on \(dateStr)."
                return AnyView(
                    AddFollowUpView(patient: patient, initialNotes: initialNote)
                        .environment(\.managedObjectContext, viewContext)
                )
            } else {
                return AnyView(
                    Text("Patient information not available").padding()
                )
            }
        }
    }
    
    private var procedureHeader: some View {
        VStack(spacing: 10) {
            Text(operativeData.procedureName ?? "Unnamed Procedure")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.orange)
                .padding(.horizontal)
            Text(dateFormatter.string(from: operativeData.operationDate ?? Date()))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }
    
    private func infoCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.orange)
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    private func detailCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.orange)
            Text(content)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Methods
    
    private func deleteProcedure() {
        viewContext.delete(operativeData)
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error deleting procedure: \(error)")
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

