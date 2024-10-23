//
//  TransactionAuthor.swift
//

import Foundation

// MARK: - TransactionAuthor Type

/// A type that is used with a `DataStack` to describe all possible authors to the persistent store
/// for the current app. One of the authors needs to be the view context for the current target, and other options
/// could be the view contexts for other targets, and any background context type that you may use.
public protocol TransactionAuthor: CaseIterable, Sendable {
    var name: String { get }
}

public extension TransactionAuthor {
    var allOtherAuthors: [Self] {
        Self.allCases.filter { $0.name != self.name }
    }
}

public extension TransactionAuthor where Self: RawRepresentable, RawValue == String {
    var name: String {
        rawValue
    }
}
