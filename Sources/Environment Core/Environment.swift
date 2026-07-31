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

/// Environment variables as values.
///
/// `Environment` is the namespace shared by this package's two halves.
/// `Environment Core` — this module — owns the value vocabulary: ``Environment/Snapshot``
/// and ``Environment/Dotenv``. It reaches nothing outside the standard library, so a
/// consumer that only needs to carry, merge, or parse environment values does not
/// resolve or compile a platform engine, and no foreign `String` enters its scope.
///
/// Access to the real process environment — `Environment.read`, `Environment.write`,
/// `Environment.task`, and `Snapshot.current()`/`Snapshot.effective()` — is a separate
/// capability with a platform binding behind it, and lives in the `Environment` module
/// of this package. The two vary independently: a value passed to a spawned process, a
/// test fixture, or a configuration loader has no process to read from.
public enum Environment {}
