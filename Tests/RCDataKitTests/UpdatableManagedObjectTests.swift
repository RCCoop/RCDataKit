//
//  UpdatableManagedObjectTests.swift
//  
//
//  Created by Ryan Linn on 5/8/24.
//

import XCTest

final class UpdatableManagedObjectTests: CoreDataTest {
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
        
        let course = Course(context: viewContext, id: "HIST101", title: "Intro to History")
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
        
        let historyA = Course(context: viewContext, id: "HIST101", title: "Intro to History")
        let historyB = Course(context: viewContext, id: "HIST201", title: "Second Year History")
        let historyC = Course(context: viewContext, id: "HIST301", title: "Advanced History")
        historyA.teacher = mrSmith
        historyB.teacher = mrSmith
        historyC.teacher = msDoe
        
        // add object to set that's already in the set
        XCTAssertFalse(mrSmith.add(\.courses, relation: historyA))
        
        // add object to set that's not already in the set
        XCTAssertTrue(mrSmith.add(\.courses, relation: historyC))
        XCTAssertEqual(historyC.teacher, mrSmith)
        
        // add nil object to the set
        XCTAssertFalse(mrSmith.add(\.courses, relation: nil))
        
        // add array of objects to the set where all objects already exist in the set
        XCTAssertFalse(mrSmith.add(\.courses, relation: [historyA, historyB, historyC]))
        
        // add array of objects to the set where some objects exist in the set
        mrSmith.courses = [historyA]
        XCTAssertTrue(mrSmith.add(\.courses, relation: [historyA, historyB]))
        XCTAssertEqual(mrSmith.courses, Set([historyA, historyB]))
        
        // add array of objects to the set where no objects already exist in the set
        mrSmith.courses = []
        XCTAssertTrue(mrSmith.add(\.courses, relation: [historyA, historyB]))
        XCTAssertEqual(mrSmith.courses, Set([historyA, historyB]))
    }
        
    func testRemoveToManyRelation() throws {
        let mrSmith = Teacher(context: viewContext, id: 0, firstName: "Mr", lastName: "Smith")
        
        let historyA = Course(context: viewContext, id: "HIST101", title: "Intro to History")
        let historyB = Course(context: viewContext, id: "HIST201", title: "Second Year History")
        historyA.teacher = mrSmith
        historyB.teacher = mrSmith

        XCTAssertEqual(mrSmith.courses, Set([historyA, historyB]))
        
        // remove object from a set that exists in the set
        XCTAssertTrue(mrSmith.remove(\.courses, relation: historyA))
        XCTAssertEqual(mrSmith.courses, Set([historyB]))
        
        // remove object from set that doesn't exist in the set
        XCTAssertFalse(mrSmith.remove(\.courses, relation: historyA))
        
        // remove nil object from the set
        XCTAssertFalse(mrSmith.remove(\.courses, relation: nil))
    }
}
