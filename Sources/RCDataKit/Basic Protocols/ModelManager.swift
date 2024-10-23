//
//  ModelManager.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/17/24.
//

import CoreData

/// <#Description#>
public protocol ModelManager {
    /// <#Description#>
    static var model: NSManagedObjectModel { get }
}

/// <#Description#>
/// represented by an `xcdatamodeld` file
public protocol ModelFileManager: ModelManager {
    /// <#Description#>
    static var bundle: Bundle { get }
    
    /// <#Description#>
    static var modelName: String { get }
}
