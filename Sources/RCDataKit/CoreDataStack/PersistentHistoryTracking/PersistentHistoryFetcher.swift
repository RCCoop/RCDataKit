//
//  PersistentHistoryFetcher.swift
//  

import CoreData
import Foundation

/// A type that can be used to fetch `NSPersistentHistoryTransaction`s from the persistent store.
public protocol PersistentHistoryFetcher {
    
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

extension PersistentHistoryTracker {
    /// PersistentHistoryFetcher that fetches only transactions with an `author` based on
    /// the `TransactionAuthors.name` of all authors besides the given `currentAuthor`.
    /// For example, if the current author is 'viewContext', all `TransactionAuthors` besides the
    /// `viewContext` will be fetched. This leaves out any authors that are not in the
    /// `TransactionAuthors.allCases` list.
    public struct DefaultFetcher: PersistentHistoryFetcher {
        public var currentAuthor: Author
        public var logger: CoreDataStackLogger?
        
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
                let subPredicates = currentAuthor.allOtherAuthors.map {
                    NSPredicate(format: "%K == %@",
                                #keyPath(NSPersistentHistoryTransaction.author),
                                $0.name)
                }
                historyFetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates)
                request.fetchRequest = historyFetchRequest
            }
            
            return request
        }
    }
    
    /// PersistentHistoryFetcher that fetches only transactions where the `author` doesn't match
    /// the `name` of the current Author. This is subtly different from `DefaultFetcher` in that
    /// this one may fetch transactions that aren't anticipated based on known `TransactionAuthor` types,
    /// so this one should be used if you are trying to find transactions that originate outside of your known
    /// scope (like CloudKit transactions?).
    public struct AlternateDefaultFetcher: PersistentHistoryFetcher {
        public var currentAuthor: Author
        public var logger: CoreDataStackLogger?
        
        public func fetchTransactions(workerContext: NSManagedObjectContext, minimumDate: Date) throws -> [NSPersistentHistoryTransaction] {
            try workerContext.performAndWait {
                let request = NSPersistentHistoryChangeRequest.fetchHistory(after: minimumDate)
                
                if let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest {
                    historyFetchRequest.predicate = NSPredicate(format: "%K != %@",
                                                                #keyPath(NSPersistentHistoryTransaction.author),
                                                                currentAuthor.name)
                    request.fetchRequest = historyFetchRequest
                }
                
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
    }
}
