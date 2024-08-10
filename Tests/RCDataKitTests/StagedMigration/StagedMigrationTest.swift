//
//  StagedMigrationTest.swift
//  
//
//  Created by Ryan Linn on 8/10/24.
//

import CoreData
import XCTest


@available(macOS 14.0, iOS 17.0, *)
final class StagedMigrationTest: PersistentStoreTest {

    func makeMigrationManager() -> NSStagedMigrationManager {
        let momdURL = Bundle.module.url(forResource: "TestModel", withExtension: "momd")!
        let modelV1URL = momdURL.appendingPathComponent("Model.mom")
        let modelV2URL = momdURL.appendingPathComponent("Model2.mom")
        let modelV3URL = momdURL.appendingPathComponent("Model3.mom")
        
        guard let model1 = NSManagedObjectModel(contentsOf: modelV1URL),
              let model2 = NSManagedObjectModel(contentsOf: modelV2URL),
              let model3 = NSManagedObjectModel(contentsOf: modelV3URL)
        else { fatalError() }
        
        let checksum1 = model1.versionChecksum
        let checksum2 = model2.versionChecksum
        let checksum3 = model3.versionChecksum
        
        let ref1 = NSManagedObjectModelReference(model: model1, versionChecksum: checksum1)
        let ref2 = NSManagedObjectModelReference(model: model2, versionChecksum: checksum2)
        let ref3 = NSManagedObjectModelReference(model: model3, versionChecksum: checksum3)
        
        let lightweightStageV1toV2 = NSLightweightMigrationStage([checksum1])
        lightweightStageV1toV2.label = "Lightweight Migration: V1 to V2 adding empty name & id fields"
        
        let customStageV2toV3 = NSCustomMigrationStage(migratingFrom: ref2, to: ref3)
        customStageV2toV3.label = "Custom Migration: V2 to V3 moving json into property fields"
        customStageV2toV3.willMigrateHandler = { migrationManager, currentStage in
            guard let container = migrationManager.container
            else { return }
            let context = container.newBackgroundContext()
            context.performAndWait {
                let fetch = NSFetchRequest<NSManagedObject>(entityName: "Student")
                fetch.returnsObjectsAsFaults = false
                if let existingThings = try? context.fetch(fetch) {
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
                    }
                    try? context.save()
                }
            }
        }
        customStageV2toV3.didMigrateHandler = { migrationManager, currentStage in
            guard let container = migrationManager.container
            else { return }
            let context = container.newBackgroundContext()
            context.performAndWait {
                let fetch = NSFetchRequest<NSManagedObject>(entityName: "Student")
                fetch.returnsObjectsAsFaults = false
                if let existingThings = try? context.fetch(fetch) {
                    print("""
                    ******************************************************
                    AFTER MIGRATION: - no more action needed
                    \(existingThings)
                    ******************************************************
                    """)
                }
            }
        }
        
        return NSStagedMigrationManager([lightweightStageV1toV2, customStageV2toV3])
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
        
        let migrator = makeMigrationManager()
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
