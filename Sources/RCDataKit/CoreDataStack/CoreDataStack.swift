//
//  CoreDataStack.swift
//  

import CoreData
import Foundation

/// A type that provides some standard helper tools for managing a CoreData persistent store.
public protocol CoreDataStack {
    associatedtype Authors: TransactionAuthor
    
    /// The `NSPersistentContainer` that the `CoreDataStack` wraps.
    var container: NSPersistentContainer { get }
    
    /// The value of `Authors` to be used in the current target's view context.
    var viewContextID: Authors { get }
}

// MARK: - TransactionAuthor Type

/// A type that is used with a `CoreDataStack` to describe all possible authors to the persistent store
/// for the current app. One of the authors needs to be the view context for the current target, and other options
/// could be the view contexts for other targets, and any background context type that you may use.
public protocol TransactionAuthor: CaseIterable {
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

public extension Collection where Element: TransactionAuthor {
    var authorNames: [String] {
        map(\.name)
    }
}

// MARK: - Common Functions

extension CoreDataStack {
    /// Returns the viewContext for the stack's persistent container, configured by the stack.
    ///
    /// - Warning: You should not change the `transactionAuthor` or `name` properties of the context,
    /// since they are set by the container in order to handle persistent history tracking.
    public var viewContext: NSManagedObjectContext {
        let vc = container.viewContext
        vc.name = "ViewContext"
        vc.transactionAuthor = viewContextID.name
        
        // Merge Policy?
        // Undo Manager?
        
        return vc
    }
        
    /// Returns a fresh background managed object context, configured by the stack.
    ///
    /// - Parameter author: The author to be used in the context.
    ///
    /// - Warning: You should not change the `name` or `transactionAuthor` properties of the
    ///            context, since they are set by the container in order to handle persistent history
    ///            tracking.
    public func backgroundContext(author: Authors) -> NSManagedObjectContext {
        assert(author.name != viewContextID.name, "Background contexts should not have the same name as the viewContext")
        
        let context = container.newBackgroundContext()
        context.transactionAuthor = author.name
        context.name = author.name
        
        // Merge Policy?
        // Undo Manager
        return context
    }
}
