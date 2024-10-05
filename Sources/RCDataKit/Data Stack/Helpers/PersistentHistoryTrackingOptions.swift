//
//  PersistentHistoryTrackingOptions.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/4/24.
//

import CoreData
import Foundation

/// A type that holds all properties needed to set up Persistent History Tracking in the `PersistentStack`.
///
/// See `PersistentHistoryTracker` for more information on creating and running a tracker. This struct
/// is used in `PersistentStack` initializers to create the Tracker, using any types passed into the struct's
/// initializer, or the default types for the `PersistentHistoryTracker`.
public struct PersistentHistoryTrackingOptions {
    var maxTransactionAge: TimeInterval?
    var customFetcher: PersistentHistoryFetcher?
    var customMerger: PersistentHistoryMerger?
    var customCleaner: PersistentHistoryCleaner?
    var timeStampManager: PersistentHistoryTimestampManager?
    var logger: DataStackLogger?
    
    public init(
        maxTransactionAge: TimeInterval? = nil,
        customFetcher: PersistentHistoryFetcher? = nil,
        customMerger: PersistentHistoryMerger? = nil,
        customCleaner: PersistentHistoryCleaner? = nil,
        timeStampManager: PersistentHistoryTimestampManager? = nil,
        logger: DataStackLogger? = nil
    ) {
        self.maxTransactionAge = maxTransactionAge
        self.customFetcher = customFetcher
        self.customMerger = customMerger
        self.customCleaner = customCleaner
        self.timeStampManager = timeStampManager
        self.logger = logger
    }
    
    func tracker<A: TransactionAuthor>(
        currentAuthor: A,
        container: NSPersistentContainer
    ) -> PersistentHistoryTracker<A> {
        PersistentHistoryTracker(
            container: container,
            currentAuthor: currentAuthor,
            timestampManager: timeStampManager,
            maxTransactionAge: maxTransactionAge ?? 24 * 7 * 60 * 60,
            customFetcher: customFetcher,
            customMerger: customMerger,
            customCleaner: customCleaner,
            logger: logger)
    }
    
    static func doConfiguration(
        options: PersistentHistoryTrackingOptions?,
        storeDescription: NSPersistentStoreDescription,
        viewContext: NSManagedObjectContext
    ) {
        if options != nil {
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        } else {
            // Automatic parent merging for ViewContext in this stack
            viewContext.automaticallyMergesChangesFromParent = true
        }
    }
}
