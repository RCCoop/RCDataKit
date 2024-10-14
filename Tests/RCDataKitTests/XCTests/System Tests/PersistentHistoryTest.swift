//
//  PersistentHistoryTest.swift
//

import CoreData
import XCTest
@testable import RCDataKit

class PersistentHistoryTest: XCTestCase {
    
    var timestampManager = DefaultTimestampManager()
    
    var stack1: SingleStoreStack<ModelAuthors>!
    var stack2: SingleStoreStack<ModelAuthors>!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        stack1 = try TestingStacks.persistentTrackingStack(mainAuthor: .viewContext1)
        stack2 = try TestingStacks.persistentTrackingStack(mainAuthor: .viewContext2)
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        ModelAuthors.allCases.forEach { timestampManager.setLatestHistoryTransactionDate(author: $0, date: nil) }
        
        stack2 = nil
        try stack1.container.destroyStore()
        stack1 = nil
        
        await sleep(seconds: 0.25)
    }
    
    // MARK: - Tests
    
    func testFetcher() async throws {
        let vc1 = stack1.viewContext
        let vc2 = stack2.viewContext
                
        // Get Fetcher
        let startDate = Date()
        let bgContext = stack1.backgroundContext(author: .backgroundContext)
        let fetcher = await stack1.historyTracker!.fetcher
        
        // create a thing in each view context
        try vc1.performAndWait {
            let _ = Student(context: vc1, id: 0, firstName: "A", lastName: "a")
            try vc1.save()
        }
        
        try vc2.performAndWait {
            let _ = Student(context: vc2, id: 1, firstName: "B", lastName: "b")
            try vc2.save()
        }
        
        // Arbitrary rest
        await sleep(seconds: 1.0)

        // fetch transactions ... count should == 1
        let transactions = try fetcher.fetchTransactions(workerContext: bgContext, minimumDate: startDate)
        XCTAssertEqual(transactions.count, 1)

        // fetch students ... count == 2
        let studentsFetch = NSFetchRequest<Student>(entityName: "Student")
        studentsFetch.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let students = try vc1.fetch(studentsFetch)
        XCTAssertEqual(students.map(\.id), [0, 1])
        XCTAssertEqual(students.count, 2)
    }
    
    func testCleaner() async throws {
        let vc1 = stack1.viewContext
        let vc2 = stack2.viewContext
        
        // Prepare to create Fetcher and Cleaner
        let bgContext = stack1.backgroundContext(author: .backgroundContext)
                
        // Perform Actions
        
        try vc1.performAndWait {
            let _ = Student(context: vc1, id: 0, firstName: "A", lastName: "A")
            try vc1.save()
        }
        
        try vc2.performAndWait {
            let _ = Student(context: vc2, id: 1, firstName: "B", lastName: "B")
            try vc2.save()
        }
        
        try vc2.performAndWait {
            let _ = Student(context: vc2, id: 2, firstName: "C", lastName: "C")
            try vc2.save()
        }
        
        // Create Cleaner & Fetcher for testing
        let fetcher = await stack1.historyTracker!.fetcher
        let cleaner = await stack1.historyTracker!.cleaner
        
        // Check number of transactions before cleaning == 2
        let transactions = try fetcher.fetchTransactions(workerContext: bgContext, minimumDate: .distantPast)
        XCTAssertEqual(transactions.count, 2)
        XCTAssertEqual(Set([ModelAuthors.viewContext2.name]), Set(transactions.map(\.author)))
        
        // Perform cleaning
        try cleaner.cleanTransactions(workerContext: bgContext, cleanBeforeDate: Date())
        
        // Check number of transactions after cleaning == 0
        let cleanedTransactions = try fetcher.fetchTransactions(workerContext: bgContext, minimumDate: .distantPast)
        XCTAssertEqual(cleanedTransactions.count, 0)
    }
    
    func testPersistentHistoryTracker() async throws {
        let vc1 = stack1.viewContext
        let vc2 = stack2.viewContext
        
        // ViewContext1.retainsRegisteredObjects = true
        vc1.retainsRegisteredObjects = true

        // Create PersistentHistoryTracker for one of the containers.
        let tracker = stack1.historyTracker!
        
        // Start tracking
        await tracker.startMonitoring()
        
        // Insert objects into VC2, and keep their ObjectIDs
        let objID1 = try vc2.performAndWait {
            let student = Student(context: vc2, id: 0, firstName: "A", lastName: "A")
            try vc2.save()
            return student.objectID
        }
        
        let objID2 = try vc2.performAndWait {
            let student = Student(context: vc2, id: 1, firstName: "B", lastName: "B")
            try vc2.save()
            return student.objectID
        }
        
        // wait a second
        await sleep(seconds: 1)
        
        // check to see if VC1 has registered those ObjectIDs √
        await vc1.perform {
            let student1 = vc1.registeredObject(for: objID1)
            let student2 = vc1.registeredObject(for: objID2)
            XCTAssertNotNil(student1)
            XCTAssertNotNil(student2)
        }
        
        // check userDefaults for latest time stamp for VC1 √
        let savedTimeStamps = ModelAuthors.allCases.reduce(into: [:]) {
            $0[$1] = timestampManager.latestHistoryTransactionDate(author: $1)
        }
        XCTAssertEqual(Array(savedTimeStamps.keys), [.viewContext1])
        
        // stop monitoring
        await tracker.stopMonitoring()
    }
    
    func testPersistentHistoryTrackerBackgroundContext() async throws {
        // similar to previous, but create two PersistentHistoryTrackers,
        // and insert object into backgroundContext, then check for ObjectIDs
        // in both view contexts.
        
        let vc1 = stack1.viewContext
        let vc2 = stack2.viewContext
        
        // ViewContexts.retainsRegisteredObjects = true
        vc1.retainsRegisteredObjects = true
        vc2.retainsRegisteredObjects = true
        
        // create two trackers
        let tracker1 = stack1.historyTracker!
        let tracker2 = stack2.historyTracker!
        await tracker1.startMonitoring()
        await tracker2.startMonitoring()
        
        // Insert objects into background context
        let bgContext = stack2.backgroundContext(author: .backgroundContext)
        bgContext.name = ModelAuthors.backgroundContext.name
        
        let objID1 = try bgContext.performAndWait {
            let student = Student(context: bgContext, id: 0, firstName: "A", lastName: "A")
            try bgContext.save()
            return student.objectID
        }
        
        await sleep(seconds: 0.5)
        
        let objID2 = try bgContext.performAndWait {
            let student = Student(context: bgContext, id: 1, firstName: "B", lastName: "B")
            try bgContext.save()
            return student.objectID
        }
        
        // wait a second
        await sleep(seconds: 1)
        
        // check to see if VC1 has registered those ObjectIDs √
        await vc1.perform {
            let student1 = vc1.registeredObject(for: objID1)
            let student2 = vc1.registeredObject(for: objID2)
            XCTAssertNotNil(student1)
            XCTAssertNotNil(student2)
        }
        
        // Check to see if VC2 has registered those ObjectIDs √
        await vc2.perform {
            let student1 = vc2.registeredObject(for: objID1)
            let student2 = vc2.registeredObject(for: objID2)
            XCTAssertNotNil(student1)
            XCTAssertNotNil(student2)
        }
        
        // check userDefaults for latest time stamp for VC1 √
        let savedTimeStamps = ModelAuthors.allCases.reduce(into: [:]) {
            $0[$1] = timestampManager.latestHistoryTransactionDate(author: $1)
        }
        XCTAssertEqual(Set(savedTimeStamps.keys), [.viewContext1, .viewContext2])
        
        // stop monitoring
        await tracker1.stopMonitoring()
        await tracker2.stopMonitoring()
    }
}
