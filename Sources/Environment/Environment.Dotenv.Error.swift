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

extension Environment.Dotenv {
    /// Failure modes for parsing a dotenv-format document.
    ///
    /// `Dotenv` has no formal specification (see the type-level documentation on
    /// `Environment.Dotenv`); these cases describe the conservative grammar this
    /// parser accepts and where non-conforming input diverges from it. All line
    /// numbers are 1-based and count physical lines (lines separated by `\n`,
    /// after CRLF normalization).
    public enum Error: Swift.Error, Sendable, Equatable, Hashable {
        /// The line did not begin with a well-formed key — a run of
        /// `[A-Za-z_][A-Za-z0-9_.]*` starting with a letter or underscore, read
        /// after skipping the optional `export ` prefix. Covers both an empty key
        /// (nothing at all before `=`, end of line, or non-key-start byte) and a
        /// first byte outside the permitted key-start set.
        case invalidKey(line: Swift.Int)

        /// A non-blank, non-comment line contained a key but no `=` separator
        /// before the end of the line (or end of input).
        ///
        /// This case is also reused for content trailing a closed quote that is
        /// neither whitespace nor a `#`-comment (e.g. `KEY="value" garbage`): the
        /// trailing content plays the same structural role as a missing
        /// separator — the line is not shaped like a valid `key=value` record —
        /// so it is not given a distinct case.
        case missingSeparator(line: Swift.Int)

        /// A single- or double-quoted value was opened but never closed before
        /// the end of input. Reports the line the opening quote was found on,
        /// even when the unterminated quote spans further lines before EOF.
        case unterminatedQuote(line: Swift.Int)

        /// A `\` inside a double-quoted value was followed by a byte other than
        /// `n`, `r`, `t`, `\`, or `"`. Reports the physical line the offending
        /// escape sequence occurs on.
        case invalidEscape(line: Swift.Int)
    }
}
