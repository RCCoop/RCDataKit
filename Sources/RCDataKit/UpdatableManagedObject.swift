//
//  UpdatableManagedObject.swift
//

import CoreData
import Foundation

/// There are no requirements for the `Updatable` protocol except that it be implemented by subclasses
/// of `NSManagedObject`. Implementing this protocol allows the `NSManagedObject` subclass to use
/// various `update` functions that are implemented in a default extension.
public protocol Updatable: NSManagedObject {}

// MARK: - Single Value Property Updaters

public extension Updatable {
    /// Sets the value of a given property only if the current value is different from the value to set.
    ///
    /// - Parameters:
    ///   - keyPath: The KeyPath of a property to write to.
    ///   - value: The final value of that the property will be set to.
    ///
    /// - Returns: True if the value was written to.
    ///
    /// Use this function to set property values but avoid triggering the `NSManagedObject`'s `isUpdated`
    /// setter when the final value would have remained the same.
    @discardableResult
    func update<V>(
        _ keyPath: WritableKeyPath<Self, V>,
        value: V
    ) -> Bool
    where V: Equatable
    {
        guard self[keyPath: keyPath] != value else {
            return false
        }
        var writableSelf = self
        writableSelf[keyPath: keyPath] = value
        return true
    }
    
    /// Sets the value of a given property only if the current value is different from the value to set, and the
    /// value to set is not `nil`.
    ///
    /// - Parameters:
    ///   - keyPath: The KeyPath of a property to write to.
    ///   - value: The final value of that the property will be set to.
    ///
    /// - Returns: True if the value was written to.
    ///
    /// Use this function to set property values but avoid triggering the `NSManagedObject`'s `isUpdated`
    /// setter when the final value would have remained the same, OR when you want to update a property
    /// without setting it to `nil`.
    @discardableResult
    func updateIfAvailable<V>(
        _ keyPath: WritableKeyPath<Self, V>,
        value: Optional<V>)
    -> Bool
    where V: Equatable
    {
        value.map { update(keyPath, value: $0) } ?? false
    }
    
    /// Sets the value of a given property only if the current value is not within a given threshold of the new value.
    ///
    /// - Parameters:
    ///   - keyPath: The KeyPath of a property to write to.
    ///   - value: The final value of that the property will be set to.
    ///   - minimumChange: The minimum change that will be allowed to the written property.
    ///
    /// - Returns: True if the value was written to.
    ///
    /// Use this function to set property values while ignoring changes that would not meet the given threshold.
    /// 
    /// For example, if a `Double` property is currently 1.0, and the new value would be set to `1.000001`,
    /// you could set an appropriate `minimumChange` to avoid making unneeded changes to the current
    /// value of the property.
    @discardableResult
    func update<V>(
        _ keyPath: WritableKeyPath<Self, V>,
        value: V,
        minimumChange: V) -> Bool
    where V: Numeric & Comparable
    {
        let existingValue = self[keyPath: keyPath]
        let range = (existingValue - minimumChange)...(existingValue + minimumChange)
        guard !range.contains(value) else {
            return false
        }
        var writableSelf = self
        writableSelf[keyPath: keyPath] = value
        return true
    }
    
    /// Sets the value of a given property only if the current value is not within a given threshold of the new 
    /// value, and the new value is not `nil`.
    ///
    /// - Parameters:
    ///   - keyPath: The KeyPath of a property to write to.
    ///   - value: The final value of that the property will be set to.
    ///   - minimumChange: The minimum change that will be allowed to the written property.
    ///
    /// - Returns: True if the value was written to.
    ///     
    /// Use this function to set property values while ignoring changes that would not meet the given threshold,
    /// or those that would result in a `nil` value.
    ///
    /// For example, if a `Double` property is currently 1.0, and the new value would be set to `1.000001`,
    /// you could set an appropriate `minimumChange` to avoid making unneeded changes to the current
    /// value of the property.
    @discardableResult
    func updateIfAvailable<V>(
        _ keyPath: WritableKeyPath<Self, V>,
        value: Optional<V>,
        minimumChange: V
    ) -> Bool
    where V: Numeric & Comparable
    {
        value.map { update(keyPath, value: $0, minimumChange: minimumChange) } ?? false
    }
}

// MARK: - To-Many Relation Updaters

public extension Updatable {
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - keyPath: <#keyPath description#>
    ///   - relation: <#relation description#>
    ///
    /// - Returns: <#description#>
    @discardableResult
    func add<R>(
        _ keyPath: WritableKeyPath<Self, Set<R>>,
        relation: R
    ) -> Bool {
        guard !self[keyPath: keyPath].contains(relation) else {
            return false
        }
        var writableSelf = self
        writableSelf[keyPath: keyPath].insert(relation)
        return true
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - keyPath: <#keyPath description#>
    ///   - relation: <#relation description#>
    ///
    /// - Returns: <#description#>
    @discardableResult
    func add<R>(
        _ keyPath: WritableKeyPath<Self, Set<R>>,
        relation: Optional<R>
    ) -> Bool {
        relation.map { add(keyPath, relation: $0) } ?? false
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - keyPath: <#keyPath description#>
    ///   - relation: <#relations description#>
    ///
    /// - Returns: <#description#>
    @discardableResult
    func add<R, C>(
        _ keyPath: WritableKeyPath<Self, Set<R>>,
        relation: C
    ) -> Bool
    where C: Collection, C.Element == R
    {
        let toAdd = Set(relation).subtracting(self[keyPath: keyPath])
        guard !toAdd.isEmpty else {
            return false
        }
        var writableSelf = self
        writableSelf[keyPath: keyPath].formUnion(toAdd)
        return true
    }

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - keyPath: <#keyPath description#>
    ///   - relation: <#relation description#>
    ///
    /// - Returns: <#description#>
    @discardableResult
    func remove<R>(
        _ keyPath: WritableKeyPath<Self, Set<R>>,
        relation: R
    ) -> Bool {
        guard self[keyPath: keyPath].contains(relation) else {
            return false
        }
        var writableSelf = self
        writableSelf[keyPath: keyPath].remove(relation)
        return true
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - keyPath: <#keyPath description#>
    ///   - relation: <#relation description#>
    ///
    /// - Returns: <#description#>
    @discardableResult
    func remove<R>(
        _ keyPath: WritableKeyPath<Self, Set<R>>,
        relation: Optional<R>
    ) -> Bool {
        relation.map { remove(keyPath, relation: $0) } ?? false
    }    
}
