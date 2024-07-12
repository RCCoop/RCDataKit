//
//  File.swift
//  

import Foundation
import os

public protocol PersistentHistoryTimestampManager: Sendable {
    ///
    func latestHistoryTransactionDate<A: TransactionAuthor>(author: A) -> Date?
    
    ///
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

@available(macOS 13.0, *)
struct DefaultTimestampManager: PersistentHistoryTimestampManager {
//    var userDefaults: UserDefaults
    var defaults: OSAllocatedUnfairLock<UserDefaults>
    
    init(userDefaults: UserDefaults) {
        defaults = OSAllocatedUnfairLock(uncheckedState: userDefaults)
    }
    
    func transactionKey<A: TransactionAuthor>(author: A) -> String {
        "PersistentHistoryTransactionDate-" + author.contextName
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

extension UserDefaults {
    func transactionKey<A: TransactionAuthor>(author: A) -> String {
        "PersistentHistoryTransactionDate-" + author.contextName
    }
    
    /// The timestamp for the most recent history transaction that was merged into the given context
    func latestHistoryTransactionDate<A: TransactionAuthor>(author: A) -> Date? {
        object(forKey: transactionKey(author: author)) as? Date
    }
    
    func setLatestHistoryTransactionDate<A: TransactionAuthor>(author: A, date: Date?) {
        set(date, forKey: transactionKey(author: author))
    }
    
    func latestCommonHistoryTransactionDate<C: Collection>(authors: C) -> Date?
    where C.Element: TransactionAuthor
    {
        authors
            .compactMap { latestHistoryTransactionDate(author: $0) }
            .min()
    }
}
