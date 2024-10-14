//
//  Student.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData

@objc(Student)
class Student: Person {
    @NSManaged var school: School?
    
    static func fetchRequest() -> NSFetchRequest<Student> {
        NSFetchRequest<Student>(entityName: "Student")
    }
}
