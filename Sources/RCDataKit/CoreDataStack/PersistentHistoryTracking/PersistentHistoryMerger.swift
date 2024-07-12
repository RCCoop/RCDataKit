//
//  PersistentHistoryMerger.swift
//

import CoreData
import Foundation

public protocol PersistentHistoryMerger {
    func mergeTransactions(
        viewContext: NSManagedObjectContext,
        transactions: [NSPersistentHistoryTransaction]
    ) throws 
}

extension PersistentHistoryTracker {
    struct DefaultMerger: PersistentHistoryMerger {
        func mergeTransactions(viewContext: NSManagedObjectContext, transactions: [NSPersistentHistoryTransaction]) throws {
            transactions.forEach {
                viewContext.mergeChanges(fromContextDidSave: $0.objectIDNotification())
            }
        }
    }
}
