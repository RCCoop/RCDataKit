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
    ///   - bundle:         The bundle in which to find the ManagedObjectModel file.
    ///   - modelName:      The title of the ManagedObjectModel file.
    ///   - modelVersion:   An optional title of the version to use of the ManagedObjectModel. If no version
    ///                     is given, the version specified by the model file is used.
    ///   - mainAuthor:     The `Author` case to use in the stack's viewContext.
    ///   - configurations: An array of actions taken after the container's descriptions are created
    ///                     and before the stores are loaded.
    private init(
        bundle: Bundle,
        modelName: String,
        modelVersion: String?,
        mainAuthor: Authors,
        configurations: [SingleStoreStackConfiguration]
    ) throws {
        // Create NSPersistentContainer
        self.container = NSPersistentContainer(
            bundle: bundle,
            modelName: modelName,
            versionName: modelVersion)
        
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
    ///   - bundle:                   The bundle in which to find the ManagedObjectModel file.
    ///   - storeURL:                 If set, the exact location for the PersistentStore.
    ///   - modelName:                The title of the ManagedObjectModel file.
    ///   - modelVersion:             The title of the version to use of the ManagedObjectModel. If no version
    ///                               is given, the version specified by the model file is used.
    ///   - mainAuthor:               The `Author` case to use in the stack's viewContext.
    ///   - persistentHistoryOptions: An optional instance of `PersistentHistoryTrackingOptions`
    ///                               that describe how to set up Persistent History Tracking. If none
    ///                               is given, the stack's viewContext automatically merges changes
    ///                               from the store, but without custom history tracking.
    public init(
        bundle: Bundle = .main,
        storeURL: URL? = nil,
        modelName: String,
        modelVersion: String? = nil,
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
            bundle: bundle,
            modelName: modelName,
            modelVersion: modelVersion,
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
    public init<V: PersistentStoreVersion>(
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
            desc.shouldMigrateStoreAutomatically = true
            desc.shouldInferMappingModelAutomatically = true
            desc.setOption(versionKey.migrationManager(), forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
        }
        
        try self.init(
            bundle: V.bundle,
            modelName: V.modelName,
            modelVersion: currentVersion?.versionName,
            mainAuthor: mainAuthor,
            configurations: [persistentHistoryConfiguration, urlConfiguration, versioningConfiguration])
    }
}
