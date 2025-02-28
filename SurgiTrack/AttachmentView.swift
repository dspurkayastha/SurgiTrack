import SwiftUI
import CoreData
import UniformTypeIdentifiers


enum AttachmentType: String, CaseIterable, Identifiable {
    case document = "Document"
    case image = "Image"
    case report = "Report"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .document: return "doc.text.fill"
        case .image: return "photo.fill"
        case .report: return "chart.bar.doc.horizontal.fill"
        case .other: return "paperclip"
        }
    }
    
    var color: Color {
        switch self {
        case .document: return .blue
        case .image: return .green
        case .report: return .purple
        case .other: return .gray
        }
    }
}

struct AttachmentView: View {
    // MARK: - Environment & State
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    
    // Attachment relationship type
    enum AttachmentParent {
        case patient(Patient)
        case operativeData(OperativeData)
        case followUp(FollowUp)
        case medicalTest(MedicalTest)
        
        var title: String {
            switch self {
            case .patient: return "Patient Attachments"
            case .operativeData: return "Surgical Attachments"
            case .followUp: return "Follow-up Attachments"
            case .medicalTest: return "Test Attachments"
            }
        }
        
        var attachments: [Attachment] {
            switch self {
            case .patient(let patient):
                return (patient.attachments as? Set<Attachment>)?.sorted {
                    ($0.dateCreated ?? Date()) > ($1.dateCreated ?? Date())
                } ?? []
            case .operativeData(let operativeData):
                return (operativeData.attachments as? Set<Attachment>)?.sorted {
                    ($0.dateCreated ?? Date()) > ($1.dateCreated ?? Date())
                } ?? []
            case .followUp(let followUp):
                return (followUp.attachments as? Set<Attachment>)?.sorted {
                    ($0.dateCreated ?? Date()) > ($1.dateCreated ?? Date())
                } ?? []
            case .medicalTest(let medicalTest):
                return (medicalTest.attachments as? Set<Attachment>)?.sorted {
                    ($0.dateCreated ?? Date()) > ($1.dateCreated ?? Date())
                } ?? []
            }
        }
        
        func addAttachment(_ attachment: Attachment) {
            switch self {
            case .patient(let patient):
                attachment.patient = patient
            case .operativeData(let operativeData):
                attachment.operativeData = operativeData
            case .followUp(let followUp):
                attachment.followUp = followUp
            case .medicalTest(let medicalTest):
                attachment.medicalTest = medicalTest
            }
        }
    }
    
    // Properties
    let parent: AttachmentParent
    
    // State variables
    @State private var isShowingDocumentPicker = false
    @State private var isShowingCamera = false
    @State private var isShowingPhotoLibrary = false
    @State private var isShowingAttachmentOptions = false
    @State private var isShowingAttachmentDetail = false
    @State private var selectedAttachment: Attachment?
    @State private var attachmentName = ""
    @State private var attachmentNotes = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteConfirmation = false
    @State private var attachmentToDelete: Attachment?
    @State private var isUploading = false
    @State private var uploadProgress: Float = 0.0
    @State private var selectedAttachmentType: AttachmentType = .document
    
    // Grouping
    @State private var groupByType = false
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Control bar with grouping toggle
                HStack {
                    Toggle("Group by Type", isOn: $groupByType)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            selectedAttachmentType = .image
                            isShowingPhotoLibrary = true
                        }) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                        }
                        
                        Button(action: {
                            selectedAttachmentType = .image
                            isShowingCamera = true
                        }) {
                            Label("Take Photo", systemImage: "camera")
                        }
                        
                        Button(action: {
                            selectedAttachmentType = .document
                            isShowingDocumentPicker = true
                        }) {
                            Label("Browse Files", systemImage: "folder")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                if parent.attachments.isEmpty {
                    emptyStateView
                } else if groupByType {
                    groupedAttachmentList
                } else {
                    attachmentGridView
                }
            }
            .navigationTitle(parent.title)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $isShowingCamera) {
                CameraView(onCapture: handleNewImage, attachmentType: selectedAttachmentType)
            }
            .sheet(isPresented: $isShowingPhotoLibrary) {
                PhotoLibraryView(onSelect: handleNewImage, attachmentType: selectedAttachmentType)
            }
            .sheet(isPresented: $isShowingDocumentPicker) {
                DocumentPickerView(onSelect: handleNewDocument, attachmentType: selectedAttachmentType)
            }
            .sheet(item: $selectedAttachment) { attachment in
                AttachmentDetailView(attachment: attachment, onDelete: { attachmentToDelete = attachment; showDeleteConfirmation = true })
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Attachment"),
                    message: Text("Are you sure you want to delete this attachment? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let attachment = attachmentToDelete {
                            deleteAttachment(attachment)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .overlay(
                Group {
                    if isUploading {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            
                            VStack(spacing: 16) {
                                ProgressView(value: uploadProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 200)
                                
                                Text("Uploading Attachment...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                            .padding(25)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                            .shadow(radius: 10)
                        }
                    }
                }
            )
        }
    }
    
    // MARK: - View Components
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No Attachments")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add medical records, images, and other files")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button(action: {
                    selectedAttachmentType = .image
                    isShowingPhotoLibrary = true
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("Add Image")
                            .font(.subheadline)
                    }
                }
                
                Button(action: {
                    selectedAttachmentType = .document
                    isShowingDocumentPicker = true
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("Add File")
                            .font(.subheadline)
                    }
                }
                
                Button(action: {
                    selectedAttachmentType = .image
                    isShowingCamera = true
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text("Take Photo")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
    
    private var attachmentGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(parent.attachments, id: \.objectID) { attachment in
                    AttachmentGridItem(attachment: attachment)
                        .onTapGesture {
                            selectedAttachment = attachment
                        }
                        .contextMenu {
                            Button(action: {
                                selectedAttachment = attachment
                            }) {
                                Label("View", systemImage: "eye")
                            }
                            
                            Button(action: {
                                shareAttachment(attachment)
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            Button(role: .destructive, action: {
                                attachmentToDelete = attachment
                                showDeleteConfirmation = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    private var groupedAttachmentList: some View {
        ScrollView {
            // Group attachments by type
            VStack(spacing: 24) {
                let groupedAttachments = Dictionary(grouping: parent.attachments) { getAttachmentType($0) }
                
                ForEach(AttachmentType.allCases) { type in
                    if let attachments = groupedAttachments[type], !attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.color)
                                
                                Text(type.rawValue)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(attachments.count) file\(attachments.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            Divider()
                            
                            // Horizontal scroll of this type
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(attachments, id: \.objectID) { attachment in
                                        AttachmentGridItem(attachment: attachment)
                                            .frame(width: 150, height: 180)
                                            .onTapGesture {
                                                selectedAttachment = attachment
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleNewImage(image: UIImage, type: AttachmentType = .image) {
        isUploading = true
        uploadProgress = 0.1
        
        // Simulate upload progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.uploadProgress = 0.3
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.uploadProgress = 0.7
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.uploadProgress = 1.0
                    
                    // Process the image
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                    let filename = "\(type.rawValue)_\(dateFormatter.string(from: Date())).jpg"
                    
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        self.isUploading = false
                        self.showAlert = true
                        self.alertMessage = "Failed to process image"
                        return
                    }
                    
                    self.saveNewAttachment(
                        data: imageData,
                        filename: filename,
                        contentType: "image/jpeg",
                        notes: "",
                        type: type
                    )
                }
            }
        }
    }
    
    private func handleNewDocument(url: URL, contentType: String, type: AttachmentType = .document) {
        isUploading = true
        uploadProgress = 0.1
        
        // Simulate upload progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.uploadProgress = 0.4
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.uploadProgress = 0.8
                
                do {
                    let data = try Data(contentsOf: url)
                    let filename = url.lastPathComponent
                    
                    // Complete the upload process
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.uploadProgress = 1.0
                        
                        self.saveNewAttachment(
                            data: data,
                            filename: filename,
                            contentType: contentType,
                            notes: "",
                            type: type
                        )
                    }
                } catch {
                    self.isUploading = false
                    self.showAlert = true
                    self.alertMessage = "Failed to load document: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveNewAttachment(data: Data, filename: String, contentType: String, notes: String, type: AttachmentType) {
        let newAttachment = Attachment(context: viewContext)
        newAttachment.id = UUID()
        newAttachment.filename = filename
        newAttachment.data = data
        newAttachment.contentType = contentType
        newAttachment.dateCreated = Date()
        newAttachment.notes = notes
        newAttachment.attachmentType = type.rawValue
        
        // Connect to the appropriate parent
        parent.addAttachment(newAttachment)
        
        do {
            try viewContext.save()
            isUploading = false
        } catch {
            isUploading = false
            showAlert = true
            alertMessage = "Error saving attachment: \(error.localizedDescription)"
        }
    }
    
    private func deleteAttachment(_ attachment: Attachment) {
        viewContext.delete(attachment)
        
        do {
            try viewContext.save()
            attachmentToDelete = nil
        } catch {
            showAlert = true
            alertMessage = "Error deleting attachment: \(error.localizedDescription)"
        }
    }
    
    private func shareAttachment(_ attachment: Attachment) {
        guard let data = attachment.data else {
            showAlert = true
            alertMessage = "Attachment data not available"
            return
        }
        
        // Create a temporary file URL for the attachment
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(attachment.filename ?? "attachment")
        
        do {
            try data.write(to: fileURL)
            
            // Use UIActivityViewController to share the file
            let activityViewController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // Present the activity view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityViewController, animated: true)
            }
        } catch {
            showAlert = true
            alertMessage = "Error preparing file for sharing: \(error.localizedDescription)"
        }
    }
    
    private func getAttachmentType(_ attachment: Attachment) -> AttachmentType {
        if let typeString = attachment.attachmentType, let type = AttachmentType(rawValue: typeString) {
            return type
        }
        
        // If no explicit type, infer from content type
        if let contentType = attachment.contentType {
            if contentType.hasPrefix("image") {
                return .image
            } else if contentType.hasPrefix("application/pdf") ||
                      contentType.hasPrefix("text") ||
                      contentType.hasPrefix("application/msword") ||
                      contentType.hasPrefix("application/vnd.openxmlformats") {
                return .document
            } else if contentType.contains("report") ||
                      attachment.filename?.lowercased().contains("report") == true {
                return .report
            }
        }
        
        return .other
    }
}

// MARK: - Supporting Views
struct AttachmentGridItem: View {
    @ObservedObject var attachment: Attachment
    
    var body: some View {
        VStack {
            if let contentType = attachment.contentType, contentType.hasPrefix("image"),
               let imageData = attachment.data, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                    
                    Image(systemName: getIconName())
                        .font(.system(size: 40))
                        .foregroundColor(getIconColor())
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.filename ?? "Unnamed File")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .frame(height: 160)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var formattedDate: String {
        guard let date = attachment.dateCreated else { return "Unknown date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getIconName() -> String {
        if let contentType = attachment.contentType {
            if contentType.hasPrefix("application/pdf") {
                return "doc.text.fill"
            } else if contentType.hasPrefix("text") {
                return "doc.text.fill"
            } else if contentType.contains("spreadsheet") || contentType.contains("excel") {
                return "tablecells.fill"
            } else if contentType.contains("presentation") || contentType.contains("powerpoint") {
                return "chart.bar.doc.horizontal.fill"
            } else if contentType.contains("word") {
                return "doc.fill"
            }
        }
        
        // Check filename extension
        if let filename = attachment.filename?.lowercased() {
            if filename.hasSuffix(".pdf") {
                return "doc.text.fill"
            } else if filename.hasSuffix(".doc") || filename.hasSuffix(".docx") {
                return "doc.fill"
            } else if filename.hasSuffix(".xls") || filename.hasSuffix(".xlsx") {
                return "tablecells.fill"
            } else if filename.hasSuffix(".ppt") || filename.hasSuffix(".pptx") {
                return "chart.bar.doc.horizontal.fill"
            } else if filename.hasSuffix(".txt") {
                return "doc.text.fill"
            }
        }
        
        return "doc.fill"
    }
    
    private func getIconColor() -> Color {
        if let contentType = attachment.contentType {
            if contentType.hasPrefix("application/pdf") {
                return .red
            } else if contentType.hasPrefix("text") {
                return .blue
            } else if contentType.contains("spreadsheet") || contentType.contains("excel") {
                return .green
            } else if contentType.contains("presentation") || contentType.contains("powerpoint") {
                return .orange
            } else if contentType.contains("word") {
                return .blue
            }
        }
        
        return .gray
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage, AttachmentType) -> Void
    let attachmentType: AttachmentType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, attachmentType: attachmentType)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage, AttachmentType) -> Void
        let attachmentType: AttachmentType
        
        init(onCapture: @escaping (UIImage, AttachmentType) -> Void, attachmentType: AttachmentType) {
            self.onCapture = onCapture
            self.attachmentType = attachmentType
            super.init()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image, attachmentType)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Photo Library View
struct PhotoLibraryView: UIViewControllerRepresentable {
    let onSelect: (UIImage, AttachmentType) -> Void
    let attachmentType: AttachmentType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect, attachmentType: attachmentType)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onSelect: (UIImage, AttachmentType) -> Void
        let attachmentType: AttachmentType
        
        init(onSelect: @escaping (UIImage, AttachmentType) -> Void, attachmentType: AttachmentType) {
            self.onSelect = onSelect
            self.attachmentType = attachmentType
            super.init()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onSelect(image, attachmentType)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Document Picker View
struct DocumentPickerView: UIViewControllerRepresentable {
    let onSelect: (URL, String, AttachmentType) -> Void
    let attachmentType: AttachmentType
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [.pdf, .text, .image, .spreadsheet, .presentation]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect, attachmentType: attachmentType)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSelect: (URL, String, AttachmentType) -> Void
        let attachmentType: AttachmentType
        
        init(onSelect: @escaping (URL, String, AttachmentType) -> Void, attachmentType: AttachmentType) {
            self.onSelect = onSelect
            self.attachmentType = attachmentType
            super.init()
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Determine content type
            let contentType: String
            
            if url.pathExtension.lowercased() == "pdf" {
                contentType = "application/pdf"
            } else if ["jpg", "jpeg", "png", "heic"].contains(url.pathExtension.lowercased()) {
                contentType = "image/\(url.pathExtension.lowercased())"
            } else if ["doc", "docx"].contains(url.pathExtension.lowercased()) {
                contentType = "application/msword"
            } else if ["xls", "xlsx"].contains(url.pathExtension.lowercased()) {
                contentType = "application/vnd.ms-excel"
            } else if ["ppt", "pptx"].contains(url.pathExtension.lowercased()) {
                contentType = "application/vnd.ms-powerpoint"
            } else if url.pathExtension.lowercased() == "txt" {
                contentType = "text/plain"
            } else {
                contentType = "application/octet-stream"
            }
            
            onSelect(url, contentType, attachmentType)
        }
    }
}

// MARK: - Attachment Detail View
struct AttachmentDetailView: View {
    let attachment: Attachment
    let onDelete: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let contentType = attachment.contentType, contentType.hasPrefix("image"),
                       let imageData = attachment.data, let uiImage = UIImage(data: imageData) {
                        // Zoomable image
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = min(max(1.0, value), 5.0)
                                    }
                                    .simultaneously(with: DragGesture()
                                        .onChanged { value in
                                            if scale > 1 {
                                                offset = value.translation
                                            }
                                        }
                                        .onEnded { _ in
                                            if scale <= 1 {
                                                withAnimation {
                                                    offset = .zero
                                                }
                                            }
                                        })
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    if scale > 1 {
                                        scale = 1.0
                                        offset = .zero
                                    } else {
                                        scale = 2.0
                                    }
                                }
                            }
                            .padding()
                    } else {
                        // Document icon
                        VStack {
                            Image(systemName: getIconName())
                                .font(.system(size: 80))
                                .foregroundColor(getIconColor())
                                .padding()
                            
                            Text("This file cannot be previewed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.bottom)
                        }
                    }
                    
                    // File details section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("File Details")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        DetailRow(label: "Filename", value: attachment.filename ?? "Unnamed File")
                        DetailRow(label: "Type", value: attachment.contentType ?? "Unknown")
                        DetailRow(label: "Size", value: formatFileSize(attachment.data?.count ?? 0))
                        DetailRow(label: "Date", value: formatDate(attachment.dateCreated))
                        
                        if let notes = attachment.notes, !notes.isEmpty {
                            Text("Notes")
                                .font(.headline)
                                .padding(.top, 16)
                                .padding(.bottom, 4)
                            
                            Text(notes)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            VStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                Text("Share")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        Button(action: {
                            onDelete()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            VStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 22))
                                    .foregroundColor(.red)
                                Text("Delete")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle(attachment.filename ?? "Attachment")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .background(colorScheme == .dark ? Color.black : Color.white)
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                scale = 1.0
                offset = .zero
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheetView(data: attachment.data, filename: attachment.filename ?? "file")
            }
        }
    }
    
    private func getIconName() -> String {
        if let contentType = attachment.contentType {
            if contentType.hasPrefix("application/pdf") {
                return "doc.text.fill"
            } else if contentType.hasPrefix("text") {
                return "doc.text.fill"
            } else if contentType.contains("spreadsheet") || contentType.contains("excel") {
                return "tablecells.fill"
            } else if contentType.contains("presentation") || contentType.contains("powerpoint") {
                return "chart.bar.doc.horizontal.fill"
            } else if contentType.contains("word") {
                return "doc.fill"
            }
        }
        
        return "doc.fill"
    }
    
    private func getIconColor() -> Color {
        if let contentType = attachment.contentType {
            if contentType.hasPrefix("application/pdf") {
                return .red
            } else if contentType.hasPrefix("text") {
                return .blue
            } else if contentType.contains("spreadsheet") || contentType.contains("excel") {
                return .green
            } else if contentType.contains("presentation") || contentType.contains("powerpoint") {
                return .orange
            } else if contentType.contains("word") {
                return .blue
            }
        }
        
        return .gray
    }
    
    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ShareSheetView: View {
    let data: Data?
    let filename: String
    
    var body: some View {
        Group {
            if let data = data {
                let tempDir = FileManager.default.temporaryDirectory
                let fileURL = tempDir.appendingPathComponent(filename)
                
                if (try? data.write(to: fileURL)) != nil {
                    ShareSheet(items: [fileURL])
                } else {
                    Text("Unable to share file")
                        .padding()
                }
            } else {
                Text("No data to share")
                    .padding()
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}


