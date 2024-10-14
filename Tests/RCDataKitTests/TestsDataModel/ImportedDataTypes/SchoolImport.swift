//
//  SchoolImport.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData
import Foundation
import RCDataKit

struct SchoolImport: Decodable, Identifiable {
    var teacher: Int
    var name: String
    var id: String
}

extension SchoolImport: Persistable {
    struct ImporterData {
        var teachers: [Int : Teacher]
    }
    
    static func generateImporterData(objects: [SchoolImport], context: NSManagedObjectContext) throws -> ImporterData {
        let teacherFetch = NSFetchRequest<Teacher>(entityName: Teacher.entity().name!)
        let teachers = try context.fetch(teacherFetch)
        let keyed = teachers.reduce(into: [:]) { $0[$1.id] = $1 }
        return ImporterData(teachers: keyed)
    }
    
    func importIntoContext(_ context: NSManagedObjectContext, importerData: inout ImporterData) -> PersistenceResult {
        let newSchool = School(context: context, id: id, name: name)
        newSchool.teacher = importerData.teachers[teacher]
        return .insert(newSchool.objectID)
    }
}
