extension Environment.Dotenv {

    public enum Error: Swift.Error, Sendable, Equatable, Hashable {

        case invalidKey(line: Swift.Int)

        case missingSeparator(line: Swift.Int)

        case unterminatedQuote(line: Swift.Int)

        case invalidEscape(line: Swift.Int)
    }
}
