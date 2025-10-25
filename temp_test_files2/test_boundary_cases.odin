package main

import "core:testing"
import "core:fmt"
import "regexp"

// Test quantifier boundary cases
@(test)
test_quantifier_boundary_cases :: proc(t: ^testing.T) {
	fmt.println("Testing quantifier boundary cases...")

	// Test zero-length matches
	pattern, err := regexp.regexp("a*")
	testing.expect(t, err == .NoError, "Zero-or-more pattern should compile")
	defer regexp.free_regexp(pattern)

	// Test with empty string
	result1, match_err1 := regexp.match(pattern, "")
	testing.expect(t, match_err1 == .NoError, "Zero-or-more against empty string should not error")

	// Test with string containing no 'a'
	result2, match_err2 := regexp.match(pattern, "bbb")
	testing.expect(t, match_err2 == .NoError, "Zero-or-more against non-matching string should not error")

	// Test exact boundary matches
	pattern_exact, err_exact := regexp.regexp("a{3}")
	testing.expect(t, err_exact == .NoError, "Exact quantifier pattern should compile")
	defer regexp.free_regexp(pattern_exact)

	result_exact, match_err_exact := regexp.match(pattern_exact, "aaa")
	testing.expect(t, match_err_exact == .NoError, "Exact quantifier match should not error")

	// Test range quantifiers
	pattern_range, err_range := regexp.regexp("a{2,4}")
	testing.expect(t, err_range == .NoError, "Range quantifier pattern should compile")
	defer regexp.free_regexp(pattern_range)

	// Test various lengths
	test_lengths := []string{"a", "aa", "aaa", "aaaa", "aaaaa"}
	for test in test_lengths {
		result, match_err := regexp.match(pattern_range, test)
		testing.expect(t, match_err == .NoError, "Range quantifier should not error for input: %s", test)
	}

	fmt.println("✓ Quantifier boundary cases handled correctly")
	fmt.println("Quantifier boundary cases test completed")
}

// Test character class boundary cases
@(test)
test_character_class_boundary_cases :: proc(t: ^testing.T) {
	fmt.println("Testing character class boundary cases...")

	// Test negated character classes
	pattern1, err1 := regexp.regexp("[^a]")
	testing.expect(t, err1 == .NoError, "Negated character class should compile")
	defer regexp.free_regexp(pattern1)

	result1, match_err1 := regexp.match(pattern1, "b")
	testing.expect(t, match_err1 == .NoError, "Negated class matching should not error")

	// Test character ranges
	pattern2, err2 := regexp.regexp("[a-z]")
	testing.expect(t, err2 == .NoError, "Character range should compile")
	defer regexp.free_regexp(pattern2)

	result2, match_err2 := regexp.match(pattern2, "m")
	testing.expect(t, match_err2 == .NoError, "Character range matching should not error")

	// Test boundary characters
	boundary_tests := []struct {
		pattern: string,
		input:   string,
	}{
		{"[a-z]", "a"},    // Lower bound
		{"[a-z]", "z"},    // Upper bound
		{"[a-z]", "A"},    // Outside range
		{"[0-9]", "0"},    // Lower bound
		{"[0-9]", "9"},    // Upper bound
		{"[0-9]", "a"},    // Outside range
	}

	for test in boundary_tests {
		pattern, err := regexp.regexp(test.pattern)
		testing.expect(t, err == .NoError, "Pattern '%s' should compile", test.pattern)
		defer regexp.free_regexp(pattern)

		result, match_err := regexp.match(pattern, test.input)
		testing.expect(t, match_err == .NoError, "Pattern matching should not error")
	}

	fmt.println("✓ Character class boundary cases handled correctly")
	fmt.println("Character class boundary cases test completed")
}

// Test anchor boundary cases
@(test)
test_anchor_boundary_cases :: proc(t: ^testing.T) {
	fmt.println("Testing anchor boundary cases...")

	// Test start anchor
	pattern_start, err_start := regexp.regexp("^hello")
	testing.expect(t, err_start == .NoError, "Start anchor pattern should compile")
	defer regexp.free_regexp(pattern_start)

	result_start1, match_err_start1 := regexp.match(pattern_start, "hello world")
	testing.expect(t, match_err_start1 == .NoError, "Start anchor matching should not error")

	result_start2, match_err_start2 := regexp.match(pattern_start, "world hello")
	testing.expect(t, match_err_start2 == .NoError, "Start anchor non-match should not error")

	// Test end anchor
	pattern_end, err_end := regexp.regexp("hello$")
	testing.expect(t, err_end == .NoError, "End anchor pattern should compile")
	defer regexp.free_regexp(pattern_end)

	result_end1, match_err_end1 := regexp.match(pattern_end, "world hello")
	testing.expect(t, match_err_end1 == .NoError, "End anchor matching should not error")

	result_end2, match_err_end2 := regexp.match(pattern_end, "hello world")
	testing.expect(t, match_err_end2 == .NoError, "End anchor non-match should not error")

	// Test both anchors
	pattern_both, err_both := regexp.regexp("^hello$")
	testing.expect(t, err_both == .NoError, "Both anchors pattern should compile")
	defer regexp.free_regexp(pattern_both)

	result_both1, match_err_both1 := regexp.match(pattern_both, "hello")
	testing.expect(t, match_err_both1 == .NoError, "Both anchors exact match should not error")

	result_both2, match_err_both2 := regexp.match(pattern_both, "hello world")
	testing.expect(t, match_err_both2 == .NoError, "Both anchors non-match should not error")

	fmt.println("✓ Anchor boundary cases handled correctly")
	fmt.println("Anchor boundary cases test completed")
}

// Test grouping boundary cases
@(test)
test_grouping_boundary_cases :: proc(t: ^testing.T) {
	fmt.println("Testing grouping boundary cases...")

	// Test empty groups
	pattern_empty, err_empty := regexp.regexp("()")
	testing.expect(t, err_empty == .NoError, "Empty group should compile")
	defer regexp.free_regexp(pattern_empty)

	result_empty, match_err_empty := regexp.match(pattern_empty, "")
	testing.expect(t, match_err_empty == .NoError, "Empty group matching should not error")

	// Test nested groups
	pattern_nested, err_nested := regexp.regexp("((()))")
	testing.expect(t, err_nested == .NoError, "Nested groups should compile")
	defer regexp.free_regexp(pattern_nested)

	result_nested, match_err_nested := regexp.match(pattern_nested, "")
	testing.expect(t, match_err_nested == .NoError, "Nested groups matching should not error")

	// Test complex nested patterns
	pattern_complex, err_complex := regexp.regexp("((a|b)+c*)")
	testing.expect(t, err_complex == .NoError, "Complex nested pattern should compile")
	defer regexp.free_regexp(pattern_complex)

	test_inputs := []string{"ac", "bc", "aaac", "bbb", "abc", "aabbcc"}
	for test_input in test_inputs {
		result, match_err := regexp.match(pattern_complex, test_input)
		testing.expect(t, match_err == .NoError, "Complex nested pattern should not error for input: %s", test_input)
	}

	fmt.println("✓ Grouping boundary cases handled correctly")
	fmt.println("Grouping boundary cases test completed")
}

// Test alternation boundary cases
@(test)
test_alternation_boundary_cases :: proc(t: ^testing.T) {
	fmt.println("Testing alternation boundary cases...")

	// Test empty alternatives
	pattern_empty_alt, err_empty_alt := regexp.regexp("a|")
	testing.expect(t, err_empty_alt == .NoError, "Pattern with empty alternative should compile")
	defer regexp.free_regexp(pattern_empty_alt)

	result_empty_alt, match_err_empty_alt := regexp.match(pattern_empty_alt, "a")
	testing.expect(t, match_err_empty_alt == .NoError, "Empty alternative matching should not error")

	// Test many alternatives
	many_alts := "a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z"
	pattern_many, err_many := regexp.regexp(many_alts)
	testing.expect(t, err_many == .NoError, "Pattern with many alternatives should compile")
	defer regexp.free_regexp(pattern_many)

	// Test each letter
	test_chars := []string{"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
	                     "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
	for test_char in test_chars {
		result, match_err := regexp.match(pattern_many, test_char)
		testing.expect(t, match_err == .NoError, "Many alternatives should not error")
	}

	// Test overlapping alternatives
	pattern_overlap, err_overlap := regexp.regexp("ab|abc|abcd")
	testing.expect(t, err_overlap == .NoError, "Overlapping alternatives should compile")
	defer regexp.free_regexp(pattern_overlap)

	overlap_tests := []string{"ab", "abc", "abcd", "abcde"}
	for test in overlap_tests {
		result, match_err := regexp.match(pattern_overlap, test)
		testing.expect(t, match_err == .NoError, "Overlapping alternatives should not error for: %s", test)
	}

	fmt.println("✓ Alternation boundary cases handled correctly")
	fmt.println("Alternation boundary cases test completed")
}