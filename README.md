# 🛠️ RCDataKit 💾

Helpful tools for your Core Data

## What Is It?

Core Data is a mature and powerful tool, but it takes plenty of time to get the hang of its intricacies. I’ve been using it heavily for years, and building a bunch of helper tools to make my life easier. RCDataKit is a bunch of my personal tools that have been cleaned up enough for me to feel they’re worth sharing with the world.

There are a lot of tools out there (CoreStore, PredicateKit) that are a lot more than what I’ve put here, and take most of the scary, non-type-safe work out of your hands. RCDataKit is intended to be a helper for your Core Data implementation, not a massive wrapper around it. It won’t prevent you from breaking things if you don’t understand Core Data, but hopefully it will help you with that understanding if you are interested in learning more. I’m still learning, and I’d love if my experience can help you, too.

## Why Bother With Core Data?

Core Data stinks! SwiftData is newer and the way of the future! Or Realm, or all kinds of other options! 

Yes! Core Data is old and can be annoying to work with, and maybe will be replaced permanently by SwiftData some day. But for now, I’m still using Core Data in my own projects because:

1. It’s a native Apple tool, which means it will probably stay available to anyone writing iOS/MacOS apps for a long time.
2. SwiftData, while very exciting and new, is seriously lacking in some finer controls that I’ve gotten used to with Core Data.

I still assume SwiftData will be the way of the future, but until I can make it completely replace every aspect of Core Data in all my projects without any annoying bugs, I’ll keep working on this.

# The Library

- [Stack Helpers](#stack-helpers)
  - [TransactionAuthor Protocol](#transactionauthor-protocol)
  - [CoreDataStack Protocol](#coredatastack-protocol)
- [Model Helpers](#model-helpers)
  - [PersistentStoreVersion Protocol](#persistentstoreversion-protocol)
  - [PersistentHistoryTracker Actor](#persistenthistorytracker-actor)
- [CRUD Helpers](#crud-helpers)
  - [Updatable Protocol](#updatable-protocol)
  - [Persistable Protocol](#persistable-protocol)
  - [NSManagedObjectContext Helpers](#nsmanagedobjectcontext-helpers)
  - [NSFetchRequest Helpers](#nsfetchrequest-helpers)

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

### CoreDataStack Protocol

Another simple protocol. This one wraps your `NSPersistentContainer` (and I’ll add some pre-made implementations eventually), and assigns a `TransactionAuthor` type to it so you can get preconfigured contexts from the container.

```swift
let myStack: CoreDataStack // has associatedType `Authors`

// Get the viewContext -- a NSManagedObjectContext with 
// transactionAuthor == myStack.viewContextID.name
let viewContext = myStack.viewContext 

// Get a background context with transactionAuthor == localEditing.name
let bgContext = myStack.backgroundContext(author: .localEditing)
```

## Model Helpers:

### PersistentStoreVersion Protocol

Migrating your Model from one version to the next used to be such a pain— Lightweight Migrations are easy enough, but Custom Migrations not so much. Setting up your environment to perform either was confusing, and [Apple’s documentation](https://developer.apple.com/documentation/coredata/staged_migrations) is even sparser than for the old migrations system. But now we have [Staged Migrations](https://developer.apple.com/videos/play/wwdc2022/10120/)! Unfortunately, Apple’d documentation is practically nonexistent once again. Thanks to [Pol Piela](https://www.polpiella.dev/staged-migrations) and [FatBobMan](https://fatbobman.com/en/posts/what-s-new-in-core-data-in-wwdc23/) for picking up the slack.

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

### PersistentHistoryTracker Actor

Persistent History Tracking can be really confusing. `PersistentHistoryTracker` is an actor that attaches to your `NSPersistentContainer` in order to manage all that tracking for you. It borrows very heavily from tutorials and projects by [Antoine Van Der Lee](https://www.avanderlee.com/swift/persistent-history-tracking-core-data/) and [FatBobMan](https://fatbobman.com/en/posts/persistenthistorytracking/) (especially FatBobMan’s [PersistentHistoryTrackingKit](https://github.com/fatbobman/PersistentHistoryTrackingKit/tree/main), thank you!), with some added helpers based on the `TransactionAuthor` protocol.

To track, just create an instance of `PersistentHistoryTracker`, and start it up:

```swift
let tracker = PersistentHistoryTracker(
    container: myPersistentContainer,
    currentAuthor: Authors.iOSViewContext)
tracker.startMonitoring()
```

I’ll work on adding more relevant helpers that deal with persistent history transactions in the future.

## CRUD Helpers:

### Updatable Protocol

Make your `NSManagedObject` subclass conform to the `Updatable` protocol to get some free functions:

```swift
let rc = Person(...)

rc.update(\.age, value: 15) // now I'm 15 years old!
rc.updateIfAvailable(\.age, value: Optional<Int>.none) // still 15, not nil!
rc.update(\.age, value: 16, minimumChange: 2) // still 15, because I only want to age in 2-year increments.

rc.add(\.friend, relation: dan) // dan is now my friend
rc.add(\.friend, relation: Optional<Person>.none) // nothing happens, because nobody's there.
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

- `NSPredicates` can be compounded with `&&`, `||`, and `!=`
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
