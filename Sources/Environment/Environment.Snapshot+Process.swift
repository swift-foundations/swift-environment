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

public import Environment_Core

// The two `Snapshot` constructors that read the real process environment. They are
// here rather than beside the type because they are the only part of `Snapshot` that
// needs a process to exist — everything else about a snapshot is a value.

extension Environment.Snapshot {
    /// Returns a snapshot of the current process environment.
    public static func current() -> Self {
        Self(Environment.read.all())
    }

    /// Returns a snapshot of the effective environment (process + TaskLocal overlay).
    public static func effective() -> Self {
        Environment.task.effective()
    }
}
