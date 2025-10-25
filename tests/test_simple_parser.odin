package main

import "core:fmt"
import "regexp"

main :: proc() {
    fmt.println("Testing basic literal parsing...")
    
    // Test basic literal parsing (User Story 1)
    re, err := regexp.regexp("hello")
    if err != .NoError {
        fmt.printf("Failed to parse 'hello': %v\n", err)
        return
    }
    defer regexp.free_regexp(re)
    
    // Test matching
    result, match_err := regexp.match(re, "hello world")
    if match_err != .NoError {
        fmt.printf("Match error: %v\n", match_err)
        return
    }
    
    if result.matched {
        fmt.printf("Success! Matched 'hello' at %d-%d\n", result.full_match.start, result.full_match.end)
    } else {
        fmt.println("Failed to match 'hello'")
    }
}