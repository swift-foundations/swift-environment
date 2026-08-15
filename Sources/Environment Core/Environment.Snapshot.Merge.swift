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
    /// Accessor for merge operations.
    public struct Merge: Sendable {
        @usableFromInline
        internal var snapshot: Environment.Snapshot

        @usableFromInline
        internal init(_ snapshot: Environment.Snapshot) {
            self.snapshot = snapshot
        }
    }
}

extension Environment.Snapshot {
    /// Merge operations on this snapshot.
    public var merge: Merge {
        Merge(self)
    }
}

extension Environment.Snapshot.Merge {
    /// Merges modifications and returns a new snapshot.
    ///
    /// - Parameter modifications: Keys map to new values. Nil values remove the variable.
    /// - Returns: A new snapshot with the modifications applied.
    public func callAsFunction(
        _ modifications: [Swift.String: Swift.String?]
    ) -> Environment.Snapshot {
        var result = snapshot
        for (key, value) in modifications {
            if let value {
                result.values[key] = value
            } else {
                result.values.removeValue(forKey: key)
            }
        }
        return result
    }
}

extension Environment.Snapshot {
    /// Merges modifications into this snapshot.
    ///
    /// - Parameter modifications: Keys map to new values. Nil values remove the variable.
    public mutating func merge(_ modifications: [Swift.String: Swift.String?]) {
        for (key, value) in modifications {
            if let value {
                values[key] = value
            } else {
                values.removeValue(forKey: key)
            }
        }
    }
}
