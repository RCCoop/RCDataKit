//
//  BasicDataStack.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/4/24.
//

import CoreData
import Foundation

typealias BasicDataStackConfiguration = (NSPersistentStoreDescription, NSManagedObjectContext) -> Void

/// An object that conforms to `DataStack`, and handles basic setup of the
public struct BasicDataStack: DataStack {
    enum Errors: Error {
        case noStoreDescription
    }

    public let container: NSPersistentContainer
    public let mainContextAuthor: TransactionAuthor
    public private(set) var historyTracker: PersistentHistoryTracker? = nil
    
    /// Private initializer that underpins the public initializers.
    ///
    /// - Parameters:
    ///   - modelName:      The title of the managed object model.
    ///   - model:          The managed model used to initialize the store.
    ///   - mainAuthor:     The `Author` case to use in the stack's viewContext.
    ///   - configurations: An array of actions taken after the container's descriptions are created
    ///                     and before the stores are loaded.
    private init(
        modelName: String,
        model: NSManagedObjectModel,
        mainAuthor: TransactionAuthor,
        configurations: [BasicDataStackConfiguration]
    ) throws {
        // Create NSPersistentContainer
        self.container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        
        // Set main viewContext name
        self.mainContextAuthor = mainAuthor
        
        // Get main Description
        guard let description = container.persistentStoreDescriptions.first else {
            throw Errors.noStoreDescription
        }
        description.type = NSSQLiteStoreType
        
        // Custom configurations
        for config in configurations {
            config(description, container.viewContext)
        }
        
        // Finish loading store
        try container.loadStores()
    }
    
    /// Initializes the stack by pointing to the ManagedObjectModel file by name and bundle, with an option
    /// to enable Persistent History Tracking.
    ///
    /// - Parameters:
    ///   - modelFile:                A type of `ModelFileManager` used to create the
    ///                               persistent store.
    ///   - storeURL:                 If set, the exact location for the PersistentStore.
    ///   - modelVersion:             The title of the version to use of the ManagedObjectModel. If no version
    ///                               is given, the version specified by the model file is used.
    ///   - mainAuthor:               The `Author` case to use in the stack's viewContext.
    ///   - persistentHistoryOptions: An optional instance of `PersistentHistoryTrackingOptions`
    ///                               that describe how to set up Persistent History Tracking. If none
    ///                               is given, the stack's viewContext automatically merges changes
    ///                               from the store, but without custom history tracking.
    public init<ModelFile: ModelFileManager>(
        _ modelFile: ModelFile.Type,
        storeURL: URL? = nil,
        mainAuthor: TransactionAuthor,
        persistentHistoryOptions: PersistentHistoryTrackingOptions? = nil
    ) throws {
        
        let persistentHistoryConfiguration: BasicDataStackConfiguration = { (desc, context) in
            PersistentHistoryTrackingOptions.doConfiguration(
                options: persistentHistoryOptions,
                storeDescription: desc,
                viewContext: context)
        }
        let urlConfiguration: BasicDataStackConfiguration = { (desc, context) in
            if let storeURL {
                desc.url = storeURL
            }
        }
        
        try self.init(
            modelName: modelFile.modelName,
            model: modelFile.model,
            mainAuthor: mainAuthor,
            configurations: [persistentHistoryConfiguration, urlConfiguration])
        
        self.historyTracker = persistentHistoryOptions?.tracker(currentAuthor: mainAuthor, container: container)
    }
    
    /// Initializes the stack using a type conforming to `ModelVersion`, with an option to
    /// enable Persistent History Tracking.
    ///
    /// - Parameters:
    ///   - storeURL:                 If set, the exact location for the PersistentStore.
    ///   - versionKey:               The `ModelVersion` type to use in setting
    ///                               up the persistent store and its staged version migration chain.
    ///   - currentVersion:           The version to use of the ManagedObjectModel. If no version
    ///                               is given, the version specified by the model file is used.
    ///   - mainAuthor:               The `Author` case to use in the stack's viewContext.
    ///   - persistentHistoryOptions: An optional instance of `PersistentHistoryTrackingOptions`
    ///                               that describe how to set up Persistent History Tracking. If none
    ///                               is given, the stack's viewContext automatically merges changes
    ///                               from the store, but without custom history tracking.
    @available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, macCatalyst 17.0, *)
    public init<V: ModelVersion>(
        storeURL: URL? = nil,
        versionKey: V.Type,
        currentVersion: V? = nil,
        mainAuthor: TransactionAuthor,
        persistentHistoryOptions: PersistentHistoryTrackingOptions? = nil
    ) throws {
        let persistentHistoryConfiguration: BasicDataStackConfiguration = { (desc, context) in
            PersistentHistoryTrackingOptions.doConfiguration(
                options: persistentHistoryOptions,
                storeDescription: desc,
                viewContext: context)
        }
        let urlConfiguration: BasicDataStackConfiguration = { (desc, context) in
            if let storeURL {
                desc.url = storeURL
            }
        }
        let versioningConfiguration: BasicDataStackConfiguration = { (desc, context) in
            // Auto migrate if no version is specified, or if specified version is older than current
            if currentVersion == versionKey.currentVersion || currentVersion == nil {
                desc.shouldMigrateStoreAutomatically = true
                desc.shouldInferMappingModelAutomatically = true
                desc.setOption(versionKey.migrationManager(), forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
            } else {
                desc.shouldMigrateStoreAutomatically = false
            }
        }
        
        try self.init(
            modelName: V.ModelFile.modelName,
            model: currentVersion?.modelVersion ?? V.ModelFile.model,
            mainAuthor: mainAuthor,
            configurations: [persistentHistoryConfiguration, urlConfiguration, versioningConfiguration])
    }
}
