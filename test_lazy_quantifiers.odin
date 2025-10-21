package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Testing Lazy Quantifier Support ===")
	
	// Test cases for lazy quantifiers
	test_cases := [?]struct {
		pattern: string,
		text:    string,
		description: string,
	}{
		{"a*?", "aaa", "Lazy star *?"},
		{"a+?", "aaa", "Lazy plus +?"},
		{"a??", "aaa", "Lazy question mark ??"},
		{"a{2,4}?", "aaaaa", "Lazy repeat {n,m}?"},
		{"a{2,}?", "aaaaa", "Lazy repeat {n,}?"},
		{"a{2}?", "aaaaa", "Lazy repeat {n}? (should be same as greedy)"},
		{"\\w+?\\d", "test123", "Lazy word followed by digit"},
		{".*?b", "abcb", "Lazy any char until b"},
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
		fmt.printf("  PARSED: Successfully parsed lazy quantifier pattern\n")
		
		// Print AST structure for debugging
		fmt.printf("  AST: %s\n", regexp.op_string(ast_node.op))
		
		// Check if non-greedy flag is set
		if ast_node.flags.NonGreedy {
			fmt.printf("  NON-GREEDY: true\n")
		}
	}
	
	fmt.println("\n=== Lazy Quantifier Parsing Test Complete ===")
}