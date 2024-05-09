//
//  KeyPathString.swift
//

import CoreData
import Foundation

extension PartialKeyPath where Root: NSManagedObject {
    /// The string name of the KeyPath.
    ///
    /// The KeyPath must be either `@NSManaged` or `@objc` or there will be a fatalError.
    var stringRepresentation: String {
        guard let value = _kvcKeyPathString else {
            fatalError("Could not get string representation of keypath \(self). Keypath must be @NSManaged or @objc")
        }
        return value
    }
}
