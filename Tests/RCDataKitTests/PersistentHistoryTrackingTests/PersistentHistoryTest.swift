//
//  File.swift
//  
//
//  Created by Ryan Linn on 7/10/24.
//

import CoreData
import XCTest
@testable import RCDataKit

class PersistentHistoryTest: XCTestCase {
    
    // MARK: - Setup
    
    enum Authors: String, TransactionAuthor {
        case viewContext1, viewContext2, backgroundContext
        
        var contextName: String { rawValue }
    }
    
    var testStoreURL: URL {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
            .appending(path: "PersistentHistoryTestStore")
    }
    
    static var persistentModel = NSManagedObjectModel.mergedModel(from: [.module])!
    
    func makeContainer(url: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Test Container", managedObjectModel: Self.persistentModel)
        let description = container.persistentStoreDescriptions.first!
        description.url = url
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        var error: Error?
        container.loadPersistentStores { _, err in
            if let err { error = err }
        }
        if let error {
            throw error
        }
        return container
    }
    
    func destroyContainer(url: URL) {
        let urls = [
            url,
            url.deletingPathExtension().appendingPathExtension("sqlite-wal"),
            url.deletingPathExtension().appendingPathExtension("sqlite-shm")
        ]
        
        urls.forEach { try? FileManager.default.removeItem(at: $0) }
    }
    
    func sleep(seconds: Double) async {
        try! await Task.sleep(for: .seconds(seconds))
    }
    
//    override func setUp() async throws {
//        <#code#>
//    }
//    
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        Authors.allCases.forEach { UserDefaults.standard.setLatestHistoryTransactionDate(author: $0, date: nil) }
    }
    
    // MARK: - Tests
    
    func testFetcher() async throws {
        // create 2 containers at same location
        let target1Container = try makeContainer(url: testStoreURL)
        let target2Container = try makeContainer(url: testStoreURL)
        let vc1 = target1Container.viewContext
        let vc2 = target2Container.viewContext
        
        // set view context names of each container to VC1 and VC2
        vc1.name = Authors.viewContext1.contextName
        vc2.name = Authors.viewContext2.contextName
        
        // Create Fetcher
        let startDate = Date()
        let bgContext = target1Container.newBackgroundContext()
//        bgContext.name = Authors.backgroundContext.contextName
        let fetcher = PersistentHistoryTracker.DefaultFetcher(
            currentAuthor: Authors.viewContext1,
            logger: DefaultLogger())
        
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
        
        // Tear down
        destroyContainer(url: testStoreURL)
    }
    
    func testCleaner() async throws {
        let logger = DefaultLogger()
        
        // create 2 containers at same location
        let target1Container = try makeContainer(url: testStoreURL)
        let target2Container = try makeContainer(url: testStoreURL)
        let vc1 = target1Container.viewContext
        let vc2 = target2Container.viewContext
        
        // set view context names of each container to VC1 and VC2
        vc1.name = Authors.viewContext1.contextName
        vc2.name = Authors.viewContext2.contextName
        
        // Prepare to create Fetcher and Cleaner
        let startDate = Date()
        let bgContext = target1Container.newBackgroundContext()
//        bgContext.name = Authors.backgroundContext.contextName
                
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
        
        // Create Cleaner & Fetcher
        
        let fetcher = PersistentHistoryTracker.DefaultFetcher(
            currentAuthor: Authors.viewContext1,
            logger: logger)
        let cleaner = PersistentHistoryTracker<Authors>.DefaultCleaner(logger: logger)
        
        // Check number of transactions before cleaning == 2
        let transactions = try fetcher.fetchTransactions(workerContext: bgContext, minimumDate: .distantPast)
        XCTAssertEqual(transactions.count, 2)
        XCTAssertEqual(Set([Authors.viewContext2.contextName]), Set(transactions.map(\.contextName)))
        
        // Perform cleaning
        try cleaner.cleanTransactions(workerContext: bgContext, cleanBeforeDate: Date())
        
        // Check number of transactions after cleaning == 0
        let cleanedTransactions = try fetcher.fetchTransactions(workerContext: bgContext, minimumDate: .distantPast)
        XCTAssertEqual(cleanedTransactions.count, 0)
        
        // Tear down
        destroyContainer(url: testStoreURL)
    }
    
    func testPersistentHistoryTracker() async throws {
        // Create two containers at same URL
        // create 2 containers at same location
        let target1Container = try makeContainer(url: testStoreURL)
        let target2Container = try makeContainer(url: testStoreURL)
        let vc1 = target1Container.viewContext
        let vc2 = target2Container.viewContext
        
        // set view context names of each container to VC1 and VC2
        vc1.name = Authors.viewContext1.contextName
        vc2.name = Authors.viewContext2.contextName

        // ViewContext1.retainsRegisteredObjects = true
        vc1.retainsRegisteredObjects = true

        // Create PersistentHistoryTracker for one of the containers.
        let tracker = PersistentHistoryTracker(
            container: target1Container,
            currentAuthor: Authors.viewContext1)
        
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
        let savedTimeStamps = Authors.allCases.reduce(into: [:]) {
            $0[$1] = UserDefaults.standard.latestHistoryTransactionDate(author: $1)
        }
        XCTAssertEqual(Array(savedTimeStamps.keys), [.viewContext1])
        
        // stop monitoring
        await tracker.stopMonitoring()
        
        // tear down containers
        destroyContainer(url: testStoreURL)
        
        // await a second
        await sleep(seconds: 1)
    }
    
    func testPersistentHistoryTrackerBackgroundContext() async throws {
        // similar to previous, but create two PersistentHistoryTrackers,
        // and insert object into backgroundContext, then check for ObjectIDs
        // in both view contexts.
        
        // Create two containers at same URL
        // create 2 containers at same location
        let target1Container = try makeContainer(url: testStoreURL)
        let target2Container = try makeContainer(url: testStoreURL)
        let vc1 = target1Container.viewContext
        let vc2 = target2Container.viewContext
        
        // set view context names of each container to VC1 and VC2
        vc1.name = Authors.viewContext1.contextName
        vc2.name = Authors.viewContext2.contextName

        // ViewContexts.retainsRegisteredObjects = true
        vc1.retainsRegisteredObjects = true
        vc2.retainsRegisteredObjects = true
        
        // create two trackers
        let tracker1 = PersistentHistoryTracker(container: target1Container, currentAuthor: Authors.viewContext1)
        let tracker2 = PersistentHistoryTracker(container: target2Container, currentAuthor: Authors.viewContext2)
        await tracker1.startMonitoring()
        await tracker2.startMonitoring()
        
        // Insert objects into background context
        let bgContext = target2Container.newBackgroundContext()
        bgContext.name = Authors.backgroundContext.contextName
        
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
        let savedTimeStamps = Authors.allCases.reduce(into: [:]) {
            $0[$1] = UserDefaults.standard.latestHistoryTransactionDate(author: $1)
        }
        XCTAssertEqual(Array(savedTimeStamps.keys), [.viewContext1, .viewContext2])
        
        // stop monitoring
        await tracker1.stopMonitoring()
        await tracker2.stopMonitoring()
        
        // tear down containers
        destroyContainer(url: testStoreURL)
        
        // await a second
        await sleep(seconds: 1)
    }
}