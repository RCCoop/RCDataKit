//
//  NSManagedObjectModel+.swift
//  RCDataKit
//
//  Created by Ryan Linn on 9/29/24.
//

import CoreData

extension NSManagedObjectModel {
    /// Returns the URL for the ManagedObjectModel file with a given name in the given bundle.
    ///
    /// - Parameters:
    ///   - bundle: The bundle where the xcdatamodeld file is located.
    ///   - modelName: The title of the xcdatamodeld file.
    ///
    /// - Returns: the file URL for the given model.
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
    
    /// Returns an initialized `NSManagedObjectModel` instance from a given xcdatamodeld file and
    /// a version of the model contained in it.
    ///
    /// - Parameters:
    ///   - modelName:    The title of the xcdatamodeld file.
    ///   - bundle:       The bundle in which to find the file.
    ///   - versionName:  The title of the version to use. If no version is specified, the file's default
    ///                   version is used.
    ///
    /// - Returns: An instance of `NSManagedObjectModel` if one can be created from the given parameters.
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
