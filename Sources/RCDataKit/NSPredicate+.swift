//
//  NSPredicate+.swift
//

import CoreData
import Foundation

public func || (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(orPredicateWithSubpredicates: [lhs, rhs])
}

public func && (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(andPredicateWithSubpredicates: [lhs, rhs])
}

public prefix func ! (predicate: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(notPredicateWithSubpredicate: predicate)
}

extension NSPredicate {
    /// Initializes a predicate matching all objects with the given `NSManagedObjectID`s.
    convenience init(managedObjectIds: [NSManagedObjectID]) {
        self.init(format: "self in %@", managedObjectIds)
    }
}
