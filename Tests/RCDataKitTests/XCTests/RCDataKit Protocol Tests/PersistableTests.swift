//
//  PersistableTests.swift
//  

import CoreData
@testable import RCDataKit
import XCTest

final class PersistableTests: XCTestCase {

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

    func testImportOutputTypes() throws {
        let teachers = try SchoolsData().teachers
        
        let teacherResult: [Int : PersistenceResult] = try viewContext.importPersistableObjects(teachers)
        XCTAssertEqual(teacherResult.keys.sorted(), teachers.map(\.id).sorted())
    }
    
    func testImportPersistableTypes() throws {
        let sampleData = try SchoolsData()
        
        // Import persistable types in order - teachers, schools, students
        let teacherResult: [PersistenceResult] = try viewContext.importPersistableObjects(sampleData.teachers)
        let schoolsResult: [PersistenceResult] = try viewContext.importPersistableObjects(sampleData.schools)
        let studentsResult: [PersistenceResult] = try viewContext.importPersistableObjects(sampleData.students)
        
        // test results
        
        // Teachers are imported without setting relations. Just test IDs
        for (importedTeacher, result) in zip(sampleData.teachers, teacherResult) {
            let teacherID = importedTeacher.id
            switch result {
            case let .insert(objectID):
                let theTeacher = try viewContext.existing(Teacher.self, withID: objectID)
                XCTAssertEqual(theTeacher.id, teacherID)
            default:
                XCTFail("Expected to insert teacher \(teacherID) but got \(result)")
            }
        }
        
        // Schools are imported with school ID and teacher ID
        for (importedSchool, result) in zip(sampleData.schools, schoolsResult) {
            let schoolID = importedSchool.id
            let teacherID = importedSchool.teacher
            switch result {
            case let .insert(objectID):
                let theSchool = try viewContext.existing(School.self, withID: objectID)
                XCTAssertEqual(theSchool.id, schoolID)
                XCTAssertEqual(theSchool.teacher?.id, teacherID)
            default:
                XCTFail("Expected to insert school \(schoolID), but got \(result)")
            }
        }
        
        // Students are updated with school ID
        for (importedStudent, result) in zip(sampleData.students, studentsResult) {
            let schoolID = importedStudent.school
            let studentID = importedStudent.id
            switch result {
            case let .update(objectID):
                let theStudent = try viewContext.existing(Student.self, withID: objectID)
                XCTAssertEqual(theStudent.id, studentID)
                XCTAssertEqual(theStudent.school?.id, schoolID)
            default:
                XCTFail("Expected to update student \(studentID), but got \(result)")
            }
        }
    }
    
}
