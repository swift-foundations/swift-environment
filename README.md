# swift-environment

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Process environment variable access with thread-safe reads and writes, immutable snapshots, and task-local overlays for isolated overrides.

---

## Key Features

- **Process environment access** — read a single variable, enumerate all variables, or check presence with `Environment.read(...)`, `Environment.read.all()`, and `Environment.read.isSet(...)`.
- **Thread-safe reads and writes** — every operation is serialized through a process-global mutex, so concurrent callers that use this API never race on `getenv` / `setenv`.
- **Task-local overlays** — `Environment.withOverlay([...])` layers overrides onto the current scope and its child tasks without mutating real process state, giving each test or task an isolated view.
- **Immutable snapshots** — `Environment.Snapshot` captures the environment at a point in time; `merge` derives modified copies where a `nil` value removes a key, ready to hand to a spawned child process.
- **Typed throws** — writes fail with a typed `Kernel.Environment.Error`, so no `any Error` crosses the API surface.
- **Windows-aware enumeration** — `Environment.read.all()` automatically excludes Windows' internal `=`-prefixed pseudo-variables.

---

## Quick Start

`Environment.withOverlay` layers override values onto a scope and its child tasks without touching real process state — so a test or task can run against a modified environment while concurrent work, and the live process, see the original values. Doing this with raw `setenv` mutates global state and is not safe across concurrent callers.

```swift
import Environment

// Reads hit the real process environment and are thread-safe.
let realLevel = Environment.read("LOG_LEVEL")          // e.g. nil

// withOverlay layers values on top for a scope, without mutating
// global process state. The overlay is task-local, so concurrent work
// and the real environment are unaffected.
let scopedLevel = Environment.withOverlay(["LOG_LEVEL": "debug"]) {
    Environment.task.read("LOG_LEVEL")                 // "debug" — the overlay wins
}

print(realLevel ?? "unset", scopedLevel ?? "unset")    // unset debug
```

To build an environment for a spawned child process, snapshot the current state and derive a modified copy. A `nil` value removes a key:

```swift
import Environment

let base = Environment.Snapshot.current()
let childEnvironment = base.merge([
    "LOG_LEVEL": "debug",   // set
    "TMPDIR": nil           // remove
])
```

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Environment", package: "swift-environment")
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26.

---

## Error Handling

Parsing a dotenv document throws a typed `Environment.Dotenv.Error`; every case
carries the 1-based physical line it was detected on:

```
Environment.Dotenv.Error
├── .invalidKey(line:)          // key is empty or begins with a non-key byte
├── .missingSeparator(line:)    // a key line has no `=` (or trailing garbage)
├── .unterminatedQuote(line:)   // an opened quote never closed before EOF
└── .invalidEscape(line:)       // `\` in a double-quoted value followed by an
                                //   unsupported byte
```

```swift
do {
    let dotenv = try Environment.Dotenv(parsing: text)
    _ = dotenv
} catch .invalidKey(let line) {
    _ = line
} catch .missingSeparator(let line) {
    _ = line
} catch .unterminatedQuote(let line) {
    _ = line
} catch .invalidEscape(let line) {
    _ = line
}
```

Process-environment reads surface a separate typed `Kernel.Environment.Error`.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public release.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
