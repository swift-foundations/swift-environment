extension Environment {

    public struct Dotenv: Sendable, Hashable {

        public var values: [Swift.String: Swift.String]

        public init(_ values: [Swift.String: Swift.String] = [:]) {
            self.values = values
        }
    }
}

extension Environment.Dotenv {

    public init(parsing text: Swift.String) throws(Environment.Dotenv.Error) {

        let asciiUnderscore: Swift.UInt8 = 0x5F
        let asciiDot: Swift.UInt8 = 0x2E
        let asciiHyphen: Swift.UInt8 = 0x2D
        let asciiSpace: Swift.UInt8 = 0x20
        let asciiTab: Swift.UInt8 = 0x09
        let asciiHash: Swift.UInt8 = 0x23
        let asciiEquals: Swift.UInt8 = 0x3D
        let asciiDoubleQuote: Swift.UInt8 = 0x22
        let asciiSingleQuote: Swift.UInt8 = 0x27
        let asciiBackslash: Swift.UInt8 = 0x5C
        let asciiCarriageReturn: Swift.UInt8 = 0x0D
        let asciiNewline: Swift.UInt8 = 0x0A

        let rawBytes = Swift.Array(text.utf8)
        var bytes: [Swift.UInt8] = []
        bytes.reserveCapacity(rawBytes.count)
        var rawIndex = 0
        while rawIndex < rawBytes.count {
            let byte = rawBytes[rawIndex]
            if byte == asciiCarriageReturn, rawIndex + 1 < rawBytes.endIndex,
                rawBytes[rawIndex + 1] == asciiNewline
            {
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
            byte >= 0x30 && byte <= 0x39
        }

        func isAlpha(_ byte: Swift.UInt8) -> Swift.Bool {
            (byte >= 0x41 && byte <= 0x5A)
                || (byte >= 0x61 && byte <= 0x7A)
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

        func consumeExportPrefixIfPresent() {
            let word: [Swift.UInt8] = [0x65, 0x78, 0x70, 0x6F, 0x72, 0x74]
            guard index + word.count < count else { return }
            guard word.indices.allSatisfy({ bytes[index + $0] == word[$0] }) else { return }
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

                quoted: while index < count {
                    switch bytes[index] {
                    case 0x22:
                        index += 1
                        closed = true
                        break quoted

                    case 0x5C:
                        index += 1
                        guard index < count else {
                            throw .unterminatedQuote(line: recordLine)
                        }
                        switch bytes[index] {
                        case 0x6E: valueBytes.append(asciiNewline)
                        case 0x72: valueBytes.append(asciiCarriageReturn)
                        case 0x74: valueBytes.append(asciiTab)
                        case 0x5C: valueBytes.append(asciiBackslash)
                        case 0x22: valueBytes.append(asciiDoubleQuote)

                        default:
                            throw .invalidEscape(line: line)
                        }
                        index += 1

                    case 0x0A:
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
