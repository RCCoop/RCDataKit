//
//  ManagedObjectClasses.swift
//

import CoreData
import Foundation

/// Abstract Entity to encompass Student and Teacher
class Person: NSManagedObject {
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var id: Int
}

class Student: Person {
    @NSManaged var courses: Set<Course>
}

class Teacher: Person {
    @NSManaged var courses: Set<Course>
}

class Course: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var id: String
    @NSManaged var isFull: Bool
    @NSManaged var teacher: Teacher
    @NSManaged var students: Set<Student>
}
