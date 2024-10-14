//
//  Teacher.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData

@objc(Teacher)
class Teacher: Person {
    @NSManaged var schools: Set<School>
    
    static func fetchRequest() -> NSFetchRequest<Teacher> {
        NSFetchRequest<Teacher>(entityName: "Teacher")
    }
}
