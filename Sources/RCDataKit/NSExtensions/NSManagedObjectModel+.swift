//
//  NSManagedObjectModel+.swift
//  RCDataKit
//
//  Created by Ryan Linn on 9/29/24.
//

import CoreData

extension NSManagedObjectModel {
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
    
    public convenience init?(
        bundle: Bundle = .main,
        modelName: String,
        versionName: String? = nil
    ) {
        let url: URL
        if let versionName {
            url = Self.modelVersionURL(bundle: bundle, modelName: modelName, versionName: versionName)
        } else {
            url = Self.modelURL(bundle: bundle, modelName: modelName)
        }
        self.init(contentsOf: url)
    }
}
