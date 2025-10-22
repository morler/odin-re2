package main

import "core:fmt"
import "regexp"

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
		
		// Compile the pattern
		ast_node, err := regexp.parse_regexp_internal(test.pattern, .None)
		if err != .NoError {
			fmt.printf("  FAILED: Parse error %v\n", err)
			continue
		}
		
		if ast_node == nil {
			fmt.printf("  FAILED: AST node is nil\n")
			continue
		}
		
		// For now, just test that parsing works
		// Full matching test would require NFA compilation
		fmt.printf("  PARSED: Successfully parsed backreference pattern\n")
		
		// Clean up
		regexp.free_arena(ast_node)
	}
	
	fmt.println("\n=== Backreference Parsing Test Complete ===")
}