# 🛠️ RCDataKit 💾

Helpful tools for Core Data

## Contents
- [What Is It?](#what-is-it)
- [Installation](#installation)
- [Creating a Data Stack](#creating-a-data-stack)
    - [DataStack Protocol](#datastack-protocol)
        - [Basic DataStack Implementations](#basic-datastack-implementations)
    - [Helper Types](#helper-types)
        - [TransactionAuthor Protocol](#transactionauthor-protocol)
        - [PersistentStoreVersion Protocol](#persistentstoreversion-protocol)
        - [PersistentHistoryTracker actor](#persistenthistorytracker-actor)
- [CRUD Helpers](#crud-helpers)
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
  .package(url: "https://github.com/RCCoop/RCDataKit", .upToNextMajor(from: "0.1"))
]
```

Or add the package to your Xcode project with `File -> Add Package Dependencies...`

# Creating a Data Stack

**RCDataKit** has a few pre-made solutions for setting up your Core Data stack. They’re not required for use with any of the other types in the library, but they do most of the setup work for you.

## DataStack Protocol

This simple protocol is for types that wrap a `NSPersistentContainer` and  provide pre-configured `NSManagedObjectContexts`. Each `DataStack` requires a `TransactionAuthor` associated type, but otherwise the implementation is up to you.

```swift
let myStack: DataStack

// Get the viewContext -- a NSManagedObjectContext where
// transactionAuthor == myStack.viewContextID.name
let viewContext = myStack.viewContext

// Get a background context where transactionAuthor == localEditing.name
let bgContext = myStack.backgroundContext(author: .cloudDataImport)
```

### Basic DataStack Implementations

There are a few pre-made implementations of `DataStack` available here:

- **PreviewStack** is an in-memory store for use in SwiftUI previews or other non-persisted environments.
- **SingleStoreStack** is a SQLite-backed stack with a single store, and initialization options for Persistent History Tracking and Staged Migrations.

## Helper Types

### TransactionAuthor Protocol

A simple protocol to keep track of the different context authors in your Persistent Store. This does nothing by itself, but is used in `DataStack` and `PersistentHistoryTracker` to provide a list of all possible author titles.

The idea is that you’ll want one case for each of your main-thread contexts that access your data store (view context from your app), and as many named background contexts as you like to keep track of who or what is writing to your store.

```swift
public protocol TransactionAuthor: CaseIterable {
    var name: String { get }
}

enum Authors: String, TransactionAuthor {
    case iOSViewContext
    case extensionContext
    case networkSync
    case localEditing

    // Authors is RawRepresentable by String, so `name` is auto-generated
}
```

### PersistentStoreVersion Protocol

Migrating your Model from one version to the next can be a huge pain— Lightweight Migrations are easy enough, but Custom Migrations not so much. But now we have [Staged Migrations](https://developer.apple.com/videos/play/wwdc2022/10120/)! Unfortunately, [Apple’s documentation](https://developer.apple.com/documentation/coredata/staged_migrations) is lacking. Thanks to [Pol Piela](https://www.polpiella.dev/staged-migrations) and [FatBobMan](https://fatbobman.com/en/posts/what-s-new-in-core-data-in-wwdc23/) for picking up the slack.

With the `PersistentStoreVersion` protocol, setting up staged migrations takes a lot less boilerplate code, so you can do the important work.

1. Make a type that conforms to the protocol, and make it reference the names of your model and its versions:

<img width="160" alt="Screenshot_2024-09-15_at_10 24 58_AM" src="https://github.com/user-attachments/assets/9a42ca82-72c2-4c17-afa7-7bba80fa9f7a">

```swift
enum ModelVersions: String, PersistentStoreVersion {
    static var modelName: String {
        "TestModel"
    }

    case v1 = "Model"
    case v2 = "Model2"
    case v3 = "Model3"
    case v4 = "Model4"
}
```

2. Create an array of migration stages to walk through your version upgrades:

```swift
extension ModelVersions {
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
let migrationManager = ModelVersions.migrationManager()
container.persistentStoreDescriptions
    .first?
    .setOption(migrationManager, forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
```

Alternately, just pass your `PersistentStoreVersion` into the initializer for `SingleStoreStack`:

```swift
let stack = try SingleStoreStack(
                    versionKey: ModelVersions.self,
                    mainAuthor: Authors.iOSViewContext)
```

### PersistentHistoryTracker actor

Persistent History Tracking is well-documented, but can still be very confusing. `PersistentHistoryTracker` is an actor that attaches to your `NSPersistentContainer` in order to manage all that tracking for you. It borrows very heavily from tutorials and projects by [Antoine Van Der Lee](https://www.avanderlee.com/swift/persistent-history-tracking-core-data/) and [FatBobMan](https://fatbobman.com/en/posts/persistenthistorytracking/) (especially FatBobMan’s [PersistentHistoryTrackingKit](https://github.com/fatbobman/PersistentHistoryTrackingKit/tree/main), thank you!), with some added helpers based on the `TransactionAuthor` protocol.

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
    currentAuthor: Authors.iOSViewContext)

// Start or stop monitoring as needed.
tracker.startMonitoring()
```

You can also enable tracking in `SingleStoreStack` by passing in an instance of `PersistentHistoryTrackingOptions` to the initializer:

```swift
let stack = try SingleStoreStack(
                    versionKey: ModelVersions.self,
                    mainAuthor: Authors.iOSViewContext,
                    persistentHistoryOptions: .init())

stack.historyTracker?.startMonitoring()
```

# CRUD Helpers

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
        importerData: ImporterData
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
    .predicated(somePredicate)
```

And for building `NSSortDescriptor`:

```swift
let sorting: [NSSortDescriptor] = [
    .ascending(\Person.lastName),
    .descending(\Person.age)
]
```

### NSPredicate Helpers

`NSPredicate`s can be combined with `&&`, `||`, and `!=` operators

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
let isTeenager = (\Person.age).between(13, and: 19)
let isOddTeen = (\Person.age).in([11, 13, 15, 17, 19])

// String properties can have comparison options, too:
let definitelyNotFred = (\Person.name).notEqual(
            to: "Fred",
            options: [.caseInsensitive, .diacriticInsensitive])
```

For a more robust, type-safe `NSPredicate` system, check out [PredicateKit](<https://github.com/ftchirou/PredicateKit>)

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
