// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PocketKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "PocketUI",
            targets: ["PocketUI"]
        ),
        .library(
            name: "PocketStorage",
            targets: ["PocketStorage"]
        ),
        .library(
            name: "PocketStorageObservation",
            targets: ["PocketStorageObservation"]
        ),
        .library(
            name: "PocketStorageUI",
            targets: ["PocketStorageUI"]
        )
    ],
    targets: [
        .target(
            name: "PocketUI",
            path: "Sources/PocketUI",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "PocketStorage",
            path: "Sources/PocketStorage"
        ),
        .target(
            name: "PocketStorageObservation",
            dependencies: ["PocketStorage"],
            path: "Sources/PocketStorageObservation"
        ),
        .target(
            name: "PocketStorageUI",
            dependencies: ["PocketStorage"],
            path: "Sources/PocketStorageUI"
        ),
        .testTarget(
            name: "PocketUITests",
            dependencies: ["PocketUI"]
        ),
        .testTarget(
            name: "PocketStorageTests",
            dependencies: ["PocketStorage", "PocketStorageObservation"]
        ),
        .testTarget(
            name: "PocketStorageUITests",
            dependencies: ["PocketStorage", "PocketStorageUI"]
        ),
    ]
)
