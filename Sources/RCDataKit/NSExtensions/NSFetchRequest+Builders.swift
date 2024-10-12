//
//  NSFetchRequest+Builders.swift
//

import CoreData
import Foundation

public extension NSFetchRequest {
    /// Convenience method for chaining creation of `NSFetchRequest` by adding a `NSPredicate`.
    /// - Parameter predicate: The predicate to add to the FetchRequest
    /// - Returns: The `NSFetchRequest` that this function was called on.
    @objc func `where`(_ predicate: NSPredicate) -> Self {
        self.predicate = predicate
        return self
    }
     
    /// Conveniece method for chaining creation of `NSFetchRequest` by adding sort descriptors.
    /// - Parameter descriptors: The sort descriptors to add to the FetchRequest
    /// - Returns: The `NSFetchRequest` that this function was called on.
    @objc func sorted(_ descriptors: [NSSortDescriptor]) -> Self {
        self.sortDescriptors = descriptors
        return self
    }
}

public extension NSFetchRequest where ResultType == NSManagedObjectID {
    /// Convenience initializer for creating a `NSFetchRequest` that only returns the `NSManagedObjectID`s
    /// of the results.
    ///
    /// The initialized `NSFetchRequest` has its `resultType` set to `.managedObjectIDResultType`,
    /// and `includesPropertyValues` to `false` in order to return as little data as possible in a
    /// lightweight fetch.
    convenience init(entityIds type: NSManagedObject.Type) {
        self.init(entityName: type.entity().name!)
        resultType = .managedObjectIDResultType
        includesPropertyValues = false
    }
}
