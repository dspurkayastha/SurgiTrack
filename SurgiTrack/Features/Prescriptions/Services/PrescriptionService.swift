//
//  PrescriptionService.swift
//  SurgiTrack
//
//  Prescription management service with CRUD operations
//  Created on December 26, 2025
//

import Foundation
import CoreData
import Combine

/// Service for managing prescriptions and prescription items
class PrescriptionService: ObservableObject {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    @Published var prescriptions: [Prescription] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    /// Creates a new prescription for a patient
    /// - Parameters:
    ///   - patient: The patient to create the prescription for
    ///   - items: Array of prescription item data
    ///   - generalInstructions: General instructions for the prescription
    ///   - prescribingPhysician: Name of the prescribing physician
    ///   - status: Status of the prescription (default: "active")
    /// - Returns: The created Prescription object
    /// - Throws: CoreData errors
    func createPrescription(
        for patient: Patient,
        items: [PrescriptionItemData],
        generalInstructions: String? = nil,
        prescribingPhysician: String? = nil,
        status: String = "active"
    ) throws -> Prescription {

        Logger.log("Creating prescription for patient: \(patient.fullName)", category: .prescriptions, level: .info)

        // Create prescription
        let prescription = Prescription(context: context)
        prescription.id = UUID()
        prescription.dateCreated = Date()
        prescription.status = status
        prescription.generalInstructions = generalInstructions
        prescription.prescribingPhysician = prescribingPhysician
        prescription.patient = patient

        // Create prescription items
        for itemData in items {
            let item = PrescriptionItem(context: context)
            item.id = UUID()
            item.drugName = itemData.drugName
            item.strength = itemData.strength
            item.dosage = itemData.dosage
            item.frequency = itemData.frequency
            item.route = itemData.route
            item.duration = itemData.duration
            item.startDate = itemData.startDate
            item.endDate = itemData.endDate
            item.specialInstructions = itemData.specialInstructions
            item.prescription = prescription

            // Link to product if available
            if let productID = itemData.productID,
               let product = try? context.existingObject(with: productID) as? Product {
                item.product = product
            }
        }

        // Check for drug interactions before saving
        let interactions = checkDrugInteractions(items: items)
        if !interactions.isEmpty {
            Logger.log("Potential drug interactions detected: \(interactions.joined(separator: ", "))",
                      category: .prescriptions, level: .warning)
        }

        // Save context
        try context.save()

        Logger.log("Prescription created successfully with ID: \(prescription.id?.uuidString ?? "unknown")",
                  category: .prescriptions, level: .info)

        return prescription
    }

    /// Updates an existing prescription
    /// - Parameters:
    ///   - prescription: The prescription to update
    ///   - generalInstructions: Updated general instructions
    ///   - prescribingPhysician: Updated prescribing physician
    ///   - status: Updated status
    /// - Throws: CoreData errors
    func updatePrescription(
        _ prescription: Prescription,
        generalInstructions: String? = nil,
        prescribingPhysician: String? = nil,
        status: String? = nil
    ) throws {

        Logger.log("Updating prescription: \(prescription.id?.uuidString ?? "unknown")",
                  category: .prescriptions, level: .info)

        if let generalInstructions = generalInstructions {
            prescription.generalInstructions = generalInstructions
        }

        if let prescribingPhysician = prescribingPhysician {
            prescription.prescribingPhysician = prescribingPhysician
        }

        if let status = status {
            prescription.status = status
        }

        try context.save()

        Logger.log("Prescription updated successfully", category: .prescriptions, level: .info)
    }

    /// Adds a new item to an existing prescription
    /// - Parameters:
    ///   - prescription: The prescription to add the item to
    ///   - itemData: The prescription item data
    /// - Throws: CoreData errors
    func addPrescriptionItem(
        to prescription: Prescription,
        itemData: PrescriptionItemData
    ) throws {

        Logger.log("Adding item to prescription: \(prescription.id?.uuidString ?? "unknown")",
                  category: .prescriptions, level: .info)

        let item = PrescriptionItem(context: context)
        item.id = UUID()
        item.drugName = itemData.drugName
        item.strength = itemData.strength
        item.dosage = itemData.dosage
        item.frequency = itemData.frequency
        item.route = itemData.route
        item.duration = itemData.duration
        item.startDate = itemData.startDate
        item.endDate = itemData.endDate
        item.specialInstructions = itemData.specialInstructions
        item.prescription = prescription

        // Link to product if available
        if let productID = itemData.productID,
           let product = try? context.existingObject(with: productID) as? Product {
            item.product = product
        }

        try context.save()

        Logger.log("Prescription item added successfully", category: .prescriptions, level: .info)
    }

    /// Updates an existing prescription item
    /// - Parameters:
    ///   - item: The prescription item to update
    ///   - itemData: The updated prescription item data
    /// - Throws: CoreData errors
    func updatePrescriptionItem(
        _ item: PrescriptionItem,
        itemData: PrescriptionItemData
    ) throws {

        Logger.log("Updating prescription item: \(item.id?.uuidString ?? "unknown")",
                  category: .prescriptions, level: .info)

        item.drugName = itemData.drugName
        item.strength = itemData.strength
        item.dosage = itemData.dosage
        item.frequency = itemData.frequency
        item.route = itemData.route
        item.duration = itemData.duration
        item.startDate = itemData.startDate
        item.endDate = itemData.endDate
        item.specialInstructions = itemData.specialInstructions

        // Link to product if available
        if let productID = itemData.productID,
           let product = try? context.existingObject(with: productID) as? Product {
            item.product = product
        }

        try context.save()

        Logger.log("Prescription item updated successfully", category: .prescriptions, level: .info)
    }

    /// Deletes a prescription item
    /// - Parameter item: The prescription item to delete
    /// - Throws: CoreData errors
    func deletePrescriptionItem(_ item: PrescriptionItem) throws {
        Logger.log("Deleting prescription item: \(item.id?.uuidString ?? "unknown")",
                  category: .prescriptions, level: .info)

        context.delete(item)
        try context.save()

        Logger.log("Prescription item deleted successfully", category: .prescriptions, level: .info)
    }

    /// Deletes a prescription and all its items
    /// - Parameter prescription: The prescription to delete
    /// - Throws: CoreData errors
    func deletePrescription(_ prescription: Prescription) throws {
        Logger.log("Deleting prescription: \(prescription.id?.uuidString ?? "unknown")",
                  category: .prescriptions, level: .info)

        context.delete(prescription)
        try context.save()

        Logger.log("Prescription deleted successfully", category: .prescriptions, level: .info)
    }

    /// Updates the status of a prescription
    /// - Parameters:
    ///   - prescription: The prescription to update
    ///   - status: The new status (e.g., "active", "completed", "discontinued")
    /// - Throws: CoreData errors
    func updatePrescriptionStatus(_ prescription: Prescription, status: String) throws {
        Logger.log("Updating prescription status to: \(status)", category: .prescriptions, level: .info)

        prescription.status = status
        try context.save()
    }

    // MARK: - Fetching Operations

    /// Fetches all prescriptions for a patient
    /// - Parameter patient: The patient to fetch prescriptions for
    /// - Returns: Array of prescriptions
    func fetchPrescriptions(for patient: Patient) -> [Prescription] {
        let request: NSFetchRequest<Prescription> = Prescription.fetchRequest()
        request.predicate = NSPredicate(format: "patient == %@", patient)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Prescription.dateCreated, ascending: false)]

        do {
            let prescriptions = try context.fetch(request)
            Logger.log("Fetched \(prescriptions.count) prescriptions for patient: \(patient.fullName)",
                      category: .prescriptions, level: .info)
            return prescriptions
        } catch {
            Logger.log("Error fetching prescriptions: \(error.localizedDescription)",
                      category: .prescriptions, level: .error)
            return []
        }
    }

    /// Fetches active prescriptions for a patient
    /// - Parameter patient: The patient to fetch prescriptions for
    /// - Returns: Array of active prescriptions
    func fetchActivePrescriptions(for patient: Patient) -> [Prescription] {
        let request: NSFetchRequest<Prescription> = Prescription.fetchRequest()
        request.predicate = NSPredicate(format: "patient == %@ AND status == %@", patient, "active")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Prescription.dateCreated, ascending: false)]

        do {
            let prescriptions = try context.fetch(request)
            Logger.log("Fetched \(prescriptions.count) active prescriptions for patient: \(patient.fullName)",
                      category: .prescriptions, level: .info)
            return prescriptions
        } catch {
            Logger.log("Error fetching active prescriptions: \(error.localizedDescription)",
                      category: .prescriptions, level: .error)
            return []
        }
    }

    /// Fetches prescription history for a patient, grouped by medication
    /// - Parameter patient: The patient to fetch history for
    /// - Returns: Dictionary mapping drug names to their prescription items
    func fetchPrescriptionHistory(for patient: Patient) -> [String: [PrescriptionItem]] {
        let prescriptions = fetchPrescriptions(for: patient)
        var history: [String: [PrescriptionItem]] = [:]

        for prescription in prescriptions {
            if let items = prescription.items as? Set<PrescriptionItem> {
                for item in items {
                    let drugName = item.drugName ?? "Unknown"
                    if history[drugName] == nil {
                        history[drugName] = []
                    }
                    history[drugName]?.append(item)
                }
            }
        }

        // Sort items by start date for each drug
        for (drugName, items) in history {
            history[drugName] = items.sorted {
                ($0.startDate ?? Date()) > ($1.startDate ?? Date())
            }
        }

        Logger.log("Fetched prescription history for \(history.keys.count) unique medications",
                  category: .prescriptions, level: .info)

        return history
    }

    /// Fetches all medications currently prescribed to a patient
    /// - Parameter patient: The patient to fetch medications for
    /// - Returns: Array of prescription items from active prescriptions
    func fetchCurrentMedications(for patient: Patient) -> [PrescriptionItem] {
        let activePrescriptions = fetchActivePrescriptions(for: patient)
        var medications: [PrescriptionItem] = []

        for prescription in activePrescriptions {
            if let items = prescription.items as? Set<PrescriptionItem> {
                medications.append(contentsOf: items)
            }
        }

        // Filter to only include items that are currently active (between start and end dates)
        let now = Date()
        medications = medications.filter { item in
            guard let startDate = item.startDate else { return false }

            if let endDate = item.endDate {
                return startDate <= now && now <= endDate
            } else {
                return startDate <= now
            }
        }

        Logger.log("Found \(medications.count) current medications for patient",
                  category: .prescriptions, level: .info)

        return medications
    }

    // MARK: - Drug Interaction Checks

    /// Checks for potential drug interactions (stub implementation)
    /// - Parameter items: Array of prescription item data to check
    /// - Returns: Array of interaction warnings
    func checkDrugInteractions(items: [PrescriptionItemData]) -> [String] {
        // This is a stub implementation. In a production environment,
        // this would integrate with a drug interaction database or API

        var interactions: [String] = []

        // Example: Check for common known interactions
        let drugNames = items.map { $0.drugName.lowercased() }

        // Warfarin + NSAIDs
        if drugNames.contains(where: { $0.contains("warfarin") }) &&
           drugNames.contains(where: { $0.contains("ibuprofen") || $0.contains("aspirin") || $0.contains("naproxen") }) {
            interactions.append("Potential interaction: Warfarin with NSAIDs may increase bleeding risk")
        }

        // ACE inhibitors + Potassium supplements
        if drugNames.contains(where: { $0.contains("lisinopril") || $0.contains("enalapril") }) &&
           drugNames.contains(where: { $0.contains("potassium") }) {
            interactions.append("Potential interaction: ACE inhibitors with potassium supplements may cause hyperkalemia")
        }

        // SSRIs + NSAIDs
        if drugNames.contains(where: { $0.contains("sertraline") || $0.contains("fluoxetine") || $0.contains("citalopram") }) &&
           drugNames.contains(where: { $0.contains("ibuprofen") || $0.contains("aspirin") || $0.contains("naproxen") }) {
            interactions.append("Potential interaction: SSRIs with NSAIDs may increase bleeding risk")
        }

        // TODO: Implement comprehensive drug interaction checking
        // This should integrate with a proper drug interaction database

        if !interactions.isEmpty {
            Logger.log("Drug interaction check found \(interactions.count) potential interactions",
                      category: .prescriptions, level: .warning)
        }

        return interactions
    }

    /// Checks a new prescription against a patient's current medications
    /// - Parameters:
    ///   - items: New prescription items to check
    ///   - patient: The patient receiving the prescription
    /// - Returns: Array of interaction warnings
    func checkInteractionsWithCurrentMedications(
        items: [PrescriptionItemData],
        for patient: Patient
    ) -> [String] {

        let currentMedications = fetchCurrentMedications(for: patient)
        let currentDrugs = currentMedications.map {
            PrescriptionItemData(from: $0)
        }

        let allDrugs = currentDrugs + items
        return checkDrugInteractions(items: allDrugs)
    }
}

// MARK: - Supporting Data Structures

/// Data structure for creating/updating prescription items
struct PrescriptionItemData {
    var drugName: String
    var strength: String
    var dosage: String
    var frequency: String
    var route: String
    var duration: String
    var startDate: Date
    var endDate: Date?
    var specialInstructions: String
    var productID: NSManagedObjectID?

    init(
        drugName: String,
        strength: String = "",
        dosage: String,
        frequency: String,
        route: String,
        duration: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        specialInstructions: String = "",
        productID: NSManagedObjectID? = nil
    ) {
        self.drugName = drugName
        self.strength = strength
        self.dosage = dosage
        self.frequency = frequency
        self.route = route
        self.duration = duration
        self.startDate = startDate
        self.endDate = endDate
        self.specialInstructions = specialInstructions
        self.productID = productID
    }

    /// Initialize from a PrescriptionItem entity
    init(from item: PrescriptionItem) {
        self.drugName = item.drugName ?? ""
        self.strength = item.strength ?? ""
        self.dosage = item.dosage ?? ""
        self.frequency = item.frequency ?? ""
        self.route = item.route ?? ""
        self.duration = item.duration ?? ""
        self.startDate = item.startDate ?? Date()
        self.endDate = item.endDate
        self.specialInstructions = item.specialInstructions ?? ""
        self.productID = item.product?.objectID
    }
}
