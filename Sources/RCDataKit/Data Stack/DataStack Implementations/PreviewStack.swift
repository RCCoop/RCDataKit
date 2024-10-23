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
    
    /// <#Description#>
    /// - Parameters:
    ///   - modelDefinition: <#modelDefinition description#>
    ///   - name: <#name description#>
    public init<ModelDefinition: ModelManager>(
        _ modelDefinition: ModelDefinition.Type,
        name: String
    ) {
        self.container = NSPersistentContainer(name: name, managedObjectModel: modelDefinition.model)
        
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        
        do {
            try container.loadStores()
        } catch {
            fatalError("PersistentStore setup error \(error.localizedDescription)")
        }
    }
    
    /// <#Description#>
    /// - Parameter modelDefinition: <#modelDefinition description#>
    public init<ModelDefinition: ModelFileManager>(
        _ modelDefinition: ModelDefinition.Type
    ) {
        self.init(ModelDefinition.self, name: modelDefinition.modelName)
    }
}
