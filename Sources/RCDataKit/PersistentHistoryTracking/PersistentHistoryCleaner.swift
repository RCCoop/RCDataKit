//
//  PersistentHistoryCleaner.swift
//

import CoreData
import Foundation

/// A type that can be used to purge old `NSPersistentHistoryTransaction`s from the persistent store.
public protocol PersistentHistoryCleaner: Sendable {
    
    /// The worker function of the `PersistentHistoryCleaner`, which should handle deleting unneeded
    /// `NSPersistentHistoryTransaction`s from the store.
    ///
    /// - Parameters:
    ///   - workerContext: The context on which to perform the work.
    ///   - cleanBeforeDate: The time stamp to use for the `deleteHistory` request.
    ///   - authors: If provided, limits the purge to transactions matching the given `TransactionAuthor`s
    ///
    /// The basic implementation looks something like:
    /// ```swift
    /// let deleteRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: cleanBeforeDate)
    /// try workerContext.execute(deleteRequest)
    /// ```
    /// But should be modified as needed for your needs.
    ///
    /// Make sure to run the work on the `workerContext`'s thread by encapsulating it in a `perform` block.
    func cleanTransactions(
        workerContext: NSManagedObjectContext,
        cleanBeforeDate: Date,
        authors: [TransactionAuthor]?
    ) throws
}

extension PersistentHistoryTracker {
    struct DefaultCleaner: PersistentHistoryCleaner {
        var logger: DataStackLogger?
        
        func cleanTransactions(
            workerContext: NSManagedObjectContext,
            cleanBeforeDate: Date,
            authors: [TransactionAuthor]?
        ) throws {
            let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: cleanBeforeDate)
            
            if let fetchRequest = NSPersistentHistoryTransaction.fetchRequest {
                // !!!: fetchRequest is always nil here
                if let authors, !authors.isEmpty {
                    let subpredicates = authors.map {
                        NSPersistentHistoryTransaction.matchingAuthor($0)
                    }
                    fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
                }
                deleteHistoryRequest.fetchRequest = fetchRequest
            }
            deleteHistoryRequest.resultType = .count
            
            logger?.log(type: .debug, message: "Deleting persistent history transactions before \(cleanBeforeDate)")
            let res = try workerContext.execute(deleteHistoryRequest) as? NSPersistentHistoryResult
            if let count = res?.result as? Int {
                logger?.log(type: .debug, message: "Deleted \(count) persistent history transactions.")
            }
        }
    }
}
