//
//  NSSortDescriptor+.swift
//

import CoreData
import Foundation

extension NSSortDescriptor {
    public static func ascending<T, K>(
        _ keyPath: KeyPath<T, K>
    ) -> NSSortDescriptor
    where T: NSManagedObject,
          K: Comparable
    {
        NSSortDescriptor(keyPath: keyPath, ascending: true)
    }
    
    public static func ascending<T, K>(
        _ keyPath: KeyPath<T, K?>
    ) -> NSSortDescriptor
    where T: NSManagedObject,
          K: Comparable
    {
        NSSortDescriptor(keyPath: keyPath, ascending: true)
    }

    public static func descending<T, K>(
        _ keyPath: KeyPath<T, K>
    ) -> NSSortDescriptor
    where T: NSManagedObject,
          K: Comparable
    {
        NSSortDescriptor(keyPath: keyPath, ascending: false)
    }

    public static func descending<T, K>(
        _ keyPath: KeyPath<T, K?>
    ) -> NSSortDescriptor
    where T: NSManagedObject,
          K: Comparable
    {
        NSSortDescriptor(keyPath: keyPath, ascending: false)
    }
}
