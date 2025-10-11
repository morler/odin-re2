package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== User Story 2 Comprehensive Test ===")
	
	tests := []struct {
		pattern: string,
		text:    string,
		expected: bool,
		description: string,
	}{
		// Character classes
		{"[abc]", "a", true, "Simple character class match"},
		{"[abc]", "d", false, "Simple character class no match"},
		{"[a-z]", "m", true, "Range match"},
		{"[a-z]", "A", false, "Range no match (case sensitive)"},
		{"[0-9]", "5", true, "Digit range match"},
		{"[0-9]", "x", false, "Digit range no match"},
		{"[^abc]", "d", true, "Negated class match"},
		{"[^abc]", "a", false, "Negated class no match"},
		{"[^0-9]", "x", true, "Negated digit class match"},
		{"[^0-9]", "5", false, "Negated digit class no match"},
		
		// Special characters
		{".", "a", true, "Any character match"},
		{".", "\n", true, "Any character newline match"},
		{"^a", "apple", true, "Begin line match"},
		{"^a", "banana", false, "Begin line no match"},
		{"a$", "banana", true, "End line match"},
		{"a$", "apple", false, "End line no match"},
		{"a$", "ba", true, "End line match short"},
		
		// Alternation
		{"a|b", "a", true, "Alternation first option"},
		{"a|b", "b", true, "Alternation second option"},
		{"a|b", "c", false, "Alternation no match"},
		{"cat|dog", "cat", true, "Alternation word first"},
		{"cat|dog", "dog", true, "Alternation word second"},
		{"cat|dog", "bird", false, "Alternation word no match"},
		
		// Concatenation
		{"ab", "ab", true, "Simple concatenation"},
		{"ab", "a", false, "Concatenation incomplete"},
		{"ab", "abc", true, "Concatenation prefix match"},
		{"[a-z][0-9]", "a5", true, "Class concatenation"},
		{"[a-z][0-9]", "5a", false, "Class concatenation wrong order"},
		
	// Complex combinations (without + quantifier for now)
		{"^[a-z][0-9]$", "a5", true, "Simple anchored pattern match"},
		{"^[a-z][0-9]$", "A5", false, "Simple anchored pattern case fail"},
		{"^[a-z][0-9]$", "a", false, "Simple anchored pattern missing digit"},
		{"cat|dog|bird", "bird", true, "Multiple alternation"},
	}
	
	passed := 0
	total := len(tests)
	
	for i in 0..<len(tests) {
		test := tests[i]
		fmt.printf("\n%d. %s\n", i+1, test.description)
		fmt.printf("   Pattern: %s, Text: %s\n", test.pattern, test.text)
		
		pattern, err := regexp.regexp(test.pattern)
		if err != regexp.ErrorCode.NoError {
			fmt.printf("   ❌ Parse error: %v\n", err)
			continue
		}
		defer regexp.free_regexp(pattern)
		
		result, match_err := regexp.match(pattern, test.text)
		if match_err != regexp.ErrorCode.NoError {
			fmt.printf("   ❌ Match error: %v\n", match_err)
			continue
		}
		
		if result.matched == test.expected {
			fmt.printf("   ✅ %v (expected %v)\n", result.matched, test.expected)
			passed += 1
		} else {
			fmt.printf("   ❌ %v (expected %v)\n", result.matched, test.expected)
		}
	}
	
	fmt.printf("\n=== Test Results ===\n")
	fmt.printf("Passed: %d/%d (%.1f%%)\n", passed, total, f32(passed)/f32(total)*100.0)
	
	if passed == total {
		fmt.println("🎉 All tests passed! User Story 2 is complete.")
	} else {
		fmt.println("⚠️  Some tests failed. Need to fix issues.")
	}
}