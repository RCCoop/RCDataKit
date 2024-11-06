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
        if let existingValue = self.value(forKey: keyPath.stringRepresentation) as? V,
           existingValue == value
        {
            return false
        } else {
            self.setValue(value, forKey: keyPath.stringRepresentation)
            return true
        }
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
        if let existingValue = self.value(forKey: keyPath.stringRepresentation) as? V,
           ((existingValue - minimumChange)...(existingValue + minimumChange)).contains(value)
        {
            return false
        } else {
            self.setValue(value, forKey: keyPath.stringRepresentation)
            return true
        }
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
    /// Adds an item to a to-many relation if that item isn't already present in the relation. Otherwise, the
    /// caller is left unchanged.
    ///
    /// - Parameters:
    ///   - keyPath: The KeyPath representing the relationship property.
    ///   - relation: The item to add into the relationship.
    ///
    /// - Returns: `true` if the new item was inserted into the relation.
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
    
    /// Adds an item to a to-many relation if that item isn't `nil`, and isn't already present in the relation.
    /// Otherwise, the caller is left unchanged.
    ///
    /// - Parameters:
    ///   - keyPath: The KeyPath representing the relationship property.
    ///   - relation: The item to add into the relationship.
    ///
    /// - Returns: `true` if the new item was inserted into the relation.
    @discardableResult
    func add<R>(
        _ keyPath: WritableKeyPath<Self, Set<R>>,
        relation: Optional<R>
    ) -> Bool {
        relation.map { add(keyPath, relation: $0) } ?? false
    }
    
    /// Adds all items in a collection into a to-many relation, as long as any of the collected items aren't already
    /// present in the relation. If all of the collection items are already present in the relation, the caller is
    /// left unchanged.
    ///
    /// - Parameters:
    ///   - keyPath: The KeyPath representing the relationship property.
    ///   - relation: The items to add into the relationship.
    ///
    /// - Returns: `true` if any new items were inserted into the relation.
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

    /// Removes an item from a to-many relation as long as the item is present in the relation to begin with.
    /// Otherwise, the caller is left unchanged.
    ///
    /// - Parameters:
    ///   - keyPath: The KeyPath representing the relationship property.
    ///   - relation: The item to remove from the relationship.
    ///
    /// - Returns: `true` if the item was present in the relation and was removed successfully.
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
    
    /// Removes an item from a to-many relation as long as the item is not `nil`, and is present in the
    /// relation to begin with. Otherwise, the caller is left unchanged.
    ///
    /// - Parameters:
    ///   - keyPath: The KeyPath representing the relationship property.
    ///   - relation: The item to remove from the relationship.
    ///
    /// - Returns: `true` if the item was present in the relation and was removed successfully.
    @discardableResult
    func remove<R>(
        _ keyPath: WritableKeyPath<Self, Set<R>>,
        relation: Optional<R>
    ) -> Bool {
        relation.map { remove(keyPath, relation: $0) } ?? false
    }    
}
