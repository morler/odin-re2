package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("Testing empty pattern...")
	
	// Test empty pattern
	pattern, err := regexp.regexp("")
	if err != .NoError {
		fmt.println("Failed to compile empty pattern:", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{"", "anything", "hello", "world"}
	
	for test in test_cases {
		result, match_err := regexp.match(pattern, test)
		if match_err != .NoError {
			fmt.printf("Error matching empty pattern against '%s': %v\n", test, match_err)
		} else {
			fmt.printf("Empty pattern vs '%s' -> matched: %v\n", test, result.matched)
		}
	}
}