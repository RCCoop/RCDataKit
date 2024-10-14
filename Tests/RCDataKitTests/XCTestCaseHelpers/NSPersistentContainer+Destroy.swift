//
//  NSPersistentContainer+Destroy.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData

extension NSPersistentContainer {
    func destroyStore() throws {
        for url in persistentStoreDescriptions.compactMap(\.url) {
            try persistentStoreCoordinator.destroyPersistentStore(at: url, type: .sqlite)
            
            let destroyURLs = [
                url,
                URL(fileURLWithPath: url.path + "-shm"),
                URL(fileURLWithPath: url.path + "-wal")
            ]
            
            for oneURL in destroyURLs {
                if let _ = try? Data(contentsOf: oneURL) {
                    try FileManager.default.removeItem(at: oneURL)
                }
            }
        }
    }
}
