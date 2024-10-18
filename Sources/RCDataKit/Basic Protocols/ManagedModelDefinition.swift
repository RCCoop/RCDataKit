//
//  ManagedModelDefinition.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/17/24.
//

import CoreData

/// <#Description#>
public protocol ManagedModelDefinition {
    /// <#Description#>
    static var model: NSManagedObjectModel { get }
}

/// <#Description#>
public protocol ManagedModelFile: ManagedModelDefinition {
    /// <#Description#>
    static var bundle: Bundle { get }
    
    /// <#Description#>
    static var modelName: String { get }
}
