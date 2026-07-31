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

// This module is the process-environment half of swift-environment; it re-exports the
// value half so that `import Environment` still yields the whole surface. The
// re-export is of this package's own dependency-free target: it adds nothing to a
// consumer's dependency closure and brings no foreign type into a consumer's scope.
//
// `Kernel` is deliberately *not* re-exported. It was, and doing so put the entire
// kernel tower into the closure of every consumer that only wanted a `Snapshot`, and
// brought `String_Primitives.String` into scope where it shadowed `Swift.String`. A
// consumer that names `Kernel.Environment.Error` — the typed error `Environment.write`
// throws — imports `Kernel` itself.
@_exported public import Environment_Core
