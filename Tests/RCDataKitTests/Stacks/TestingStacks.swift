//
//  TestingStacks.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData
import RCDataKit
import XCTest

protocol RCDataKitTestCase: XCTestCase {
    
}

extension RCDataKitTestCase {
    
}

enum TestingStacks {
    
    static var modelName: String { "TestModel" }
    
    static func inMemoryContainer() throws -> NSPersistentContainer {
        let stack = PreviewStack(bundle: .module, modelName: modelName)
        return stack.container
    }
    
    static func persistentTrackingStack(mainAuthor: ModelAuthors) throws -> SingleStoreStack<ModelAuthors> {
        let persistentHistoryOptions = PersistentHistoryTrackingOptions()
        let store = try SingleStoreStack(
            bundle: .module,
            storeURL: diskLocation,
            modelName: modelName,
            modelVersion: nil,
            mainAuthor: mainAuthor,
            persistentHistoryOptions: persistentHistoryOptions)
        
        return store
    }
    
    @available(macOS 14.0, iOS 17.0, *)
    static func originalModelStack(mainAuthor: ModelAuthors) throws -> NSPersistentContainer {
        let stack = try SingleStoreStack(
            storeURL: diskLocation,
            versionKey: ModelVersions.self,
            currentVersion: .v1,
            mainAuthor: mainAuthor)
        
        return stack.container
    }
        
    @available(macOS 14.0, iOS 17.0, *)
    static func stagedMigrationsStack(mainAuthor: ModelAuthors) throws -> NSPersistentContainer {
        let stack = try SingleStoreStack(
            storeURL: diskLocation,
            versionKey: ModelVersions.self,
            mainAuthor: mainAuthor)

        return stack.container
    }
    
    // MARK: - Storage File Management
    
    private static var diskLocation: URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
            .appending(path: "TestStore")
    }
}
