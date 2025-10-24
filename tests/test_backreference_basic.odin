package main

import "core:fmt"
import "../regexp"

main :: proc() {
	fmt.println("=== Testing Backreference Support ===")
	
	// Test cases for backreferences
	test_cases := [?]struct {
		pattern: string,
		text:    string,
		should_match: bool,
		description: string,
	}{
		{"(\\w+)\\1", "testtest", true, "Simple backreference \\1"},
		{"(\\w+)\\1", "testother", false, "Backreference should fail"},
		{"(\\d+)\\1", "123123", true, "Numeric backreference"},
		{"(\\w+)\\g{1}", "hellohello", true, "Named backreference \\g{1}"},
		{"(.)\\1\\1", "aaa", true, "Triple character backreference"},
		{"(.)\\1\\1", "aa", false, "Insufficient repeats"},
	}
	
	for test in test_cases {
		fmt.printf("\nTest: %s\n", test.description)
		fmt.printf("Pattern: %s, Text: %s\n", test.pattern, test.text)
		
		// Compile the pattern using public API
		pattern, err := regexp.regexp(test.pattern)
		if err != .NoError {
			fmt.printf("  FAILED: Compilation error %v\n", err)
			continue
		}
		
		if pattern == nil {
			fmt.printf("  FAILED: Pattern is nil\n")
			continue
		}
		
		// Test matching
		result, match_err := regexp.match(pattern, test.text)
		if match_err != .NoError {
			fmt.printf("  FAILED: Match error %v\n", match_err)
			regexp.free_regexp(pattern)
			continue
		}
		
		if result.matched == test.should_match {
			fmt.printf("  PASSED: Match result %v (expected %v)\n", result.matched, test.should_match)
		} else {
			fmt.printf("  FAILED: Match result %v (expected %v)\n", result.matched, test.should_match)
		}
		
		// Clean up
		regexp.free_regexp(pattern)
	}
	
	fmt.println("\n=== Backreference Parsing Test Complete ===")
}