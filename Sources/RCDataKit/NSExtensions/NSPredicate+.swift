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

public enum PredicateJoiner {
    case and, or
}

extension Collection where Element == NSPredicate {
    public func joined(with joiner: PredicateJoiner) -> NSCompoundPredicate {
        switch joiner {
        case .and:
            NSCompoundPredicate(andPredicateWithSubpredicates: Array(self))
        case .or:
            NSCompoundPredicate(orPredicateWithSubpredicates: Array(self))
        }
    }
}

// MARK: - NSManagedObjectID Predicate

extension NSPredicate {
    /// Initializes a predicate matching all objects with the given `NSManagedObjectID`s.
    convenience init(managedObjectIds: [NSManagedObjectID]) {
        self.init(format: "self in %@", managedObjectIds)
    }
}

// MARK: - NSPredicate Construction

extension NSComparisonPredicate.Options {
    public static var caseAndDiacriticInsensitive: Self {
        [.caseInsensitive, diacriticInsensitive]
    }
}

private func comparisonFactory<T: NSManagedObject, V>(
    keyPath: KeyPath<T, V>,
    compare: NSComparisonPredicate.Operator,
    value: Any,
    options: NSComparisonPredicate.Options = []
) -> NSComparisonPredicate {
    NSComparisonPredicate(
        leftExpression: NSExpression(forKeyPath: keyPath.stringRepresentation),
        rightExpression: NSExpression(forConstantValue: value),
        modifier: .direct,
        type: compare,
        options: options)
}

// MARK: Equatable & Comparable

// General Equal
public func == <T: NSManagedObject, V: Equatable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .equalTo, value: rhs)
}

public func == <T: NSManagedObject, V: Equatable>(
    _ lhs: KeyPath<T, V?>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .equalTo, value: rhs)
}

// General Not Equal
public func != <T: NSManagedObject, V: Equatable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
    !(lhs == rhs)
}

public func != <T: NSManagedObject, V: Equatable>(
    _ lhs: KeyPath<T, V?>,
    _ rhs: V
) -> NSPredicate {
    !(lhs == rhs)
}

// General Greater
public func > <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .greaterThan, value: rhs)
}

public func > <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V?>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .greaterThan, value: rhs)
}

// General GreaterEqual
public func >= <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .greaterThanOrEqualTo, value: rhs)
}

public func >= <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V?>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .greaterThanOrEqualTo, value: rhs)
}

// General Less
public func < <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .lessThan, value: rhs)
}

public func < <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V?>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .lessThan, value: rhs)
}

// General LessEqual
public func <= <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .lessThanOrEqualTo, value: rhs)
}

public func <= <T: NSManagedObject, V: Comparable>(
    _ lhs: KeyPath<T, V?>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .lessThanOrEqualTo, value: rhs)
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
                forConstantValue: [
                    NSExpression(forConstantValue: range.lowerBound),
                    NSExpression(forConstantValue: range.upperBound)
                ]
            ),
            modifier: .direct,
            type: .between
        )
    }
}

extension KeyPath where Root: NSManagedObject {
    // Numeric Between with Optional Value
    public func between<V>(_ range: ClosedRange<V>) -> NSPredicate
    where V: Comparable,
          Value == V?
    {
        NSComparisonPredicate(
            leftExpression: NSExpression(
                forKeyPath: stringRepresentation
            ),
            rightExpression: NSExpression(
                forConstantValue: [
                    NSExpression(forConstantValue: range.lowerBound),
                    NSExpression(forConstantValue: range.upperBound)
                ]
            ),
            modifier: .direct,
            type: .between
        )
    }
}

// MARK: Strings

extension KeyPath where Root: NSManagedObject, Value == String {
    
    // String Not Equal
    public func notEqual<Y: StringProtocol>(
        to rhs: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .notEqualTo, value: rhs, options: options)
    }

    // String Equal
    public func equal<Y: StringProtocol>(
        to rhs: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .equalTo, value: rhs, options: options)
    }

    // String LIKE
    public func like<Y: StringProtocol>(
        _ comparator: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .like, value: comparator, options: options)
    }
    
    // String CONTAINS
    public func contains<Y: StringProtocol>(
        _ substring: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .contains, value: substring, options: options)
    }
    
    // String BEGINSWITH
    public func beginsWith<Y: StringProtocol>(
        _ prefix: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .beginsWith, value: prefix, options: options)
    }
    
    // Stirng ENDSWITH
    public func endsWith<Y: StringProtocol>(
        _ suffix: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .endsWith, value: suffix, options: options)
    }
    
    // String MATCHES
    public func matches<Y: StringProtocol>(
        _ regex: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .matches, value: regex, options: options)
    }
}

// MARK: Optional Strings

extension KeyPath where Root: NSManagedObject, Value == Optional<String> {
    
    // String Not Equal
    public func notEqual<Y: StringProtocol>(
        to rhs: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .notEqualTo, value: rhs, options: options)
    }

    // String Equal
    public func equal<Y: StringProtocol>(
        to rhs: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .equalTo, value: rhs, options: options)
    }
    
    // String LIKE
    public func like<Y: StringProtocol>(
        _ comparator: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .like, value: comparator, options: options)
    }
    
    // String CONTAINS
    public func contains<Y: StringProtocol>(
        _ substring: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .contains, value: substring, options: options)
    }
    
    // String BEGINSWITH
    public func beginsWith<Y: StringProtocol>(
        _ prefix: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .beginsWith, value: prefix, options: options)
    }
    
    // Stirng ENDSWITH
    public func endsWith<Y: StringProtocol>(
        _ suffix: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .endsWith, value: suffix, options: options)
    }
    
    // String MATCHES
    public func matches<Y: StringProtocol>(
        _ regex: Y,
        options: NSComparisonPredicate.Options = []
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .matches, value: regex, options: options)
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
        comparisonFactory(keyPath: self, compare: .in, value: collection)
    }
}

// MARK: NSManagedObject Relations

public func == <T: NSManagedObject, V: NSManagedObject>(
    _ lhs: KeyPath<T, V>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .equalTo, value: rhs.objectID)
}

public func == <T: NSManagedObject, V: NSManagedObject>(
    _ lhs: KeyPath<T, V?>,
    _ rhs: V
) -> NSPredicate {
    comparisonFactory(keyPath: lhs, compare: .equalTo, value: rhs.objectID)
}

extension KeyPath
where Root: NSManagedObject,
        Value: Collection,
        Value.Element: NSManagedObject
{
    public func contains(
        _ value: Value.Element
    ) -> NSPredicate {
        comparisonFactory(keyPath: self, compare: .contains, value: value.objectID)
    }
}

extension KeyPath where Root: NSManagedObject {
    public func contains<V: Collection>(_ value: V.Element) -> NSPredicate
    where Value == V?, V.Element: NSManagedObject
    {
        comparisonFactory(keyPath: self, compare: .contains, value: value.objectID)
    }
}
