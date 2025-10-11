package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Testing Simple Quantifier Logic ===")
	
	// Test the most basic case
	pattern := "a?"
	text := "aa"
	
	fmt.printf("Pattern: %s, Text: %s\n", pattern, text)
	
	re, err := regexp.regexp(pattern)
	if err != .NoError {
		fmt.printf("Failed to compile: %v\n", err)
		return
	}
	defer regexp.free_regexp(re)
	
	matched, match_err := regexp.match_string(pattern, text)
	fmt.printf("Result: %v (error: %v)\n", matched, match_err)
	
	// Let's also test what position it matches at
	result, result_err := regexp.match(re, text)
	if result_err == .NoError {
		fmt.printf("Full match: %v\n", result.full_match)
		fmt.printf("Captures: %v\n", result.captures)
	}
}