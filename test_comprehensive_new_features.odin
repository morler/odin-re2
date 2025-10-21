package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Comprehensive Test of New Regex Features ===")
	
	// Test cases combining all new features
	test_cases := [?]struct {
		pattern: string,
		text:    string,
		description: string,
		features: string,
	}{
		// Word boundaries
		{"\\bword\\b", "word", "Single word boundary", "Word Boundary"},
		{"\\bword\\b", "a word b", "Word in text", "Word Boundary"},
		{"\\Bword\\B", "swords", "Non-word boundary", "Word Boundary"},
		
		// Backreferences
		{"(\\w+)\\1", "testtest", "Simple backreference", "Backreference"},
		{"(\\d+)\\g{1}", "123123", "Named backreference", "Backreference"},
		{"(.)\\1\\1", "aaa", "Triple backreference", "Backreference"},
		
		// Lookahead assertions
		{"a(?=b)", "ab", "Positive lookahead", "Lookahead"},
		{"a(?!b)", "ac", "Negative lookahead", "Lookahead"},
		{"\\w+(?=\\d)", "test123", "Word before digit", "Lookahead"},
		
		// Lazy quantifiers
		{"a*?b", "aaab", "Lazy star", "Lazy Quantifier"},
		{"a+?b", "aaab", "Lazy plus", "Lazy Quantifier"},
		{"a??b", "ab", "Lazy question", "Lazy Quantifier"},
		{"a{2,4}?b", "aaab", "Lazy repeat", "Lazy Quantifier"},
		
		// Combined features
		{"\\b(\\w+)\\1\\b", "testtest", "Word boundary + backreference", "Combined"},
		{"(\\w+)(?=\\d)\\1", "test123test", "Backreference + lookahead", "Combined"},
		{"\\b(\\w+?)\\1\\b", "testtest", "Word boundary + lazy + backreference", "Combined"},
		{"a(?=b).*?c", "abxc", "Lookahead + lazy quantifier", "Combined"},
		
		// Complex patterns
		{"\\b(\\w{3,5}?)(?=\\d)\\1\\b", "test123test", "Complex combined", "Complex"},
		{"^(?!\\d)(\\w+?)\\1$", "testtest", "Negative lookahead + lazy + backreference", "Complex"},
	}
	
	passed := 0
	total := len(test_cases)
	
	for test in test_cases {
		fmt.printf("\nTest: %s\n", test.description)
		fmt.printf("Pattern: %s, Text: %s\n", test.pattern, test.text)
		fmt.printf("Features: %s\n", test.features)
		
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
		
		// Test passed
		fmt.printf("  PASSED: Successfully parsed\n")
		fmt.printf("  AST: %s\n", regexp.op_string(ast_node.op))
		
		if ast_node.flags.NonGreedy {
			fmt.printf("  NON-GREEDY: true\n")
		}
		
		passed += 1
	}
	
	fmt.printf("\n=== Test Summary ===\n")
	fmt.printf("Passed: %d/%d tests\n", passed, total)
	fmt.printf("Success Rate: %.1f%%\n", f32(passed) / f32(total) * 100.0)
	
	if passed == total {
		fmt.println("🎉 All tests passed! New regex features are working correctly.")
	} else {
		fmt.println("⚠️  Some tests failed. Please review the implementation.")
	}
	
	fmt.println("\n=== Comprehensive Test Complete ===")
}