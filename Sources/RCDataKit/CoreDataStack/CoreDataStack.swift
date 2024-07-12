//
//  CoreDataStack.swift
//  

import CoreData
import Foundation

/// <#Description#>
public protocol CoreDataStack {
    associatedtype Authors: TransactionAuthor
    var container: NSPersistentContainer { get }
    var viewContextID: Authors { get }
}

// MARK: - TransactionAuthor Type

public protocol TransactionAuthor: CaseIterable {
    var contextName: String { get }
}

public extension TransactionAuthor {
    var allOtherAuthors: [Self] {
        Self.allCases.filter { $0.contextName != self.contextName }
    }
}

public extension Collection where Element: TransactionAuthor {
    var contextNames: [String] {
        map(\.contextName)
    }
}

// MARK: - Common Functions

extension CoreDataStack {
    /// Returns the viewContext for the stack's persistent container, configured by the stack.
    ///
    /// - Warning: You should not change the `name` property of the context, since the name is set
    ///            by the container in order to handle persistent history tracking.
    public var viewContext: NSManagedObjectContext {
        let vc = container.viewContext
        vc.name = viewContextID.contextName
        
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
        let context = container.newBackgroundContext()
        context.name = author.contextName
        context.transactionAuthor = author.contextName
        
        // Merge Policy?
        // Undo Manager
        return context
    }
}

// MARK: - Logging

public enum CoreDataStackLogLevel: String {
    case debug, info, error, warning
}

public protocol CoreDataStackLogger {
    func log(type: CoreDataStackLogLevel, message: String)
}

public struct DefaultLogger: CoreDataStackLogger {
    public func log(type: CoreDataStackLogLevel, message: String) {
        print("CORE DATA \(type.rawValue.uppercased()): \(message)")
    }
    
    public init() {}
}

// MARK: - Basic Stack for Testing & Previews

/// A basic `CoreDataStack` with no file-backed store (in-memory only) and only one background context
/// available.
public struct PreviewStack: CoreDataStack {
    
    public enum Authors: String, TransactionAuthor {
        case viewContext
        case backgroundContext
        
        public var contextName: String { rawValue }
    }
    
    public var viewContextID: Authors { .viewContext }

    public let container: NSPersistentContainer
            
    public init(container: NSPersistentContainer) {
        self.container = container
        
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions.first!.type = NSInMemoryStoreType
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("PersistentStore setup error \(error), \(error.userInfo)")
            }
        }
    }
}
