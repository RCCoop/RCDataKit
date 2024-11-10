//
//  SwiftUI+DataStack.swift
//  RCDataKit
//
//  Created by Ryan Linn on 11/10/24.
//

import SwiftUI

extension View {
    /// Adds the `DataStack` to the View's environment.
    ///
    /// This call includes adding the `DataStack`'s `viewContext` to the View environment, so child views
    /// can access both or either the `DataStack` and/or `managedObjectContext` through the following
    /// variable declarations:
    ///
    /// ```swift
    /// struct MyView: View {
    ///     // Get the DataStack's viewContext:
    ///     @Environment(\.managedObjectContext) var context
    ///
    ///     // Get the DataStack
    ///     @EnvironmentDataStack var dataStack
    /// }
    /// ```
    public func dataStackEnvironment(_ stack: any DataStack) -> some View {
        self
            .environment(\.dataStack, stack)
            .environment(\.managedObjectContext, stack.viewContext)
    }
}

/// A property wrapper that accesses a `DataStack` from the view environment.
///
/// You must set the `DataStack` into the environment in a parent view to be able to access this environment
/// variable this way. Otherwise, attempting to access `EnvironmentDataStack` will cause a fatal error.
///
/// ```swift
/// struct ParentView: View {
///     var dataStack: MyDataStack
///
///     var body: some View {
///         ChildView()
///             .dataStackEnvironment(dataStack)
///     }
/// }
///
/// struct ChildView: View {
///     // accesses ParentView.dataStack as (any DataStack)
///     @EnvironmentDataStack var dataStack
///
///     // accesses ParentView.dataStack.viewContext
///     @Environment(\.managedObjectContext) var viewContext
///
///     var body: some View {
///         Text("Hello World")
///     }
/// }
/// ```
@propertyWrapper public struct EnvironmentDataStack: DynamicProperty {
    @Environment(\.dataStack) var env: (any DataStack)?
    
    public init() {
        _env = Environment(\.dataStack)
    }
    
    public var wrappedValue: any DataStack {
        if let env {
            return env
        } else {
            fatalError("Attempted to access environment DataStack, but none was found")
        }
    }
}

fileprivate extension EnvironmentValues {
    var dataStack: (any DataStack)? {
        get { self[DataStackKey.self] }
        set { self[DataStackKey.self] = newValue }
    }
}

fileprivate struct DataStackKey: EnvironmentKey {
    static let defaultValue: (any DataStack)? = nil
}
