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

internal import Synchronization

extension Environment {
    /// Process-global lock for environment access.
    ///
    /// Serializes every read and write this module performs against the real
    /// process environment. It lives with the process binding rather than with the
    /// environment value vocabulary because it exists only to guard `getenv`,
    /// `setenv`, and `environ` — a `Snapshot` needs no lock.
    internal static let lock = Mutex<Void>(())
}
