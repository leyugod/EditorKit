// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EditorKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "EditorKit",
            targets: ["EditorKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EditorKit",
            dependencies: [],
            path: "Sources/EditorKit",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "EditorKitTests",
            dependencies: ["EditorKit"],
            path: "Tests/EditorKitTests"
        ),
    ]
)
