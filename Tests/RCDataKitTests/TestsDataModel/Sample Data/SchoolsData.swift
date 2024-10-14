//
//  SchoolsData.swift
//  

import CoreData
import Foundation
import RCDataKit

struct SchoolsData: Decodable {
    var students: [StudentImport]
    var teachers: [TeacherImport]
    var schools: [SchoolImport]
    
    init() throws {
        self = try Self.build()
    }
    
    private static func build() throws -> SchoolsData {
        let url = Bundle.module.url(forResource: "SchoolsData", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(SchoolsData.self, from: data)
        return decoded
    }
}
