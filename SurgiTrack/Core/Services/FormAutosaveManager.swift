// FormAutosaveManager.swift
// SurgiTrack
// Automatic form state preservation to prevent data loss
// Created on 26/12/2025

import Foundation
import SwiftUI
import Combine

/// Manages automatic saving of form data to prevent data loss
/// Persists form state locally and restores on app restart
@MainActor
final class FormAutosaveManager: ObservableObject {

    // MARK: - Singleton

    static let shared = FormAutosaveManager()

    // MARK: - Published Properties

    @Published private(set) var hasPendingChanges = false
    @Published private(set) var lastSaveTime: Date?

    // MARK: - Private Properties

    private let saveInterval: TimeInterval = 30 // Auto-save every 30 seconds
    private var saveTimer: Timer?
    private var pendingForms: [String: FormData] = [:]
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Types

    struct FormData: Codable {
        let formId: String
        let formType: String
        let data: [String: AnyCodable]
        let savedAt: Date
        let entityId: String? // e.g., patient ID if editing existing record

        init(formId: String, formType: String, data: [String: Any], entityId: String? = nil) {
            self.formId = formId
            self.formType = formType
            self.data = data.mapValues { AnyCodable($0) }
            self.savedAt = Date()
            self.entityId = entityId
        }
    }

    // MARK: - Initialization

    private init() {
        loadPendingForms()
        setupAutoSaveTimer()
    }

    deinit {
        saveTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Registers form data for autosave
    /// - Parameters:
    ///   - formId: Unique identifier for the form instance
    ///   - formType: Type of form (e.g., "PatientRegistration", "OperativeData")
    ///   - data: Form field values as a dictionary
    ///   - entityId: Optional ID of existing entity being edited
    func registerForm(_ formId: String, type formType: String, data: [String: Any], entityId: String? = nil) {
        let formData = FormData(formId: formId, formType: formType, data: data, entityId: entityId)
        pendingForms[formId] = formData
        hasPendingChanges = true
        Logger.info("Form registered for autosave: \(formType)", category: .data)
    }

    /// Updates form data
    /// - Parameters:
    ///   - formId: Form identifier
    ///   - data: Updated form field values
    func updateForm(_ formId: String, data: [String: Any]) {
        guard let existing = pendingForms[formId] else { return }
        let updated = FormData(
            formId: existing.formId,
            formType: existing.formType,
            data: data,
            entityId: existing.entityId
        )
        pendingForms[formId] = updated
        hasPendingChanges = true
    }

    /// Marks a form as successfully saved (removes from autosave)
    /// - Parameter formId: Form identifier
    func formSaved(_ formId: String) {
        pendingForms.removeValue(forKey: formId)
        hasPendingChanges = !pendingForms.isEmpty
        saveToStorage()
        Logger.info("Form removed from autosave: \(formId)", category: .data)
    }

    /// Retrieves pending form data if available
    /// - Parameter formId: Form identifier
    /// - Returns: The saved form data or nil
    func getPendingForm(_ formId: String) -> FormData? {
        return pendingForms[formId]
    }

    /// Gets all pending forms of a specific type
    /// - Parameter formType: Type of form to retrieve
    /// - Returns: Array of pending form data
    func getPendingForms(ofType formType: String) -> [FormData] {
        return pendingForms.values.filter { $0.formType == formType }
    }

    /// Discards pending form data
    /// - Parameter formId: Form identifier
    func discardForm(_ formId: String) {
        pendingForms.removeValue(forKey: formId)
        hasPendingChanges = !pendingForms.isEmpty
        saveToStorage()
        Logger.info("Form discarded: \(formId)", category: .data)
    }

    /// Forces an immediate save of all pending forms
    func saveNow() {
        saveToStorage()
    }

    /// Clears all pending form data
    func clearAll() {
        pendingForms.removeAll()
        hasPendingChanges = false
        saveToStorage()
    }

    // MARK: - Private Methods

    private func setupAutoSaveTimer() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveToStorage()
            }
        }
    }

    private var storageURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("pending_forms.json")
    }

    private func saveToStorage() {
        guard hasPendingChanges else { return }

        do {
            let data = try encoder.encode(Array(pendingForms.values))
            try data.write(to: storageURL, options: .atomicWrite)
            lastSaveTime = Date()
            Logger.info("Autosaved \(pendingForms.count) form(s)", category: .data)
        } catch {
            Logger.error("Failed to autosave forms", error: error, category: .data)
        }
    }

    private func loadPendingForms() {
        guard fileManager.fileExists(atPath: storageURL.path) else { return }

        do {
            let data = try Data(contentsOf: storageURL)
            let forms = try decoder.decode([FormData].self, from: data)
            pendingForms = Dictionary(uniqueKeysWithValues: forms.map { ($0.formId, $0) })
            hasPendingChanges = !pendingForms.isEmpty
            Logger.info("Loaded \(pendingForms.count) pending form(s)", category: .data)
        } catch {
            Logger.error("Failed to load pending forms", error: error, category: .data)
        }
    }
}

// MARK: - AnyCodable Helper

/// Type-erased Codable wrapper for heterogeneous form data
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - SwiftUI View Modifier for Autosave

struct AutosaveFormModifier: ViewModifier {
    let formId: String
    let formType: String
    let entityId: String?
    let dataProvider: () -> [String: Any]

    @StateObject private var autosaveManager = FormAutosaveManager.shared

    func body(content: Content) -> some View {
        content
            .onAppear {
                autosaveManager.registerForm(formId, type: formType, data: dataProvider(), entityId: entityId)
            }
            .onChange(of: dataProvider() as NSDictionary) { _, newValue in
                if let data = newValue as? [String: Any] {
                    autosaveManager.updateForm(formId, data: data)
                }
            }
            .onDisappear {
                // Don't remove on disappear - form may be saved or user may return
            }
    }
}

extension View {
    /// Enables autosave for a form view
    /// - Parameters:
    ///   - formId: Unique identifier for this form instance
    ///   - formType: Type of form for categorization
    ///   - entityId: Optional ID if editing existing entity
    ///   - dataProvider: Closure that returns current form data
    func autosaveForm(
        id formId: String,
        type formType: String,
        entityId: String? = nil,
        data dataProvider: @escaping () -> [String: Any]
    ) -> some View {
        modifier(AutosaveFormModifier(
            formId: formId,
            formType: formType,
            entityId: entityId,
            dataProvider: dataProvider
        ))
    }
}

// MARK: - Pending Forms Recovery View

struct PendingFormsRecoveryView: View {
    @StateObject private var autosaveManager = FormAutosaveManager.shared
    @Environment(\.dismiss) private var dismiss
    let formType: String
    let onRecover: (FormAutosaveManager.FormData) -> Void

    var pendingForms: [FormAutosaveManager.FormData] {
        autosaveManager.getPendingForms(ofType: formType)
    }

    var body: some View {
        NavigationStack {
            List {
                if pendingForms.isEmpty {
                    ContentUnavailableView(
                        "No Pending Forms",
                        systemImage: "doc.text",
                        description: Text("No unsaved forms to recover")
                    )
                } else {
                    ForEach(pendingForms, id: \.formId) { form in
                        Button(action: { onRecover(form) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Unsaved \(form.formType)")
                                    .font(.headline)

                                Text("Saved \(form.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if let entityId = form.entityId {
                                    Text("Entity: \(entityId)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                autosaveManager.discardForm(form.formId)
                            } label: {
                                Label("Discard", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recover Forms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
