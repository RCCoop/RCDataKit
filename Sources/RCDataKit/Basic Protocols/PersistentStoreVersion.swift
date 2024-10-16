//
//  PersistentStoreVersion.swift
//

import CoreData
import UniformTypeIdentifiers

/// A protocol used to streamline the process of building a `NSStagedMigrationManager` for your Core
/// Data Persistent Model.
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, macCatalyst 17.0, *)
public protocol PersistentStoreVersion: CaseIterable {
    /// The bundle where the ManagedObjectModel file resides
    static var bundle: Bundle { get }
    
    /// The title of the ManagedObjectModel file
    static var modelName: String { get }
    
    /// The title of the model version represented by this instance.
    ///
    /// If the `PersistentStoreVersion` type is a `RawRepresentable` of type `String`, the
    /// default implementation of `versionName` takes the raw value of the instance as its version name.
    var versionName: String { get }

    /// The `PersistentStoreVersion` type must provide an array of `NSMigrationStage` to be used
    /// to create a migration path across versions of the persistent model.
    ///
    /// The stages must be returned in order from earliest version to latest, in the order that the stages will
    /// be performed.
    ///
    /// The stages are passed directly to [NSStagedMigrationManager.init(_:)](https://developer.apple.com/documentation/coredata/nsstagedmigrationmanager/4211266-init)
    /// to create a `NSStagedMigrationManager` in `Self.migrationManager()`.
    static func migrationStages() -> [NSMigrationStage]
}

// MARK: - Default Implementations

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, macCatalyst 17.0, *)
public extension PersistentStoreVersion where Self: RawRepresentable, RawValue == String {
    var versionName: String {
        rawValue
    }
}

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, macCatalyst 17.0, *)
extension PersistentStoreVersion {
    static var modelURL: URL {
        NSManagedObjectModel.modelURL(modelName: modelName)
    }
    
    var versionURL: URL {
        NSManagedObjectModel
            .modelVersionURL(
                bundle: Self.bundle,
                modelName: Self.modelName,
                versionName: versionName)
    }
    
    var modelVersion: NSManagedObjectModel {
        NSManagedObjectModel.create(
            bundle: Self.bundle,
            modelName: Self.modelName,
            versionName: versionName)!
    }
    
    var versionChecksum: String {
        modelVersion.versionChecksum
    }
    
    var modelReference: NSManagedObjectModelReference {
        NSManagedObjectModelReference(model: modelVersion, versionChecksum: versionChecksum)
    }
}

// MARK: - Helpers:

enum MigrationError: Error {
    case persistentContainerNotFound
}

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, macCatalyst 17.0, *)
extension PersistentStoreVersion {
    public typealias MigrationHandler = (NSManagedObjectContext) throws -> Void
    
    /// Creates a `NSStagedMigrationManager` from the `PersistentStoreVersion`'s
    /// `migrationStages()` function to be added to the persistent store.
    public static func migrationManager() -> NSStagedMigrationManager {
        NSStagedMigrationManager(migrationStages())
    }
    
    /// A helper function that creates a distinct `NSMigrationStage` from the calling version to the next
    /// `PersistentStoreVersion` for use in building a series of staged migration steps.
    ///
    /// - Parameters:
    ///   - toVersion:     The version that this migration stage will end at, starting from the calling version.
    ///   - label:         A descriptive title for the migration stage.
    ///   - preMigration:  The work to be done in a background context before the migration stage is
    ///                    complete.
    ///   - postMigration: The work to be done in a background context after the migration stage is
    ///                    complete.
    ///
    /// - Returns: A `NSCustomMigrationStage`, erased to `NSMigrationStage` with the specified
    ///            versions, label, and migration handlers.
    ///
    /// If both `preMigration` and `postMigration` are empty, the migration stage is effectively a
    /// `NSLightweightMigrationHandler`.
    ///
    /// Both `preMigration` and `postMigration` closures are performed in a background context,
    /// on the context's thread, so you don't need to call `perform` functions on the context.
    ///
    /// All work done in the pre- and post-migration handlers should only use `NSManagedObject`s rather
    /// than concrete subclasses, since the subclasses may not be loaded in the model at the time of execution.
    public func migrationStage(
        toVersion: Self,
        label: String,
        preMigration: MigrationHandler? = nil,
        postMigration: MigrationHandler? = nil
    ) -> NSMigrationStage {
        let result = NSCustomMigrationStage(
            migratingFrom: self.modelReference,
            to: toVersion.modelReference
        )
        
        if let preMigration {
            result.willMigrateHandler = { migrationManager, stage in
                guard let container = migrationManager.container else {
                    throw MigrationError.persistentContainerNotFound
                }
                
                let context = container.newBackgroundContext()
                try context.performAndWait {
                    try preMigration(context)
                    try context.save()
                }
            }
        }
        
        if let postMigration {
            result.didMigrateHandler = { migrationManager, stage in
                guard let container = migrationManager.container else {
                    throw MigrationError.persistentContainerNotFound
                }
                
                let context = container.newBackgroundContext()
                try context.performAndWait {
                    try postMigration(context)
                    try context.saveIfNeeded()
                }
            }
        }
        
        result.label = label
        return result
    }
}
