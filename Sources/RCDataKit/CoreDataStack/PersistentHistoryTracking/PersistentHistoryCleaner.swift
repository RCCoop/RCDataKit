//
//  PersistentHistoryCleaner.swift
//

import CoreData
import Foundation

public protocol PersistentHistoryCleaner {
    func cleanTransactions(
        workerContext: NSManagedObjectContext,
        cleanBeforeDate: Date
    ) throws
}

extension PersistentHistoryTracker {
    struct DefaultCleaner: PersistentHistoryCleaner {
        var logger: CoreDataStackLogger?
        
        func cleanTransactions(workerContext: NSManagedObjectContext, cleanBeforeDate: Date) throws {
            let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: cleanBeforeDate)
            
            if let fetchRequest = NSPersistentHistoryTransaction.fetchRequest {
                // !!!: fetchRequest is always nil here
                let subpredicates = Author.allCases.map {
                    NSPredicate(format: "%K == %@",
                                #keyPath(NSPersistentHistoryTransaction.contextName),
                                $0.contextName)
                }
                fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
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
