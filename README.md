# 🛠️ RCDataKit 💾

Helpful tools for your Core Data

## What Is It?

Core Data is a mature and powerful tool, but it takes some time to get used to its intricacies. I’ve been using it heavily for years, and building a bunch of helper tools to make my life easier. RCDataKit is the latest version of those tools.

There are really amazing tools already out there for Core Data ([CoreStore](https://github.com/JohnEstropia/CoreStore), [PredicateKit](https://github.com/ftchirou/PredicateKit) to name a few of my favorites) that take most of the scary, non-type-safe work out of your hands. RCDataKit isn't intended to replace your use of Core Data tools as much as those libraries, though. It won’t prevent you from breaking things if you don’t understand Core Data, but hopefully it will help you with that understanding if you are interested in learning more.

## Why Bother With Core Data?

Sure. Core Data is old and can be annoying to work with, and maybe will be replaced permanently by SwiftData some day. But for now, I’m still using Core Data in my own projects because:

1. It’s a native Apple tool, which means it will probably stay available to anyone writing iOS/MacOS apps for a long time.
2. SwiftData, while very exciting and new, is seriously lacking in some finer controls that I’ve gotten used to with Core Data.

I still assume SwiftData will be the way of the future, but until I can make it completely replace every aspect of Core Data in all my projects without any annoying bugs, I’ll keep working on this.

# The Library

- [Stack Helpers](#stack-helpers)
  - [TransactionAuthor Protocol](#transactionauthor-protocol)
  - [DataStack Protocol](#datastack-protocol)
- [Model Helpers](#model-helpers)
  - [PersistentStoreVersion Protocol](#persistentstoreversion-protocol)
  - [PersistentHistoryTracker Actor](#persistenthistorytracker-actor)
- [CRUD Helpers](#crud-helpers)
  - [Updatable Protocol](#updatable-protocol)
  - [Persistable Protocol](#persistable-protocol)
  - [NSManagedObjectContext Helpers](#nsmanagedobjectcontext-helpers)
  - [NSFetchRequest Helpers](#nsfetchrequest-helpers)
  - [NSPredicate Helpers](#nspredicate-helpers)

## Stack Helpers:

### TransactionAuthor Protocol

A simple protocol to keep track of the different context authors in your Persistent Store. This does nothing by itself, but can be plugged into other types here to do some management for you.

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

The idea here is that you’ll want one case for each of your main-thread contexts that access your data store (view context from your app), and as many named background contexts as you like to help keep track of who or what is writing to your store.

### DataStack Protocol

Another simple protocol, this one wraps your `NSPersistentContainer` and assigns a `TransactionAuthor` type to it so you can get preconfigured contexts from the container.

```swift
let myStack: DataStack // has associatedType `Authors`

// Get the viewContext -- a NSManagedObjectContext where 
// transactionAuthor == myStack.viewContextID.name
let viewContext = myStack.viewContext 

// Get a background context with transactionAuthor == localEditing.name
let bgContext = myStack.backgroundContext(author: .localEditing)
```

There are a few implementations of `DataStack` available here:
- `PreviewStack` is an in-memory store for use in SwiftUI previews or other non-persisted environments.
- `SingleStoreStack` is a SQLite-backed stack with a single store, and initialization options for Persistent History Tracking and Staged Migrations.

## Model Helpers:

### PersistentStoreVersion Protocol

Migrating your Model from one version to the next used to be such a pain— Lightweight Migrations are easy enough, but Custom Migrations not so much. Setting up your environment to perform either was confusing, and [Apple’s documentation](https://developer.apple.com/documentation/coredata/staged_migrations) is even sparser than for the old migrations system. But now we have [Staged Migrations](https://developer.apple.com/videos/play/wwdc2022/10120/)! Unfortunately, Apple’s documentation is practically nonexistent once again. Thanks to [Pol Piela](https://www.polpiella.dev/staged-migrations) and [FatBobMan](https://fatbobman.com/en/posts/what-s-new-in-core-data-in-wwdc23/) for picking up the slack.

With the `PersistentStoreVersion` protocol, I’ve built a bunch of useful helpers for getting your migrations set up.

- First, make a type that conforms to the protocol, and make it reference the names of your model and its versions:

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

- Next, create an array of migration stages to walk through your versions and upgrade them as you go:

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

- When creating your `NSPersistentContainer`, you can get a `NSStagedMigrationManager` to handle the migrations as easy as this:

```swift
let migrationManager = ModelVersions.migrationManager()
container.persistentStoreDescriptions
    .first?
    .setOption(
        migrationManager,
        forKey: NSPersistentStoreStagedMigrationManagerOptionKey)
```

- Alternately, just pass your `PersistentStoreVersion` into the initializer for `SingleStoreStack`:

```swift
let stack = try SingleStoreStack(
                    versionKey: ModelVersions.self, 
                    mainAuthor: Authors.iOSViewContext)
```

### PersistentHistoryTracker Actor

Persistent History Tracking can be really confusing. `PersistentHistoryTracker` is an actor that attaches to your `NSPersistentContainer` in order to manage all that tracking for you. It borrows very heavily from tutorials and projects by [Antoine Van Der Lee](https://www.avanderlee.com/swift/persistent-history-tracking-core-data/) and [FatBobMan](https://fatbobman.com/en/posts/persistenthistorytracking/) (especially FatBobMan’s [PersistentHistoryTrackingKit](https://github.com/fatbobman/PersistentHistoryTrackingKit/tree/main), thank you!), with some added helpers based on the `TransactionAuthor` protocol.

To track, just create an instance of `PersistentHistoryTracker`, and start it up:

```swift
let tracker = PersistentHistoryTracker(
    container: myPersistentContainer,
    currentAuthor: Authors.iOSViewContext)
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

## CRUD Helpers:

### Updatable Protocol

Make your `NSManagedObject` subclass conform to the `Updatable` protocol to get some free functions:

```swift
let rc = Person(...)

rc.update(\.age, value: 15) // now I'm 15 years old!
rc.updateIfAvailable(\.age, value: nil) // still 15, not nil!
rc.update(\.age, value: 16, minimumChange: 2) // still 15, because I only want to age in 2-year increments.

rc.add(\.friend, relation: dan) // dan is now my friend
rc.add(\.friend, relation: nil) // nothing happens, because nobody's there.
rc.remove(\.friend, relation: dan) // dan's not my friend anymore.
```

Why bother with these, rather than `rc.age = 15`, or `rc.friend = dan`? Because if I’m already 15, or if dan is already my friend, using the `=` operator still causes my `hasChanges` flag to be set to `true`. I like making sure that if something didn’t change, I can believe `hasChanges`.

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
    // This function is called once per import operation to provide any extra
    // necessary data for the import
    static func generateImporterData(
        objects: [ImportablePerson], 
        context: NSManagedObjectContext
    ) throws -> [Int : Town] {
        let townRefs = try context.getTownsWithIds(objects.map(\.townID))
        return townRefs.reduce(into: [:]) { $0[$1] = $1.id }
    }
    
    // Then, for each item in the import operation, this function does the import:
    func importIntoContext(
        _ context: NSManagedObjectContext,
        importerData: [Int : Town]
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
let results: [PersistenceResult] = try context
    .importPersistableObjects(importablePeople)
// results can also be a dictionary keyed to Identifiers.
```

### NSManagedObjectContext Helpers

Some extra functions in an extension of `NSManagedObjectContext`:

```swift
// Save changes on the context, but only if changes have been made.
// (if you only update object properties with `Updatable` protocol functions,
// this will save you unnecessary `save()` calls)
try context.saveIfNeeded()

// Get typed NSManagedObjects from the context
let someGuy = try context.existing(Person.self, withID: nsManagedObjectID)
let somePeople = try context.existing(Person.self, withIDs: [ID1, ID2, ID3])

// Remove all objects from context, optionally only those matching a predicate.
try context.removeInstances(of: Person.self, matching: someNSPredicate)
```

### NSFetchRequest Helpers

And some functions in extensions of `NSPredicate` , `NSFetchRequest`, `NSSortDescriptor`

- `NSPredicate`:
    - Combine with `&&`, `||`, and `!=`.
    - Create with KeyPath comparators like `==`, `>`, `!=` and so on.
```swift
let olderThanDirt = \Person.age > 1000
let notFred = \Person.name != "Fred"
```
    - Also create with `in` or `between` for number properties:
```swift
// note the parentheses around the KeyPath
let isTeenager = (\Person.age).between(13, and: 19)
let isOddTeen = (\Person.age).in([11, 13, 15, 17, 19])
```
    - For `String` properties, add options to the predicate like so:
```swift
let definitelyNotFred = \(Person.name).notEqual(
            to: "Fred", 
            options: [.caseInsensitive, .diacriticInsensitive])
```
    - For a more robust, type-safe `NSPredicate` system, check out [PredicateKit](https://github.com/ftchirou/PredicateKit)
    
- `NSFetchRequest`s can be built with chaining methods like:

```swift
let fetchRequest = NSFetchRequest<Person>(entityName: "Person")
    .sorted(sortDescriptors)
    .predicated(somePredicate)
```

- Convenience initializers for `NSSortDescriptor` :

```swift
let sorting: [NSSortDescriptor] = [
    .ascending(\Person.lastName),
    .descending(\Person.age)
]
```
