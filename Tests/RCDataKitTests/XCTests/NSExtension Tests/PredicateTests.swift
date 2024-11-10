//
//  PredicateTests.swift
//  

import CoreData
import XCTest
@testable import RCDataKit

final class PredicateTests: XCTestCase {
    
    func testBasicPredicates() throws {
        // Setup:
        let stack = try TestingStacks.temporaryStack(uniqueName: "PredicateTests")
        let context = stack.viewContext
        let testSubjects = try TestSubjectsData()
        let importResult = try context.importPersistableObjects(testSubjects.subjects)
        try context.save()
        
        guard importResult.count == 50 else {
            XCTFail("Didn't import all test subjects. \(importResult.count)")
            return
        }
        
        let requestWhere: (NSPredicate) throws -> [TestSubject] = { predicate in
            try context.fetch(TestSubject.fetchRequest().where(predicate))
        }
        
        // UUID Tests
        let someUUIDs = [
            "25dc9c71-bf96-49b4-9b82-1fa131d225a3",
            "26db1066-2a43-4b56-b04d-c0105f5d4ec5",
            "2780a9f4-3d4b-4ff7-9ec5-7d1989d5b7de"
        ].map { UUID(uuidString: $0)! }
        
        // equal
        let oneResult = try requestWhere(\TestSubject.id == someUUIDs[0])
        XCTAssertEqual(oneResult.count, 1)
        
        // IN
        let threeResults = try requestWhere((\TestSubject.id).in(someUUIDs))
        XCTAssertEqual(threeResults.count, 3)
        
        // not equal
        let lotsOfResults = try requestWhere(\TestSubject.id != someUUIDs[0])
        XCTAssertEqual(lotsOfResults.count, 49)
        
        // String Tests
        // equal
        let david = try requestWhere(\TestSubject.name == "David Schwarz")
        XCTAssertEqual(david.count, 1)
        
        // not equal
        let notDavid = try requestWhere(\TestSubject.name != "David Schwarz")
        XCTAssertEqual(notDavid.count, 49)
        
        // equal with options
        let lukas = try requestWhere((\TestSubject.name).equal(to: "lukas gross", options: .caseInsensitive))
        XCTAssertEqual(lukas.count, 1)
        let clara = try requestWhere((\TestSubject.name).equal(to: "clara kohler", options: .caseAndDiacriticInsensitive))
        XCTAssertEqual(clara.count, 1)
        
        // not equal with options
        let notLukas = try requestWhere((\TestSubject.name).notEqual(to: "lukas gross", options: .caseInsensitive))
        XCTAssertEqual(notLukas.count, 49)
        let notClara = try requestWhere((\TestSubject.name).notEqual(to: "clara kohler", options: .caseAndDiacriticInsensitive))
        XCTAssertEqual(notClara.count, 49)
        
        // LIKE
        // Hannah Vogel and Finn Bräutigam
        let likeResults = try requestWhere((\TestSubject.name).like("??nn*"))
        XCTAssertEqual(likeResults.count, 2)
        
        // CONTAINS
        // Clara Köhler, Lara Wagner, and Clara Huber
        let containsResults = try requestWhere((\TestSubject.name).contains("lara", options: .caseInsensitive))
        XCTAssertEqual(containsResults.count, 3)
        
        // BEGINSWITH
        // Anna Schäfer and Anton Straßmann
        let beginsWithResults = try requestWhere((\TestSubject.name).beginsWith("an", options: .caseInsensitive))
        XCTAssertEqual(beginsWithResults.count, 2)
        
        // ENDSWITH
        // Lukas Groß, Sophie Weiß, Jonas Strauß, and Pia Reiß
        let endsWithResults = try requestWhere((\TestSubject.name).endsWith("ss"))
        XCTAssertEqual(endsWithResults.count, 4)
        
        // matches regex
        // three-letter first name
        let regex = "^\\b\\w{3}\\b \\w+$"
        let regexResults = try requestWhere((\TestSubject.name).matches(regex))
        XCTAssertEqual(regexResults.count, 8)
        
        // Int Tests
        // equal
        let zeroScore = try requestWhere(\TestSubject.score == 0)
        XCTAssertEqual(zeroScore.count, 1)
        
        // not equal
        let notZeroScore = try requestWhere(\TestSubject.score != 0)
        XCTAssertEqual(notZeroScore.count, 49)
        
        // greater
        let moreThanNinety = try requestWhere(\TestSubject.score > 90)
        XCTAssertEqual(moreThanNinety.count, 2)
        
        // greater or equal
        let atLeastInt = try requestWhere(\TestSubject.score >= 75)
        XCTAssertEqual(atLeastInt.count, 11)
        
        // less than
        let lessThanTen = try requestWhere(\TestSubject.score < 10)
        XCTAssertEqual(lessThanTen.count, 4)

        // less than or equal
        let atMost15 = try requestWhere(\TestSubject.score <= 15)
        XCTAssertEqual(atMost15.count, 6)

        // between
        let teen = try requestWhere((\TestSubject.score).between(10...19))
        XCTAssertEqual(teen.count, 2)

        // in
        let tens = try requestWhere((\TestSubject.score).in([10, 20, 30, 40, 50, 60, 70, 80, 90]))
        XCTAssertEqual(tens.count, 4)

        // Double Tests
        // equal
        let doubleEqual = try requestWhere(\TestSubject.height == 1.40)
        XCTAssertEqual(doubleEqual.count, 2)

        // not equal
        let doubleNotEqual = try requestWhere(\TestSubject.height != 1.40)
        XCTAssertEqual(doubleNotEqual.count, 48)

        // greater
        let doubleGreater = try requestWhere(\TestSubject.height > 1.7)
        XCTAssertEqual(doubleGreater.count, 17)

        // greater or equal
        let doubleAtLeast = try requestWhere(\TestSubject.height >= 1.7)
        XCTAssertEqual(doubleAtLeast.count, 18)

        // less than
        let doubleLess = try requestWhere(\TestSubject.height < 1.25)
        XCTAssertEqual(doubleLess.count, 2)

        // less than or equal
        let doubleAtMost = try requestWhere(\TestSubject.height <= 1.25)
        XCTAssertEqual(doubleAtMost.count, 4)

        // between
        let doubleBetween = try requestWhere((\TestSubject.height).between(1.3...1.4))
        XCTAssertEqual(doubleBetween.count, 7)

        // in
        let doubleIn = try requestWhere((\TestSubject.height).in([1.4, 1.5, 1.6, 1.7]))
        XCTAssertEqual(doubleIn.count, 3)


        // Boolean Tests
        // equal
        let isMale = try requestWhere(\TestSubject.isMale == true)
        XCTAssertEqual(isMale.count, 26)
        
        // not equal
        let notMale = try requestWhere(\TestSubject.isMale != true)
        XCTAssertEqual(notMale.count, 24)
        
        // Date Tests
        // equal
        let equalDate = TestSubject.dob(from: "09/21/1997")!
        let bornOnDate = try requestWhere(\TestSubject.dateOfBirth == equalDate)
        XCTAssertEqual(bornOnDate.count, 1)

        // not equal
        let notBornOnDate = try requestWhere(\TestSubject.dateOfBirth != equalDate)
        XCTAssertEqual(notBornOnDate.count, 49)

        // greater
        let greaterDate = TestSubject.dob(from: "12/31/1999")!
        let bornAfter = try requestWhere(\TestSubject.dateOfBirth > greaterDate)
        XCTAssertEqual(bornAfter.count, 10)

        // greater or equal
        let atLeastDate = TestSubject.dob(from: "11/30/2008")!
        let bornAtLeast = try requestWhere(\TestSubject.dateOfBirth >= atLeastDate)
        XCTAssertEqual(bornAtLeast.count, 2)

        // less than
        let lessThanDate = TestSubject.dob(from: "12/31/1959")!
        let bornBefore = try requestWhere(\TestSubject.dateOfBirth < lessThanDate)
        XCTAssertEqual(bornBefore.count, 8)

        // less than or equal
        let atMostDate = TestSubject.dob(from: "09/30/1953")!
        let bornAtMost = try requestWhere(\TestSubject.dateOfBirth <= atMostDate)
        XCTAssertEqual(bornAtMost.count, 3)

        // between
        let startOfSixties = TestSubject.dob(from: "01/01/1960")!
        let endOfSixties = TestSubject.dob(from: "12/31/1969")!
        let sixties = startOfSixties...endOfSixties
        let bornInSixties = try requestWhere((\TestSubject.dateOfBirth).between(sixties))
        XCTAssertEqual(bornInSixties.count, 7)

        // in
        let someDates = [equalDate, atLeastDate, atMostDate, .distantPast, .distantFuture]
        let datesIn = try requestWhere((\TestSubject.dateOfBirth).in(someDates))
        XCTAssertEqual(datesIn.count, 3)
    }
    
    func testRelationPredicates() throws {
        let stack = try TestingStacks.temporaryStack(uniqueName: "RelationTests")
        let context = stack.viewContext
        let data = try SchoolsData()
        let teachersResult = try context.importPersistableObjects(data.teachers)
        let schoolsResult = try context.importPersistableObjects(data.schools)
        let studentsResult = try context.importPersistableObjects(data.students)
        try context.save()
        
        guard !studentsResult.isEmpty,
              !teachersResult.isEmpty,
              !schoolsResult.isEmpty
        else {
            XCTFail("Didn't import all data")
            return
        }

        let studentRequest = Student.fetchRequest()
        studentRequest.fetchLimit = 1
        let oneStudent = try context.fetch(studentRequest).first!
        
        let teacherRequest = Teacher.fetchRequest()
        teacherRequest.fetchLimit = 1
        let oneTeacher = try context.fetch(teacherRequest).first!
        
        let schoolRequest = School.fetchRequest()
        schoolRequest.fetchLimit = 1
        let oneSchool = try context.fetch(schoolRequest).first!
        
        // predicate for \School.teacher == teacher -> teacher is nonOptional
        let predicate1 = \School.teacher == oneTeacher
        let nonOptionalPredicate = try XCTUnwrap(predicate1 as? NSComparisonPredicate)
        XCTAssertEqual(nonOptionalPredicate.leftExpression.keyPath, "teacher")
        XCTAssertEqual(nonOptionalPredicate.rightExpression, NSExpression(forConstantValue: oneTeacher.objectID))
        
        // predicate for \Student.school == school -> school is Optional
        let predicate2 = \Student.school == oneSchool
        let optionalPredicate = try XCTUnwrap(predicate2 as? NSComparisonPredicate)
        XCTAssertEqual(optionalPredicate.leftExpression.keyPath, "school")
        XCTAssertEqual(optionalPredicate.rightExpression, NSExpression(forConstantValue: oneSchool.objectID))
        
        // predicate for \School.students.contains(student) -> Students is collection
        let predicate3 = (\School.students).contains(oneStudent)
        let collectionPredicate = try XCTUnwrap(predicate3 as? NSComparisonPredicate)
        XCTAssertEqual(collectionPredicate.leftExpression.keyPath, "students")
        XCTAssertEqual(collectionPredicate.rightExpression, NSExpression(forConstantValue: oneStudent.objectID))
        
        // Make sure the "contains" predicate actually works
        let containsFetchResults = try context.fetch(School.fetchRequest().where(predicate3))
        XCTAssertFalse(containsFetchResults.isEmpty)
    }
    
    func testOtherPredicates() throws {
        // Setup:
        let stack = try TestingStacks.temporaryStack(uniqueName: "AltPredicateTests")
        let context = stack.viewContext
        let data = try SchoolsData()
        let teachersResult = try context.importPersistableObjects(data.teachers)
        let schoolsResult = try context.importPersistableObjects(data.schools)
        let studentsResult = try context.importPersistableObjects(data.students)
        try context.save()
        
        guard !studentsResult.isEmpty,
              !teachersResult.isEmpty,
              !schoolsResult.isEmpty
        else {
            XCTFail("Didn't import all data")
            return
        }

        let southParkElementaryStudentsRequest = Student.fetchRequest()
            .where(\Student.school?.id == "SOU")
        let soParkStudents = try context.fetch(southParkElementaryStudentsRequest)
        XCTAssertEqual(soParkStudents.count, 4)
        
        // Add student with no school
        let _ = Student(context: context, id: 99, firstName: "No", lastName: "Body")
        try context.save()
        
        let noSchoolRequest = Student.fetchRequest()
            .where(\Student.school == nil)
        let noSchoolResult = try context.fetch(noSchoolRequest)
        XCTAssertEqual(noSchoolResult.count, 1)
    }
}
