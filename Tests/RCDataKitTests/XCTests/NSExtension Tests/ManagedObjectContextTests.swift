//
//  ManagedObjectContextTests.swift
//  

import XCTest
@testable import RCDataKit

final class ManagedObjectContextTests: XCTestCase {
    
    var container: NSPersistentContainer!
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    override func setUp() async throws {
        try await super.setUp()
        container = try TestingStacks.inMemoryContainer()
        
        let students = try SchoolsData().students
        _ = try viewContext.importPersistableObjects(students)
        try viewContext.save()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        self.container = nil
    }

    func testSaveIfNeeded() throws {
        let _ = Teacher(context: viewContext, id: 0, firstName: "Mr", lastName: "Rogers")
        
        let yes = try viewContext.saveIfNeeded()
        let no = try viewContext.saveIfNeeded()
        XCTAssertTrue(yes)
        XCTAssertFalse(no)
    }
    
    func testTypedObjectFromID() throws {
        let allStudents = try viewContext.fetch(Student.fetchRequest())
        let oneID = allStudents[0].objectID
        let studentName = allStudents[0].fullName
        
        viewContext.reset()
        
        let refetched = try viewContext.existing(Student.self, withID: oneID)
        let student = try XCTUnwrap(refetched)
        XCTAssertEqual(student.fullName, studentName)
        
        // Test failure
        do {
            let _ = try viewContext.existing(Teacher.self, withID: oneID)
            XCTFail("Should fail here")
        } catch let error as NSManagedObjectContext.ExistingObjectFailure {
            XCTAssertEqual(error, .mismatchedType(foundEntity: "Student"))
        } catch {
            XCTFail("Wrong error type: \(String(describing: type(of: error)))")
        }
    }
    
    func testTypedObjectsFromIDs() throws {
        let simpsonKidsRequest = Student.fetchRequest()
        simpsonKidsRequest.predicate = \Student.lastName == "Simpson"
        let simpsonKids = try viewContext.fetch(simpsonKidsRequest)
        let ids = simpsonKids.map { $0.objectID }
        
        viewContext.reset()
        
        let refetched = try viewContext.existing(Student.self, withIDs: ids)
        XCTAssertEqual(refetched.count, 3)
        XCTAssertTrue(refetched.allSatisfy({ $0.lastName == "Simpson" }))
    }
    
    func testDeleteObjects() throws {
        try viewContext.removeInstances(of: Student.self)
        
        let studentCount = try viewContext.count(for: Student.fetchRequest())
        XCTAssertEqual(studentCount, 0)
    }
    
    func testDeleteSomeObjects() throws {
        try viewContext.removeInstances(of: Student.self, matching: \Student.lastName == "Simpson")
        
        let remainingStudents = try viewContext.fetch(Student.fetchRequest())
        XCTAssertTrue(remainingStudents.filter({ $0.lastName == "Simpson" }).isEmpty)
        XCTAssertFalse(remainingStudents.isEmpty)
    }
}
