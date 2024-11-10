//
//  PreviewStack.swift
//

import CoreData
import Foundation

// MARK: - Basic Stack for Testing & Previews

/// A basic `DataStack` with no file-backed store (in-memory only).
public struct PreviewStack: DataStack {
    public let mainContextAuthor: TransactionAuthor = .viewContext
    public let container: NSPersistentContainer
    
    /// Initializes a `PreviewStack` using a `ModelManager` type and a name for the model to use.
    ///
    /// - Parameters:
    ///   - model: A type conforming to `ModelManager`.
    ///   - name: The name to give the PersistentContainer.
    public init<Model: ModelManager>(
        _ model: Model.Type,
        name: String
    ) {
        self.container = NSPersistentContainer(name: name, managedObjectModel: model.model)
        
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        
        do {
            try container.loadStores()
        } catch {
            fatalError("PersistentStore setup error \(error.localizedDescription)")
        }
    }
    
    /// Initializes a `PreviewStack` using just a `ModelFileManager` type.
    ///
    /// - Parameters:
    ///   - model: The type that conforms to `ModelFileManager` to use in creating the PersistentContainer.
    public init<Model: ModelFileManager>(
        _ model: Model.Type
    ) {
        self.init(Model.self, name: model.modelName)
    }
}
