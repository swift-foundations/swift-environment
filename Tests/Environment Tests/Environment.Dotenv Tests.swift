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

extension Environment.Dotenv {
    @Suite("Environment.Dotenv Tests")
    struct Test {
        @Test
        func `Parses basic key-value pairs`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO=bar\nBAZ=qux\n")
            #expect(dotenv.values["FOO"] == "bar")
            #expect(dotenv.values["BAZ"] == "qux")
            #expect(dotenv.values.count == 2)
        }

        @Test
        func `Skips full-line comments`() throws {
            let dotenv = try Environment.Dotenv(
                parsing: "# a comment\nFOO=bar\n  # indented comment\nBAZ=qux\n"
            )
            #expect(dotenv.values.count == 2)
            #expect(dotenv.values["FOO"] == "bar")
            #expect(dotenv.values["BAZ"] == "qux")
        }

        @Test
        func `Allows a comment after a closing quote`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO=\"bar\" # trailing comment\n")
            #expect(dotenv.values["FOO"] == "bar")
        }

        @Test
        func `Skips optional export prefix`() throws {
            let dotenv = try Environment.Dotenv(parsing: "export FOO=bar\n")
            #expect(dotenv.values["FOO"] == "bar")
        }

        @Test
        func `Key literally starting with export is not treated as the prefix`() throws {
            let dotenv = try Environment.Dotenv(parsing: "exportFOO=bar\n")
            #expect(dotenv.values["exportFOO"] == "bar")
        }

        @Test
        func `Parses double-quoted value`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO=\"bar baz\"\n")
            #expect(dotenv.values["FOO"] == "bar baz")
        }

        @Test
        func `Parses single-quoted value literally, without interpreting escapes`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO='bar \\n baz'\n")
            #expect(dotenv.values["FOO"] == "bar \\n baz")
        }

        @Test
        func `Double-quoted value supports backslash escapes`() throws {
            let input = "FOO=\"line1\\nline2\\ttab\\\\slash\\\"quote\"\n"
            let dotenv = try Environment.Dotenv(parsing: input)
            #expect(dotenv.values["FOO"] == "line1\nline2\ttab\\slash\"quote")
        }

        @Test
        func `Double-quoted value may span multiple physical lines`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO=\"line one\nline two\"\n")
            #expect(dotenv.values["FOO"] == "line one\nline two")
        }

        @Test
        func `Single-quoted value may span multiple physical lines`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO='line one\nline two'\n")
            #expect(dotenv.values["FOO"] == "line one\nline two")
        }

        @Test
        func `Normalizes CRLF line endings`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO=bar\r\nBAZ=qux\r\n")
            #expect(dotenv.values["FOO"] == "bar")
            #expect(dotenv.values["BAZ"] == "qux")
        }

        @Test
        func `Skips blank lines`() throws {
            let dotenv = try Environment.Dotenv(parsing: "\n\nFOO=bar\n\n\nBAZ=qux\n\n")
            #expect(dotenv.values.count == 2)
            #expect(dotenv.values["FOO"] == "bar")
            #expect(dotenv.values["BAZ"] == "qux")
        }

        @Test
        func `Trims surrounding whitespace on key and unquoted value`() throws {
            let dotenv = try Environment.Dotenv(parsing: "  FOO  =  bar  \n")
            #expect(dotenv.values["FOO"] == "bar")
        }

        @Test
        func `Allows an empty unquoted value`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO=\n")
            #expect(dotenv.values["FOO"] == "")
        }

        @Test
        func `Later duplicate key overwrites earlier value`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO=first\nFOO=second\n")
            #expect(dotenv.values["FOO"] == "second")
            #expect(dotenv.values.count == 1)
        }

        @Test
        func `Invalid key throws invalidKey with the offending line`() {
            do {
                _ = try Environment.Dotenv(parsing: "1FOO=bar\n")
                Issue.record("Expected Environment.Dotenv.Error.invalidKey")
            } catch let error as Environment.Dotenv.Error {
                #expect(error == .invalidKey(line: 1))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func `Key admits interior hyphens`() throws {
            // Real-world externally-imposed keys this grammar must accept —
            // notably Apple's literal `apple-developer-merchantid-domain-association`
            // naming (uppercased here per this project's env-var convention).
            let dotenv = try Environment.Dotenv(
                parsing: """
                    LOCAL-SSL-SERVER-CRT=cert_content
                    LOCAL-SSL-SERVER-KEY=key_content
                    APPLE-DEVELOPER-MERCHANTID-DOMAIN-ASSOCIATION=association_content
                    """
            )
            #expect(dotenv.values["LOCAL-SSL-SERVER-CRT"] == "cert_content")
            #expect(dotenv.values["LOCAL-SSL-SERVER-KEY"] == "key_content")
            #expect(
                dotenv.values["APPLE-DEVELOPER-MERCHANTID-DOMAIN-ASSOCIATION"]
                    == "association_content"
            )
            #expect(dotenv.values.count == 3)
        }

        @Test
        func `A leading hyphen still throws invalidKey`() {
            do {
                _ = try Environment.Dotenv(parsing: "-FOO=bar\n")
                Issue.record("Expected Environment.Dotenv.Error.invalidKey")
            } catch let error as Environment.Dotenv.Error {
                #expect(error == .invalidKey(line: 1))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func `A truly malformed line still aborts the parse despite hyphen support`() {
            // Retention case: admitting interior hyphens must not loosen the parser
            // into accepting arbitrary punctuation — the loader stays strict.
            do {
                _ = try Environment.Dotenv(parsing: "FOO!BAR=baz\n")
                Issue.record("Expected Environment.Dotenv.Error.missingSeparator")
            } catch let error as Environment.Dotenv.Error {
                #expect(error == .missingSeparator(line: 1))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func `Missing separator throws missingSeparator with the offending line`() {
            do {
                _ = try Environment.Dotenv(parsing: "FOO bar\n")
                Issue.record("Expected Environment.Dotenv.Error.missingSeparator")
            } catch let error as Environment.Dotenv.Error {
                #expect(error == .missingSeparator(line: 1))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func `Trailing content after a closing quote throws missingSeparator`() {
            do {
                _ = try Environment.Dotenv(parsing: "FOO=\"bar\" garbage\n")
                Issue.record("Expected Environment.Dotenv.Error.missingSeparator")
            } catch let error as Environment.Dotenv.Error {
                #expect(error == .missingSeparator(line: 1))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func `Unterminated double quote throws unterminatedQuote with the opening line`() {
            do {
                _ = try Environment.Dotenv(parsing: "FOO=\"bar\n")
                Issue.record("Expected Environment.Dotenv.Error.unterminatedQuote")
            } catch let error as Environment.Dotenv.Error {
                #expect(error == .unterminatedQuote(line: 1))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func `Unterminated single quote throws unterminatedQuote with the opening line`() {
            do {
                _ = try Environment.Dotenv(parsing: "FOO='bar\n")
                Issue.record("Expected Environment.Dotenv.Error.unterminatedQuote")
            } catch let error as Environment.Dotenv.Error {
                #expect(error == .unterminatedQuote(line: 1))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func `Invalid escape sequence throws invalidEscape with the offending line`() {
            do {
                _ = try Environment.Dotenv(parsing: "FOO=\"bar\\zbaz\"\n")
                Issue.record("Expected Environment.Dotenv.Error.invalidEscape")
            } catch let error as Environment.Dotenv.Error {
                #expect(error == .invalidEscape(line: 1))
            } catch {
                Issue.record("Unexpected error: \(error)")
            }
        }

        @Test
        func `Snapshot can be created from a parsed Dotenv`() throws {
            let dotenv = try Environment.Dotenv(parsing: "FOO=bar\nBAZ=qux\n")
            let snapshot = Environment.Snapshot(dotenv)
            #expect(snapshot.values == dotenv.values)
            #expect(snapshot["FOO"] == "bar")
        }
    }
}
