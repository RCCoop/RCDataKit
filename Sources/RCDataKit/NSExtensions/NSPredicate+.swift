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

public func == <T: NSManagedObject, V: Equatable>(_ lhs: KeyPath<T, V>, _ rhs: V) -> NSPredicate {
    NSComparisonPredicate(
        leftExpression: NSExpression(
            forKeyPath: lhs.stringRepresentation
        ),
        rightExpression: NSExpression(
            forConstantValue: rhs
        ),
        modifier: .direct,
        type: .equalTo
    )
}

public func != <T: NSManagedObject, V: Equatable>(_ lhs: KeyPath<T, V>, _ rhs: V) -> NSPredicate {
    !(lhs == rhs)
}

public func > <T: NSManagedObject, V: Comparable>(_ lhs: KeyPath<T, V>, _ rhs: V) -> NSPredicate {
    NSComparisonPredicate(
        leftExpression: NSExpression(
            forKeyPath: lhs.stringRepresentation
        ),
        rightExpression: NSExpression(
            forConstantValue: rhs
        ),
        modifier: .direct,
        type: .greaterThan
    )
}

public func >= <T: NSManagedObject, V: Comparable>(_ lhs: KeyPath<T, V>, _ rhs: V) -> NSPredicate {
    NSComparisonPredicate(
        leftExpression: NSExpression(
            forKeyPath: lhs.stringRepresentation
        ),
        rightExpression: NSExpression(
            forConstantValue: rhs
        ),
        modifier: .direct,
        type: .greaterThanOrEqualTo
    )
}

public func < <T: NSManagedObject, V: Comparable>(_ lhs: KeyPath<T, V>, _ rhs: V) -> NSPredicate {
    NSComparisonPredicate(
        leftExpression: NSExpression(
            forKeyPath: lhs.stringRepresentation
        ),
        rightExpression: NSExpression(
            forConstantValue: rhs
        ),
        modifier: .direct,
        type: .lessThan
    )
}

public func <= <T: NSManagedObject, V: Comparable>(_ lhs: KeyPath<T, V>, _ rhs: V) -> NSPredicate {
    NSComparisonPredicate(
        leftExpression: NSExpression(
            forKeyPath: lhs.stringRepresentation
        ),
        rightExpression: NSExpression(
            forConstantValue: rhs
        ),
        modifier: .direct,
        type: .lessThanOrEqualTo
    )
}

