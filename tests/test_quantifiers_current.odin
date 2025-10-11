package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Testing Current Quantifier Support ===")
	
	// Test basic quantifiers
	test_cases := []string{
		"a*",     // Star quantifier
		"a+",     // Plus quantifier  
		"a?",     // Question quantifier
		"ab*c",   // Star in middle
		"ab+c",   // Plus in middle
		"ab?c",   // Question in middle
		"a*b+",   // Multiple quantifiers
	}
	
	texts := []string{
		"", "a", "aa", "aaa", "b", "ab", "abc", "abbc", "abbbc", "ac", "abb", "abbb",
	}
	
	for i := 0; i < len(test_cases); i += 1 {
		pattern := test_cases[i]
		fmt.printf("\n--- Testing pattern: %s ---\n", pattern)
		
		re, err := regexp.regexp(pattern)
		if err != .NoError {
			fmt.printf("Failed to compile pattern %s: %v\n", pattern, err)
			continue
		}
		defer regexp.free_regexp(re)
		
		for j := 0; j < len(texts); j += 1 {
			text := texts[j]
			matched, match_err := regexp.match_string(pattern, text)
			if match_err != .NoError {
				fmt.printf("  '%s' -> ERROR: %v\n", text, match_err)
			} else {
				fmt.printf("  '%s' -> %v\n", text, matched)
			}
		}
	}
}