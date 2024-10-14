//
//  FetchRequestBuilderTests.swift
//

import CoreData
import XCTest
@testable import RCDataKit

final class FetchRequestBuilderTests: XCTestCase {
    
    var container: NSPersistentContainer!
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    override func setUp() async throws {
        try await super.setUp()
        container = try TestingStacks.inMemoryContainer()
        let sampleStudents = try SchoolsData().students
        _ = try viewContext.importPersistableObjects(sampleStudents)
        try viewContext.save()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        self.container = nil
    }
    
    func testAddingPredicate() throws {
        let simpsonsRequest = Student.fetchRequest()
            .where(\Student.lastName == "Simpson")
        
        let simpsonsKids = try viewContext.fetch(simpsonsRequest)
        XCTAssertEqual(simpsonsKids.map(\.lastName), Array(repeating: "Simpson", count: 3))
    }
    
    func testAddingSortDescriptors() throws {
        let kidsRequest = Student.fetchRequest()
            .sorted([.ascending(\Student.id)])
        
        let allKids = try viewContext.fetch(kidsRequest)
        XCTAssertEqual(allKids.map(\.id), Array(0...9))
    }
    
    func testSortingAndPredicate() throws {
        let simpsonsRequest = Student.fetchRequest()
            .where(\Student.lastName == "Simpson")
            .sorted([.ascending(\Student.id)])
        
        let simpsonsKids = try viewContext.fetch(simpsonsRequest)
        XCTAssertEqual(simpsonsKids.map(\.firstName), ["Bart", "Lisa", "Maggie"])
    }
    
    func testFetchByID() throws {
        let idsRequest = NSFetchRequest(entityIds: Student.self)
            .sorted([.ascending(\Student.id)])
        
        let ids = try viewContext.fetch(idsRequest)
        let bartFromID = try XCTUnwrap(viewContext.object(with: ids[0]) as? Student)
        XCTAssertEqual(bartFromID.firstName, "Bart")
    }
    
}
