//
//  KidsTests.swift
//  
//
//  Created by Ryan Linn on 5/9/24.
//

import CoreData
import XCTest

class KidsTests: CoreDataTest {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        _ = Student(context: viewContext, id: 0, firstName: "Bart", lastName: "Simpson")
        _ = Student(context: viewContext, id: 1, firstName: "Lisa", lastName: "Simpson")
        _ = Student(context: viewContext, id: 2, firstName: "Maggie", lastName: "Simpson")
        _ = Student(context: viewContext, id: 3, firstName: "Eric", lastName: "Cartman")
        _ = Student(context: viewContext, id: 4, firstName: "Stan", lastName: "Marsh")
        _ = Student(context: viewContext, id: 5, firstName: "Kyle", lastName: "Broflovski")
        _ = Student(context: viewContext, id: 6, firstName: "Kenny", lastName: "McCormick")
        _ = Student(context: viewContext, id: 7, firstName: "Tina", lastName: "Belcher")
        _ = Student(context: viewContext, id: 8, firstName: "Gene", lastName: "Belcher")
        _ = Student(context: viewContext, id: 9, firstName: "Louise", lastName: "Belcher")

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
