package main

import "core:fmt"
import "./regexp"

main :: proc() {
	fmt.println("Testing dotall behavior...")
	
	// Test dot behavior - should not cross newlines
	pattern, err := regexp.regexp("a.*b")
	if err != .NoError {
		fmt.printf("Failed to compile pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	fmt.println("Pattern compiled successfully")
	
	// Test case: should not match across newlines
	text := "a\nc\nb"
	fmt.printf("Testing text: '%s'\n", text)
	
	result, match_err := regexp.match(pattern, text)
	if match_err != .NoError {
		fmt.printf("Match error: %v\n", match_err)
		return
	}
	
	fmt.printf("Matched: %v\n", result.matched)
	if result.matched {
		match_text := text[result.full_match.start:result.full_match.end]
		fmt.printf("Match: '%s' (range: %d-%d)\n", match_text, result.full_match.start, result.full_match.end)
	} else {
		fmt.printf("No match found (correct behavior)\n")
	}
}