//
//  CoreDataStackHelpers.swift
//

import CoreData
import Foundation

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
        
        public var name: String { rawValue }
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
