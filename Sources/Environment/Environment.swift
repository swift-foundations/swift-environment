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

public import Synchronization

/// Cross-platform environment variable management.
///
/// ## Thread Safety
///
/// All operations on `Environment` are internally synchronized using a process-global
/// mutex. This makes `Environment` thread-safe for concurrent callers **within your
/// process that use this API**.
///
/// **Caveat**: This synchronization cannot protect against external code (including
/// third-party libraries or C code) that calls `getenv`/`setenv`/`putenv` directly
/// without using this API. If such code exists in your process, you must coordinate
/// access externally.
///
/// ## Semantic Invariants
///
/// 1. `Environment.read` and `Environment.write` always operate on the real process environment.
/// 2. TaskLocal overlays are only visible through `Environment.task.*` APIs.
/// 3. Spawned child processes see the real process environment unless you explicitly
///    pass a snapshot (e.g., via `.effective()` to include TaskLocal overlay).
public enum Environment {
    /// Process-global lock for environment access.
    @usableFromInline
    internal static let lock = Mutex<Void>(())
}
