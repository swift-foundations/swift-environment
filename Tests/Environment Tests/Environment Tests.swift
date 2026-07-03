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

import Environment
import Testing

@Suite("Environment Tests")
struct EnvironmentTests {
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

        // Clean up first
        try? Environment.write.unset(testName)

        // Set the variable
        try Environment.write(testName, to: testValue)

        // Read it back
        let readValue = Environment.read(testName)
        #expect(readValue == testValue)

        // Clean up
        try Environment.write.unset(testName)
        #expect(Environment.read(testName) == nil)
    }

    @Test
    func `Read all environment variables`() {
        let all = Environment.read.all()
        #expect(all["PATH"] != nil)
        #expect(all.count > 0)
    }

    @Test
    func `TaskLocal overlay`() async throws {
        let testName = "__TEST_OVERLAY_VAR__"

        // Ensure variable is not set in process
        try? Environment.write.unset(testName)
        #expect(Environment.read(testName) == nil)

        // Use overlay
        try await Environment.withOverlay([testName: "overlay_value"]) {
            // Task-local read sees overlay
            #expect(Environment.task.read(testName) == "overlay_value")

            // Process read still sees nil
            #expect(Environment.read(testName) == nil)
        }

        // Outside overlay, task read also sees nil
        #expect(Environment.task.read(testName) == nil)
    }
}
