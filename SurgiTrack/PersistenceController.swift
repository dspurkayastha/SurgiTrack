// PersistenceController.swift
// SurgiTrack
// Created on 06/03/2025

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
        appointment.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        appointment.appointmentType = "Consultation"
        appointment.patient = patient
        
        // Save the context
        try? viewContext.save()
        
        return controller
    }()
    
    // Core Data container
    let container: NSPersistentContainer
    
    // Initialize with optional in-memory flag for testing/previews
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SurgiTrack")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to terminate, which is not appropriate for production.
                print("Unresolved error loading persistent stores: \(error), \(error.userInfo)")
                
                // In a production app, you would log this error and present a user-friendly recovery UI
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Helper methods
    
    // Save changes if any are present
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
                
                // In a production app, you might recover by discarding changes or handling gracefully
            }
        }
    }
    
    // Clear test/development data (for debugging only)
    func deleteAllData() {
        let entities = container.managedObjectModel.entities
        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try container.persistentStoreCoordinator.execute(deleteRequest, with: container.viewContext)
                } catch {
                    print("Error deleting all data in \(entityName): \(error)")
                }
            }
        }
        
        // Save context to ensure changes are persisted
        save()
    }
}
