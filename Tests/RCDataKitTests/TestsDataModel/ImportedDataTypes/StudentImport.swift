//
//  StudentImport.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData
import Foundation
import RCDataKit

struct StudentImport: Codable, Identifiable {
    var firstName: String
    var lastName: String
    var id: Int
    var school: String
}

extension StudentImport: Persistable {
    struct ImporterData {
        var existingStudents: [StudentImport.ID : Student]
        var schools: [String : School]
    }

    static func generateImporterData(objects: [StudentImport], context: NSManagedObjectContext) throws -> ImporterData {
        // Get existing students to update
        let studentsPredicate = (\Student.id).in(objects.map(\.id))
        let studentsFetch = NSFetchRequest<Student>(entityName: Student.entity().name!)
        studentsFetch.predicate = studentsPredicate
        let students = try context.fetch(studentsFetch)
        let keyedStudents = students.reduce(into: [:]) { $0[$1.id] = $1 }
        
        // Get existing schools for setting school relation
        let schoolsPredicate = (\School.id).in(objects.map(\.school))
        let schoolsFetch = NSFetchRequest<School>(entityName: School.entity().name!)
        schoolsFetch.predicate = schoolsPredicate
        let schools = try context.fetch(schoolsFetch)
        let keyedSchools = schools.reduce(into: [:]) { $0[$1.id] = $1 }
        
        let data = ImporterData(existingStudents: keyedStudents, schools: keyedSchools)
        return data
    }
    
    func importIntoContext(_ context: NSManagedObjectContext, importerData: inout ImporterData) -> PersistenceResult {
        let newSchool = importerData.schools[school]
        
        if let existingStudent = importerData.existingStudents[id] {
            _ = existingStudent.update(\.firstName, value: firstName)
            _ = existingStudent.update(\.lastName, value: lastName)
            _ = existingStudent.updateIfAvailable(\.school, value: newSchool)
            return .update(existingStudent.objectID)
        } else {
            let newStudent = Student(context: context, id: id, firstName: firstName, lastName: lastName)
            newStudent.school = newSchool
            return .insert(newStudent.objectID)
        }
    }

}
