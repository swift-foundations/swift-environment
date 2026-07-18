// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-environment open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-environment project authors
// Licensed under Apache License 2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Environment.Snapshot {
    /// Returns the string value for a key.
    public func string(_ key: Swift.String) -> Swift.String? {
        self[key]
    }

    /// Returns the integer value for a key, or `nil` when absent or unparsable.
    public func int(_ key: Swift.String) -> Swift.Int? {
        self[key].flatMap(Swift.Int.init)
    }

    /// Returns the boolean value for a key using the conventional environment spellings.
    ///
    /// The accepted true values are `1`, `true`, `yes`, and `on`; the accepted false values
    /// are `0`, `false`, `no`, and `off`, all case-insensitive.
    public func bool(_ key: Swift.String) -> Swift.Bool? {
        guard let value = self[key]?.lowercased() else { return nil }
        switch value {
        case "1", "true", "yes", "on": return true
        case "0", "false", "no", "off": return false
        default: return nil
        }
    }

    /// Returns the string value for a URL-shaped key.
    ///
    /// URL parsing belongs to a higher layer; this package remains Foundation-free.
    public func url(_ key: Swift.String) -> Swift.String? {
        self[key]
    }
}
