extension Environment {

    public struct Snapshot: Sendable, Hashable {

        public var values: [Swift.String: Swift.String]
    }
}

extension Environment.Snapshot {

    public init() {
        self.values = [:]
    }

    public init(_ values: [Swift.String: Swift.String]) {
        self.values = values
    }
}

extension Environment.Snapshot {

    public subscript(name: Swift.String) -> Swift.String? {
        get { values[name] }
        set { values[name] = newValue }
    }
}
