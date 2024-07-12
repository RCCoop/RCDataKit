//
//  PersistentHistoryTracker.swift
//

import Combine
import CoreData
import Foundation

/// An actor that attaches to a persistent container in order to handle persistent history tracking.
///
/// Inspired by FatBobMan and SwiftLee:
/// https://github.com/fatbobman/PersistentHistoryTrackingKit/tree/main
/// https://fatbobman.com/en/posts/persistenthistorytracking/
/// https://www.avanderlee.com/swift/persistent-history-tracking-core-data/
///
/// Note: In order to enable persistent history tracking in a persistent container, set description options
/// NSPersistentHistoryTrackingKey and NSPersistentStoreRemoteChangeNotificationPostOptionKey to true
/// (as NSNumber) before loading the container. Also, the viewContext should probably have
/// automaticallyMergesChangesFromParent set to false, since the persistent history merges handle that.
public actor PersistentHistoryTracker<Author: TransactionAuthor> {
    var container: NSPersistentContainer
        
    /// The Author type for the viewContext of the current app target for the PersistentHistoryTracker. This should
    /// be the context that is never directly written to, since it receives all write transactions through persistent
    /// history merging.
    var currentAuthor: Author
    
    /// A UserDefaults instance where timestamp info will be stored for the app group
    var userDefaults: UserDefaults
        
    /// Regardless of whether persistent history transactions have been merged, they will be deleted if they
    /// are older than this.
    public var maxTransactionAge: TimeInterval
    
    /// Logger
    public var logger: CoreDataStackLogger?

    private var notificationSubscription: AnyCancellable?
    
    /// Initializes an instance of the history tracker and attaches it to a persistent container. You must call
    /// `startMonitoring()` for the tracker to begin its functioning.
    ///
    /// - Parameters:
    ///   - container:            The `NSPersistentContainer` to track history changes on.
    ///   - currentAuthor:        The value of `TransactionAuthor` that represents the View
    ///                           context of the current app target.
    ///   - userDefaults:         A `UserDefaults` instance where timestamp info will be stored
    ///                           for the container's app group.
    ///   - maxTransactionAge:    Regardless of whether persistent history transactions have been
    ///                           merged, they will be deleted during cleanup if they are older than
    ///                           this age.
    ///   - logger:               An instance of `CoreDataStackLogger` to handle logging.
    ///
    /// - Important: In order to enable persistent history tracking, the container's store description must
    ///              set the `NSPersistentHistoryTrackingKey` and
    ///              `NSPersistentStoreRemoteChangeNotificationPostOptionKey` to
    ///              `true as NSNumber` before loading the container.
    public init(
        container: NSPersistentContainer,
        currentAuthor: Author,
        userDefaults: UserDefaults = .standard,
        maxTransactionAge: TimeInterval = 24 * 7 * 60 * 60,
        logger: CoreDataStackLogger? = DefaultLogger()
    ) {
        self.container = container
        self.userDefaults = userDefaults
        self.currentAuthor = currentAuthor
        self.maxTransactionAge = maxTransactionAge
        self.logger = logger
    }
        
    public func startMonitoring() {
        notificationSubscription = NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange, object: container.persistentStoreCoordinator)
            .sink { [weak self] _ in
                guard let self else { return }
                Task {
                    await self.processHistoryNotification()
                }
            }
    }
    
    public func stopMonitoring() {
        notificationSubscription = nil
    }
    
    func processHistoryNotification() {
        let minimumDate = userDefaults
            .latestCommonHistoryTransactionDate(authors: Author.allCases)
        ?? .distantPast
        
        logger?.log(type: .debug, message: "PersistentHistoryTracker \(currentAuthor.contextName) received history notification. Merging transactions from \(minimumDate)")
        
        let workerContext = container.newBackgroundContext()
        workerContext.name = "PersistentHistoryTrackingContext"
        workerContext.transactionAuthor = "PersistentHistoryTracker"
        
        // Fetch transactions
        let transactions: [NSPersistentHistoryTransaction]
        let fetcher = DefaultFetcher(currentAuthor: currentAuthor, logger: logger)
        do {
            transactions = try fetcher.fetchTransactions(
                workerContext: workerContext,
                minimumDate: minimumDate)
        } catch {
            logger?.log(type: .error, message: "TransactionHistoryFetcher failed with error - \(error)")
            return
        }
        
        // Merge fetched transactions into ViewContext
        let merger = DefaultMerger()
        do {
            try merger.mergeTransactions(viewContext: container.viewContext, transactions: transactions)
        } catch {
            logger?.log(type: .error, message: "TransactionHistoryMerger failed with error - \(error)")
        }
        
        // set timestamp for current target
        if let lastTimeStamp = transactions.last?.timestamp {
            userDefaults.setLatestHistoryTransactionDate(author: currentAuthor, date: lastTimeStamp)
        }
        
        // Clean up
        
        let minDate = Date().addingTimeInterval(-1 * abs(maxTransactionAge))
        let commonTimestamp = userDefaults.latestCommonHistoryTransactionDate(
            authors: Author.allCases)
        
        // Whichever is later, the common timestamp between different transaction
        // authors, or the date of the maximum transaction age, use that to delete
        // old/expired transactions.
        let deleteBeforeDate = [minDate, commonTimestamp]
            .compactMap { $0 }
            .max()!

        let cleaner = DefaultCleaner(logger: logger)
        do {
            try cleaner.cleanTransactions(workerContext: workerContext, cleanBeforeDate: deleteBeforeDate)
        } catch {
            logger?.log(type: .error, message: "TransactionHistoryCleaner failed with error - \(error)")
        }
    }
}
