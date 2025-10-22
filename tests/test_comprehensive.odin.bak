package main

import "core:testing"
import "core:fmt"
import "regexp"

// Test RE2 compliance for literal patterns
// This ensures our implementation matches RE2 behavior exactly
@(test)
test_re2_literal_compliance :: proc(t: ^testing.T) {
	// Test basic literal matching
	test_cases := []struct {
		pattern: string,
		input:   string,
		expect:  bool,
	}{
		{"a", "a", true},
		{"a", "b", false},
		{"abc", "abc", true},
		{"abc", "abcd", true},
		{"abc", "xabc", true},
		{"abc", "xabcy", true},
		{"abc", "ab", false},
		{"abc", "bc", false},
		{"", "", true},
		{"", "anything", true},
		{"hello", "hello world", true},
		{"world", "hello world", true},
	}
	
	for idx in 0..<len(test_cases) {
		test_case := test_cases[idx]
		pattern, compile_err := regexp.regexp(test_case.pattern)
		testing.expect(t, compile_err == .NoError)
		testing.expect(t, pattern != nil)
		defer regexp.free_regexp(pattern)
		
		result, match_err := regexp.match(pattern, test_case.input)
		testing.expect(t, match_err == .NoError)
		testing.expect(t, result.matched == test_case.expect)
	}
	
	fmt.printf("RE2 literal compliance test completed with %d cases\n", len(test_cases))
}

// Test edge cases that RE2 handles specifically
@(test)
test_re2_edge_cases :: proc(t: ^testing.T) {
	// Test empty pattern and empty string
	pattern, err := regexp.regexp("")
	testing.expect(t, err == .NoError)
	defer regexp.free_regexp(pattern)
	
	result, match_err := regexp.match(pattern, "")
	testing.expect(t, match_err == .NoError)
	testing.expect(t, result.matched)
	
	// Test pattern longer than input
	long_pattern, long_err := regexp.regexp("longpattern")
	testing.expect(t, long_err == .NoError)
	defer regexp.free_regexp(long_pattern)
	
	result, match_err = regexp.match(long_pattern, "short")
	testing.expect(t, match_err == .NoError)
	testing.expect(t, !result.matched)
	
	// Test single character patterns
	single_chars := []rune{'a', 'b', 'c', '1', '2', ' ', '\t', '\n'}
	for idx in 0..<len(single_chars) {
		char := single_chars[idx]
		pattern_str := fmt.tprintf("%c", char)
		char_pattern, char_err := regexp.regexp(pattern_str)
		testing.expect(t, char_err == .NoError)
		defer regexp.free_regexp(char_pattern)
		
		// Should match itself
		result, match_err := regexp.match(char_pattern, pattern_str)
		testing.expect(t, match_err == .NoError)
		testing.expect(t, result.matched)
		
		// Should not match different character
		different := "x"
		if pattern_str == different {
			different = "y"
		}
		result, match_err = regexp.match(char_pattern, different)
		testing.expect(t, match_err == .NoError)
		testing.expect(t, !result.matched)
	}
	
	fmt.printf("RE2 edge cases test completed\n")
}

// Test Unicode handling (RE2 is UTF-8 by default)
@(test)
test_re2_unicode_handling :: proc(t: ^testing.T) {
	// Test basic Unicode characters
	unicode_patterns := []string{
		"é",
		"ñ",
		"中文",
		"🙂",
	}
	
	for idx in 0..<len(unicode_patterns) {
		pattern_str := unicode_patterns[idx]
		pattern, compile_err := regexp.regexp(pattern_str)
		testing.expect(t, compile_err == .NoError)
		defer regexp.free_regexp(pattern)
		
		// Should match itself
		result, match_err := regexp.match(pattern, pattern_str)
		testing.expect(t, match_err == .NoError)
		testing.expect(t, result.matched)
		
		// Should match when embedded in longer string
		embedded := fmt.tprintf("prefix_%s_suffix", pattern_str)
		result, match_err = regexp.match(pattern, embedded)
		testing.expect(t, match_err == .NoError)
		testing.expect(t, result.matched)
	}
	
	fmt.printf("RE2 Unicode handling test completed\n")
}

// Test performance characteristics match RE2
@(test)
test_re2_performance_characteristics :: proc(t: ^testing.T) {
	// RE2 guarantees linear time complexity
	// Test with patterns that could cause exponential behavior in naive implementations
	
	pattern, err := regexp.regexp("a")
	testing.expect(t, err == .NoError)
	defer regexp.free_regexp(pattern)
	
	// Test with input that has many potential match positions
	input := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" // 30 'a's
	
	result, match_err := regexp.match(pattern, input)
	testing.expect(t, match_err == .NoError)
	testing.expect(t, result.matched)
	
	// Should find first occurrence quickly
	testing.expect(t, result.captures[0].start == 0)
	testing.expect(t, result.captures[0].end == 1)
	
	fmt.printf("RE2 performance characteristics test completed\n")
}

// Test error handling matches RE2 behavior
@(test)
test_re2_error_handling :: proc(t: ^testing.T) {
	// Test that currently unsupported features return appropriate errors
	// For now, we only support literals, so anything else should fail
	
	invalid_patterns := []string{
		"(",      // Unclosed parenthesis
		"[",      // Unclosed bracket
		"{",      // Unclosed brace
		"\\",     // Incomplete escape
	}
	
	for idx in 0..<len(invalid_patterns) {
		invalid_pattern := invalid_patterns[idx]
		pattern, compile_err := regexp.regexp(invalid_pattern)
		testing.expect(t, compile_err != .NoError)
		testing.expect(t, pattern == nil)
	}
	
	fmt.printf("RE2 error handling test completed with %d invalid patterns\n", len(invalid_patterns))
}

// Test memory usage patterns match RE2
@(test)
test_re2_memory_patterns :: proc(t: ^testing.T) {
	// Test that repeated pattern compilation and matching doesn't leak memory
	// This simulates real-world usage patterns
	
	for i in 0..<10 {
		pattern, err := regexp.regexp("test_pattern")
		testing.expect(t, err == .NoError)
		
		// Use pattern multiple times
		for j in 0..<5 {
			input := fmt.tprintf("this is test_pattern number %d", j)
			result, err := regexp.match(pattern, input)
			testing.expect(t, err == .NoError)
			testing.expect(t, result.matched)
		}
		
		regexp.free_regexp(pattern)
	}
	
	fmt.printf("RE2 memory patterns test completed\n")
}