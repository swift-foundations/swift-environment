public import Environment_Core
internal import Kernel
internal import Strings
internal import Synchronization

extension Environment {

    public struct Read: Sendable {
        @usableFromInline
        internal init() {}
    }
}

extension Environment {

    public static var read: Read { Read() }
}

extension Environment.Read {

    public func callAsFunction(_ name: Swift.String) -> Swift.String? {
        Environment.lock.withLock { _ -> Swift.String? in
            guard let value = unsafe Kernel.Environment.get(name) else { return nil }
            return Swift.String(value.view)
        }
    }

    public func all() -> [Swift.String: Swift.String] {
        Environment.lock.withLock { _ in
            var result: [Swift.String: Swift.String] = [:]
            #if os(Windows)
                guard var entries = Kernel.Environment.entries() else {
                    return result
                }
            #else
                var entries = Kernel.Environment.entries()
            #endif
            while let entry = entries.next() {
                let name = Self.lossyDecoded(entry.name)
                let value = Self.lossyDecoded(entry.value)
                result[name] = value
            }
            return result
        }
    }

    public func isSet(_ name: Swift.String) -> Bool {
        Environment.lock.withLock { _ -> Bool in
            unsafe (Kernel.Environment.get(name) != nil)
        }
    }
}

extension Environment.Read {
    #if os(Windows)

        @inline(__always)
        fileprivate static func lossyDecoded(
            _ codeUnits: borrowing String_Primitives.String.Borrowed
        ) -> Swift.String {
            unsafe codeUnits.span.withUnsafeBufferPointer { buffer in
                unsafe Swift.String.lossy(platformNative: Array(buffer))
            }
        }
    #else

        @inline(__always)
        fileprivate static func lossyDecoded(
            _ codeUnits: Swift.Span<String_Primitives.String.Char>
        ) -> Swift.String {
            codeUnits.withUnsafeBufferPointer { buffer in
                unsafe Swift.String.lossy(platformNative: Array(buffer))
            }
        }
    #endif
}
