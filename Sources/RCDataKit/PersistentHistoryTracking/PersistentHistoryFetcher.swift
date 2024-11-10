//
//  PersistentHistoryFetcher.swift
//  

import CoreData
import Foundation

/// A type that can be used to fetch `NSPersistentHistoryTransaction`s from the persistent store.
public protocol PersistentHistoryFetcher: Sendable {
    
    /// The worker function for `PersistentHistoryFetcher`, which fetches
    /// `NSPersistentHistoryTransaction`s that will be merged into the main context.
    ///
    /// - Parameters:
    ///   - workerContext: The context on which to perform the work.
    ///   - minimumDate: The time stamp after which to fetch transactions.
    ///
    /// See `DefaultFetcher` and `AlternateDefaultFetcher` for the basics of implementing
    /// the `fetchTransactions(workerContext:minimumDate:)` function.
    ///
    /// Make sure to run the work on the `workerContext`'s thread by encapsulating it in a `perform` block.
    ///
    /// - Returns: An array of `NSPersistentHistoryTransaction` fetched from
    ///            the persistent store.
    func fetchTransactions(
        workerContext: NSManagedObjectContext,
        minimumDate: Date
    ) throws -> [NSPersistentHistoryTransaction]
}

extension NSPersistentHistoryTransaction {
    /// Generates a `NSPredicate` for `NSPersistentHistoryTransaction`s originating from a context
    /// with the given author name.
    public static func matchingAuthor(_ author: TransactionAuthor) -> NSPredicate {
        NSPredicate(format: "%K == %@",
                    #keyPath(NSPersistentHistoryTransaction.author),
                    author.name)
    }
    
    /// Generates a `NSPredicate` for `NSPersistentHistoryTransaction`s that do not originate
    /// from a context with the given author name.
    public static func notMatchingAuthor(_ author: TransactionAuthor) -> NSPredicate {
        NSPredicate(format: "%K != %@",
                    #keyPath(NSPersistentHistoryTransaction.author),
                    author.name)
    }
}

extension PersistentHistoryTracker {
    /// PersistentHistoryFetcher that fetches only transactions where the `author` doesn't match
    /// the `name` of the current Author.
    public struct DefaultFetcher: PersistentHistoryFetcher {
        public var currentAuthor: TransactionAuthor
        public var logger: DataStackLogger?
        
        public func fetchTransactions(workerContext: NSManagedObjectContext, minimumDate: Date) throws -> [NSPersistentHistoryTransaction] {
            try workerContext.performAndWait {
                let request = persistentHistoryRequest(minimumDate: minimumDate)
                let result = try workerContext.execute(request) as? NSPersistentHistoryResult
                let finalResult = result?.result as? [NSPersistentHistoryTransaction] ?? []
                logger?.log(type: .debug, message: """
                    TransactionHistoryFetcher \(currentAuthor.name) got \
                    \(finalResult.count) transactions after \(minimumDate):
                    \(finalResult.map({ $0.debugDescription }).joined(separator: "\n"))
                    """)
                return finalResult
            }
        }
        
        func persistentHistoryRequest(minimumDate: Date) -> NSPersistentHistoryChangeRequest {
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: minimumDate)
            
            if let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest {
                historyFetchRequest.predicate = NSPersistentHistoryTransaction.notMatchingAuthor(currentAuthor)
                request.fetchRequest = historyFetchRequest
            }
            
            return request
        }
    }
}
