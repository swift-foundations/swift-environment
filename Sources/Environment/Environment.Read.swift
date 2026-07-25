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
    /// - Note: Decoding policy: entries are decoded from the platform-native
    ///   encoding **lossily** — UTF-8 on POSIX, UTF-16 on Windows — so any code
    ///   unit sequence that is not valid in that encoding is replaced with
    ///   U+FFFD (REPLACEMENT CHARACTER) rather than throwing or trapping. This
    ///   matches ``callAsFunction(_:)``, which already decodes the process
    ///   environment lossily via a non-throwing path. `all()` is therefore
    ///   total: it never traps the process, even when the real OS environment
    ///   contains malformed code units (which POSIX permits).
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
                let name = Self.lossyDecoded(entry.name)
                let value = Self.lossyDecoded(entry.value)
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

// MARK: - Entry decoding

// The only platform-conditional surface in this file besides the optionality of
// `Kernel.Environment.entries()`. The kernel vends an entry's name and value in
// the borrowed shape native to the platform's environment block — a
// `Swift.Span` over the `environ` bytes on POSIX, a null-terminated
// `String.Borrowed` view over `GetEnvironmentStringsW`'s UTF-16 units on
// Windows — so the two legs differ in *shape*, not in policy. Both hand the
// code units to `Swift.String.lossy(platformNative:)`, which owns the choice of
// codec, keeping the decoding policy itself unconditional.

extension Environment.Read {
    #if os(Windows)
        /// Lossily decodes a borrowed view of platform-native (UTF-16) code units.
        ///
        /// - Parameter codeUnits: A borrowed view over a kernel entry's code units.
        /// - Returns: The decoded string; malformed sequences become U+FFFD.
        @inline(__always)
        fileprivate static func lossyDecoded(
            _ codeUnits: borrowing String_Primitives.String.Borrowed
        ) -> Swift.String {
            unsafe codeUnits.span.withUnsafeBufferPointer { buffer in
                unsafe Swift.String.lossy(platformNative: Array(buffer))
            }
        }
    #else
        /// Lossily decodes a span of platform-native (UTF-8) code units.
        ///
        /// - Parameter codeUnits: A span over a kernel entry's code units.
        /// - Returns: The decoded string; malformed sequences become U+FFFD.
        @inline(__always)
        fileprivate static func lossyDecoded(
            _ codeUnits: Swift.Span<String_Primitives.String.Char>
        ) -> Swift.String {
            unsafe codeUnits.withUnsafeBufferPointer { buffer in
                unsafe Swift.String.lossy(platformNative: Array(buffer))
            }
        }
    #endif
}
