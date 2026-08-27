// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-environment",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [

        .library(name: "Environment Core", targets: ["Environment Core"]),

        .library(name: "Environment", targets: ["Environment"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-compositions/swift-kernel.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-strings.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Environment Core",
            dependencies: [],
            path: "Sources/Environment Core"
        ),
        .target(
            name: "Environment",
            dependencies: [
                "Environment Core",
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Strings", package: "swift-strings"),
            ],
            path: "Sources/Environment"
        ),
        .testTarget(
            name: "Environment Core Tests",
            dependencies: [
                "Environment Core"
            ]
        ),
        .testTarget(
            name: "Environment Tests",
            dependencies: [
                "Environment"
            ]
        ),
    ]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
