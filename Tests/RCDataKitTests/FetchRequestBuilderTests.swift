//
//  FetchRequestBuilderTests.swift
//  
//
//  Created by Ryan Linn on 5/9/24.
//

import CoreData
import XCTest
@testable import RCDataKit

final class FetchRequestBuilderTests: KidsTests {
    
    func testAddingPredicate() throws {
        let simpsonsRequest = NSFetchRequest<Student>(entityName: "Student")
            .predicated(simpsonsPredicate)
        
        let simpsonsKids = try viewContext.fetch(simpsonsRequest)
        XCTAssertEqual(simpsonsKids.map(\.lastName), Array(repeating: "Simpson", count: 3))
    }
    
    func testAddingSortDescriptors() throws {
        let kidsRequest = NSFetchRequest<Student>(entityName: "Student")
            .sorted([NSSortDescriptor(keyPath: \Student.id, ascending: true)])
        
        let allKids = try viewContext.fetch(kidsRequest)
        XCTAssertEqual(allKids.map(\.id), Array(0...9))
    }
    
    func testSortingAndPredicate() throws {
        let simpsonsRequest = NSFetchRequest<Student>(entityName: "Student")
            .predicated(simpsonsPredicate)
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
