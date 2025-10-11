package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== User Story 1 Simple Test ===")
	
	// Test basic literal matching
	pattern := "hello"
	text := "hello world"
	
	fmt.printf("Pattern: %s, Text: %s\n", pattern, text)
	
	// Compile regex
	regex, err := regexp.regexp(pattern)
	if err != .NoError {
		fmt.printf("❌ Failed to compile pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(regex)
	
	// Test match
	result, match_err := regexp.match(regex, text)
	if match_err != .NoError {
		fmt.printf("❌ Match error: %v\n", match_err)
		return
	}
	
	fmt.printf("Result: %v\n", result.matched)
	
	if result.matched {
		fmt.println("✅ User Story 1 PASSED - Basic literal matching works!")
	} else {
		fmt.println("❌ User Story 1 FAILED - Basic literal matching broken!")
	}
}