public import Environment_Core

extension Environment {

    @TaskLocal
    @usableFromInline
    internal static var overlay: Snapshot?
}

extension Environment {

    public struct Task: Sendable {
        @usableFromInline
        internal init() {}
    }
}

extension Environment {

    public static var task: Task { Task() }
}

extension Environment.Task {

    public func read(_ name: Swift.String) -> Swift.String? {
        if let overlay = Environment.overlay {
            if let value = overlay.values[name] {
                return value
            }
        }
        return Environment.read(name)
    }

    public func all() -> [Swift.String: Swift.String] {
        var result = Environment.read.all()
        if let overlay = Environment.overlay {
            for (key, value) in overlay.values {
                result[key] = value
            }
        }
        return result
    }

    public func isSet(_ name: Swift.String) -> Bool {
        if let overlay = Environment.overlay, overlay.values[name] != nil {
            return true
        }
        return Environment.read.isSet(name)
    }

    public func effective() -> Environment.Snapshot {
        var result = Environment.Snapshot.current()
        if let overlay = Environment.overlay {
            for (key, value) in overlay.values {
                result.values[key] = value
            }
        }
        return result
    }

    public func overlay() -> Environment.Snapshot? {
        Environment.overlay
    }
}

extension Environment {

    public static func withOverlay<R: Sendable, E: Swift.Error>(
        _ values: [Swift.String: Swift.String],
        perform body: () async throws(E) -> R
    ) async throws(E) -> R {

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

    public static func withOverlay<R, E: Swift.Error>(
        _ values: [Swift.String: Swift.String],
        perform body: () throws(E) -> R
    ) throws(E) -> R {

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
