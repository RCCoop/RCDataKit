//
//  TestSubject.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/23/24.
//

import CoreData
import RCDataKit

@objc(TestSubject)
class TestSubject: NSManagedObject, Updatable {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var height: Double
    @NSManaged var score: Int
    @NSManaged var dateOfBirth: Date
    @NSManaged var isMale: Bool
    
    convenience init(
        context: NSManagedObjectContext,
        id: UUID,
        name: String,
        score: Int,
        height: Double,
        dateOfBirth: Date,
        isMale: Bool
    ) {
        self.init(context: context)
        self.id = id
        self.name = name
        self.height = height
        self.score = score
        self.dateOfBirth = dateOfBirth
        self.isMale = isMale
    }
    
    static func fetchRequest() -> NSFetchRequest<TestSubject> {
        NSFetchRequest(entityName: "TestSubject")
    }
    
    static func dob(from string: String) -> Date? {
        let parseStrategy = Date.ParseStrategy(format: "\(month: .twoDigits)/\(day: .twoDigits)/\(year: .defaultDigits)", timeZone: .current)
        let res = try? Date(string, strategy: parseStrategy)
        return res
    }
}

