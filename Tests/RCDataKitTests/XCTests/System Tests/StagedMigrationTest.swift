//
//  StagedMigrationTest.swift
//  
//
//  Created by Ryan Linn on 8/10/24.
//

import CoreData
import XCTest
@testable import RCDataKit

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, macCatalyst 17.0, *)
final class StagedMigrationTest: XCTestCase {
    
    override func tearDown() async throws {
        try await super.tearDown()
    }
    
    func testStackUsingOldModel() throws {
        let name = "oldSchoolStore"
        let stack = try TestingStacks.oldModelStack(uniqueName: name)
        
        let context = stack.viewContext
        
        // fetch all students -- should be 10
        let studentFetch = NSFetchRequest<NSManagedObject>(entityName: "Student")
        let students = try context.fetch(studentFetch)
        XCTAssertEqual(students.count, 10)
        
        // check that data is not empty, and that isOldData == true
        for student in students {
            let studentDataIsOld = student.value(forKey: "isOldData") as? Bool ?? false
            XCTAssertTrue(studentDataIsOld)
            
            let studentData = try XCTUnwrap(student.value(forKey: "data") as? Data)
            XCTAssertFalse(studentData.isEmpty)
            let decodedStudent = try JSONDecoder().decode(StudentImport.self, from: studentData)
            XCTAssertFalse(decodedStudent.firstName.isEmpty)
            XCTAssertFalse(decodedStudent.lastName.isEmpty)
            XCTAssertFalse(decodedStudent.school.isEmpty)
        }
    }
    
    func testStackMigratedFromOldModel() throws {
        let name = "migratedStore"
        let stack = try TestingStacks.migratedContainer(uniqueName: name)
        
        let context = stack.viewContext
        
        // fetch all students -- should be 10 of them
        let studentFetch = Student.fetchRequest()
        studentFetch.returnsObjectsAsFaults = false
        let students = try context.fetch(studentFetch)
        XCTAssertEqual(students.count, 10)
    }
}
