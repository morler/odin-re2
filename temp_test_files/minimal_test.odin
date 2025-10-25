package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Minimal Test ===")
	
	// Test single character
	fmt.println("Testing single character 'a'...")
	pattern, err := regexp.regexp("a")
	if err != .NoError {
		fmt.printf("Pattern compilation failed: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	result, match_err := regexp.match(pattern, "a")
	if match_err != .NoError {
		fmt.printf("Match error: %v\n", match_err)
		return
	}
	
	fmt.printf("Single character match result: %v\n", result.matched)
	
	if result.matched {
		fmt.printf("Match range: %d-%d\n", result.full_match.start, result.full_match.end)
	}
	
	fmt.println("Minimal test completed!")
}