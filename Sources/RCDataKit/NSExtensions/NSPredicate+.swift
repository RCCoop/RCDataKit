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

    // String Greater
    public func greaterThan<Y: StringProtocol>(
        _ rhs: Y,
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
            type: .greaterThan,
            options: options
        )
    }

    // String GreaterEqual
    public func greaterThanOrEqual<Y: StringProtocol>(
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
            type: .greaterThanOrEqualTo,
            options: options
        )
    }

    // String Less
    public func lessThan<Y: StringProtocol>(
        _ rhs: Y,
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
            type: .lessThan,
            options: options
        )
    }

    // String LessEqual
    public func lessThanOrEqual<Y: StringProtocol>(
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
            type: .lessThanOrEqualTo,
            options: options
        )
    }
    
    // String In
    public func `in`<C: Collection>(
        _ collection: C,
        options: NSComparisonPredicate.Options = []
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
    
    // String Between
    public func between<Y: StringProtocol>(
        _ lhs: Y, and rhs: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: [lhs, rhs]
            ),
            modifier: .direct,
            type: .between,
            options: options
        )
    }
}

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

extension KeyPath where Root: NSManagedObject, Value: Comparable & Numeric {
    // Numeric In
    public func `in`<C: Collection>(
        _ collection: C
    ) -> NSPredicate
        where C.Element: Equatable & Numeric
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

    // Numeric Between
    public func between<Y: Comparable & Numeric>(
        _ lhs: Y,
        and rhs: Y
    ) -> NSPredicate {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: [lhs, rhs]
            ),
            modifier: .direct,
            type: .between
        )
    }
}
