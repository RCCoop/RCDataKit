//
//  TeacherImport.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/13/24.
//

import CoreData
import Foundation
import RCDataKit

struct TeacherImport: Decodable, Identifiable {
    var firstName: String
    var lastName: String
    var id: Int
}

extension TeacherImport: Persistable {
    func importIntoContext(_ context: NSManagedObjectContext, importerData: inout Void) -> PersistenceResult {
        let newTeach = Teacher(context: context, id: id, firstName: firstName, lastName: lastName)
        return .insert(newTeach.objectID)
    }
}
