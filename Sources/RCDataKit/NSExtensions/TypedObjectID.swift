//
//  TypedObjectID.swift
//  RCDataKit
//
//  Created by Ryan Linn on 11/24/24.
//

import CoreData

/// A wrapper around `NSManagedObjectID` that includes the `NSManagedObject` class type for Swift
/// type safety.
public struct TypedObjectID<T: NSManagedObject>: Sendable, Hashable {
    public let wrapped: NSManagedObjectID
    
    public init(_ object: T) {
        wrapped = object.objectID
    }
}

extension NSManagedObjectContext {
    /// Gets an existing object from the context using a `TypedObjectID`.
    public func existingObject<T: NSManagedObject>(with typedId: TypedObjectID<T>) throws -> T {
        try existing(T.self, withID: typedId.wrapped)
    }
}
