//
//  PersistentStoreTest.swift
//  
//
//  Created by Ryan Linn on 8/10/24.
//

import CoreData
import XCTest

class PersistentStoreTest: XCTestCase {
    
    private static let modelName = "TestModel"
    private static var mergedModel: NSManagedObjectModel {
        .mergedModel(from: [.module])!
    }
        
    private static var diskLocation: URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
            .appending(path: "TestStore")
    }
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        // Setup things
    }
    
    override func tearDown() async throws {
        try Self.removeDiskStoredContainers()
        await sleep(seconds: 0.5)
    }

    // MARK: - Persistent Container Factories
    
    static func makeContainer() throws -> NSPersistentContainer {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        
        let container = NSPersistentContainer(name: modelName, managedObjectModel: mergedModel)
        container.persistentStoreDescriptions = [description]
        
        var loadingError: Error?
        container.loadPersistentStores { description, error in
            loadingError = error
        }
        
        if let loadingError {
            throw loadingError
        }
        
        return container
    }
    
    static func makeContainerWithPersistentTracking() throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: mergedModel)
        let description = container.persistentStoreDescriptions.first!
        description.url = diskLocation
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        var error: Error?
        container.loadPersistentStores { _, err in
            if let err { error = err }
        }
        if let error {
            throw error
        }
        return container
    }
    
    static func makeContainerForOriginalModel() throws -> NSPersistentContainer {
        let momdURL = Bundle.module.url(forResource: "TestModel", withExtension: "momd")
        let modelV1URL = momdURL.map { $0.appendingPathComponent("Model.mom") }
        let modelV1 = modelV1URL.flatMap { NSManagedObjectModel(contentsOf: $0) }
        
        guard let modelV1 else {
            fatalError()
        }
        
        let persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: modelV1)
        if let description = persistentContainer.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = false
            description.shouldInferMappingModelAutomatically = false
            description.url = diskLocation
        }
        
        var error: Error?
        persistentContainer.loadPersistentStores { _, err in
            if let err { error = err }
        }
        if let error {
            throw error
        }
        
        return persistentContainer
    }
        
    @available(macOS 14.0, iOS 17.0, *)
    static func makeContainerWithStagedMigrations(manager: NSStagedMigrationManager) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: mergedModel)
        let description = container.persistentStoreDescriptions.first!
        description.url = diskLocation
//        description.shouldMigrateStoreAutomatically = false
//        description.shouldInferMappingModelAutomatically = false
        description.setOption(manager, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
        
        var error: Error?
        container.loadPersistentStores { _, err in
            if let err { error = err }
        }
        if let error {
            throw error
        }
        return container
    }
    
    // MARK: - General Helper Functions
    
    func sleep(seconds: Double) async {
        try! await Task.sleep(for: .seconds(seconds))
    }
    
    // MARK: - Context Helpers
    
    func addStudentsFromSampleData(context: NSManagedObjectContext) throws {
        let sampleData = try SampleData.build()
        for student in sampleData.students {
            _ = Student(
                context: context,
                id: student.id,
                firstName: student.firstName,
                lastName: student.lastName)
        }

        try context.save()

    }

    var simpsonsPredicate: NSPredicate {
        NSPredicate(format: "%K == 'Simpson'", #keyPath(Student.lastName))
    }
    
    var bobsPredicate: NSPredicate {
        NSPredicate(format: "%K == 'Belcher'", #keyPath(Student.lastName))
    }
    
    var southParkPredicate: NSPredicate {
        NSPredicate(format: "%K BETWEEN %@", #keyPath(Student.id), [3, 6])
    }
    
    var sortById: [NSSortDescriptor] {
        [NSSortDescriptor(key: "id", ascending: true)]
    }

    
    // MARK: - Private Functions
    
    private static func removeDiskStoredContainers() throws {
        let url = diskLocation
        let urls = [
            url,
            URL(fileURLWithPath: url.path + "-shm"),
            URL(fileURLWithPath: url.path + "-wal")
        ]
        
        for oneURL in urls {
            if let _ = try? Data(contentsOf: oneURL) {
                try FileManager.default.removeItem(at: oneURL)
            }
        }
    }
}
