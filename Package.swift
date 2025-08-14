import PackageDescription

let package = Package(
    name: "ZipUtl",
    products: [
        .library(
            name: "ZipUtl",
            targets: ["ZipUtl"]
        ),
    ],
    targets: [
        .target(
            name: "ZipUtl",
            dependencies: []
            linkerSettings: [
                .linkedLibrary("z")
            ]
        )
    ]
)
