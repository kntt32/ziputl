// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ZipUtl",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
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
