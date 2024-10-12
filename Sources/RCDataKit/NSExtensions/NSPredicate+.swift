//
//  NSPredicate+.swift
//

import CoreData
import Foundation

// MARK: - Compounding Operators

public func || (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(orPredicateWithSubpredicates: [lhs, rhs])
}

public func && (lhs: NSPredicate, rhs: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(andPredicateWithSubpredicates: [lhs, rhs])
}

public prefix func ! (predicate: NSPredicate) -> NSPredicate {
    NSCompoundPredicate(notPredicateWithSubpredicate: predicate)
}

// MARK: - NSManagedObjectID Predicate

extension NSPredicate {
    /// Initializes a predicate matching all objects with the given `NSManagedObjectID`s.
    convenience init(managedObjectIds: [NSManagedObjectID]) {
        self.init(format: "self in %@", managedObjectIds)
    }
}

// MARK: - Equatable & Comparable

// General Equal
public func == <T: NSManagedObject, V: Equatable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
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

// General Not Equal
public func != <T: NSManagedObject, V: Equatable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
    !(lhs == rhs)
}

// General Greater
public func > <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
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

// General GreaterEqual
public func >= <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
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

// General Less
public func < <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
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

// General LessEqual
public func <= <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
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

extension KeyPath where Root: NSManagedObject, Value: Comparable {
    // Numeric Between
    public func between(
        _ range: ClosedRange<Value>
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: [range.lowerBound, range.upperBound]
            ),
            modifier: .direct,
            type: .between
        )
    }
}

// MARK: - Strings

extension KeyPath where Root: NSManagedObject, Value == String {
    
    // String Not Equal
    public func notEqual<Y: StringProtocol>(
        to rhs: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: rhs
            ),
            modifier: .direct,
            type: .notEqualTo,
            options: options
        )
    }

    // String Equal
    public func equal<Y: StringProtocol>(
        to rhs: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: rhs
            ),
            modifier: .direct,
            type: .equalTo,
            options: options
        )
    }
    
    // String In
    public func `in`<C: Collection>(
        _ collection: C,
        options: NSComparisonPredicate.Options
    ) -> NSPredicate
        where C.Element: StringProtocol
    {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: collection
            ),
            modifier: .direct,
            type: .in,
            options: options
        )
    }
    
    // String LIKE
    public func like<Y: StringProtocol>(
        _ comparator: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: comparator
            ),
            modifier: .direct,
            type: .like,
            options: options
        )
    }
    
    // String CONTAINS
    public func contains<Y: StringProtocol>(
        _ substring: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: substring
            ),
            modifier: .direct,
            type: .contains,
            options: options
        )
    }
    
    // String BEGINSWITH
    public func beginsWith<Y: StringProtocol>(
        _ prefix: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: prefix
            ),
            modifier: .direct,
            type: .beginsWith,
            options: options
        )
    }
    
    // Stirng ENDSWITH
    public func endsWith<Y: StringProtocol>(
        _ suffix: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: suffix
            ),
            modifier: .direct,
            type: .endsWith,
            options: options
        )
    }
    
    // String MATCHES
    public func matches<Y: StringProtocol>(
        _ regex: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: regex
            ),
            modifier: .direct,
            type: .matches,
            options: options
        )
    }
}

// MARK: IN

extension KeyPath where Root: NSManagedObject, Value: Equatable {
    // General In
    public func `in`<C: Collection>(
        _ collection: C
    ) -> NSPredicate
        where C.Element == Value
    {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: collection
            ),
            modifier: .direct,
            type: .in
        )
    }
}
