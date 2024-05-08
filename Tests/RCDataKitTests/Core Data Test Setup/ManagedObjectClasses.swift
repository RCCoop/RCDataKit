//
//  ManagedObjectClasses.swift
//

import CoreData
import Foundation

/// Abstract Entity to encompass Student and Teacher
@objc(Person)
class Person: NSManagedObject {
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var id: Int
}

@objc(Student)
class Student: Person {
    @NSManaged var courses: Set<Course>
}

@objc(Teacher)
class Teacher: Person {
    @NSManaged var courses: Set<Course>
}

@objc(Course)
class Course: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var id: String
    @NSManaged var isFull: Bool
    @NSManaged var teacher: Teacher
    @NSManaged var students: Set<Student>
}

// MARK: - The Model

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
    let courseEntity = NSEntityDescription()
    courseEntity.name = "Course"
    courseEntity.managedObjectClassName = "Course"
    let courseIdAttribute = NSAttributeDescription()
    courseIdAttribute.name = "id"
    courseIdAttribute.attributeType = .stringAttributeType
    courseEntity.properties.append(courseIdAttribute)
    let titleAttribute = NSAttributeDescription()
    titleAttribute.name = "title"
    titleAttribute.attributeType = .stringAttributeType
    courseEntity.properties.append(titleAttribute)
    let isFullAttribute = NSAttributeDescription()
    isFullAttribute.name = "isFull"
    isFullAttribute.attributeType = .booleanAttributeType
    isFullAttribute.isOptional = false
    isFullAttribute.defaultValue = false
    courseEntity.properties.append(isFullAttribute)
    
    // Relationships
    let studentClassesAttribute = NSRelationshipDescription()
    studentClassesAttribute.name = "courses"
    studentClassesAttribute.destinationEntity = courseEntity
    studentEntity.properties.append(studentClassesAttribute)
    
    let teacherClassAttribute = NSRelationshipDescription()
    teacherClassAttribute.name = "courses"
    teacherClassAttribute.destinationEntity = courseEntity
    teacherEntity.properties.append(teacherClassAttribute)
    
    let courseStudentsAttribute = NSRelationshipDescription()
    courseStudentsAttribute.name = "students"
    courseStudentsAttribute.destinationEntity = studentEntity
    courseEntity.properties.append(courseStudentsAttribute)
    
    let courseTeacherAttribute = NSRelationshipDescription()
    courseTeacherAttribute.name = "teacher"
    courseTeacherAttribute.destinationEntity = teacherEntity
    courseTeacherAttribute.maxCount = 1
    courseEntity.properties.append(courseTeacherAttribute)
    
    studentClassesAttribute.inverseRelationship = courseStudentsAttribute
    courseStudentsAttribute.inverseRelationship = studentClassesAttribute
    teacherClassAttribute.inverseRelationship = courseTeacherAttribute
    courseTeacherAttribute.inverseRelationship = teacherClassAttribute
    
    // Model
    let model = NSManagedObjectModel()
    model.entities = [personEntity, studentEntity, teacherEntity, courseEntity]
    
    return model
}
