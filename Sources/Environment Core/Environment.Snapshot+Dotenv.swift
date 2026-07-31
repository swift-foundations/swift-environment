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

extension Environment.Snapshot {
    /// Creates a snapshot from a parsed dotenv document.
    ///
    /// - Parameter dotenv: The parsed dotenv key-value pairs.
    public init(_ dotenv: Environment.Dotenv) {
        self.init(dotenv.values)
    }
}
