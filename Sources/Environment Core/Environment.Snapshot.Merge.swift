extension Environment.Snapshot {

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

    public var merge: Merge {
        Merge(self)
    }
}

extension Environment.Snapshot.Merge {

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
