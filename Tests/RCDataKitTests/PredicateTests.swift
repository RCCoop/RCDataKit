//
//  PredicateTests.swift
//  

import CoreData
import XCTest
@testable import RCDataKit

final class PredicateTests: CoreDataTest {

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        _ = try insertStudents(
            (0, "Bart", "Simpson"),
            (1, "Lisa", "Simpson"),
            (2, "Maggie", "Simpson"),
            (3, "Eric", "Cartman"),
            (4, "Stan", "Marsh"),
            (5, "Kyle", "Broflovski"),
            (6, "Kenny", "McCormick"),
            (7, "Tina", "Belcher"),
            (8, "Gene", "Belcher"),
            (9, "Louise", "Belcher")
        )
    }

    var simpsonsPredicate: NSPredicate {
        NSPredicate(format: "%K == 'Simpson'", #keyPath(Student.lastName))
    }
    
    var bobsPredicate: NSPredicate {
        NSPredicate(format: "%K == 'Belcher'", #keyPath(Student.lastName))
    }
    
    var southParkPredicate: NSPredicate {
        NSPredicate(format: "%K BETWEEN %@", #keyPath(Student.id), [3, 6])
    }
    
    var sorting: [NSSortDescriptor] {
        [NSSortDescriptor(key: "id", ascending: true)]
    }
    
    func testBasicSetupPredicates() throws {
        let simpsonsRequest = studentFetchRequest()
        simpsonsRequest.sortDescriptors = sorting
        simpsonsRequest.predicate = simpsonsPredicate
        let simpsons = try viewContext.fetch(simpsonsRequest)
        
        XCTAssertEqual(simpsons.count, 3)
        XCTAssertEqual(simpsons.map(\.firstName), ["Bart", "Lisa", "Maggie"])
        
        let bobsRequest = studentFetchRequest()
        bobsRequest.sortDescriptors = sorting
        bobsRequest.predicate = bobsPredicate
        let bobsKids = try viewContext.fetch(bobsRequest)
        
        XCTAssertEqual(bobsKids.count, 3)
        XCTAssertEqual(bobsKids.map(\.firstName), ["Tina", "Gene", "Louise"])
        
        let soParkRequest = studentFetchRequest()
        soParkRequest.sortDescriptors = sorting
        soParkRequest.predicate = southParkPredicate
        let parkKids = try viewContext.fetch(soParkRequest)
        
        XCTAssertEqual(parkKids.count, 4)
        XCTAssertEqual(parkKids.map(\.firstName), ["Eric", "Stan", "Kyle", "Kenny"])
    }
    
    func testOrPredicate() throws {
        let request = studentFetchRequest()
        request.sortDescriptors = sorting
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
        let idLessThanFivePredicate = NSPredicate(format: "%K < %i", #keyPath(Student.id), 5)
        let request = studentFetchRequest()
        request.sortDescriptors = sorting
        request.predicate = southParkPredicate && idLessThanFivePredicate
        let kids = try viewContext.fetch(request)
        
        XCTAssertEqual(kids.count, 2)
        XCTAssertEqual(kids.map(\.firstName), ["Eric", "Stan"])
    }
    
    func testNotPredicate() throws {
        let request = studentFetchRequest()
        request.sortDescriptors = sorting
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
}
