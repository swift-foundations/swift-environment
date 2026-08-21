#if !os(Windows)

    import Environment
    import Testing

    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #elseif canImport(Musl)
        import Musl
    #endif

    extension Environment.Read {
        @Suite
        struct `Edge Case` {

            @Test
            func `all decodes a non-UTF8 environment value losslessly instead of trapping`() {
                let name = "__SWIFT_ENVIRONMENT_F001_INVALID_UTF8__"

                let rawValue: [UInt8] = [0x76, 0x61, 0x6C, 0xFF, 0x00]

                rawValue.withUnsafeBufferPointer { buffer in
                    buffer.baseAddress!.withMemoryRebound(
                        to: CChar.self,
                        capacity: buffer.count
                    ) { cString in
                        _ = setenv(name, cString, 1)
                    }
                }
                defer { _ = unsetenv(name) }

                let all = Environment.read.all()

                #expect(all[name] == "val\u{FFFD}")
            }
        }
    }

#endif
