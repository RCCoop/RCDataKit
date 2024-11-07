//
//  TestingStack.swift
//  RCDataKit
//
//  Created by Ryan Linn on 11/6/24.
//

import CoreData
import Foundation

/// A basic `DataStack` with a file-backed store in a temporary directory that is reset upon initialization.
public final class TestingStack<Authors: TransactionAuthor>: DataStack {
    public let container: NSPersistentContainer
    public var viewContextID: Authors { Authors.allCases.first! }
    
    /// The directory where the SQLite files for the persistent store are located.
    public let directoryLocation: URL
    
    /// The file name of the SQLite file of the persistent store.
    public let fileID = UUID()
    
    /// Initializes a `TestingStack` using a `ModelManager` type and information about where to
    /// write the temporary storage file.
    ///
    /// - Parameters:
    ///   - model: A type conforming to `ModelManager`.
    ///   - authors: The `TransactionAuthor` type for the Data Stack
    ///   - bundle: The bundle in which to write the temporary storage files.
    ///   - testName: The name of the directory in which to write the temporary storage files.
    ///
    /// The directory created using `bundle` and `testName` is erased before initialization, so it is important
    /// to never run two `TestingStack`s with the same names at the same time, or your data will likely
    /// become corrupted.
    public init <Model: ModelManager>(
        _ model: Model.Type,
        authors: Authors.Type,
        bundle: Bundle,
        testName: String
    ) throws {
        let directory = try Self.createDirectory(name: testName, bundle: bundle)
        self.directoryLocation = directory
        
        self.container = NSPersistentContainer(name: testName, managedObjectModel: model.model)
        container.persistentStoreDescriptions.first!.url = directory
            .appendingPathComponent(fileID.uuidString + "sqlite")
        
        try container.loadStores()
    }
    
    static func createDirectory(name: String, bundle: Bundle) throws -> URL {
        let tempDirectory: URL
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            tempDirectory = .temporaryDirectory
        } else {
            tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        }
        let dir = tempDirectory
            .appendingPathComponent(bundle.bundleIdentifier ?? "DataStackTesting")
            .appendingPathComponent(name)
        
        if FileManager.default.fileExists(atPath: dir.path) {
            // Remove existing files to create a fresh start
            try FileManager.default.removeItem(at: dir)
        }
        
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

extension TestingStack where Authors == BasicAuthors {
    /// Initializes a `TestingStack` using a `ModelManager` type, a default `TransactionAuthor`,
    ///  and information about where to write the temporary storage file.
    ///
    /// - Parameters:
    ///   - model: A type conforming to `ModelManager`.
    ///   - bundle: The bundle in which to write the temporary storage files.
    ///   - testName: The name of the directory in which to write the temporary storage files.
    ///
    /// The directory created using `bundle` and `testName` is erased before initialization, so it is important
    /// to never run two `TestingStack`s with the same names at the same time, or your data will likely
    /// become corrupted.
    public convenience init<Model: ModelManager>(
        _ model: Model.Type,
        bundle: Bundle,
        testName: String
    ) throws {
        try self.init(model, authors: BasicAuthors.self, bundle: bundle, testName: testName)
    }
}
