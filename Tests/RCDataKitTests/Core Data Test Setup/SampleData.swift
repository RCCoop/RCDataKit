//
//  SampleData.swift
//  

import CoreData
import Foundation
import RCDataKit

struct SampleData: Decodable {
    struct Student: Decodable, Identifiable {
        var firstName: String
        var lastName: String
        var id: Int
        var school: String
    }
    
    struct Teacher: Decodable, Identifiable {
        var firstName: String
        var lastName: String
        var id: Int
    }
    
    struct School: Decodable, Identifiable {
        var teacher: Int
        var name: String
        var id: String
    }
    
    var students: [Student]
    var teachers: [Teacher]
    var schools: [School]
    
    static func build() throws -> SampleData {
        let url = Bundle.module.url(forResource: "SampleData", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(SampleData.self, from: data)
        return decoded
    }
}

// MARK: - Importable Protocol

extension SampleData.Teacher: Persistable {
    static func generateImporterData(objects: [SampleData.Teacher], context: NSManagedObjectContext) throws -> () {
        // nothing
    }
    
    func importIntoContext(_ context: NSManagedObjectContext, importerData: Void) -> PersistenceResult {
        let newTeach = Teacher(context: context, id: id, firstName: firstName, lastName: lastName)
        return .insert(newTeach.objectID)
    }
}

extension SampleData.School: Persistable {
    struct ImporterData {
        var teachers: [Int : Teacher]
    }
    
    static func generateImporterData(objects: [SampleData.School], context: NSManagedObjectContext) throws -> ImporterData {
        let teacherFetch = NSFetchRequest<Teacher>(entityName: Teacher.entity().name!)
        let teachers = try context.fetch(teacherFetch)
        let keyed = teachers.reduce(into: [:]) { $0[$1.id] = $1 }
        return ImporterData(teachers: keyed)
    }
    
    func importIntoContext(_ context: NSManagedObjectContext, importerData: ImporterData) -> PersistenceResult {
        let newSchool = School(context: context, id: id, name: name)
        newSchool.teacher = importerData.teachers[teacher]
        return .insert(newSchool.objectID)
    }
}

extension SampleData.Student: Persistable {
    struct ImporterData {
        var existingStudents: [SampleData.Student.ID : Student]
        var schools: [String : School]
    }

    static func generateImporterData(objects: [SampleData.Student], context: NSManagedObjectContext) throws -> ImporterData {
        // Get existing students to update
        let studentsPredicate = NSPredicate(
            format: "%K IN %@",
            #keyPath(Student.id),
            objects.map(\.id))
        let studentsFetch = NSFetchRequest<Student>(entityName: Student.entity().name!)
        studentsFetch.predicate = studentsPredicate
        let students = try context.fetch(studentsFetch)
        let keyedStudents = students.reduce(into: [:]) { $0[$1.id] = $1 }
        
        // Get existing schools for setting school relation
        let schoolsPredicate = NSPredicate(
            format: "%K IN %@",
            #keyPath(School.id),
            objects.map(\.school))
        let schoolsFetch = NSFetchRequest<School>(entityName: School.entity().name!)
        schoolsFetch.predicate = schoolsPredicate
        let schools = try context.fetch(schoolsFetch)
        let keyedSchools = schools.reduce(into: [:]) { $0[$1.id] = $1 }
        
        let data = ImporterData(existingStudents: keyedStudents, schools: keyedSchools)
        return data
    }
    
    func importIntoContext(_ context: NSManagedObjectContext, importerData: ImporterData) -> PersistenceResult {
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
