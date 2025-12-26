// PersistenceController.swift
// SurgiTrack
// Created on 06/03/2025
// Updated on 26/12/2025 - Added proper error handling and Logger

import CoreData

struct PersistenceController {
    // Shared instance used throughout the app
    static let shared = PersistenceController()

    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Create example data for previews
        let viewContext = controller.container.viewContext

        // Create sample patient
        let patient = Patient(context: viewContext)
        patient.id = UUID()
        patient.firstName = "John"
        patient.lastName = "Doe"
        patient.dateOfBirth = Calendar.current.date(byAdding: .year, value: -45, to: Date())
        patient.medicalRecordNumber = "MRN12345"
        patient.gender = "Male"
        patient.dateCreated = Date()
        patient.dateModified = Date()

        // Create sample appointment
        let appointment = Appointment(context: viewContext)
        appointment.id = UUID()
        appointment.title = "Initial Consultation"
        appointment.startTime = Date()
        appointment.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        appointment.appointmentType = "Consultation"
        appointment.patient = patient

        // Save the context
        do {
            try viewContext.save()
        } catch {
            Logger.error("Failed to save preview context", error: error, category: .persistence)
        }

        return controller
    }()

    // Core Data container
    let container: NSPersistentContainer

    // Flag indicating if store loaded successfully
    private(set) var storeLoadError: Error?

    // Initialize with optional in-memory flag for testing/previews
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SurgiTrack")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Enable persistent history tracking for background sync
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        var loadError: Error?

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                loadError = error
                Logger.fault("Failed to load persistent stores: \(error.localizedDescription)", category: .persistence)
                Logger.error("Persistent store error details", error: error, category: .persistence)

                // Attempt recovery by removing and recreating the store
                if !inMemory {
                    self.attemptStoreRecovery(description: description)
                }
            } else {
                Logger.info("Persistent store loaded successfully: \(description.url?.lastPathComponent ?? "unknown")", category: .persistence)
            }
        }

        self.storeLoadError = loadError

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.name = "viewContext"

        // Set undo manager for the view context
        container.viewContext.undoManager = nil
    }

    // MARK: - Store Recovery

    private func attemptStoreRecovery(description: NSPersistentStoreDescription) {
        guard let storeURL = description.url else {
            Logger.warning("Cannot attempt store recovery: no URL", category: .persistence)
            return
        }

        Logger.warning("Attempting persistent store recovery", category: .persistence)

        // In production, you might want to:
        // 1. Backup the corrupted store
        // 2. Try lightweight migration
        // 3. As last resort, remove and recreate

        // For now, log the issue - actual recovery should be handled carefully
        Logger.info("Store URL: \(storeURL.path)", category: .persistence)
    }

    // MARK: - Context Management

    /// Creates a new background context for performing work off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.name = "backgroundContext"
        return context
    }

    /// Performs a task on a background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(context)
        }
    }

    // MARK: - Save Operations

    /// Save changes if any are present
    @discardableResult
    func save() -> Bool {
        return save(context: container.viewContext)
    }

    /// Save changes to a specific context
    @discardableResult
    func save(context: NSManagedObjectContext) -> Bool {
        guard context.hasChanges else {
            return true
        }

        do {
            try context.save()
            Logger.debug("Context saved successfully", category: .persistence)
            return true
        } catch {
            let nsError = error as NSError
            Logger.error("Failed to save context: \(nsError.localizedDescription)", error: error, category: .persistence)

            // Log detailed error info
            if let detailedErrors = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                for detailedError in detailedErrors {
                    Logger.error("Detailed error: \(detailedError.localizedDescription)", error: detailedError, category: .persistence)
                }
            }

            // Rollback changes on failure
            context.rollback()
            Logger.info("Context rolled back after save failure", category: .persistence)

            return false
        }
    }

    /// Save context with error throwing for explicit handling
    func saveThrows(context: NSManagedObjectContext? = nil) throws {
        let targetContext = context ?? container.viewContext
        guard targetContext.hasChanges else { return }

        do {
            try targetContext.save()
            Logger.debug("Context saved successfully", category: .persistence)
        } catch {
            Logger.error("Failed to save context", error: error, category: .persistence)
            throw AppError.persistenceError(underlying: error)
        }
    }

    // MARK: - Data Management

    /// Clear all data (for development/testing only)
    func deleteAllData() {
        Logger.warning("Deleting all data from persistent store", category: .persistence)

        let entities = container.managedObjectModel.entities
        for entity in entities {
            guard let entityName = entity.name else { continue }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            do {
                let result = try container.persistentStoreCoordinator.execute(deleteRequest, with: container.viewContext) as? NSBatchDeleteResult
                let deletedIDs = result?.result as? [NSManagedObjectID] ?? []

                // Merge deletions into the view context
                let changes = [NSDeletedObjectsKey: deletedIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])

                Logger.info("Deleted \(deletedIDs.count) objects from \(entityName)", category: .persistence)
            } catch {
                Logger.error("Failed to delete data from \(entityName)", error: error, category: .persistence)
            }
        }

        // Save context to ensure changes are persisted
        save()
        Logger.info("All data deletion complete", category: .persistence)
    }

    /// Get the store URL for backup purposes
    var storeURL: URL? {
        return container.persistentStoreDescriptions.first?.url
    }

    /// Check if the store is available
    var isStoreAvailable: Bool {
        return storeLoadError == nil && !container.persistentStoreCoordinator.persistentStores.isEmpty
    }
}
