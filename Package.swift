// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ZipUtl",
    platforms: [
        .macOS("14.0.0"),
        .iOS("18.0.0")
    ],
    products: [
        .library(
            name: "ZipUtl",
            targets: ["ZipUtl"]
        ),
    ],
    targets: [
        .target(
            name: "ZipUtl",
            dependencies: [],
            linkerSettings: [
                .linkedLibrary("z")
            ]
        )
    ]
)
