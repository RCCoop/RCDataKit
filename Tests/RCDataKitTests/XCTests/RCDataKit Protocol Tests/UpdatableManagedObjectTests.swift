//
//  UpdatableManagedObjectTests.swift
//  

import RCDataKit
import XCTest

final class UpdatableManagedObjectTests: XCTestCase {
    
    var container: NSPersistentContainer!
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    override func setUp() async throws {
        try await super.setUp()
        container = try TestingStacks.inMemoryContainer()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        
        self.container = nil
    }

    func testBasicUpdates() throws {
        let john = Student(context: viewContext, id: 0, firstName: "John", lastName: "Doe")
        try viewContext.save()
        
        XCTAssertFalse(john.hasChanges)
        john.id = 0
        john.firstName = "John"
        XCTAssertTrue(john.hasChanges)
        
        viewContext.delete(john)
        try viewContext.save()
    }
    
    func testUpdateBasicProperties() throws {
        let john = Student(context: viewContext, id: 0, firstName: "John", lastName: "Doe")
        try viewContext.save()
        XCTAssertFalse(john.hasChanges)
        
        // Attempt updates that won't apply
        XCTAssertFalse(john.update(\.id, value: 0))
        XCTAssertFalse(john.update(\.firstName, value: "John"))
        XCTAssertFalse(john.hasChanges)
        
        // Attempt optional updates that won't apply
        XCTAssertFalse(john.updateIfAvailable(\.firstName, value: nil))
        XCTAssertFalse(john.updateIfAvailable(\.firstName, value: Optional("John")))
        XCTAssertFalse(john.hasChanges)
        
        // Attempt threshold update that won't apply
        XCTAssertFalse(john.update(\.id, value: 1, minimumChange: 2))
        XCTAssertFalse(john.updateIfAvailable(\.id, value: nil, minimumChange: 0))
        XCTAssertFalse(john.updateIfAvailable(\.id, value: Optional(1), minimumChange: 2))
        XCTAssertFalse(john.hasChanges)
        
        // Attempt a string update that will apply
        XCTAssertTrue(john.update(\.firstName, value: "Jon"))
        
        // Attempt an optional update that will apply
        XCTAssertTrue(john.updateIfAvailable(\.lastName, value: Optional("Do")))
        
        // Attempt a threshold update that will apply
        XCTAssertTrue(john.update(\.id, value: 2, minimumChange: 1))
        
        // Attempt an optional threshold update that will apply
        XCTAssertTrue(john.updateIfAvailable(\.id, value: Optional(5), minimumChange: 2))
        
        XCTAssertTrue(john.hasChanges)
        
        try viewContext.save()
        XCTAssertFalse(john.hasChanges)
        
        viewContext.delete(john)
        try viewContext.save()
    }
    
    func testUpdateToOneRelations() throws {
        let teacherA = Teacher(context: viewContext, id: 0, firstName: "Mr", lastName: "Smith")
        let teacherB = Teacher(context: viewContext, id: 1, firstName: "Mrs", lastName: "Jane")
        
        let course = School(context: viewContext, id: "ABC", name: "High School")
        course.teacher = teacherA
        
        try viewContext.save()
        XCTAssertFalse(teacherA.hasChanges)
        XCTAssertFalse(teacherB.hasChanges)
        XCTAssertFalse(course.hasChanges)
        
        // Attempt an update that won't apply
        course.update(\.teacher, value: teacherA)
        XCTAssertFalse(course.hasChanges)
        XCTAssertFalse(teacherA.hasChanges)
        XCTAssertFalse(teacherB.hasChanges)

        // Attempt an optional update that won't apply
        XCTAssertFalse(course.updateIfAvailable(\.teacher, value: nil))
        XCTAssertFalse(course.hasChanges)
        XCTAssertFalse(teacherA.hasChanges)
        XCTAssertFalse(teacherB.hasChanges)
        
        // Attempt an update to nil that will apply
        XCTAssertTrue(course.update(\.teacher, value: nil))
        XCTAssertTrue(course.hasChanges)
        XCTAssertTrue(teacherA.hasChanges)
        
        // Attempt an update that will apply
        XCTAssertTrue(course.update(\.teacher, value: teacherB))
        XCTAssertTrue(course.hasChanges)
        XCTAssertTrue(teacherA.hasChanges)
        XCTAssertTrue(teacherB.hasChanges)
        
        // Attempt an optional update that will apply
        XCTAssertTrue(course.updateIfAvailable(\.teacher, value: Optional(teacherA)))
                
        viewContext.delete(teacherA)
        viewContext.delete(teacherB)
        viewContext.delete(course)
        try viewContext.save()
    }
    
    func testAddToManyRelation() throws {
        let mrSmith = Teacher(context: viewContext, id: 0, firstName: "Mr", lastName: "Smith")
        let msDoe = Teacher(context: viewContext, id: 1, firstName: "Ms", lastName: "Doe")
        
        let schoolA = School(context: viewContext, id: "ABC", name: "School A")
        let schoolB = School(context: viewContext, id: "DEF", name: "School B")
        let schoolC = School(context: viewContext, id: "GHI", name: "School C")
        schoolA.teacher = mrSmith
        schoolB.teacher = mrSmith
        schoolC.teacher = msDoe
        
        // add object to set that's already in the set
        XCTAssertFalse(mrSmith.add(\.schools, relation: schoolA))
        
        // add object to set that's not already in the set
        XCTAssertTrue(mrSmith.add(\.schools, relation: schoolC))
        XCTAssertEqual(schoolC.teacher, mrSmith)
        
        // add nil object to the set
        XCTAssertFalse(mrSmith.add(\.schools, relation: nil))
        
        // add array of objects to the set where all objects already exist in the set
        XCTAssertFalse(mrSmith.add(\.schools, relation: [schoolA, schoolB, schoolC]))
        
        // add array of objects to the set where some objects exist in the set
        mrSmith.schools = [schoolA]
        XCTAssertTrue(mrSmith.add(\.schools, relation: [schoolA, schoolB]))
        XCTAssertEqual(mrSmith.schools, Set([schoolA, schoolB]))
        
        // add array of objects to the set where no objects already exist in the set
        mrSmith.schools = []
        XCTAssertTrue(mrSmith.add(\.schools, relation: [schoolA, schoolB]))
        XCTAssertEqual(mrSmith.schools, Set([schoolA, schoolB]))
    }
        
    func testRemoveToManyRelation() throws {
        let mrSmith = Teacher(context: viewContext, id: 0, firstName: "Mr", lastName: "Smith")
        
        let schoolA = School(context: viewContext, id: "ABC", name: "School A")
        let schoolB = School(context: viewContext, id: "DEF", name: "School B")
        schoolA.teacher = mrSmith
        schoolB.teacher = mrSmith

        XCTAssertEqual(mrSmith.schools, Set([schoolA, schoolB]))
        
        // remove object from a set that exists in the set
        XCTAssertTrue(mrSmith.remove(\.schools, relation: schoolA))
        XCTAssertEqual(mrSmith.schools, Set([schoolB]))
        
        // remove object from set that doesn't exist in the set
        XCTAssertFalse(mrSmith.remove(\.schools, relation: schoolA))
        
        // remove nil object from the set
        XCTAssertFalse(mrSmith.remove(\.schools, relation: nil))
    }
}
