# ``Environment``

@Metadata {
    @DisplayName("Environment")
    @TitleHeading("Swift Foundations")
}

Thread-safe, cross-platform environment variable management: direct
process-environment read/write synchronized internally on a process-global
mutex, immutable `Environment.Snapshot`s for point-in-time capture and
process spawning, `Environment.task` TaskLocal overlays for scoped
overrides, and a `.env`-format `Environment.Dotenv` parser implementing this
package's own conservative common-denominator grammar rather than
conformance to any single existing dotenv implementation.

## When to use this

Reach for this package wherever code reads or writes process environment
variables and needs the operation to be internally thread-safe, or needs to
capture, override, or restore environment state without mutating the real
process environment (via `Snapshot` or a `task`-scoped overlay). It cannot
protect against non-Swift code calling `getenv`/`setenv`/`putenv` directly;
coordinate externally if such code shares the process.

## Topics

### Related packages

- [swift-kernel](https://github.com/swift-foundations/swift-kernel) — the
  underlying syscall layer this package's direct reads and writes go
  through.
