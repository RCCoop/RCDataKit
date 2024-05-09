//
//  PredicateTests.swift
//  

import CoreData
import XCTest
@testable import RCDataKit

final class PredicateTests: CoreDataTest {

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        _ = Student(context: viewContext, id: 0, firstName: "Bart", lastName: "Simpson")
        _ = Student(context: viewContext, id: 1, firstName: "Lisa", lastName: "Simpson")
        _ = Student(context: viewContext, id: 2, firstName: "Maggie", lastName: "Simpson")
        _ = Student(context: viewContext, id: 3, firstName: "Eric", lastName: "Cartman")
        _ = Student(context: viewContext, id: 4, firstName: "Stan", lastName: "Marsh")
        _ = Student(context: viewContext, id: 5, firstName: "Kyle", lastName: "Broflovski")
        _ = Student(context: viewContext, id: 6, firstName: "Kenny", lastName: "McCormick")
        _ = Student(context: viewContext, id: 7, firstName: "Tina", lastName: "Belcher")
        _ = Student(context: viewContext, id: 8, firstName: "Gene", lastName: "Belcher")
        _ = Student(context: viewContext, id: 9, firstName: "Louise", lastName: "Belcher")

        try viewContext.save()
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
