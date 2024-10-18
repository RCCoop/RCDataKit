//
//  ModelKey.swift
//  RCDataKit
//
//  Created by Ryan Linn on 10/17/24.
//

import CoreData
import RCDataKit

enum ModelKey: ManagedModelFile {
    static var bundle: Bundle { .module }
    
    static var modelName: String { "TestModel" }
    
    static var model: NSManagedObjectModel = {
        guard let res = NSManagedObjectModel.named(modelName, in: bundle) else {
            fatalError("Failed to create Model \(modelName)")
        }
        return res
    }()
}
