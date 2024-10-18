//
//  NSManagedObjectModel+.swift
//  RCDataKit
//
//  Created by Ryan Linn on 9/29/24.
//

import CoreData

extension NSManagedObjectModel {
    /// <#Description#>
    /// - Parameters:
    ///   - bundle: <#bundle description#>
    ///   - modelName: <#modelName description#>
    /// - Returns: <#description#>
    public static func modelURL(
        bundle: Bundle = .main,
        modelName: String
    ) -> URL {
        bundle.url(forResource: modelName, withExtension: "momd")!
    }
    
    public static func modelVersionURL(
        bundle: Bundle = .main,
        modelName: String,
        versionName: String
    ) -> URL {
        modelURL(bundle: bundle, modelName: modelName)
            .appendingPathComponent(versionName + ".mom", conformingTo: .managedObjectModel)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - modelName: <#modelName description#>
    ///   - bundle: <#bundle description#>
    ///   - versionName: <#versionName description#>
    /// - Returns: <#description#>
    public static func named(
        _ modelName: String,
        in bundle: Bundle = .main,
        versionName: String? = nil
    ) -> NSManagedObjectModel? {
        let url: URL
        if let versionName {
            url = Self.modelVersionURL(bundle: bundle, modelName: modelName, versionName: versionName)
        } else {
            url = Self.modelURL(bundle: bundle, modelName: modelName)
        }
        
        return NSManagedObjectModel(contentsOf: url)
    }
}
