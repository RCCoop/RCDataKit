//
//  NSPersistentContainer+Load.swift
//
//
//  Created by Ryan Linn on 9/24/24.
//

import CoreData

extension NSPersistentContainer {
    /// A convenience initializer that builds a `NSPersistentContainer` using the most basic parameters.
    ///
    /// - Parameters:
    ///   - bundle:      The bundle where the ManagedObjectModel file is located.
    ///   - modelName:   The title of the ManagedObjectModel file.
    ///   - versionName: Optionally, the title of the model version to use. If none is given, the latest version
    ///                  will be used.
    public convenience init(
        bundle: Bundle = .main,
        modelName: String,
        versionName: String?
    ) {
        if let model = NSManagedObjectModel.create(bundle: bundle, modelName: modelName, versionName: versionName) {
            self.init(name: modelName, managedObjectModel: model)
        } else {
            self.init(name: modelName)
        }
    }
    
    /// Synchronously load stores.
    ///
    /// Should be used at the end of `NSPersistentContainer` initialization, as a replacement for
    /// `loadPersistentStores(completionHandler:)`
    public func loadStores() throws {
        persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = false }
        
        // This function is called syncronously because description.shouldAddStoreAsynchronously
        // defaults to false, and that's fine.
        var loadingError: Error?
        loadPersistentStores { _, err in
            loadingError = err
        }
        if let loadingError {
            throw loadingError
        }
    }
    
    /// Asynchronously loads stores.
    /// 
    /// Should be used at the end of `NSPersistentContainer` initialization, as a replacement for
    /// `loadPersistentStores(completionHandler:)`
    public func loadStores() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var loadingError: Error?
            loadPersistentStores { _, err in
                loadingError = err
            }
            if let loadingError {
                continuation.resume(throwing: loadingError)
            } else {
                continuation.resume()
            }
        }
    }
}
