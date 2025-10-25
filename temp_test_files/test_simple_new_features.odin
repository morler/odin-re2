package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("Testing new regex features...")
	
	// Test Unicode properties
	test_unicode_properties()
	
	fmt.println("Basic tests completed!")
}

test_unicode_properties :: proc() {
	fmt.println("\n=== Testing Unicode Properties ===")
	
	pattern := "\\p{L}+"
	text := "Hello123"
	
	fmt.printf("Pattern: %s\n", pattern)
	pat, err := regexp.regexp(pattern)
	if err != .NoError {
		fmt.printf("Error compiling pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(pat)
	
	result, err := regexp.match(pat, text)
	if err != .NoError {
		fmt.printf("Error matching '%s': %v\n", text, err)
		return
	}
	
	if result.matched {
		matched_text := text[result.full_match.start:result.full_match.end]
		fmt.printf("'%s' -> matches '%s'\n", text, matched_text)
	} else {
		fmt.printf("'%s' -> no match\n", text)
	}
}