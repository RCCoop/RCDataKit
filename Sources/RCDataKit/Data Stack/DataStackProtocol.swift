//
//  DataStackProtocol.swift
//  

import CoreData
import Foundation

/// A type that provides some standard helper tools for managing a CoreData persistent store.
public protocol DataStack {
    associatedtype Authors: TransactionAuthor
    
    /// The `NSPersistentContainer` that the `DataStack` wraps.
    var container: NSPersistentContainer { get }
    
    /// The value of `Authors` to be used in the current target's view context.
    var viewContextID: Authors { get }
}

// MARK: - Common Functions

extension DataStack {
    /// Returns the viewContext for the stack's persistent container, configured by the stack.
    ///
    /// - Warning: You should not change the `transactionAuthor` or `name` properties of the context,
    /// since they are set by the container in order to handle persistent history tracking.
    public var viewContext: NSManagedObjectContext {
        let vc = container.viewContext
        vc.name = "ViewContext"
        vc.setAuthor(viewContextID)
        
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
        context.setAuthor(author)
        context.name = author.name
        
        // Merge Policy?
        // Undo Manager
        return context
    }
}
