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
    /// TaskLocal storage for environment overlay.
    @TaskLocal
    @usableFromInline
    internal static var overlay: Snapshot?
}

extension Environment {
    /// Accessor for task-local environment overlay operations.
    ///
    /// Task-local overlays provide isolated environment views for:
    /// - **Test isolation**: Each test can have its own environment without global mutation
    /// - **Structured concurrency**: Child tasks inherit the parent's overlay
    /// - **Temporary overrides**: Override values without touching process state
    ///
    /// ## Semantics
    ///
    /// - `Environment.task.read` checks the TaskLocal overlay first, then falls back to process env
    /// - `Environment.task.write` mutates the overlay only (virtual, not process state)
    /// - `Environment.read` and `Environment.write` always use process environment (unchanged)
    ///
    /// ## Important
    ///
    /// Spawned child processes **do not** see TaskLocal overlays. Use `Environment.task.effective()`
    /// to build a `Snapshot` that merges the overlay with the process environment for spawning.
    public struct Task: Sendable {
        @usableFromInline
        internal init() {}
    }
}

extension Environment {
    /// Task-local overlay operations.
    public static var task: Task { Task() }
}

// MARK: - Read Operations

extension Environment.Task {
    /// Returns the value from the TaskLocal overlay, or falls back to the process environment.
    ///
    /// - Parameter name: The name of the environment variable.
    /// - Returns: The value from overlay if present, otherwise from process environment.
    public func read(_ name: Swift.String) -> Swift.String? {
        if let overlay = Environment.overlay {
            if let value = overlay.values[name] {
                return value
            }
        }
        return Environment.read(name)
    }

    /// Returns all environment variables, with TaskLocal overlay merged over process environment.
    public func all() -> [Swift.String: Swift.String] {
        var result = Environment.read.all()
        if let overlay = Environment.overlay {
            for (key, value) in overlay.values {
                result[key] = value
            }
        }
        return result
    }

    /// Returns true if the variable is set in the overlay or process environment.
    ///
    /// - Parameter name: The name of the environment variable.
    /// - Returns: true if the variable is set in either overlay or process environment.
    public func isSet(_ name: Swift.String) -> Bool {
        if let overlay = Environment.overlay, overlay.values[name] != nil {
            return true
        }
        return Environment.read.isSet(name)
    }

    /// Returns an effective snapshot: process environment merged with TaskLocal overlay.
    ///
    /// Use this when spawning a child process that should see the overlay values.
    public func effective() -> Environment.Snapshot {
        var result = Environment.Snapshot.current()
        if let overlay = Environment.overlay {
            for (key, value) in overlay.values {
                result.values[key] = value
            }
        }
        return result
    }

    /// Returns the current TaskLocal overlay snapshot, if any.
    public func overlay() -> Environment.Snapshot? {
        Environment.overlay
    }
}

// MARK: - Scoped Overlay

extension Environment {
    /// Executes a closure with a TaskLocal environment overlay.
    ///
    /// The overlay is inherited by child tasks created within the closure.
    /// Reads via `Environment.task.read` will see overlay values first.
    ///
    /// ```swift
    /// try await Environment.withOverlay(["DEBUG": "1"]) {
    ///     // Environment.task.read("DEBUG") returns "1"
    ///     // Environment.read("DEBUG") still returns process value
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - values: The environment variable overrides.
    ///   - body: The closure to execute with the overlay.
    /// - Returns: The result of the closure.
    public static func withOverlay<R: Sendable, E: Swift.Error>(
        _ values: [Swift.String: Swift.String],
        perform body: () async throws(E) -> R
    ) async throws(E) -> R {
        // Result-wrapping workaround: stdlib's TaskLocal.withValue rethrows erases
        // typed error info. When FullTypedThrows (AvailableInProd) lands, replace
        // with: try await $overlay.withValue(Snapshot(values), operation: body)
        let result: Result<R, E> = await $overlay.withValue(
            Snapshot(values),
            operation: {
                do throws(E) {
                    return .success(try await body())
                } catch {
                    return .failure(error)
                }
            }
        )
        return try result.get()
    }

    /// Executes a closure with a TaskLocal environment overlay (synchronous).
    ///
    /// - Parameters:
    ///   - values: The environment variable overrides.
    ///   - body: The closure to execute with the overlay.
    /// - Returns: The result of the closure.
    public static func withOverlay<R, E: Swift.Error>(
        _ values: [Swift.String: Swift.String],
        perform body: () throws(E) -> R
    ) throws(E) -> R {
        // Result-wrapping workaround: stdlib's TaskLocal.withValue rethrows erases
        // typed error info. When FullTypedThrows (AvailableInProd) lands, replace
        // with: try $overlay.withValue(Snapshot(values), operation: body)
        let result: Result<R, E> = $overlay.withValue(
            Snapshot(values),
            operation: {
                do throws(E) {
                    return .success(try body())
                } catch {
                    return .failure(error)
                }
            }
        )
        return try result.get()
    }
}
