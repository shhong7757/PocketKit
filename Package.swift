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
        .testTarget(
            name: "PocketUITests",
            dependencies: ["PocketUI"]
        ),
    ]
)
