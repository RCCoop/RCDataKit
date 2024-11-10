//
//  School.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData
import RCDataKit

@objc(School)
class School: NSManagedObject, Updatable {
    @NSManaged var name: String
    @NSManaged var id: String
    @NSManaged var teacher: Teacher
    @NSManaged var students: Set<Student>
    
    static func fetchRequest() -> NSFetchRequest<School> {
        NSFetchRequest<School>(entityName: "School")
    }
    
    convenience init(context: NSManagedObjectContext, id: String, name: String) {
        self.init(context: context)
        self.id = id
        self.name = name
    }
}
