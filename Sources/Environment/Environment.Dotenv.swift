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

extension Environment {
    /// A parsed dotenv-format document: key-value pairs read from a `.env`-style text.
    ///
    /// There is no single, canonical specification for the "dotenv" format — behavior
    /// diverges across popular implementations (the Ruby `dotenv` gem, Node's `dotenv`
    /// package, Python's `python-dotenv`, and others) on edge cases such as comment
    /// handling, quoting, escapes, and multiline values. `Dotenv` does not claim
    /// conformance to any of those implementations; it implements this package's own
    /// conservative, common-denominator reading of the format. See `init(parsing:)`
    /// for the exact accepted grammar and `Environment.Dotenv.Error` for exactly which
    /// malformed inputs are rejected.
    public struct Dotenv: Sendable, Hashable {
        /// The parsed key-value pairs.
        public var values: [Swift.String: Swift.String]

        /// Creates a dotenv value from already-parsed key-value pairs.
        ///
        /// - Parameter values: The key-value pairs.
        public init(_ values: [Swift.String: Swift.String] = [:]) {
            self.values = values
        }
    }
}

// MARK: - Parsing

extension Environment.Dotenv {
    /// Parses dotenv-format text into key-value pairs.
    ///
    /// Grammar (de-facto, not spec-backed — see the type-level documentation):
    ///
    /// - Lines are separated by `\n`. A `\r` immediately preceding a `\n` is dropped
    ///   before scanning (CRLF support); this normalization applies uniformly,
    ///   including inside multiline quoted values.
    /// - Blank lines are skipped.
    /// - A line whose first non-space/tab byte is `#` is a full-line comment and is
    ///   skipped.
    /// - An optional literal `export` followed by whitespace, before the key, is
    ///   skipped.
    /// - A key matches `[A-Za-z_][A-Za-z0-9_.-]*`, with surrounding whitespace trimmed.
    ///   Interior hyphens are admitted (but a hyphen may not start a key) because at
    ///   least one legacy key is externally imposed — Apple's own dotenv-style naming
    ///   for `apple-developer-merchantid-domain-association` uses hyphens literally,
    ///   and this parser has to accept it as-is rather than rewrite it. Note for
    ///   POSIX-export consumers: a dotenv **file** is not a shell — `export` and
    ///   direct assignment of a hyphenated identifier are not valid POSIX shell
    ///   syntax, so code that re-exports these key/value pairs into a POSIX
    ///   environment (e.g. via `export $(cat .env)` or similar) must map hyphenated
    ///   keys to a shell-legal form itself; this parser does not do that mapping.
    /// - Everything up to (and including skipping) the `=` separator, and the value
    ///   that follows, is then read:
    ///   - Leading whitespace before the value is trimmed.
    ///   - A double-quoted value supports the escapes `\n`, `\r`, `\t`, `\\`, `\"` and
    ///     may span multiple physical lines (the literal newlines are kept in the
    ///     value). Any other backslash escape is rejected.
    ///   - A single-quoted value is literal (no escapes) and may also span multiple
    ///     physical lines.
    ///   - An unquoted value runs to the end of the line, with leading/trailing
    ///     space and tab trimmed. A trailing `# comment` on an unquoted value is
    ///     **not** stripped — it is kept as part of the value, verbatim. This keeps
    ///     unquoted-value parsing simple and predictable at the cost of not
    ///     supporting inline comments on unquoted values; quote the value if a
    ///     trailing comment is needed.
    /// - After a closing quote, only trailing whitespace or a `#`-comment may follow
    ///   on the line; anything else is rejected (see
    ///   `Environment.Dotenv.Error.missingSeparator(line:)`).
    /// - Later duplicate keys overwrite earlier ones.
    ///
    /// - Parameter text: The dotenv-format document to parse.
    /// - Throws: `Environment.Dotenv.Error` describing the first malformed line
    ///   encountered.
    public init(parsing text: Swift.String) throws(Environment.Dotenv.Error) {
        // ASCII byte constants used throughout the scan. Spelled as hex literals
        // (not `UInt8(ascii:)`): ASCII_Primitives — re-exported via Strings — vends
        // its own `UInt8.init(ascii: Character)`, which makes the stdlib
        // `init(ascii: Unicode.Scalar)` ambiguous for a string-literal argument.
        let asciiUnderscore: Swift.UInt8 = 0x5F  // '_'
        let asciiDot: Swift.UInt8 = 0x2E  // '.'
        let asciiHyphen: Swift.UInt8 = 0x2D  // '-'
        let asciiSpace: Swift.UInt8 = 0x20  // ' '
        let asciiTab: Swift.UInt8 = 0x09  // '\t'
        let asciiHash: Swift.UInt8 = 0x23  // '#'
        let asciiEquals: Swift.UInt8 = 0x3D  // '='
        let asciiDoubleQuote: Swift.UInt8 = 0x22  // '"'
        let asciiSingleQuote: Swift.UInt8 = 0x27  // '\''
        let asciiBackslash: Swift.UInt8 = 0x5C  // '\'
        let asciiCarriageReturn: Swift.UInt8 = 0x0D  // '\r'
        let asciiNewline: Swift.UInt8 = 0x0A  // '\n'

        // Normalize CRLF -> LF up front: drop every `\r` that is immediately
        // followed by `\n`. This keeps the rest of the scan free of `\r`
        // special-casing, including inside multiline quoted values.
        let rawBytes = Swift.Array(text.utf8)
        var bytes: [Swift.UInt8] = []
        bytes.reserveCapacity(rawBytes.count)
        var rawIndex = 0
        while rawIndex < rawBytes.count {
            let byte = rawBytes[rawIndex]
            if byte == asciiCarriageReturn, rawIndex + 1 < rawBytes.count, rawBytes[rawIndex + 1] == asciiNewline {
                rawIndex += 1
                continue
            }
            bytes.append(byte)
            rawIndex += 1
        }

        let count = bytes.count
        var index = 0
        var line = 1
        var values: [Swift.String: Swift.String] = [:]

        func isSpaceOrTab(_ byte: Swift.UInt8) -> Swift.Bool {
            byte == asciiSpace || byte == asciiTab
        }

        func isDigit(_ byte: Swift.UInt8) -> Swift.Bool {
            byte >= 0x30 && byte <= 0x39  // '0'...'9'
        }

        func isAlpha(_ byte: Swift.UInt8) -> Swift.Bool {
            (byte >= 0x41 && byte <= 0x5A)  // 'A'...'Z'
                || (byte >= 0x61 && byte <= 0x7A)  // 'a'...'z'
        }

        func isKeyStart(_ byte: Swift.UInt8) -> Swift.Bool {
            isAlpha(byte) || byte == asciiUnderscore
        }

        func isKeyContinuation(_ byte: Swift.UInt8) -> Swift.Bool {
            isAlpha(byte) || isDigit(byte) || byte == asciiUnderscore || byte == asciiDot
                || byte == asciiHyphen
        }

        func skipSpacesAndTabs() {
            while index < count, isSpaceOrTab(bytes[index]) {
                index += 1
            }
        }

        // Matches the literal `export` only when followed by whitespace, so a key
        // that merely starts with "export" (e.g. `exportFOO=bar`) is left untouched.
        func consumeExportPrefixIfPresent() {
            let word: [Swift.UInt8] = [0x65, 0x78, 0x70, 0x6F, 0x72, 0x74]  // "export"
            guard index + word.count < count else { return }
            for offset in 0..<word.count where bytes[index + offset] != word[offset] {
                return
            }
            guard isSpaceOrTab(bytes[index + word.count]) else { return }
            index += word.count
            skipSpacesAndTabs()
        }

        while index < count {
            skipSpacesAndTabs()

            guard index < count else { break }

            if bytes[index] == asciiNewline {
                index += 1
                line += 1
                continue
            }

            if bytes[index] == asciiHash {
                while index < count, bytes[index] != asciiNewline {
                    index += 1
                }
                if index < count {
                    index += 1
                    line += 1
                }
                continue
            }

            let recordLine = line

            consumeExportPrefixIfPresent()

            guard index < count, isKeyStart(bytes[index]) else {
                throw .invalidKey(line: recordLine)
            }
            var keyBytes: [Swift.UInt8] = []
            while index < count, isKeyContinuation(bytes[index]) {
                keyBytes.append(bytes[index])
                index += 1
            }

            skipSpacesAndTabs()
            guard index < count, bytes[index] == asciiEquals else {
                throw .missingSeparator(line: recordLine)
            }
            index += 1
            skipSpacesAndTabs()

            let value: Swift.String
            if index < count, bytes[index] == asciiDoubleQuote {
                index += 1
                var valueBytes: [Swift.UInt8] = []
                var closed = false
                // Case labels below are raw hex literals (unambiguous expression
                // patterns), matching the ecosystem byte-classification idiom —
                // see `Lexer.Classify.isOperatorStart` — rather than named `let`
                // constants, whose use as case labels is easy to misread as a
                // rebinding rather than a value comparison.
                quoted: while index < count {
                    switch bytes[index] {
                    case 0x22:  // '"' — closing quote
                        index += 1
                        closed = true
                        break quoted

                    case 0x5C:  // '\' — escape introducer
                        index += 1
                        guard index < count else {
                            throw .unterminatedQuote(line: recordLine)
                        }
                        switch bytes[index] {
                        case 0x6E: valueBytes.append(asciiNewline)  // 'n' -> \n
                        case 0x72: valueBytes.append(asciiCarriageReturn)  // 'r' -> \r
                        case 0x74: valueBytes.append(asciiTab)  // 't' -> \t
                        case 0x5C: valueBytes.append(asciiBackslash)  // '\' -> \
                        case 0x22: valueBytes.append(asciiDoubleQuote)  // '"' -> "

                        default:
                            throw .invalidEscape(line: line)
                        }
                        index += 1

                    case 0x0A:  // '\n' — literal newline kept in a multiline value
                        line += 1
                        valueBytes.append(asciiNewline)
                        index += 1

                    default:
                        valueBytes.append(bytes[index])
                        index += 1
                    }
                }
                guard closed else {
                    throw .unterminatedQuote(line: recordLine)
                }
                value = Swift.String(decoding: valueBytes, as: Swift.UTF8.self)

                skipSpacesAndTabs()
                if index < count, bytes[index] == asciiHash {
                    while index < count, bytes[index] != asciiNewline {
                        index += 1
                    }
                } else if index < count, bytes[index] != asciiNewline {
                    throw .missingSeparator(line: line)
                }
            } else if index < count, bytes[index] == asciiSingleQuote {
                index += 1
                var valueBytes: [Swift.UInt8] = []
                var closed = false
                while index < count {
                    let byte = bytes[index]
                    if byte == asciiSingleQuote {
                        index += 1
                        closed = true
                        break
                    }
                    if byte == asciiNewline {
                        line += 1
                    }
                    valueBytes.append(byte)
                    index += 1
                }
                guard closed else {
                    throw .unterminatedQuote(line: recordLine)
                }
                value = Swift.String(decoding: valueBytes, as: Swift.UTF8.self)

                skipSpacesAndTabs()
                if index < count, bytes[index] == asciiHash {
                    while index < count, bytes[index] != asciiNewline {
                        index += 1
                    }
                } else if index < count, bytes[index] != asciiNewline {
                    throw .missingSeparator(line: line)
                }
            } else {
                var valueBytes: [Swift.UInt8] = []
                while index < count, bytes[index] != asciiNewline {
                    valueBytes.append(bytes[index])
                    index += 1
                }
                while let last = valueBytes.last, isSpaceOrTab(last) {
                    valueBytes.removeLast()
                }
                value = Swift.String(decoding: valueBytes, as: Swift.UTF8.self)
            }

            values[Swift.String(decoding: keyBytes, as: Swift.UTF8.self)] = value

            if index < count, bytes[index] == asciiNewline {
                index += 1
                line += 1
            }
        }

        self.values = values
    }
}
