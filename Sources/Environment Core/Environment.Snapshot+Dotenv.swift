extension Environment.Snapshot {

    public init(_ dotenv: Environment.Dotenv) {
        self.init(dotenv.values)
    }
}
