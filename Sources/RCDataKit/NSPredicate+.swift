//
//  NSPredicate+.swift
//

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
