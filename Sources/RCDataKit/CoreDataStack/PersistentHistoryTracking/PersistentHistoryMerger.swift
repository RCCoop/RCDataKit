//
//  PersistentHistoryMerger.swift
//

import CoreData
import Foundation

/// A type that can be used to merge `NSPersistentHistoryTransaction`s into the persistent coordinator's
/// view context.
public protocol PersistentHistoryMerger {
    /// After the `PersistentHistoryFetcher` returns an array of
    /// `NSPersistentHistoryTransaction`s, the `PersistentHistoryMerger`'s
    /// job is to merge those transactions into the persistent store.
    ///
    /// - Parameters:
    ///   - viewContext:  The context on which to perform the work.
    ///   - transactions: An array of `NSPersistentHistoryTransaction` fetched by
    ///                   a `PersistentHistoryFetcher` during the merging process.
    ///
    /// The basic implementation of a merger looks like:
    /// ```swift
    /// for tx in transactions {
    ///    viewContext.mergeChanges(fromContextDidSave: tx.objectIDNotification())
    /// }
    /// ```
    /// but you may provide extra functionality to handle pre- or post-processing of data that is
    /// merged.
    ///
    /// Make sure to run the work on the `viewContext`'s thread by encapsulating it in a
    /// `perform` block.
    func mergeTransactions(
        viewContext: NSManagedObjectContext,
        transactions: [NSPersistentHistoryTransaction]
    ) throws 
}

extension PersistentHistoryTracker {
    struct DefaultMerger: PersistentHistoryMerger {
        func mergeTransactions(viewContext: NSManagedObjectContext, transactions: [NSPersistentHistoryTransaction]) throws {
            for tx in transactions {
                viewContext.performAndWait {
                    viewContext.mergeChanges(fromContextDidSave: tx.objectIDNotification())
                }
            }
        }
    }
}
