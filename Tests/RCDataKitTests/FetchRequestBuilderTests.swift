//
//  FetchRequestBuilderTests.swift
//

import CoreData
import XCTest
@testable import RCDataKit

final class FetchRequestBuilderTests: PersistentStoreTest {
    
    var container: NSPersistentContainer!
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    override func setUp() async throws {
        try await super.setUp()
        container = try Self.makeContainer()
        
        try addStudentsFromSampleData(context: container.viewContext)
    }
    
    func testAddingPredicate() throws {
        let simpsonsRequest = Student.studentRequest()
            .where(simpsonsPredicate)
        
        let simpsonsKids = try viewContext.fetch(simpsonsRequest)
        XCTAssertEqual(simpsonsKids.map(\.lastName), Array(repeating: "Simpson", count: 3))
    }
    
    func testAddingSortDescriptors() throws {
        let kidsRequest = Student.studentRequest()
            .sorted([NSSortDescriptor(keyPath: \Student.id, ascending: true)])
        
        let allKids = try viewContext.fetch(kidsRequest)
        XCTAssertEqual(allKids.map(\.id), Array(0...9))
    }
    
    func testSortingAndPredicate() throws {
        let simpsonsRequest = Student.studentRequest()
            .where(simpsonsPredicate)
            .sorted(sortById)
        
        let simpsonsKids = try viewContext.fetch(simpsonsRequest)
        XCTAssertEqual(simpsonsKids.map(\.firstName), ["Bart", "Lisa", "Maggie"])
    }
    
    func testFetchByID() throws {
        let idsRequest = NSFetchRequest(entityIds: Student.self)
            .sorted(sortById)
        
        let ids = try viewContext.fetch(idsRequest)
        let bartFromID = try XCTUnwrap(viewContext.object(with: ids[0]) as? Student)
        XCTAssertEqual(bartFromID.firstName, "Bart")
    }
    
}
