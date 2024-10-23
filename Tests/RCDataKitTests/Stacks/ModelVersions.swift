//
//  ModelVersions.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData
import RCDataKit

@available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, macCatalyst 17.0, *)
enum ModelVersions: String, ModelVersion {
    typealias ModelDefinition = ModelKey
        
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
    
    // MARK: - Stages
    
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
            let decoder = JSONDecoder()
            for existingThing in existingThings {
                let jsonData = existingThing.value(forKey: "data") as? Data
                let sampleStudent = jsonData.flatMap { try? decoder.decode(StudentImport.self, from: $0) }
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
        v3.migrationStage(
            toVersion: .v4,
            label: "Lightweight Migration v3 to v4: remove `isMigrated` field."
        )
    }
}

