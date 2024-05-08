//
//  CoreDataTest.swift
//

import CoreData
import XCTest

class CoreDataTest: XCTestCase {
    private var container: NSPersistentContainer!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try makePersistentContainer()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        // TODO: remove all data of all types from container
        /*
         container.viewContext.deleteAll(Note.self)
         container.viewContext.deleteAll(User.self)
         container.viewContext.deleteAll(UserAccount.self)
         container.viewContext.deleteAll(Profile.self)
         container.viewContext.deleteAll(BillingInfo.self)
         */
        container = nil
    }
}

private extension CoreDataTest {
    func makePersistentContainer() throws -> NSPersistentContainer {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        
        let container = NSPersistentContainer(name: "Model", managedObjectModel: buildCoreDataModel())
        container.persistentStoreDescriptions = [description]
        
        var loadingError: Error?
        container.loadPersistentStores { description, error in
            loadingError = error
        }
        
        if let loadingError {
            throw loadingError
        }
        
        return container
    }
}

// MARK: - Test Setup Helpers

internal extension CoreDataTest {
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    func studentFetchRequest() -> NSFetchRequest<Student> {
        NSFetchRequest(entityName: "Student")
    }
    
    func teacherFetchRequest() -> NSFetchRequest<Teacher> {
        NSFetchRequest(entityName: "Teacher")
    }

    func insertStudents(_ students: (id: Int, firstName: String, lastName: String)...) throws -> [Student] {
        let ctx = container.viewContext
        let result = students.map { one in
            let storedStudent = NSEntityDescription.insertNewObject(forEntityName: "Student", into: ctx) as! Student
            storedStudent.firstName = one.firstName
            storedStudent.lastName = one.lastName
            storedStudent.id = one.id
            return storedStudent
        }
        
        try ctx.save()
        return result
    }
}
