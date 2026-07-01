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

internal import Kernel
internal import Synchronization

extension Environment {
    /// Accessor for write operations on the process environment.
    public struct Write: Sendable {
        @usableFromInline
        internal init() {}
    }
}

extension Environment {
    /// Write operations on the process environment.
    ///
    /// Always writes to the real process environment.
    /// Does NOT affect TaskLocal overlays.
    public static var write: Write { Write() }
}

extension Environment.Write {
    /// Sets an environment variable, overwriting any existing value.
    ///
    /// - Parameters:
    ///   - name: The name of the environment variable.
    ///   - value: The value to set.
    /// - Throws: `Kernel.Environment.Error` on failure.
    public func callAsFunction(_ name: Swift.String, to value: Swift.String) throws(Kernel.Environment.Error) {
        try set(name, to: value, overwrite: true)
    }

    /// Sets an environment variable.
    ///
    /// - Parameters:
    ///   - name: The name of the environment variable.
    ///   - value: The value to set.
    ///   - overwrite: If true, overwrite existing value. If false and variable exists, no-op.
    /// - Throws: `Kernel.Environment.Error` on failure.
    public func set(_ name: Swift.String, to value: Swift.String, overwrite: Bool) throws(Kernel.Environment.Error) {
        try Environment.lock.withLock { _ throws(Kernel.Environment.Error) in
            unsafe try Kernel.Environment.set(name, to: value, overwrite: overwrite)
        }
    }

    /// Removes an environment variable.
    ///
    /// - Parameter name: The name of the environment variable.
    /// - Throws: `Kernel.Environment.Error` on failure.
    public func unset(_ name: Swift.String) throws(Kernel.Environment.Error) {
        try Environment.lock.withLock { _ throws(Kernel.Environment.Error) in
            unsafe try Kernel.Environment.unset(name)
        }
    }
}
