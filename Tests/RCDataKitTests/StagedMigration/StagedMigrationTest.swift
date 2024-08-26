//
//  StagedMigrationTest.swift
//  
//
//  Created by Ryan Linn on 8/10/24.
//

import CoreData
import XCTest
@testable import RCDataKit

@available(macOS 14.0, iOS 17.0, *)
final class StagedMigrationTest: PersistentStoreTest {
    
    enum ModelVersions: String, PersistentStoreVersion {
        static var bundle: Bundle { .module }
        
        static var modelName: String { "TestModel" }
                
        case v1 = "Model"
        case v2 = "Model2"
        case v3 = "Model3"
        case v4 = "Model4"
        
        static func migrationStages() -> [NSMigrationStage] {
            [
                stageV1toV2(),
                stageV2toV3(),
                stageV3toV4()
            ]
        }
    }
    
    func makeOldContainer(students: [SampleData.Student]) throws -> NSPersistentContainer? {
        let oldContainer = try Self.makeContainerForOriginalModel()
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
        let sampleStudents = try SampleData.build().students
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
    }
    
    func testMakeNewContainerOnTopOfOldContainer() throws {
        let sampleStudents = try SampleData.build().students
        guard let oldContainer = try makeOldContainer(students: sampleStudents)
        else { fatalError() }
        
        let migrator = ModelVersions.migrationManager()
        let newContainer = try Self.makeContainerWithStagedMigrations(manager: migrator)
        let context = newContainer.viewContext
        
        let studentsRequest = Student.studentRequest()
        studentsRequest.returnsObjectsAsFaults = false
        let existingStudents = try context.fetch(studentsRequest)
        XCTAssertEqual(sampleStudents.count, existingStudents.count)
        for oneStudent in existingStudents {
            XCTAssertNotNil(oneStudent.value(forKey: "firstName"))
            XCTAssertNotNil(oneStudent.value(forKey: "lastName"))
            XCTAssertNil(oneStudent.school)
            XCTAssertGreaterThanOrEqual(oneStudent.id, 0)
        }
    }
}


@available(macOS 14.0, *)
extension StagedMigrationTest.ModelVersions {
    static func stageV1toV2() -> NSMigrationStage {
        v1.migrationStage(
            toVersion: .v2,
            label: "Lightweight Migration: V1 to V2 adding empty name & id fields"
        )
    }
    
    static func stageV2toV3() -> NSMigrationStage {
        v2.migrationStage(
            toVersion: .v3,
            label: "Custom Migration: V2 to V3 moving json into property fields"
        ) { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "Student")
            fetch.returnsObjectsAsFaults = false
            let existingThings = try context.fetch(fetch)
            print("""
                ******************************************************
                BEFORE MIGRATION:
                decompose jsonData into firstName, lastName, id
                \(existingThings)
                ******************************************************
                """)
            for existingThing in existingThings {
                let jsonData = existingThing.value(forKey: "data") as? Data
                let sampleStudent = jsonData.flatMap { try? JSONDecoder().decode(SampleData.Student.self, from: $0) }
                existingThing.setValue(sampleStudent?.firstName, forKey: "firstName")
                existingThing.setValue(sampleStudent?.lastName, forKey: "lastName")
                existingThing.setValue(sampleStudent?.id ?? -1, forKey: "id")
                existingThing.setValue(nil, forKey: "data")
                existingThing.setValue(true, forKey: "isMigrated")
            }
        } postMigration: { context in
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "Student")
            fetch.returnsObjectsAsFaults = false
            let existingThings = try context.fetch(fetch)
            print("""
                ******************************************************
                AFTER MIGRATION: - no more action needed
                \(existingThings)
                ******************************************************
                """)
        }

    }
    
    static func stageV3toV4() -> NSMigrationStage {
        v3.migrationStage(toVersion: .v4, label: "Lightweight Migration v3 to v4: remove `isMigrated` field.")
    }
}
