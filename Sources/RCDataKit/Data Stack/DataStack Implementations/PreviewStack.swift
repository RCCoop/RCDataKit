//
//  PreviewStack.swift
//

import CoreData
import Foundation

// MARK: - Basic Stack for Testing & Previews

/// A basic `DataStack` with no file-backed store (in-memory only) and only one background context
/// available.
public struct PreviewStack: DataStack {
    
    public enum Authors: String, TransactionAuthor {
        case viewContext
        case backgroundContext
    }
    
    public var viewContextID: Authors { .viewContext }
    
    public let container: NSPersistentContainer
    
    public init(
        bundle: Bundle = .main,
        modelName: String
    ) {
        self.container = NSPersistentContainer(bundle: bundle, modelName: modelName, versionName: nil)
        
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions.first!.type = NSInMemoryStoreType
        
        do {
            try container.loadStores()
        } catch {
            fatalError("PersistentStore setup error \(error.localizedDescription)")
        }
    }
}
