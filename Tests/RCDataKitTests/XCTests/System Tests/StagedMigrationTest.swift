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
    
    func testStackModelChecks() throws {
        let oldName = "oldSchoolStore"
        let oldStack = try TestingStacks.oldModelStack(uniqueName: oldName)
        
        let oldStackUrl = try XCTUnwrap(oldStack.container.persistentStoreDescriptions.first?.url)
        let oldStackVersions = ModelVersions.versionsForStore(type: .sqlite, at: oldStackUrl)
        XCTAssertEqual(oldStackVersions, [.v1])
        
        let oldStackVersions2 = ModelVersions.versionsForStore(coordinator: oldStack.container.persistentStoreCoordinator)
        XCTAssertEqual(oldStackVersions2, [.v1])
        
        let oldStackModel = oldStack.container.managedObjectModel
        XCTAssertEqual(oldStackModel.versionChecksum, ModelVersions.v1.versionChecksum)
        
        let oldCoordinatorModel = oldStack.container.persistentStoreCoordinator.managedObjectModel
        XCTAssertEqual(oldCoordinatorModel, ModelVersions.v1.modelVersion)
        XCTAssertNotEqual(oldCoordinatorModel, ModelVersions.v3.modelVersion)
        
        let newName = "newStore"
        let newStack = try TestingStacks.temporaryStack(uniqueName: newName)
        
        let newStackUrl = try XCTUnwrap(newStack.container.persistentStoreDescriptions.first?.url)
        let newStackVersions = ModelVersions.versionsForStore(type: .sqlite, at: newStackUrl)
        XCTAssertEqual(newStackVersions, [.v4])
        
        let newStackVersions2 = ModelVersions.versionsForStore(coordinator: newStack.container.persistentStoreCoordinator)
        XCTAssertEqual(newStackVersions2, [.v4])
        
        let newStackModel = newStack.container.managedObjectModel
        XCTAssertEqual(newStackModel.versionChecksum, ModelVersions.v4.versionChecksum)
        
        let newCoordinatorModel = newStack.container.persistentStoreCoordinator.managedObjectModel
        XCTAssertEqual(newCoordinatorModel, ModelVersions.v4.modelVersion)
        XCTAssertNotEqual(newCoordinatorModel, ModelVersions.v2.modelVersion)
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
