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

import Environment
import Testing

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

extension Environment.Read {
    @Suite
    struct `Edge Case` {
        /// F-001: `all()` used to force-try UTF-8 decoding of every environment
        /// entry (`try! String(entry.name)` / `try! String(entry.value)`), which
        /// traps the whole process the instant any environment variable holds a
        /// byte sequence that is not valid UTF-8 — a state POSIX explicitly
        /// permits (`environ` is a NUL-terminated byte string, not a validated
        /// UTF-8 string). This test injects a real, malformed environment
        /// variable via raw `setenv` (bypassing `Swift.String` construction
        /// entirely, since a `String` literal cannot itself hold invalid UTF-8)
        /// and asserts `all()` returns lossily-decoded U+FFFD replacement text
        /// instead of trapping.
        @Test
        func `all decodes a non-UTF8 environment value losslessly instead of trapping`() {
            let name = "__SWIFT_ENVIRONMENT_F001_INVALID_UTF8__"

            // "val" followed by a lone 0xFF byte (never valid in UTF-8, in any
            // position) followed by the C-string NUL terminator.
            let rawValue: [UInt8] = [0x76, 0x61, 0x6C, 0xFF, 0x00]

            rawValue.withUnsafeBufferPointer { buffer in
                buffer.baseAddress!.withMemoryRebound(
                    to: CChar.self,
                    capacity: buffer.count
                ) { cString in
                    _ = setenv(name, cString, 1)
                }
            }
            defer { _ = unsetenv(name) }

            let all = Environment.read.all()

            #expect(all[name] == "val\u{FFFD}")
        }
    }
}
