//
//  PersistentHistoryFetcher.swift
//  

import CoreData
import Foundation

public protocol PersistentHistoryFetcher {
    func fetchTransactions(
        workerContext: NSManagedObjectContext,
        minimumDate: Date
    ) throws -> [NSPersistentHistoryTransaction]
}

extension PersistentHistoryTracker {
    /// PersistentHistoryFetcher that fetches only transactions with a `contextName` based on
    /// the `TransactionAuthors.contextName` of all authors besides the given
    /// `currentAuthor`. eg, if the current author is 'viewContext', all `TransactionAuthors`
    /// besides the `viewContext` will be fetched. This leaves out any contextNames that are not
    /// in the `TransactionAuthors.allCases` list.
    struct DefaultFetcher: PersistentHistoryFetcher {
        var currentAuthor: Author
        var logger: CoreDataStackLogger?
        
        func fetchTransactions(workerContext: NSManagedObjectContext, minimumDate: Date) throws -> [NSPersistentHistoryTransaction] {
            try workerContext.performAndWait {
                let request = persistentHistoryRequest(minimumDate: minimumDate)
                let result = try workerContext.execute(request) as? NSPersistentHistoryResult
                let finalResult = result?.result as? [NSPersistentHistoryTransaction] ?? []
                logger?.log(type: .debug, message: """
                    TransactionHistoryFetcher \(currentAuthor.contextName) got \
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
                                #keyPath(NSPersistentHistoryTransaction.contextName),
                                $0.contextName)
                }
                historyFetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: subPredicates)
                request.fetchRequest = historyFetchRequest
            }
            
            return request
        }
    }
}
