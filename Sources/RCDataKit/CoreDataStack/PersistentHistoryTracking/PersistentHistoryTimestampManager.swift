//
//  PersistentHistoryTimestampManager.swift
//

import Foundation
import os

/// A type that is used to store time stamps of when each app target has merged `NSPersistentHistoryTransaction`s
/// from the persistent store.
public protocol PersistentHistoryTimestampManager: Sendable {
    /// Fetches the latest date at which the given `TransactionAuthor` has merged
    /// `NSPersistentHistoryTransaction`s into the persistent store.
    func latestHistoryTransactionDate<A: TransactionAuthor>(author: A) -> Date?
    
    /// Sets the latest date at which the given `TransactionAuthor` has merged
    /// `NSPersistentHistoryTransaction`s into the persistent store.
    func setLatestHistoryTransactionDate<A: TransactionAuthor>(author: A, date: Date?)
}

extension PersistentHistoryTimestampManager {
    func latestCommonHistoryTransactionDate<C: Collection>(authors: C) -> Date?
    where C.Element: TransactionAuthor
    {
        authors.compactMap {
            latestHistoryTransactionDate(author: $0)
        }
        .min()
    }
}

struct DefaultTimestampManager: PersistentHistoryTimestampManager {
    var defaults: OSAllocatedUnfairLock<UserDefaults>
    
    init(userDefaults: UserDefaults) {
        defaults = OSAllocatedUnfairLock(uncheckedState: userDefaults)
    }
    
    func transactionKey<A: TransactionAuthor>(author: A) -> String {
        "PersistentHistoryTransactionDate-" + author.name
    }
    
    func latestHistoryTransactionDate<A>(author: A) -> Date? where A : TransactionAuthor {
        let key = transactionKey(author: author)
        return defaults.withLock { def in
            def.object(forKey: key) as? Date
        }
    }
    
    func setLatestHistoryTransactionDate<A>(author: A, date: Date?) where A : TransactionAuthor {
        let key = transactionKey(author: author)
        defaults.withLock { def in
            def.set(date, forKey: key)
        }
    }
}
