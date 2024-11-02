//
//  PreviewStack.swift
//

import CoreData
import Foundation

// MARK: - Basic Stack for Testing & Previews

/// A basic `DataStack` with no file-backed store (in-memory only) and only one background context
/// available.
public struct PreviewStack<Authors: TransactionAuthor>: DataStack {
    public var viewContextID: Authors { Authors.allCases.first! }
    
    public let container: NSPersistentContainer
    
    /// Initializes a `PreviewStack` using a `ModelManager` type and a name for the model to use.
    ///
    /// - Parameters:
    ///   - model: A type conforming to `ModelManager`.
    ///   - name: The name to give the PersistentContainer.
    ///   - authors: The `TransactionAuthor` type for the Data Stack
    public init<Model: ModelManager>(
        _ model: Model.Type,
        name: String,
        authors: Authors.Type
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
    /// - Parameters
    ///   - model: The type that conforms to `ModelFileManager` to use in creating the PersistentContainer.
    ///   - authors: The `TransactionAuthor` type for the Data Stack
    public init<Model: ModelFileManager>(
        _ model: Model.Type,
        authors: Authors.Type
    ) {
        self.init(Model.self, name: model.modelName, authors: authors)
    }
}

public enum BasicAuthors: String, TransactionAuthor {
    case viewContext
    case backgroundContext
}

extension PreviewStack where Authors == BasicAuthors {
    
    /// Initializes a `PreviewStack` using a `ModelManager` type and a name for the model to use,
    /// with the default `Authors` type.
    ///
    /// - Parameters:
    ///   - model: A type conforming to `ModelManager`.
    ///   - name: The name to give the PersistentContainer.
    public init<Model: ModelManager>(
        _ model: Model.Type,
        name: String
    ) {
        self.init(model, name: name, authors: BasicAuthors.self)
    }
    
    /// Initializes a `PreviewStack` using just a `ModelFileManager` type and the default `Authors`
    /// type.
    ///
    /// - Parameters
    ///   - model: The type that conforms to `ModelFileManager` to use in creating the PersistentContainer.
    public init<Model: ModelFileManager>(
        _ model: Model.Type
    ) {
        self.init(model, authors: BasicAuthors.self)
    }
}
