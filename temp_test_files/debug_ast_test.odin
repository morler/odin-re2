package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Debugging Regex AST ===")
	
	// Test alternation with AST inspection
	fmt.println("\n1. Testing alternation 'a|b' - AST inspection:")
	pattern1, err1 := regexp.regexp("a|b")
	if err1 == .NoError {
		fmt.printf("  Pattern compiled successfully\n")
		
		// Test both possibilities
		result1, match_err1 := regexp.match(pattern1, "a")
		fmt.printf("  Pattern: 'a|b', Text: 'a' -> Match: %v\n", result1.matched)
		
		result2, match_err2 := regexp.match(pattern1, "b") 
		fmt.printf("  Pattern: 'a|b', Text: 'b' -> Match: %v\n", result2.matched)
		
		// Test simple literal first for comparison
		fmt.println("\n2. Testing simple literal 'a':")
		pattern2, err2 := regexp.regexp("a")
		if err2 == .NoError {
			result3, match_err3 := regexp.match(pattern2, "a")
			fmt.printf("  Pattern: 'a', Text: 'a' -> Match: %v\n", result3.matched)
			regexp.free_regexp(pattern2)
		}
		
		regexp.free_regexp(pattern1)
	} else {
		fmt.printf("  Compilation failed: %v\n", err1)
	}
	
	fmt.println("\n=== Debug Complete ===")
}