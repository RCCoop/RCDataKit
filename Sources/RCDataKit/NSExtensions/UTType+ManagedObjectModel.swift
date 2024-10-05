//
//  UTType+ManagedObjectModel.swift
//  RCDataKit
//
//  Created by Ryan Linn on 9/29/24.
//

import UniformTypeIdentifiers

extension UTType {
    public static var managedObjectModel: UTType {
        UTType(tag: "mom", tagClass: .filenameExtension, conformingTo: nil)!
    }
}
