//
//  ModelVersion.swift
//

import CoreData
import UniformTypeIdentifiers

/// A protocol used to streamline the process of building a `NSStagedMigrationManager` for your Core
/// Data Persistent Model.
@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, macCatalyst 17.0, *)
public protocol ModelVersion: CaseIterable, Hashable {
    associatedtype ModelFile: ModelFileManager
    
    /// The instance of `Self` that represents the current version of the data model.
    ///
    /// A default implementation returns the last case of `allCases`.
    static var currentVersion: Self { get }
    
    /// The title of the model version represented by this instance.
    ///
    /// If the `ModelVersion` type is a `RawRepresentable` of type `String`, the
    /// default implementation of `versionName` takes the raw value of the instance as its version name.
    var versionName: String { get }
    
    /// The `NSManagedObjectModel` represented by this version of the model.
    ///
    /// The default implementation of this variable will return the model inferred from the `ModelFile`
    /// type associated with this type.
    var modelVersion: NSManagedObjectModel { get }
    
    /// The `ModelVersion` type must provide an array of `NSMigrationStage` to be used
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
public extension ModelVersion where Self: RawRepresentable, RawValue == String {
    var versionName: String {
        rawValue
    }
}

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, macCatalyst 17.0, *)
extension ModelVersion {
    public var modelVersion: NSManagedObjectModel {
        if self == Self.currentVersion {
            return ModelFile.model
        } else {
            return NSManagedObjectModel.named(
                ModelFile.modelName,
                in: ModelFile.bundle,
                versionName: versionName)!
        }
    }

    public static var currentVersion: Self {
        Array(allCases).last!
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
extension ModelVersion {
    public typealias MigrationHandler = (NSManagedObjectContext) throws -> Void
    
    /// Creates a `NSStagedMigrationManager` from the `ModelVersion`'s
    /// `migrationStages()` function to be added to the persistent store.
    public static func migrationManager() -> NSStagedMigrationManager {
        NSStagedMigrationManager(migrationStages())
    }
    
    /// A helper function that creates a distinct `NSMigrationStage` from the calling version to the next
    /// `ModelVersion` for use in building a series of staged migration steps.
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
    
    /// Tests an existing Persistent Store for which model version it uses.
    ///
    /// Use this function on a Persistent Store file that isn't necessarily currently being used, in order to determine
    /// which version of your `ModelVersion` the store is configured for. This can be used for debugging
    /// staged migrations.
    ///
    /// - Parameters:
    ///   - type: The type of store at the given location.
    ///   - storeUrl: The location of the store.
    ///   - configuration: Optionally, the configuration of the data model to use.
    ///
    /// - Returns: An array of versions that are compatible with the store (there should only be zero or
    ///            one versions in the resulting array).
    public static func versionsForStore(
        type: NSPersistentStore.StoreType,
        at storeUrl: URL,
        configuration: String? = nil
    ) -> [Self] {
        // using https://williamboles.com/progressive-core-data-migration/
        // to find which version of the model is currently used for the store
        guard let storeMetadata = try? NSPersistentStoreCoordinator
            .metadataForPersistentStore(type: type, at: storeUrl)
        else {
            return []
        }
        
        let bundle = ModelFile.bundle
        let modelName = ModelFile.modelName
        let res = allCases.filter { version in
            if let testModel = NSManagedObjectModel.named(modelName, in: bundle, versionName: version.versionName) {
                if testModel.isConfiguration(withName: configuration, compatibleWithStoreMetadata: storeMetadata) {
                    return true
                }
            }
            return false
        }
        return res
    }
    
    /// Tests a `NSPersistentStoreCoordinator` to determine which version of the model it is using.
    ///
    /// - Parameter coordinator: The persistent store coordinator to test.
    ///
    /// - Returns: An array of versions that are compatible with the store (there should only be zero or
    ///            one versions in the resulting array).
    public static func versionsForStore(coordinator: NSPersistentStoreCoordinator) -> [Self] {
        allCases.filter { version in
            coordinator.managedObjectModel == version.modelVersion
        }
    }
}
