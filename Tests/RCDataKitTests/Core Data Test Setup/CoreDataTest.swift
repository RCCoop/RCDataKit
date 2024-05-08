//
//  CoreDataTest.swift
//

import CoreData
import XCTest

class CoreDataTest: XCTestCase {
    private lazy var model = NSManagedObjectModel.mergedModel(
      from: [Bundle(for: CoreDataTest.self)]
    )!

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
        
        let container = NSPersistentContainer(name: "Model", managedObjectModel: model)
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
