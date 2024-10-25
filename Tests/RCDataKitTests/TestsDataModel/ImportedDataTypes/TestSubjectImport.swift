//
//  TestSubjectImport.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/23/24.
//

import CoreData
import Foundation
import RCDataKit

struct TestSubjectImport {
    var id: UUID
    var name: String
    var height: Double
    var score: Int
    var dateOfBirth: Date
    var isMale: Bool
}

extension TestSubjectImport: Persistable {
    func importIntoContext(
        _ context: NSManagedObjectContext,
        importerData: inout ()
    ) -> PersistenceResult {
        let subject = TestSubject(
            context: context,
            id: id,
            name: name,
            score: score,
            height: height,
            dateOfBirth: dateOfBirth,
            isMale: isMale
        )
        return .insert(subject.objectID)
    }
}
