package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Debug Anchor Test ===")
	
	// Test the failing case
	pattern := "^a"
	text := "banana"
	
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
		fmt.printf("Match range: %d-%d\n", result.full_match.start, result.full_match.end)
		fmt.printf("Matched text: %q\n", text[result.full_match.start:result.full_match.end])
	}
}