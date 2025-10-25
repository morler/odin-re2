package main

import "core:testing"
import "core:fmt"
import "regexp"

@(test)
test_empty_pattern_matching :: proc(t: ^testing.T) {
	fmt.println("Testing empty pattern...")

	// Test empty pattern
	pattern, err := regexp.regexp("")
	testing.expect(t, err == .NoError, "Failed to compile empty pattern")
	defer regexp.free_regexp(pattern)

	test_cases := []string{"", "anything", "hello", "world"}

	for test in test_cases {
		result, match_err := regexp.match(pattern, test)
		testing.expect(t, match_err == .NoError, "Error matching empty pattern")
		// Empty pattern should match all strings at position 0
		testing.expect(t, result.matched, "Empty pattern should match '%s'", test)
		testing.expect(t, result.full_match.start == 0, "Empty match should start at position 0")
		testing.expect(t, result.full_match.end == 0, "Empty match should end at position 0")
	}
}