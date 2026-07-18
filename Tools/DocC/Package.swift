// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PocketKitDocCTools",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    dependencies: [
        .package(path: "../.."),
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin",
            from: "1.5.0"
        ),
    ],
    targets: [
        .target(
            name: "DocCTools",
            dependencies: [
                .product(name: "PocketUI", package: "PocketKit"),
                .product(name: "PocketStorage", package: "PocketKit"),
                .product(name: "PhotosGallery", package: "PocketKit")
            ]
        )
    ]
)
