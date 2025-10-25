package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Testing Lookahead Assertion Support ===")
	
	// Test cases for lookahead assertions
	test_cases := [?]struct {
		pattern: string,
		text:    string,
		should_match: bool,
		description: string,
	}{
		{"a(?=b)", "ab", true, "Positive lookahead should match"},
		{"a(?=b)", "ac", false, "Positive lookahead should fail"},
		{"a(?!b)", "ac", true, "Negative lookahead should match"},
		{"a(?!b)", "ab", false, "Negative lookahead should fail"},
		{"\\w+(?=\\d)", "test123", true, "Word followed by digit"},
		{"\\w+(?=\\d)", "testabc", false, "Word not followed by digit"},
		{"^(?!test)", "hello", true, "Negative lookahead at start"},
		{"^(?!test)", "test", false, "Negative lookahead should fail"},
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
		fmt.printf("  PARSED: Successfully parsed lookahead pattern\n")
		
		// Print AST structure for debugging
		fmt.printf("  AST: %s\n", regexp.op_string(ast_node.op))
	}
	
	fmt.println("\n=== Lookahead Parsing Test Complete ===")
}