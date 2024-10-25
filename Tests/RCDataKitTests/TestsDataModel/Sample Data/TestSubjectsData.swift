//
//  TestSubjectsData.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/23/24.
//

import Foundation

struct TestSubjectsData {
    var subjects: [TestSubjectImport]
    
    init() throws {
        let fileURL: URL = Bundle.module.url(forResource: "TestSubjects", withExtension: "csv")!
        
        let fileString = try String(contentsOf: fileURL, encoding: .utf8)
        let rows = fileString.components(separatedBy: .newlines)
        let people = rows.dropFirst()
            .map { $0.components(separatedBy: ",") }
            .compactMap { oneRow -> TestSubjectImport? in
                guard oneRow.count == 6 else {
                    return nil
                }
                return TestSubjectImport(
                    id: UUID(uuidString: oneRow[0])!,
                    name: oneRow[1],
                    height: Double(oneRow[2])!,
                    score: Int(oneRow[3])!,
                    dateOfBirth: TestSubject.dob(from: oneRow[4])!,
                    isMale: oneRow[5] == "1")
            }
        self.subjects = people
    }
}
