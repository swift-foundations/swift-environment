extension Environment.Snapshot {

    public func string(_ key: Swift.String) -> Swift.String? {
        self[key]
    }

    public func int(_ key: Swift.String) -> Swift.Int? {
        self[key].flatMap(Swift.Int.init)
    }

    public func bool(_ key: Swift.String) -> Swift.Bool? {
        guard let value = self[key]?.lowercased() else { return nil }
        switch value {
        case "1", "true", "yes", "on": return true
        case "0", "false", "no", "off": return false
        default: return nil
        }
    }

    public func url(_ key: Swift.String) -> Swift.String? {
        self[key]
    }
}
