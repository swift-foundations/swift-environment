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

extension Environment {
    /// An immutable snapshot of environment variables.
    ///
    /// Use snapshots for:
    /// - Process spawning with modified environment
    /// - Capturing environment state at a point in time
    /// - TaskLocal overlays
    public struct Snapshot: Sendable, Hashable {
        /// The environment variable key-value pairs.
        public var values: [Swift.String: Swift.String]
    }
}

// MARK: - Initialization

extension Environment.Snapshot {
    /// Creates an empty snapshot.
    public init() {
        self.values = [:]
    }

    /// Creates a snapshot with the given values.
    ///
    /// - Parameter values: The environment variable key-value pairs.
    public init(_ values: [Swift.String: Swift.String]) {
        self.values = values
    }
}

// MARK: - Subscript

extension Environment.Snapshot {
    /// Accesses the value for the given variable name.
    public subscript(name: Swift.String) -> Swift.String? {
        get { values[name] }
        set { values[name] = newValue }
    }
}
