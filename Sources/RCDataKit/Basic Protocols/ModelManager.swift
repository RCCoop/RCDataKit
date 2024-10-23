//
//  ModelManager.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/17/24.
//

import CoreData

/// A type that is used to provide a definition of a `NSManagedObjectModel`.
///
/// On its own, `ModelManager` isn't used anywhere yet, but a sub-protocol, `ModelFileManager`,
/// has many uses. See that protocol for more info.
public protocol ModelManager {
    /// The only requirement for `ModelManager` is to create and store an instance of
    /// `NSManagedObjectModel`.
    ///
    /// This should be a stored property, since creating multiple `NSManagedObjectModel` instances
    /// with the same model causes errors in Core Data.
    static var model: NSManagedObjectModel { get }
}

/// A `ModelManager` that represents a xcdatamodeld file defining a Core Data `NSManagedObjectModel`.
///
/// Defining a type that conforms to `ModelFileManager` allows the type to be used in other types throughout
/// this package to simplify data stack creation.
public protocol ModelFileManager: ModelManager {
    /// The bundle in which to find the xcdatamodeld file represented by this type.
    static var bundle: Bundle { get }
    
    /// The title of the xcdatamodeld file represented by this type.
    static var modelName: String { get }
}
