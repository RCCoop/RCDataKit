//
//  PredicateTests.swift
//  

import CoreData
import XCTest
@testable import RCDataKit

final class PredicateTests: PersistentStoreTest {
    
    var container: NSPersistentContainer!
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    override func setUp() async throws {
        try await super.setUp()
        container = try Self.makeContainer()
        
        try addStudentsFromSampleData(context: container.viewContext)
    }

    func testBasicSetupPredicates() throws {
        let simpsonsRequest = Student.studentRequest()
        simpsonsRequest.sortDescriptors = sortById
        simpsonsRequest.predicate = simpsonsPredicate
        let simpsons = try viewContext.fetch(simpsonsRequest)
        
        XCTAssertEqual(simpsons.count, 3)
        XCTAssertEqual(simpsons.map(\.firstName), ["Bart", "Lisa", "Maggie"])
        
        let bobsRequest = Student.studentRequest()
        bobsRequest.sortDescriptors = sortById
        bobsRequest.predicate = bobsPredicate
        let bobsKids = try viewContext.fetch(bobsRequest)
        
        XCTAssertEqual(bobsKids.count, 3)
        XCTAssertEqual(bobsKids.map(\.firstName), ["Tina", "Gene", "Louise"])
        
        let soParkRequest = Student.studentRequest()
        soParkRequest.sortDescriptors = sortById
        soParkRequest.predicate = southParkPredicate
        let parkKids = try viewContext.fetch(soParkRequest)
        
        XCTAssertEqual(parkKids.count, 4)
        XCTAssertEqual(parkKids.map(\.firstName), ["Eric", "Stan", "Kyle", "Kenny"])
    }
    
    func testOrPredicate() throws {
        let request = Student.studentRequest()
        request.sortDescriptors = sortById
        request.predicate = simpsonsPredicate || bobsPredicate
        let kids = try viewContext.fetch(request)
        
        let firstNames = [
            "Bart",
            "Lisa",
            "Maggie",
            "Tina",
            "Gene",
            "Louise"
        ]
        
        XCTAssertEqual(kids.count, 6)
        XCTAssertEqual(kids.map(\.firstName), firstNames)
    }
    
    func testAndPredicate() throws {
        let idLessThanFivePredicate = \Student.id < 5
        let request = Student.studentRequest()
        request.sortDescriptors = sortById
        request.predicate = southParkPredicate && idLessThanFivePredicate
        let kids = try viewContext.fetch(request)
        
        XCTAssertEqual(kids.count, 2)
        XCTAssertEqual(kids.map(\.firstName), ["Eric", "Stan"])
    }
    
    func testNotPredicate() throws {
        let request = Student.studentRequest()
        request.sortDescriptors = sortById
        request.predicate = !bobsPredicate
        let kids = try viewContext.fetch(request)
        
        let firstNames = [
            "Bart",
            "Lisa",
            "Maggie",
            "Eric",
            "Stan",
            "Kyle",
            "Kenny"
        ]
        
        XCTAssertEqual(kids.count, 7)
        XCTAssertEqual(kids.map(\.firstName), firstNames)
    }
    
    func testObjectIDPredicate() throws {
        let allStudents = try viewContext.fetch(Student.studentRequest())
        let simpsonIDs = allStudents
            .filter { $0.lastName == "Simpson" }
            .map { $0.objectID }
        let idsRequest = Student.studentRequest()
            .predicated(NSPredicate(managedObjectIds: simpsonIDs))
        let simpsonsKids = try viewContext.fetch(idsRequest)
        
        XCTAssertEqual(simpsonsKids.count, 3)
        XCTAssert(simpsonsKids.allSatisfy({ $0.lastName == "Simpson" }))
    }
    
    func testObjectIDPredicateTypeMismatch() throws {
        let someTeacher = Teacher(context: viewContext, id: 0, firstName: "Mr", lastName: "Rogers")
        try viewContext.save()
        
        let request = Student.studentRequest()
        request.predicate = NSPredicate(managedObjectIds: [someTeacher.objectID])
        let result = try viewContext.fetch(request)
        XCTAssertEqual(result.count, 0)
    }
    
    func testComparisonPredicates() {
        
        // >
        let greaterThan = \Student.id > 0
        let alsoGreaterThan = \Student.id > 5
        
        // <
        
        // >=
        
        // <=
        
    }
}
