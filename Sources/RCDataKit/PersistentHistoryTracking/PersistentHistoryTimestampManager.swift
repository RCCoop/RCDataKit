//
//  PersistentHistoryTimestampManager.swift
//

import Foundation
import os

/// A type that is used to store time stamps of when each app target has merged `NSPersistentHistoryTransaction`s
/// from the persistent store.
public protocol PersistentHistoryTimestampManager: Sendable {
    /// Gets the names of all `TransactionAuthor`s that are known to have performed a merge of
    /// `NSPersistentHistoryTransaction`s into the persistent store.
    var storedTransactionDateAuthors: [TransactionAuthor] { get }
    
    /// Fetches the latest date at which the given `TransactionAuthor`s have merged
    /// `NSPersistentHistoryTransaction`s into the persistent store. If no list of authors is provided,
    /// fetch the latest date of all known authors.
    func latestHistoryTransactionDate(authors: [TransactionAuthor]?) -> Date?
    
    /// Sets the latest dates at which the given `TransactionAuthor`s have merged
    /// `NSPersistentHistoryTransaction`s into the persistent store.
    func updateLatestHistoryTransactionDate(_ updates: [TransactionAuthor : Date?])
}

public extension PersistentHistoryTimestampManager {
    func latestHistoryTransactionDate(author: TransactionAuthor) -> Date? {
        latestHistoryTransactionDate(authors: [author])
    }
    
    func updateLatestHistoryTransactionDate(author: TransactionAuthor, date: Date?) {
        updateLatestHistoryTransactionDate([author : date])
    }
}

fileprivate extension UserDefaults {
    static var rcData: UserDefaults {
        UserDefaults(suiteName: "com.rccoop.rcdatakit")!
    }
}

struct DefaultTimestampManager: PersistentHistoryTimestampManager {
    private var transactionKey: String {
        "PersistentHistoryTransactionDates"
    }
    
    private var storedData: [String : Date] {
        UserDefaults.rcData.data(forKey: transactionKey)
            .flatMap { try? JSONDecoder().decode([String : Date].self, from: $0) }
        ?? [:]
    }
    
    private func updateData(_ newData: [String : Date]) {
        let coded = try? JSONEncoder().encode(newData)
        UserDefaults.rcData.set(coded, forKey: transactionKey)
    }
    
    var storedTransactionDateAuthors: [TransactionAuthor] {
        storedData.keys.map { TransactionAuthor($0) }
    }
    
    func latestHistoryTransactionDate(authors: [TransactionAuthor]?) -> Date? {
        let data = storedData
        
        let dates: [Date] = if let authors {
            authors.compactMap { data[$0.name] }
        } else {
            Array(data.values)
        }
        
        return dates.min()
    }
    
    func updateLatestHistoryTransactionDate(_ updates: [TransactionAuthor : Date?]) {
        var data = storedData
        for (author, newDate) in updates {
            data[author.name] = newDate
        }
        updateData(data)
    }
}
