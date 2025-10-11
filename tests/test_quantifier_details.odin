package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Testing Quantifier Details ===")
	
	patterns := []string{
		"a*",
		"a+", 
		"a?",
	}
	
	texts := []string{
		"", "a", "aa", "b",
	}
	
	for i := 0; i < len(patterns); i += 1 {
		pattern := patterns[i]
		fmt.printf("\n--- Pattern: %s ---\n", pattern)
		
		re, err := regexp.regexp(pattern)
		if err != .NoError {
			fmt.printf("Failed to compile: %v\n", err)
			continue
		}
		defer regexp.free_regexp(re)
		
		for j := 0; j < len(texts); j += 1 {
			text := texts[j]
			result, result_err := regexp.match(re, text)
			if result_err == .NoError {
				if result.matched {
					match_text := text[result.full_match.start:result.full_match.end]
					fmt.printf("  '%s' -> MATCH: '%v' at [%d:%d]\n", text, match_text, result.full_match.start, result.full_match.end)
				} else {
					fmt.printf("  '%s' -> NO MATCH\n", text)
				}
			} else {
				fmt.printf("  '%s' -> ERROR: %v\n", text, result_err)
			}
		}
	}
}