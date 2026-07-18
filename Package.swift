// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PocketKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
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
            name: "PhotosGallery",
            targets: ["PhotosGallery"]
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
            name: "PhotosGallery",
            dependencies: ["PocketUI"],
            path: "Sources/PhotosGallery",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PocketUITests",
            dependencies: ["PocketUI"]
        ),
        .testTarget(
            name: "PocketStorageTests",
            dependencies: ["PocketStorage"]
        ),
        .testTarget(
            name: "PhotosGalleryTests",
            dependencies: ["PhotosGallery"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
