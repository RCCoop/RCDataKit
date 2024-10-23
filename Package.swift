// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RCDataKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1),
        .macCatalyst(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RCDataKit",
            targets: ["RCDataKit"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RCDataKit",
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]),
        .testTarget(
            name: "RCDataKitTests",
            dependencies: ["RCDataKit"],
            resources: [
                .copy("TestsDataModel/Sample Data/SchoolsData.json"),
                .copy("TestsDataModel/Sample Data/OldStudentsStore.sqlite"),
            ]),
    ]
)
