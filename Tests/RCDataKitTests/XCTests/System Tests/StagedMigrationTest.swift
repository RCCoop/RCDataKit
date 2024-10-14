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
    
    func makeOldContainer(students: [StudentImport]) throws -> NSPersistentContainer? {
        let oldContainer = try TestingStacks.originalModelStack(mainAuthor: .viewContext1)
        guard let studentEntity = oldContainer.managedObjectModel.entitiesByName["Student"]
        else { return nil }
        
        let context = oldContainer.viewContext

        // Insert data!
        for student in students {
            let rawStudent = NSManagedObject(entity: studentEntity, insertInto: context)
            let jsonData = try JSONEncoder().encode(student)
            rawStudent.setValue(jsonData, forKey: "data")
        }
        try context.save()
        
        return oldContainer
    }
    
    func testMakeOldContainer() throws {
        let sampleStudents = try SchoolsData().students
        guard let container = try makeOldContainer(students: sampleStudents)
        else { fatalError() }
        
        let context = container.viewContext
                
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Student")
        fetchRequest.predicate = NSPredicate(format: "isOldData == 1")
        let fetchedResults = try context.fetch(fetchRequest)
        XCTAssertFalse(fetchedResults.isEmpty)
        XCTAssertEqual(fetchedResults.count, sampleStudents.count)
        
        let otherFetch = NSFetchRequest<NSManagedObject>(entityName: "Student")
        otherFetch.predicate = NSPredicate(format: "isOldData == 0")
        let otherResults = try context.fetch(otherFetch)
        XCTAssert(otherResults.isEmpty)
        
        try container.destroyStore()
    }
    
    func testMakeNewContainerOnTopOfOldContainer() async throws {
        /*
         NOTE: Running this test brings up the following error in the terminal:
         
         `CoreData: error: Attempting to retrieve an NSManagedObjectModel version
         checksum while the model is still editable. This may result in an
         unstable verison checksum. Add model to NSPersistentStoreCoordinator
         and try again.`

         The only reference I've found to this error message online is here:
         https://forums.developer.apple.com/forums/thread/761735
         
         And the Apple Engineer in the thread says it's harmless. I've only run
         into this error message while performing migrations in this test class,
         not while performing them in an actual app, so I'm ignoring the error
         for now.
         */
        
        let sampleStudents = try SchoolsData().students
        guard let _ = try makeOldContainer(students: sampleStudents)
        else { fatalError() }
                
        let newContainer = try TestingStacks.stagedMigrationsStack(mainAuthor: .viewContext1)
        let context = newContainer.viewContext
        
        let studentsRequest = Student.fetchRequest()
        studentsRequest.returnsObjectsAsFaults = false
        let existingStudents = try context.fetch(studentsRequest)
        XCTAssertEqual(sampleStudents.count, existingStudents.count)
        for oneStudent in existingStudents {
            XCTAssertNotNil(oneStudent.value(forKey: "firstName"))
            XCTAssertNotNil(oneStudent.value(forKey: "lastName"))
            XCTAssertNil(oneStudent.school)
            XCTAssertGreaterThanOrEqual(oneStudent.id, 0)
        }
        
        try newContainer.destroyStore()
    }
}
