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
        .testTarget(
            name: "PocketUITests",
            dependencies: ["PocketUI"]
        ),
        .testTarget(
            name: "PocketStorageTests",
            dependencies: ["PocketStorage"]
        ),
    ]
)
