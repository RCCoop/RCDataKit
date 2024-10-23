//
//  TestingStacks.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData
import RCDataKit
import XCTest

enum TestingStacks {
    private static func prepareStorageURL(name: String, removeExistingFile: Bool = true) throws -> URL {
        let baseURL = URL.temporaryDirectory.appending(component: "com.RCCoop.RCDataKitTests")
        if !FileManager.default.fileExists(atPath: baseURL.path) {
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
        
        let sqliteName = name + ".sqlite"
        let sqliteFileURL = baseURL.appendingPathComponent(sqliteName)
        let walUrl = baseURL.appendingPathComponent(sqliteName + "-wal")
        let shmUrl = baseURL.appendingPathComponent(sqliteName + "-shm")
        if removeExistingFile {
            for anUrl in [sqliteFileURL, walUrl, shmUrl] {
                if FileManager.default.fileExists(atPath: anUrl.path) {
                    try FileManager.default.removeItem(at: anUrl)
                }
            }
        }
        
        return sqliteFileURL
    }
    
    static func inMemoryContainer() throws -> NSPersistentContainer {
        let stack = PreviewStack(TestModel.self)
        return stack.container
    }
    
    static func temporaryStack(
        uniqueName: String,
        mainAuthor: ModelAuthors = .viewContext1,
        removeOldStore: Bool = true,
        withPersistentHistoryTracking: Bool = false
    ) throws -> BasicDataStack<ModelAuthors> {
        let url = try prepareStorageURL(name: uniqueName, removeExistingFile: removeOldStore)
        print("Creating temporary stack at \(url.path())")
        let trackingOptions = withPersistentHistoryTracking ? PersistentHistoryTrackingOptions() : nil
        let store = try BasicDataStack(
            TestModel.self,
            storeURL: url,
            mainAuthor: mainAuthor,
            persistentHistoryOptions: trackingOptions)
        
        return store
    }
}

// MARK: - Versioning Functions

@available(macOS 14.0, iOS 17.0, *)
extension TestingStacks {
    
    fileprivate static var oldSqliteURL: URL {
        Bundle.module.url(forResource: "OldStudentsStore", withExtension: "sqlite")!
    }
    
    static func oldModelStack(
        uniqueName: String,
        mainAuthor: ModelAuthors = .viewContext1
    ) throws -> BasicDataStack<ModelAuthors> {
        // Copy testing version of Sqlite store to temporary location
        let url = try prepareStorageURL(name: uniqueName)
        try FileManager.default.copyItem(at: oldSqliteURL, to: url)
        
        let stack = try BasicDataStack(
            storeURL: url,
            versionKey: ModelVersions.self,
            currentVersion: .v1,
            mainAuthor: mainAuthor)
        return stack
    }
    
    static func migratedContainer(
        uniqueName: String,
        mainAuthor: ModelAuthors = .viewContext1
    ) throws -> BasicDataStack<ModelAuthors> {
        // Copy testing version of Sqlite store to temporary location:
        let url = try prepareStorageURL(name: uniqueName)
        try FileManager.default.copyItem(at: oldSqliteURL, to: url)
        
        let stack = try BasicDataStack(
            storeURL: url,
            versionKey: ModelVersions.self,
            mainAuthor: mainAuthor)
        return stack
    }
}
