//
//  NSManagedObjectContext+.swift
//

import CoreData

// MARK: - Data Modifications

public extension NSManagedObjectContext {
    /// Attempts to save the context only if changes are present in it. Otherwise, skips the save.
    ///
    /// - Returns: A boolean indicating if a save occurred.
    @discardableResult
    func saveIfNeeded() throws -> Bool {
        if hasChanges {
            try save()
            return true
        } else {
            return false
        }
    }

    /// Deletes all instances of a `NSManagedObject` type in the persistent store, or those matching a
    /// provided `NSPredicate`.
    ///
    /// - Parameters:
    ///   - type:   The type of `NSManagedObject` to delete.
    ///   - filter: An optional `NSPredicate`. If provided, the function will only delete those objects
    ///             matching the predicate.
    func removeInstances<T: NSManagedObject>(of type: T.Type, matching filter: NSPredicate? = nil) throws {
        guard let entityName = T.entity().name else {
            fatalError("No entity name found for \(String(describing: T.self))")
        }
        let request = NSFetchRequest<T>(entityName: entityName)
        request.includesPropertyValues = false
        request.predicate = filter
        let results = try fetch(request)
        results.forEach { delete($0) }
    }
}

// MARK: - NSManagedObject Access

public extension NSManagedObjectContext {
    enum ExistingObjectFailure: Error {
        case mismatchedType(foundEntity: String)
        case notFound
    }

    /// Retrieves an object of a given `NSManagedObject` subclass from persistent store if it exists.
    ///
    /// - Parameters:
    ///   - type: The type of object to retrieve.
    ///   - id:   The `NSManagedObjectID` of the object.
    ///
    /// - Returns: The concrete object, if it exists in the store. Otherwise, an error is thrown.
    func existing<T: NSManagedObject>(_ type: T.Type, withID id: NSManagedObjectID) throws -> T {
        guard let managedObject = try? existingObject(with: id) else {
            throw ExistingObjectFailure.notFound
        }
        guard let typedObject = managedObject as? T else {
            throw ExistingObjectFailure.mismatchedType(foundEntity: managedObject.entity.name!)
        }
        return typedObject
    }
    
    /// Retrieves an array of objects of a given `NSManagedObject` subclass from persistent store, skipping
    /// any that don't exist.
    ///
    /// - Parameters:
    ///   - type: The type of object to retrieve.
    ///   - ids:  An array of `NSManagedObjectID`s to fetch from the store.
    ///
    /// - Returns: An unordered array of objects of the given type that match the IDs provided.
    func existing<T: NSManagedObject>(_ type: T.Type, withIDs ids: [NSManagedObjectID]) throws -> [T] {
        guard let entityName = T.entity().name else {
            fatalError("No entity name found for \(String(describing: T.self))")
        }
        let predicate = NSPredicate(managedObjectIds: ids)
        let request = NSFetchRequest<T>(entityName: entityName)
        request.predicate = predicate
        return try fetch(request)
    }
}

// MARK: - TransactionAuthors

public extension NSManagedObjectContext {
    func setAuthor<A: TransactionAuthor>(_ author: A) {
        transactionAuthor = author.name
    }
    
    func author<A: TransactionAuthor>(as authorType: A.Type = A.self) -> A? {
        guard let transactionAuthor else { return nil }
        return A.allCases.first { $0.name == transactionAuthor }
    }
}
