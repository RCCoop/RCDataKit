//
//  ManagedObjectClasses.swift
//

import CoreData
import Foundation
import RCDataKit

/// Abstract Entity to encompass Student and Teacher
@objc(Person)
class Person: NSManagedObject, Updatable {
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var id: Int
    
    var fullName: String {
        firstName + " " + lastName
    }
    
    convenience init(context: NSManagedObjectContext, id: Int, firstName: String, lastName: String) {
        self.init(context: context)
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
    }
}

@objc(Student)
class Student: Person {
    @NSManaged var school: School?
    
    static func studentRequest() -> NSFetchRequest<Student> {
        NSFetchRequest<Student>(entityName: "Student")
    }
}

@objc(Teacher)
class Teacher: Person {
    @NSManaged var schools: Set<School>
    
    static func teacherRequest() -> NSFetchRequest<Teacher> {
        NSFetchRequest<Teacher>(entityName: "Teacher")
    }
}

@objc(School)
class School: NSManagedObject, Updatable {
    @NSManaged var name: String
    @NSManaged var id: String
    @NSManaged var teacher: Teacher?
    @NSManaged var students: Set<Student>
    
    static func schoolRequest() -> NSFetchRequest<School> {
        NSFetchRequest<School>(entityName: "School")
    }
    
    convenience init(context: NSManagedObjectContext, id: String, name: String) {
        self.init(context: context)
        self.id = id
        self.name = name
    }
}

// MARK: - The Model

/// Not currently used. Builds NSManagedObjectModel manually without a mom file.
/*
func buildCoreDataModel() -> NSManagedObjectModel {
    // Student
    let studentEntity = NSEntityDescription()
    studentEntity.name = "Student"
    studentEntity.managedObjectClassName = "Student"
    
    // Teacher
    let teacherEntity = NSEntityDescription()
    teacherEntity.name = "Teacher"
    teacherEntity.managedObjectClassName = "Teacher"
    
    // Person
    let personEntity = NSEntityDescription()
    personEntity.name = "Person"
    personEntity.managedObjectClassName = "Person"
    personEntity.isAbstract = true
    let firstNameAttribute = NSAttributeDescription()
    firstNameAttribute.name = "firstName"
    firstNameAttribute.attributeType = .stringAttributeType
    personEntity.properties.append(firstNameAttribute)
    let lastNameAttribute = NSAttributeDescription()
    lastNameAttribute.name = "lastName"
    lastNameAttribute.attributeType = .stringAttributeType
    personEntity.properties.append(lastNameAttribute)
    let personIdAttribute = NSAttributeDescription()
    personIdAttribute.name = "id"
    personIdAttribute.attributeType = .integer64AttributeType
    personEntity.properties.append(personIdAttribute)
    
    personEntity.subentities = [studentEntity, teacherEntity]
    
    // Course
    let schoolEntity = NSEntityDescription()
    schoolEntity.name = "School"
    schoolEntity.managedObjectClassName = "School"
    let schoolIdAttribute = NSAttributeDescription()
    schoolIdAttribute.name = "id"
    schoolIdAttribute.attributeType = .stringAttributeType
    schoolEntity.properties.append(schoolIdAttribute)
    let titleAttribute = NSAttributeDescription()
    titleAttribute.name = "name"
    titleAttribute.attributeType = .stringAttributeType
    schoolEntity.properties.append(titleAttribute)
    
    // Relationships
    let studentSchoolAttribute = NSRelationshipDescription()
    studentSchoolAttribute.name = "school"
    studentSchoolAttribute.destinationEntity = schoolEntity
    studentEntity.properties.append(studentSchoolAttribute)
    
    let teacherSchoolAttribute = NSRelationshipDescription()
    teacherSchoolAttribute.name = "school"
    teacherSchoolAttribute.destinationEntity = schoolEntity
    teacherEntity.properties.append(teacherSchoolAttribute)
    
    let schoolStudentsAttribute = NSRelationshipDescription()
    schoolStudentsAttribute.name = "students"
    schoolStudentsAttribute.destinationEntity = studentEntity
    schoolEntity.properties.append(schoolStudentsAttribute)
    
    let schoolTeacherAttribute = NSRelationshipDescription()
    schoolTeacherAttribute.name = "teacher"
    schoolTeacherAttribute.maxCount = 1
    schoolTeacherAttribute.destinationEntity = teacherEntity
    schoolEntity.properties.append(schoolTeacherAttribute)
    
    studentSchoolAttribute.inverseRelationship = schoolStudentsAttribute
    schoolStudentsAttribute.inverseRelationship = studentSchoolAttribute
    teacherSchoolAttribute.inverseRelationship = schoolTeacherAttribute
    schoolTeacherAttribute.inverseRelationship = teacherSchoolAttribute
    
    // Model
    let model = NSManagedObjectModel()
    model.entities = [personEntity, studentEntity, teacherEntity, schoolEntity]
    
    return model
}
*/
