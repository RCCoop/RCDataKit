//
//  SingleStoreStack.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/4/24.
//

import CoreData
import Foundation

typealias SingleStoreStackConfiguration = (NSPersistentStoreDescription, NSManagedObjectContext) -> Void

/// An object that conforms to `DataStack`, and handles basic setup of the
public struct SingleStoreStack<Authors: TransactionAuthor>: DataStack {
    enum Errors: Error {
        case noStoreDescription
    }

    public let container: NSPersistentContainer
    public private(set) var historyTracker: PersistentHistoryTracker<Authors>? = nil
    public let viewContextID: Authors
    
    /// Private initializer that underpins the public initializers.
    ///
    /// - Parameters:
    ///   - modelName:      The title of the ManagedObjectModel file.
    ///   - model:          <#description#>
    ///   - mainAuthor:     The `Author` case to use in the stack's viewContext.
    ///   - configurations: An array of actions taken after the container's descriptions are created
    ///                     and before the stores are loaded.
    private init(
        modelName: String,
        model: NSManagedObjectModel,
        mainAuthor: Authors,
        configurations: [SingleStoreStackConfiguration]
    ) throws {
        // Create NSPersistentContainer
        self.container = NSPersistentContainer(name: modelName, managedObjectModel: model)
        
        // Set main viewContext name
        self.viewContextID = mainAuthor
        
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
    ///   - modelDefinition:          <#description#>
    ///   - storeURL:                 If set, the exact location for the PersistentStore.
    ///   - modelVersion:             The title of the version to use of the ManagedObjectModel. If no version
    ///                               is given, the version specified by the model file is used.
    ///   - mainAuthor:               The `Author` case to use in the stack's viewContext.
    ///   - persistentHistoryOptions: An optional instance of `PersistentHistoryTrackingOptions`
    ///                               that describe how to set up Persistent History Tracking. If none
    ///                               is given, the stack's viewContext automatically merges changes
    ///                               from the store, but without custom history tracking.
    public init<ModelDefinition: ModelFileManager>(
        _ modelDefinition: ModelDefinition.Type,
        storeURL: URL? = nil,
        mainAuthor: Authors,
        persistentHistoryOptions: PersistentHistoryTrackingOptions? = nil
    ) throws {
        
        let persistentHistoryConfiguration: SingleStoreStackConfiguration = { (desc, context) in
            PersistentHistoryTrackingOptions.doConfiguration(
                options: persistentHistoryOptions,
                storeDescription: desc,
                viewContext: context)
        }
        let urlConfiguration: SingleStoreStackConfiguration = { (desc, context) in
            if let storeURL {
                desc.url = storeURL
            }
        }
        
        try self.init(
            modelName: modelDefinition.modelName,
            model: modelDefinition.model,
            mainAuthor: mainAuthor,
            configurations: [persistentHistoryConfiguration, urlConfiguration])
        
        self.historyTracker = persistentHistoryOptions?.tracker(currentAuthor: mainAuthor, container: container)
    }
    
    /// Initializes the stack using a type conforming to `PersistentStoreVersion`, with an option to
    /// enable Persistent History Tracking.
    ///
    /// - Parameters:
    ///   - storeURL:                 If set, the exact location for the PersistentStore.
    ///   - versionKey:               The `PersistentStoreVersion` type to use in setting
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
        mainAuthor: Authors,
        persistentHistoryOptions: PersistentHistoryTrackingOptions? = nil
    ) throws {
        let persistentHistoryConfiguration: SingleStoreStackConfiguration = { (desc, context) in
            PersistentHistoryTrackingOptions.doConfiguration(
                options: persistentHistoryOptions,
                storeDescription: desc,
                viewContext: context)
        }
        let urlConfiguration: SingleStoreStackConfiguration = { (desc, context) in
            if let storeURL {
                desc.url = storeURL
            }
        }
        let versioningConfiguration: SingleStoreStackConfiguration = { (desc, context) in
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
