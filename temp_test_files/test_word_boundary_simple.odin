package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Testing Word Boundary Implementation ===")
	
	// Test basic word boundary
	fmt.println("Compiling pattern \\bhello...")
	pattern, err := regexp.regexp("\\bhello")
	if err != .NoError {
		fmt.printf("Pattern compilation failed: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	fmt.println("Pattern compiled successfully!")
	
	// Test cases
	test_cases := [?]string{
		"hello world",
		"say hello!",
		"ahello world",  // Should not match
		"hello",        // Should match
	}
	
	fmt.println("Running test cases...")
	for i in 0..<len(test_cases) {
		text := test_cases[i]
		fmt.printf("Testing '%s'...\n", text)
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Match error for '%s': %v\n", text, match_err)
			continue
		}
		
		fmt.printf("Test %d: '%s' -> ", i + 1, text)
		if result.matched {
			fmt.printf("MATCH at %d-%d\n", result.full_match.start, result.full_match.end)
		} else {
			fmt.println("NO MATCH")
		}
	}
	fmt.println("Test cases completed.")
	
	// Test non-word boundary
	fmt.println("\n=== Testing Non-Word Boundary ===")
	pattern2, err2 := regexp.regexp("\\Bhello\\B")
	if err2 != .NoError {
		fmt.printf("Pattern2 compilation failed: %v\n", err2)
		return
	}
	defer regexp.free_regexp(pattern2)
	
	test_cases2 := [?]string{
		"ahelloa",      // Should match
		"hello",        // Should not match
		" hello ",      // Should not match
		"prehellopost", // Should match
	}
	
	for i in 0..<len(test_cases2) {
		text := test_cases2[i]
		result, match_err := regexp.match(pattern2, text)
		if match_err != .NoError {
			fmt.printf("Match error for '%s': %v\n", text, match_err)
			continue
		}
		
		fmt.printf("Test %d: '%s' -> ", i + 1, text)
		if result.matched {
			fmt.printf("MATCH at %d-%d\n", result.full_match.start, result.full_match.end)
		} else {
			fmt.println("NO MATCH")
		}
	}
	
	fmt.println("\n=== Word Boundary Test Complete ===")
}