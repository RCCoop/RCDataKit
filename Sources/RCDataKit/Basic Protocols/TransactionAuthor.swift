//
//  TransactionAuthor.swift
//

import Foundation

/// A type that is used with a `DataStack` and `NSManagedObjectContext` to describe the sources of
/// write transactions for the current app.
///
/// `TransactionAuthor` is just a light wrapper around `String`, and it is used to set the `transactionAuthor`
/// property of `NSManagedObjectContext`. Several types in `RCDataKit` make use of `TransactionAuthor`
/// to aid in various operations.
public struct TransactionAuthor: Sendable, Hashable, Identifiable {
    public var name: String
    
    public var id: String { name }
    
    public init(_ name: String) {
        self.name = name
    }
    
    public static let viewContext = TransactionAuthor("viewContext")
}

extension TransactionAuthor: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.name = value
    }
}
