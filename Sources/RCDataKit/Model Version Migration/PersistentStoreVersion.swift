//
//  PersistentStoreVersion.swift
//
//
//  Created by Ryan Linn on 8/25/24.
//

import CoreData
import UniformTypeIdentifiers

@available(macOS 14.0, *)
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

    /// <#Description#>
    static func migrationStages() -> [NSMigrationStage]
}

// MARK: - Default Implementations

@available(macOS 14.0, *)
public extension PersistentStoreVersion where Self: RawRepresentable, RawValue == String {
    var versionName: String {
        rawValue
    }
}

@available(macOS 14.0, *)
extension PersistentStoreVersion {
    static var modelURL: URL {
        bundle.url(forResource: modelName, withExtension: "momd")!
    }
    
    var versionURL: URL {
        Self.modelURL.appendingPathComponent(versionName + ".mom", conformingTo: .managedObjectModel)
    }
    
    var modelVersion: NSManagedObjectModel {
        NSManagedObjectModel(contentsOf: versionURL)!
    }
    
    var versionChecksum: String {
        modelVersion.versionChecksum
    }
    
    var modelReference: NSManagedObjectModelReference {
        NSManagedObjectModelReference(model: modelVersion, versionChecksum: versionChecksum)
    }
}

// MARK: - Helpers:

extension UTType {
    static var managedObjectModel: UTType {
        UTType(tag: "mom", tagClass: .filenameExtension, conformingTo: nil)!
    }
}

enum MigrationError: Error {
    case persistentContainerNotFound
}

@available(macOS 14.0, *)
extension PersistentStoreVersion {
    public typealias MigrationHandler = (NSManagedObjectContext) throws -> Void
    
    /// <#Description#>
    /// - Returns: <#description#>
    public static func migrationManager() -> NSStagedMigrationManager {
        NSStagedMigrationManager(migrationStages())
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - toVersion: <#toVersion description#>
    ///   - label: <#label description#>
    ///   - preMigration: <#preMigration description#>
    ///   - postMigration: <#postMigration description#>
    /// - Returns: <#description#>
    public func migrationStage(
        toVersion: Self,
        label: String,
        preMigration: MigrationHandler? = nil,
        postMigration: MigrationHandler? = nil
    ) -> NSCustomMigrationStage {
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
