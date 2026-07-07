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
internal import Strings
internal import Synchronization

extension Environment {
    /// Accessor for read operations on the process environment.
    public struct Read: Sendable {
        @usableFromInline
        internal init() {}
    }
}

extension Environment {
    /// Read operations on the process environment.
    ///
    /// Always reads from the real process environment.
    /// Does NOT consult TaskLocal overlays.
    public static var read: Read { Read() }
}

extension Environment.Read {
    /// Returns the value of an environment variable, or nil if not set.
    ///
    /// - Parameter name: The name of the environment variable.
    /// - Returns: The value, or nil if not set.
    public func callAsFunction(_ name: Swift.String) -> Swift.String? {
        Environment.lock.withLock { _ -> Swift.String? in
            guard let value = unsafe Kernel.Environment.get(name) else { return nil }
            return Swift.String(value.view)
        }
    }

    /// Returns all environment variables as a dictionary.
    ///
    /// - Note: On Windows, internal pseudo-variables (entries starting with `=`)
    ///   are excluded automatically at the kernel level.
    public func all() -> [Swift.String: Swift.String] {
        Environment.lock.withLock { _ in
            var result: [Swift.String: Swift.String] = [:]
            #if os(Windows)
                guard var entries = Kernel.Environment.entries() else {
                    return result
                }
            #else
                var entries = Kernel.Environment.entries()
            #endif
            while let entry = entries.next() {
                // OS process-environment bytes are treated as valid UTF-8 by contract;
                // skipping malformed entries would change behavior (crash vs. silent drop).
                // swiftlint:disable force_try
                let name = try! Swift.String(entry.name)
                let value = try! Swift.String(entry.value)
                // swiftlint:enable force_try
                result[name] = value
            }
            return result
        }
    }

    /// Returns true if the environment variable is set.
    ///
    /// - Parameter name: The name of the environment variable.
    /// - Returns: true if the variable is set, false otherwise.
    public func isSet(_ name: Swift.String) -> Bool {
        Environment.lock.withLock { _ -> Bool in
            unsafe (Kernel.Environment.get(name) != nil)
        }
    }
}
