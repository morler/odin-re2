package main

import "core:fmt"

// Import the regexp package from core directory
import regexp "../core"

main :: proc() {
    fmt.println("=== Odin RE2 Basic Usage Example ===")

    // Test 1: Simple literal matching
    {
        pattern, err := regexp.regexp("hello")
        if err != .NoError {
            fmt.printf("Error compiling pattern: %v\n", err)
            return
        }
        defer regexp.free_regexp(pattern)

        result, match_err := regexp.match(pattern, "hello world")
        if match_err != .NoError {
            fmt.printf("Error matching: %v\n", match_err)
            return
        }

        fmt.println("Test 1: Simple literal matching")
        fmt.printf("  Pattern: 'hello'\n")
        fmt.printf("  Text: 'hello world'\n")
        fmt.printf("  Matched: %v\n", result.matched)
        if result.matched {
            fmt.printf("  Match range: [%d, %d]\n", result.full_match.start, result.full_match.end)
            fmt.println("  ✓ SUCCESS")
        } else {
            fmt.println("  ✗ FAILED")
        }
        fmt.println()
    }

    // Test 2: Dot pattern matching
    {
        pattern, err := regexp.regexp("h.llo")
        if err != .NoError {
            fmt.printf("Error compiling pattern: %v\n", err)
            return
        }
        defer regexp.free_regexp(pattern)

        result, match_err := regexp.match(pattern, "hello")
        if match_err != .NoError {
            fmt.printf("Error matching: %v\n", match_err)
            return
        }

        fmt.println("Test 2: Dot pattern matching")
        fmt.printf("  Pattern: 'h.llo'\n")
        fmt.printf("  Text: 'hello'\n")
        fmt.printf("  Matched: %v\n", result.matched)
        if result.matched {
            fmt.println("  ✓ SUCCESS")
        } else {
            fmt.println("  ✗ FAILED")
        }
        fmt.println()
    }

    // Test 3: Empty pattern
    {
        pattern, err := regexp.regexp("")
        if err != .NoError {
            fmt.printf("Error compiling pattern: %v\n", err)
            return
        }
        defer regexp.free_regexp(pattern)

        result, match_err := regexp.match(pattern, "test")
        if match_err != .NoError {
            fmt.printf("Error matching: %v\n", match_err)
            return
        }

        fmt.println("Test 3: Empty pattern matching")
        fmt.printf("  Pattern: '' (empty)\n")
        fmt.printf("  Text: 'test'\n")
        fmt.printf("  Matched: %v\n", result.matched)
        if result.matched {
            fmt.println("  ✓ SUCCESS")
        } else {
            fmt.println("  ✗ FAILED")
        }
        fmt.println()
    }

    fmt.println("=== All tests completed ===")
}