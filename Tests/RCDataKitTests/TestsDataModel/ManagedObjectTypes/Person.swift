//
//  Person.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData
import RCDataKit

/// Abstract Entity to encompass Student and Teacher
@objc(Person)
class Person: NSManagedObject, Updatable {
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var id: Int
    
    var fullName: String {
        firstName + " " + lastName
    }
    
    convenience init(context: NSManagedObjectContext, id: Int, firstName: String, lastName: String) {
        self.init(context: context)
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}
