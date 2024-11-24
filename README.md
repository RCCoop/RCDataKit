# 🛠️ RCDataKit 💾

![GitHub](https://img.shields.io/github/license/RCCoop/RCDataKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRCCoop%2FRCDataKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/RCCoop/RCDataKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FRCCoop%2FRCDataKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/RCCoop/RCDataKit)

Helpful tools for Core Data

## Contents
- [What Is It?](#what-is-it)
- [Installation](#installation)
- [Creating a Data Stack](#creating-a-data-stack)
    - [DataStack Protocol](#datastack-protocol)
        - [Default DataStack Implementations](#default-datastack-implementations)
    - [Helper Types](#helper-types)
        - [TransactionAuthor](#transactionauthor)
        - [ModelManager and ModelFileManager Protocols](#modelmanager-and-modelfilemanager-protocols)
        - [ModelVersion Protocol](#modelversion-protocol)
        - [PersistentHistoryTracker actor](#persistenthistorytracker-actor)
        - [SwiftUI Integration](#swiftui-integration)
- [CRUD Helpers](#crud-helpers)
    - [Typed NSManagedObjectID](#typed-nsmanagedobjectid)
    - [Updatable Protocol](#updatable-protocol)
    - [Persistable Protocol](#persistable-protocol)
    - [NSManagedObjectContext Helpers](#nsmanagedobjectcontext-helpers)
    - [NSFetchRequest Helpers](#nsfetchrequest-helpers)
    - [NSPredicate Helpers](#nspredicate-helpers)
- [Further Plans](#further-plans)
- [Contribution/Feedback](#contributionfeedback)

## What Is It?

Core Data is a big and powerful tool, but it has never felt to me that it’s easy to learn. I’ve been using it heavily for years, and I still get confused when I try to do new things with it. **RCDataKit** is a collection of helper tools I’ve made over the years to make Core Data development and learning just a little easier.

**RCDataKit** is a work in progress, and I’m intentionally keeping it fairly simple so that beginners can hopefully learn from it by browsing the source code. If you want something a lot more powerful, check out these really great libraries:

- [JohnEstropia/CoreStore](https://github.com/JohnEstropia/CoreStore)
- [ftchirou/PredicateKit](https://github.com/ftchirou/PredicateKit)
- [jessesquires/JSQCoreDataKit](https://github.com/jessesquires/JSQCoreDataKit/tree/main)

#### Why Not Just Use SwiftData?

Sure. Core Data is old and can be annoying to work with, and may be replaced permanently by SwiftData some day. But for now, I’m still using Core Data in my own projects because SwiftData just doesn’t work as well as I want it to. Until it’s got a lot of bugs worked out, I’ll keep working with the tried and true tool, even if it’s sometimes frustrating and difficult to learn.

## Installation

### Requirements

- Minimum:
    - iOS/tvOS/Catalyst: 15+
    - macOS: 12+
    - watchOS: 8+
- Added Support for Staged Model Migrations:
    - iOS/tvOS/Catalyst 17+
    - macOS: 14+
    - watchOS: 10+

### Swift Package Manager

In your own Package, add the following to your dependencies:

```swift
dependencies: [
  .package(url: "https://github.com/RCCoop/RCDataKit", .upToNextMajor(from: "0.1.0"))
]
```

Or add the package to your Xcode project with `File -> Add Package Dependencies...`

# Creating a Data Stack

**RCDataKit** has a few pre-made solutions for setting up your Core Data stack. They’re not required for use with any of the other types in the library, but they do most of the setup work for you.

## DataStack Protocol
This simple protocol is for types that wrap a `NSPersistentContainer` and  provide pre-configured `NSManagedObjectContexts`.

```swift
let myStack: DataStack

// Get the viewContext -- a NSManagedObjectContext where
// transactionAuthor == myStack.mainContextAuthor.name
let viewContext = myStack.viewContext

// Get a background context where transactionAuthor == TransactionAuthor.cloudDataImport.name
let bgContext = myStack.backgroundContext(author: .cloudDataImport)
```

### Default DataStack Implementations

There are a few pre-made implementations of `DataStack` available here:

- **BasicDataStack** is a SQLite-backed stack with a single store, and initialization options for Persistent History Tracking and Staged Migrations.
- **PreviewStack** is an in-memory store for use in SwiftUI previews or other non-persisted environments.
- **TestingStack** is stored in a temporary directory so you can use it in test cases. (I've found that in-memory stores during test cases can have unpredictable exceptions that file-backed storage doesn't. Also, I've found that running test cases in parallel with stacks using the same `NSManagedObjectModel` often throw exceptions, so it's best to run these tests serially rather than concurrently.)

## Helper Types

### TransactionAuthor
A simple type to keep track of the different context authors in your Persistent Store. This does nothing by itself, but is used in `DataStack` and `PersistentHistoryTracker` standardize your author titles.

An easy way to set this up is to make an extension for `TransactionAuthor` to make a pre-set list of authors-- one for each main-thread context that accesses your data store (the app's view context, a widget's context, etc.), and as many named background contexts as you like to keep track of who or what is writing to your store.

```swift
extension TransactionAuthor {
    static var iOSViewContext: TransactionAuthor { "iOSViewContext" }
    static var extensionContext: TransactionAuthor { "extensionContext" }
    static var networkSync: TransactionAuthor { "networkSync" }
    static var localEditing: TransactionAuthor { "localEditing" }
}
```

### ModelManager and ModelFileManager Protocols

These two paired protocols (mostly `ModelFileManager`, which inherits from `ModelManager`) are required by several other parts of this library to automate some of the boilerplate in creating a `NSManagedObjectModel`. The `ModelFileManager` represents the `.xcdatamodeld` file that most of us use to create our managed object model.

Defining a `ModelFileManager` is simple:

```swift
enum TestModelFile: ModelFileManager {
    static var bundle: Bundle {
        .main // or use .module if your model file is in a separate module
    }
    
    static var modelName: String {
        "TestModel"
    }
    
    static let model: NSManagedObjectModel = {
        // Use one of RCDataKit's convenience methods to create the model:
        NSManagedObjectModel.named(modelName, in: bundle)
    }()
}
```

Then you can use your `ModelFileManager` type in initializers for `BasicDataStack` and `PreviewStack`, and in your `ModelVersion` protocol implementation.

### ModelVersion Protocol

Migrating your Model from one version to the next can be a huge pain— Lightweight Migrations are easy enough, but Custom Migrations not so much. But now we have [Staged Migrations](https://developer.apple.com/videos/play/wwdc2022/10120/)! Unfortunately, [Apple’s documentation](https://developer.apple.com/documentation/coredata/staged_migrations) is lacking. Thanks to [Pol Piela](https://www.polpiella.dev/staged-migrations) and [FatBobMan](https://fatbobman.com/en/posts/what-s-new-in-core-data-in-wwdc23/) for picking up the slack.

With the `ModelVersion` protocol, setting up staged migrations takes a lot less boilerplate code, so you can do the important work.

1. Make a type that conforms to the protocol, and make it reference the names of your model versions, and give it a `ModelFileManager` type:

<img width="160" alt="Screenshot_2024-09-15_at_10 24 58_AM" src="https://github.com/user-attachments/assets/9a42ca82-72c2-4c17-afa7-7bba80fa9f7a">

```swift
enum Versions: String, ModelVersion {
    typealias ModelFile = TestModelFile

    case v1 = "Model"
    case v2 = "Model2"
    case v3 = "Model3"
    case v4 = "Model4"
}
```

2. Create an array of migration stages to walk through your version upgrades:

```swift
extension Versions {
    static func migrationStages() -> [NSMigrationStage] {
        [
            v1.migrationStage(
                toStage: .v2,
                label: "Lightweight Migration: V1 to V2"),
            v2.migrationStage(
                toStage: .v3,
                label: "Custom Migration: V2 to V3",
                preMigration: { context in
                    // Do work before model is updated from v2 to v3
                } postMigration: { context in
                    // Do work after model is updated
                }),
            v3.migrationStage(
                toStage: .v4,
                label: "Lightweight Migration: V3 to V4")
        ]
    }
}
```

3. When creating your `NSPersistentContainer`, add a `NSStagedMigrationManager` to the description options:

```swift
let migrationManager = Versions.migrationManager()
container.persistentStoreDescriptions
    .first?
    .setOption(migrationManager, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
```

Alternately, just pass your `ModelVersion` into the initializer for `BasicDataStack`:

```swift
let stack = try BasicDataStack(
                    versionKey: Versions.self,
                    mainAuthor: .iOSViewContext)
```

### PersistentHistoryTracker actor

Persistent History Tracking is well-documented, but can still be very confusing. `PersistentHistoryTracker` is an actor that attaches to your `NSPersistentContainer` in order to manage all that tracking for you. It borrows very heavily from tutorials and projects by [Antoine Van Der Lee](https://www.avanderlee.com/swift/persistent-history-tracking-core-data/) and [FatBobMan](https://fatbobman.com/en/posts/persistenthistorytracking/) (especially FatBobMan’s [PersistentHistoryTrackingKit](https://github.com/fatbobman/PersistentHistoryTrackingKit/tree/main), thank you!), with some added helpers based on `TransactionAuthor`.

To begin tracking:

```swift
// Before loading your persistent store, set persistent history options:
let storeDescription = myPersistentContainer.persistentStoreDescriptions[0]
let trueOption = true as NSNumber
storeDescription.setOption(trueOption, forKey: NSPersistentHistoryTrackingKey)
storeDescription.setOption(trueOption, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

// Add a PersistentHistoryTracker to your container
self.tracker = PersistentHistoryTracker(
    container: myPersistentContainer,
    currentAuthor: .iOSViewContext)

// Start or stop monitoring as needed.
tracker.startMonitoring()
```

You can also enable tracking in `BasicDataStack` by passing in an instance of `PersistentHistoryTrackingOptions` to the initializer:

```swift
let stack = try BasicDataStack(
                    versionKey: Versions.self,
                    mainAuthor: .iOSViewContext,
                    persistentHistoryOptions: .init())

stack.historyTracker?.startMonitoring()
```

### SwiftUI Integration

You can add your `DataStack` and its `viewContext` to the SwiftUI environment in a single call:

```swift
struct MyView: View {
    var myStack: MyDataStack
    
    var body: some View {
        SubView()
            .dataStackEnvironment(myStack)
    }
}
```

The `.dataStackEnvironment(_:)` call wraps `.environment(_:,_:)` calls for both the DataStack and ManagedObjectContext, so you can access either environment value with the following property wrappers:

```swift
struct SubView: View {
    /// This is a NSManagedObjectContext accessed by `myStack.viewContext`
    @Environment(\.managedObjectContext) var context
    
    /// This is a (any DataStack)? equal to `myStack` from MyView.
    @EnvironmentDataStack var dataStack
    
    var body: some View { ... }
}
```

You must set the DataStack into a view's environment using the `dataStackEnvironment(_:)` call in order to use the `@EnvironmentDataStack` property wrapper, or it will cause a fatal error.

# CRUD Helpers

### Typed NSManagedObjectID

Use `TypedObjectID` in place of `NSManagedObjectID` anywhere that you want to enforce type safety around the ID. Because both `NSManagedObjectID` and the `TypedObjectID` wrapper are `Sendable`, they are the best way to send references to `NSManagedObject` between contexts.
```swift
let viewContextPerson = Person(...) // get a person on the ViewContext
let personId = TypedObjectID(viewContextPerson.objectID) // personId refers only to Person type

try backgroundContext.perform {
    // get a reference to the same Person from storage, but safe for this context:
    let backgroundContextPerson = try backgroundContext.existingObject(with: personId)
}
```

### Updatable Protocol

Add the `Updatable` protocol to your Model types to get some free functions. Protocol conformance has no requirements except that the implementing type is a `NSManagedObject` subclass.
```swift
let rc = Person(...)

rc.update(\.age, value: 15) // now I'm 15 years old!
rc.updateIfAvailable(\.age, value: nil) // still 15, not nil!
rc.update(\.age, value: 16, minimumChange: 2) // still 15, because I only want to age in 2-year increments.

rc.add(\.friend, relation: dan) // dan is now my friend
rc.add(\.friend, relation: nil) // nothing happens, because nobody's there.
rc.remove(\.friend, relation: dan) // dan's not my friend anymore.
```

Why bother with these, rather than `rc.age = 15`, or `rc.friend = dan`? Because if I’m already 15, or if Dan is already my friend, using the `=` operator still causes the `NSManagedObject.hasChanges` flag to be set to `true`. I like making sure that if something didn’t change, I can believe `hasChanges`.

### Persistable Protocol

Importing lots of data into Core Data doesn’t need to be chaotic. Just implement the `Persistable` protocol in the data type that you want to import, and the protocol will walk you through some steps to make sure everything is nice and orderly.

```swift
struct ImportablePerson {
    var firstName: String
    var lastName: String
    var age: Int
    var townID: Int
}

extension ImportablePerson: Persistable {
    typealias ImporterData = [Int : Town]

    // This function is called once per import operation to provide any extra
    // necessary data for the import
    static func generateImporterData(
        objects: [Self], 
        context: NSManagedObjectContext
    ) throws -> ImporterData {
        let townRefs = try context.getTownsWithIds(objects.map(\.townID))
        return townRefs.reduce(into: [:]) { $0[$1] = $1.id }
    }
    
    // Then, for each item in the import operation, this function does the import:
    func importIntoContext(
        _ context: NSManagedObjectContext,
        importerData: inout ImporterData
    ) -> PersistenceResult {
        let persistedPerson = PersistentPerson(context: context)
        persistedPerson.firstName = firstName
        persistedPerson.lastName = lastName
        persistedPerson.age = age
        persistedPerson.town = importerData[townID]
        return .insert(persistedPerson.objectID)
    }
}
```

To use the importer functions, just use the handy function on `NSManagedObjectContext`:

```swift
let arrayResults: [PersistenceResult] = try context
    .importPersistableObjects(importablePeople)

// results can also be a dictionary keyed to Identifiers.
let dictionaryResults: [ImportablePerson.ID : PersistenceResult] = try context
    .importPersistableObjects(importablePeople)
```

### NSManagedObjectContext Helpers

There are some extra functions in an extension of `NSManagedObjectContext` help with basic operations:

Save changes, but only if changes exist in the context. If you update object properties with the `Updatable` protocol functions, this will save you unnecessary `save()` calls.

```swift
try context.saveIfNeeded()
```

Get typed `NSManagedObjects` from the context.

```swift
let somePerson = try context.existing(Person.self, withID: personID)
let somePeople = try context.existing(Person.self, withIDs: [ID1, ID2, ID3])
```

Remove all objects of a given type from the context (with an optional `NSPredicate` to only remove objects that match the given criteria).

```swift
try context.removeInstances(of: Person.self, matching: someNSPredicate)
```

### NSFetchRequest Helpers

A little syntactic sugar for using chaining functions to build your `NSFetchRequest`:

```swift
let fetchRequest = NSFetchRequest<Person>(entityName: "Person")
    .sorted(sortDescriptors)
    .where(somePredicate)
```

And for building `NSSortDescriptor`:

```swift
let sorting: [NSSortDescriptor] = [
    .ascending(\Person.lastName),
    .descending(\Person.age)
]
```

### NSPredicate Helpers

`NSPredicate`s can be combined with `&&`, `||`, and `!` operators

```swift
let predicate1 = NSPredicate(format: "'age' >= 13")
let predicate2 = NSPredicate(format: "'age' < 20")

let isTeenager = predicate1 && predicate2
let isNotTeenager = !isTeenager
let alsoIsNotTeenager = !predicate1 || !predicate2
```

You can also use `KeyPath`s on `NSManagedObject` subclasses to make simple predicates:

```swift
// Simple Equatable or Comparable KeyPaths allow this kind of NSPredicate creation
let isOlderThanDirt = \Person.age > 1000
let notFred = \Person.name != "Fred"

// Or wrap the KeyPath in parentheses for further NSPredicate functions:
let isTeenager = (\Person.age).between(13...19)
let isOddTeen = (\Person.age).in([11, 13, 15, 17, 19])

// String properties can have comparison options, too:
let definitelyNotFred = (\Person.name).notEqual(
            to: "Fred",
            options: .caseAndDiacriticInsensitive)
```

For a more robust, elegant, and type-safe `NSPredicate` system, check out [PredicateKit](<https://github.com/ftchirou/PredicateKit>)

## Further Plans

**RCDataKit** is a work-in-progress… here are a few general improvements I currently have in mind:

- 🚨 Better (or any) error handling.
- 🤠 Improved versatility in `DataStack` protocol
- 🚜 Combine publishers
- 🛩️ Async/Await helpers
- 💭 CloudKit integration
- 🚧 More testing

## Contribution/Feedback

And since it’s a work-in-progress, I’m happy to receive suggestions, feedback, or contributions to it. Create an issue or pull request if you like.
