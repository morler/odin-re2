package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Debugging Regex Syntax Issues ===")
	
	// Test alternation with detailed debugging
	fmt.println("\n1. Testing alternation 'a|b' with debug:")
	pattern1, err1 := regexp.regexp("a|b")
	if err1 == .NoError {
		fmt.printf("  Pattern compiled successfully\n")
		
		// Test with specific debugging
		result1, match_err1 := regexp.match(pattern1, "a")
		fmt.printf("  Pattern: 'a|b', Text: 'a' -> Match: %v, Error: %v\n", result1.matched, match_err1)
		if result1.matched {
			fmt.printf("    Match range: %d-%d\n", result1.full_match.start, result1.full_match.end)
		}
		
		regexp.free_regexp(pattern1)
	} else {
		fmt.printf("  Compilation failed: %v\n", err1)
	}
	
	fmt.println("\n=== Debug Complete ===")
}