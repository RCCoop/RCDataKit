//
//  ManualModelCreation.swift
//

import CoreData

/// Not currently used, and not kept updated with TestModel.mom
/// Builds NSManagedObjectModel manually without a mom file.
/// Kept in here for reference purposes.

private func buildCoreDataModel() -> NSManagedObjectModel {
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
