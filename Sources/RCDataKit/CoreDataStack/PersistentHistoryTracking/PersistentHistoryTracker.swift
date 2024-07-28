//
//  PersistentHistoryTracker.swift
//

import CoreData
import Foundation

/// An actor that attaches to a persistent container in order to handle persistent history tracking.
///
/// Inspired by FatBobMan and SwiftLee:
/// https://github.com/fatbobman/PersistentHistoryTrackingKit/tree/main
/// https://fatbobman.com/en/posts/persistenthistorytracking/
/// https://www.avanderlee.com/swift/persistent-history-tracking-core-data/
///
/// - Important: In order to enable persistent history tracking in a persistent container, set description options
/// NSPersistentHistoryTrackingKey and NSPersistentStoreRemoteChangeNotificationPostOptionKey to true
/// (as NSNumber) before loading the container. Also, the viewContext should probably have
/// automaticallyMergesChangesFromParent set to false, since the persistent history merges handle that.
public actor PersistentHistoryTracker<Author: TransactionAuthor> {
    var container: NSPersistentContainer
        
    /// The Author type for the viewContext of the current app target for the PersistentHistoryTracker. This should
    /// be the context that is never directly written to, since it receives all write transactions through persistent
    /// history merging.
    var currentAuthor: Author
            
    /// Regardless of whether persistent history transactions have been merged, they will be deleted if they
    /// are older than this.
    public var maxTransactionAge: TimeInterval
    
    var fetcher: PersistentHistoryFetcher
    var merger: PersistentHistoryMerger
    var cleaner: PersistentHistoryCleaner
    var timestampManager: PersistentHistoryTimestampManager
    
    /// Logger
    var logger: CoreDataStackLogger?

    private var notificationsTask: Task<(), Never>?
    
    /// Initializes an instance of the history tracker and attaches it to a persistent container. You must call
    /// `startMonitoring()` for the tracker to begin its functioning.
    ///
    /// - Parameters:
    ///   - container:            The `NSPersistentContainer` to track history changes on.
    ///   - currentAuthor:        The value of `TransactionAuthor` that represents the View
    ///                           context of the current app target.
    ///   - timestampManager:     An instance where timestamp info will be stored for the container's
    ///                           app group.
    ///   - maxTransactionAge:    Regardless of whether persistent history transactions have been
    ///                           merged, they will be deleted during cleanup if they are older than
    ///                           this age.
    ///   - customFetcher:        An optional `PersistentHistoryFetcher` to retrieve
    ///                           `PersistentHistoryTransaction`s. If no custom fetcher
    ///                           is provided, a default one is used that fetches transactions with
    ///                           `author` equal to any of the tracker's `Authors` types
    ///                           besides the `currentAuthor` value.
    ///   - customMerger:         An optional `PersistentHistoryMerger` to handle merging
    ///                           of `PersistentHistoryTransaction`s retrieved by the
    ///                           `PersistentHistoryFetcher`. If no custom merger is
    ///                           provided, a default one is used which automatically merges all
    ///                           transactions.
    ///   - customCleaner:        An optional `PersistentHistoryCleaner` to clean expired
    ///                           `PersistentHistoryTransactions` after merging. If no
    ///                           custom cleaner is provided, a default one is used that removes
    ///                           all transactions with `author` corresponding to any of
    ///                           the tracker's `Authors` type.
    ///   - logger:               An instance of `CoreDataStackLogger` to handle logging.
    ///
    /// - Important: In order to enable persistent history tracking, the container's store description must
    ///              set the `NSPersistentHistoryTrackingKey` and
    ///              `NSPersistentStoreRemoteChangeNotificationPostOptionKey` to
    ///              `true as NSNumber` before loading the container.
    public init(
        container: NSPersistentContainer,
        currentAuthor: Author,
        timestampManager: PersistentHistoryTimestampManager? = nil,
        maxTransactionAge: TimeInterval = 24 * 7 * 60 * 60,
        customFetcher: PersistentHistoryFetcher? = nil,
        customMerger: PersistentHistoryMerger? = nil,
        customCleaner: PersistentHistoryCleaner? = nil,
        logger: CoreDataStackLogger? = DefaultLogger()
    ) {
        self.container = container
        self.currentAuthor = currentAuthor
        self.maxTransactionAge = maxTransactionAge
        self.logger = logger
        
        self.timestampManager = timestampManager ?? DefaultTimestampManager(userDefaults: .standard)
        fetcher = customFetcher ?? DefaultFetcher(currentAuthor: currentAuthor, logger: logger)
        merger = customMerger ?? DefaultMerger()
        cleaner = customCleaner ?? DefaultCleaner(logger: logger)
    }
        
    public func startMonitoring() {
        let notifications = NotificationCenter.default
            .notifications(
                named: .NSPersistentStoreRemoteChange,
                object: container.persistentStoreCoordinator)
        
        notificationsTask = Task { [weak self] in
            for await _ in notifications {
                await self?.processHistoryNotification()
            }
        }
    }
    
    public func stopMonitoring() {
        notificationsTask?.cancel()
        notificationsTask = nil
    }
    
    func processHistoryNotification() {
        let minimumDate = timestampManager
            .latestCommonHistoryTransactionDate(authors: Author.allCases)
        ?? .distantPast
        
        logger?.log(type: .debug, message: "PersistentHistoryTracker \(currentAuthor.name) received history notification. Merging transactions from \(minimumDate)")
        
        let workerContext = container.newBackgroundContext()
        workerContext.name = "PersistentHistoryTrackingContext"
        workerContext.transactionAuthor = "PersistentHistoryTracker"
        
        // Fetch transactions
        let transactions: [NSPersistentHistoryTransaction]
        do {
            transactions = try fetcher.fetchTransactions(
                workerContext: workerContext,
                minimumDate: minimumDate)
        } catch {
            logger?.log(type: .error, message: "TransactionHistoryFetcher failed with error - \(error)")
            return
        }
        
        // Merge fetched transactions into ViewContext
        do {
            try merger.mergeTransactions(viewContext: container.viewContext, transactions: transactions)
        } catch {
            logger?.log(type: .error, message: "TransactionHistoryMerger failed with error - \(error)")
        }
        
        // set timestamp for current target
        if let lastTimeStamp = transactions.last?.timestamp {
            timestampManager.setLatestHistoryTransactionDate(author: currentAuthor, date: lastTimeStamp)
        }
        
        // Clean up
        
        let minDate = Date().addingTimeInterval(-1 * abs(maxTransactionAge))
        let commonTimestamp = timestampManager
            .latestCommonHistoryTransactionDate(
                authors: Author.allCases)
        
        // Whichever is later, the common timestamp between different transaction
        // authors, or the date of the maximum transaction age, use that to delete
        // old/expired transactions.
        let deleteBeforeDate = [minDate, commonTimestamp]
            .compactMap { $0 }
            .max()!

        do {
            try cleaner.cleanTransactions(workerContext: workerContext, cleanBeforeDate: deleteBeforeDate)
        } catch {
            logger?.log(type: .error, message: "TransactionHistoryCleaner failed with error - \(error)")
        }
    }
}
