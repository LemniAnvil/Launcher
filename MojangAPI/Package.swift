// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MojangAPI",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MojangAPI",
            targets: ["MojangAPI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MojangAPI",
            dependencies: [],
            path: "Sources/MojangAPI"
        ),
        .testTarget(
            name: "MojangAPITests",
            dependencies: ["MojangAPI"],
            path: "Tests/MojangAPITests"
        )
    ]
)
