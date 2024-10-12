//
//  Persistable.swift
//

import CoreData
import Foundation

/// A simple protocol that facilitates imports into Core Data. Types that implement `Persistable` do almost
/// all of the work associated with the import, but the functions associated with `Persistable` provide a
/// standardized process for the import.
///
/// To implement this protocol, there are three requirements:
///
/// - Specify an associated `ImporterData` type, which holds other data to aid in writing the `Persistable`
///   types into Core Data. `ImporterData` can be `Void` if no extra data is needed. Example data to
///   be used in `ImporterData` types can be relations to be set in the imported objects, or existing
///   objects that will be replaced or updated by the import.
/// - A static function that generates an instance of `ImporterData` for a given array of `Persistable`
///   instances and a `NSManagedObjectContext`. If `ImporterData` is `Void`, this function can
///   be skipped.
/// - An instance function that takes a `NSManagedObjectContext` and the generated `ImporterData`,
///   and imports the caller into the Core Data context.
///
/// To import the `Persistable` types into Core Data, simply call `importPersistableObjects(_:)`
/// on the `NSManagedObjectContext`, and the context will call the above functions, performing the
/// `Persistable` type's import functions for you.
public protocol Persistable {
    associatedtype ImporterData
    
    /// The first function called by `NSManagedObjectContext.importPersistableObjects(_:)`,
    /// this function requires you to provide an instance of `ImporterData` for a given array of `Persistable`
    /// items.
    ///
    /// In implementing the protocol, you decide what information will go into the result, which can be of any
    /// type you decide. Useful information could be related `NSManagedObject`s to reference in the
    /// imported objects, existing instances of the import target that could be updated, or whatever else you
    /// find helpful.
    ///
    /// - Parameters:
    ///   - objects: An array of `Self` that will be imported into the persistent store.
    ///   - context: The `NSManagedObjectContext` that will receive the imported objects.
    ///
    /// - Returns: An instance of `ImporterData` necessary for the next step of the import process --
    ///            `importIntoContext(_:importerData:)`.
    ///
    /// - Throws: If generating the `ImporterData` result fails, this function must throw an error, which
    ///           will cause the import process to fail.
    static func generateImporterData(
        objects: [Self],
        context: NSManagedObjectContext
    ) throws -> ImporterData
    
    /// This function is called on each `Persistable` item to be imported during `NSManagedObjectContext`'s
    /// `importPersistableObjects(_:)` function, and is responsible for writing the item's data into
    /// the context.
    ///
    /// - Parameters:
    ///   - context:      The `NSManagedObjectContext` to write the item into.
    ///   - importerData: An instance of this type's `ImporterData` created by the type's
    ///                   `generateImporterData(objects:context:)` function.
    ///                   `importerData` is an `inout` parameter, so you may modify it as
    ///                   you import more objects.
    ///
    /// - Returns: An instance of `PersistableResult` describing the action taken to write the item's
    ///            data into the context.
    func importIntoContext(
        _ context: NSManagedObjectContext,
        importerData: inout ImporterData
    ) -> PersistenceResult
}

/*
extension Persistable where ImporterData == Void {
    // !!!: This should satisfy the protocol requirement, but in practice it fails to
    static func generateImporterData(
        objects: [Self],
        context: NSManagedObjectContext
    ) throws -> () {
        // No action
        return ()
    }
}
 */

public enum PersistenceResult {
    case insert(NSManagedObjectID)
    case update(NSManagedObjectID)
    case delete(NSManagedObjectID)
    case noAction
    case fail(Error)
}

extension NSManagedObjectContext {
    /// This function is used to import a batch of items that implement the `Persistable` protocol into
    /// the `NSManagedObjectContext` using the `Persistable` type's structured import process.
    ///
    /// The function does very besides call the developer-defined functions supplied by the `Persistable`
    /// protocol -- first, it calls `generateImporterData(objects:context:)` to generate an instance
    /// of the type's `ImporterData` associated type, and then uses that `ImporterData` to call
    /// `importIntoContext(_:importerData:)` on each item in the `objects` array. It is up to
    /// you as the developer implementing the `Perstistable` protocol to define the process taken in
    /// each step.
    ///
    /// - Parameter objects: An array of `Persistable` objects to be written into the context.
    ///
    /// - Returns: An array of `PersistenceResult` in the same indexed order as the `objects`
    ///            array parameter, each result a product of the `Persistable` type's
    ///            `importIntoContext(_:importerData:)` function.
    ///
    /// - Throws: This function will only throw if the `Persistable` type's `generateImporterData(objects:context:)`
    ///           throws an error, since that will cause the entire import process to fail. If any invidual items
    ///           fail to import, they would otherwise return a `PersistenceResult.fail()` result
    ///           that can be handled separately.
    public func importPersistableObjects<T: Persistable>(
        _ objects: [T]
    ) throws -> [PersistenceResult] {
        var importerData = try T.generateImporterData(objects: objects, context: self)
        
        let resultsArray = objects.map {
            $0.importIntoContext(self, importerData: &importerData)
        }
        
        return resultsArray
    }
    
    /// This function is used to import a batch of items that implement the `Persistable` protocol into
    /// the `NSManagedObjectContext` using the `Persistable` type's structured import process.
    ///
    /// The function does very besides call the developer-defined functions supplied by the `Persistable`
    /// protocol -- first, it calls `generateImporterData(objects:context:)` to generate an instance
    /// of the type's `ImporterData` associated type, and then uses that `ImporterData` to call
    /// `importIntoContext(_:importerData:)` on each item in the `objects` array. It is up to
    /// you as the developer implementing the `Perstistable` protocol to define the process taken in
    /// each step.
    ///
    /// - Parameter objects: An array of `Persistable` objects to be written into the context.
    ///
    /// - Returns: A dictionary where each `Persistable` object's `ID` is keyed to the
    ///            `PersistenceResult` produced by that object's `importIntoContext(_:importerData:)`
    ///            function call.
    ///
    /// - Throws: This function will only throw if the `Persistable` type's `generateImporterData(objects:context:)`
    ///           throws an error, since that will cause the entire import process to fail. If any invidual items
    ///           fail to import, they would otherwise return a `PersistenceResult.fail()` result
    ///           that can be handled separately.
    public func importPersistableObjects<T: Persistable & Identifiable>(
        _ objects: [T]
    ) throws -> [T.ID : PersistenceResult] {
        var importerData = try T.generateImporterData(objects: objects, context: self)
        
        let resultsDict = objects.reduce(into: [:]) {
            $0[$1.id] = $1.importIntoContext(self, importerData: &importerData)
        }
        
        return resultsDict
    }
}
