import Environment
import Kernel
import Testing

extension Environment {
    @Suite
    struct Test {
        @Test
        func `Read existing PATH variable`() {
            let path = Environment.read("PATH")
            #expect(path != nil)
        }

        @Test
        func `Read non-existent variable`() {
            let value = Environment.read("__NONEXISTENT_VAR_FOR_TESTING__")
            #expect(value == nil)
        }

        @Test
        func `Write and read variable`() throws {
            let testName = "__TEST_ENV_VAR__"
            let testValue = "test_value_123"

            do throws(Kernel.Environment.Error) {
                try Environment.write.unset(testName)
            } catch {}

            try Environment.write(testName, to: testValue)

            let readValue = Environment.read(testName)
            #expect(readValue == testValue)

            try Environment.write.unset(testName)
            #expect(Environment.read(testName) == nil)
        }

        @Test
        func `Read all environment variables`() {
            let all = Environment.read.all()

            #expect(all.contains { $0.key.uppercased() == "PATH" })
            #expect(all.count > 0)
        }

        @Test
        func `Snapshot typed accessors`() {
            let snapshot = Environment.Snapshot([
                "TEXT": "value",
                "NUMBER": "42",
                "TRUE": "YeS",
                "FALSE": "off",
                "URL": "https://example.com",
            ])

            #expect(snapshot.string("TEXT") == "value")
            #expect(snapshot.int("NUMBER") == 42)
            #expect(snapshot.bool("TRUE") == true)
            #expect(snapshot.bool("FALSE") == false)
            #expect(snapshot.url("URL") == "https://example.com")
            #expect(snapshot.int("TEXT") == nil)
            #expect(snapshot.bool("TEXT") == nil)
        }

        @Test
        func `TaskLocal overlay`() async throws {
            let testName = "__TEST_OVERLAY_VAR__"

            do throws(Kernel.Environment.Error) {
                try Environment.write.unset(testName)
            } catch {}
            #expect(Environment.read(testName) == nil)

            try await Environment.withOverlay([testName: "overlay_value"]) {

                #expect(Environment.task.read(testName) == "overlay_value")

                #expect(Environment.read(testName) == nil)
            }

            #expect(Environment.task.read(testName) == nil)
        }
    }
}
