//
//  KidsTests.swift
//  

import CoreData
import XCTest

class KidsTests: CoreDataTest {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let sampleData = try SampleData.build()
        for student in sampleData.students {
            _ = Student(
                context: viewContext,
                id: student.id,
                firstName: student.firstName,
                lastName: student.lastName)
        }

        try viewContext.save()
    }

    var simpsonsPredicate: NSPredicate {
        NSPredicate(format: "%K == 'Simpson'", #keyPath(Student.lastName))
    }
    
    var bobsPredicate: NSPredicate {
        NSPredicate(format: "%K == 'Belcher'", #keyPath(Student.lastName))
    }
    
    var southParkPredicate: NSPredicate {
        NSPredicate(format: "%K BETWEEN %@", #keyPath(Student.id), [3, 6])
    }
    
    var sortById: [NSSortDescriptor] {
        [NSSortDescriptor(key: "id", ascending: true)]
    }
    
}
