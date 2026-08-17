// swift-tools-version: 6.3.3

// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-environment open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-environment project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
    name: "swift-environment",
    platforms: [
        .macOS("27"),
        .iOS("27"),
        .tvOS("27"),
        .watchOS("27"),
        .visionOS("27")
    ],
    products: [
        // The environment value vocabulary — `Environment.Snapshot`, `Environment.Dotenv`.
        // No package dependencies, no platform engine, no foreign `String`. Depend on
        // this when you carry, merge, or parse environment values.
        .library(name: "Environment Core", targets: ["Environment Core"]),

        // The value vocabulary plus access to the real process environment —
        // `Environment.read`, `Environment.write`, `Environment.task`,
        // `Snapshot.current()`. Binds to `Kernel`, and therefore to a platform engine.
        .library(name: "Environment", targets: ["Environment"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-kernel.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-strings.git", branch: "main")
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
                .product(name: "Strings", package: "swift-strings")
            ],
            path: "Sources/Environment"
        ),
        .testTarget(
            name: "Environment Core Tests",
            dependencies: [
                "Environment Core",
            ]
        ),
        .testTarget(
            name: "Environment Tests",
            dependencies: [
                "Environment",
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
