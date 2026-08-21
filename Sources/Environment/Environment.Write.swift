public import Environment_Core
public import Kernel
internal import Synchronization

extension Environment {

    public struct Write: Sendable {
        @usableFromInline
        internal init() {}
    }
}

extension Environment {

    public static var write: Write { Write() }
}

extension Environment.Write {

    public func callAsFunction(
        _ name: Swift.String,
        to value: Swift.String
    ) throws(Kernel.Environment.Error) {
        try set(name, to: value, overwrite: true)
    }

    public func set(
        _ name: Swift.String,
        to value: Swift.String,
        overwrite: Bool
    ) throws(Kernel.Environment.Error) {
        try Environment.lock.withLock { _ throws(Kernel.Environment.Error) in
            unsafe try Kernel.Environment.set(name, to: value, overwrite: overwrite)
        }
    }

    public func unset(_ name: Swift.String) throws(Kernel.Environment.Error) {
        try Environment.lock.withLock { _ throws(Kernel.Environment.Error) in
            unsafe try Kernel.Environment.unset(name)
        }
    }
}
