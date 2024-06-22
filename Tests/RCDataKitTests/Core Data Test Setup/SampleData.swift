//
//  SampleData.swift
//  

import Foundation

struct SampleData: Decodable {
    struct Student: Decodable {
        var firstName: String
        var lastName: String
        var id: Int
        var school: String
    }
    
    struct Teacher: Decodable {
        var firstName: String
        var lastName: String
        var id: Int
    }
    
    struct School: Decodable {
        var teacher: Int
        var name: String
        var id: String
    }
    
    var students: [Student]
    var teachers: [Teacher]
    var schools: [School]
    
    static func build() throws -> SampleData {
        let url = Bundle.module.url(forResource: "SampleData", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(SampleData.self, from: data)
        return decoded
    }
}
