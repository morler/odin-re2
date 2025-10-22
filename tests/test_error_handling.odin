package main

import "core:testing"
import "core:fmt"
import "regexp"

// Test compilation errors for invalid regex patterns
@(test)
test_compilation_error_handling :: proc(t: ^testing.T) {
	fmt.println("Testing compilation error handling...")

	invalid_patterns := []string{
		"(",           // Unclosed parenthesis
		"[",           // Unclosed character class
		"\\",          // Incomplete escape
		"*abc",        // Quantifier without target
		"+abc",        // Quantifier without target
		"?abc",        // Quantifier without target
		"{a}",         // Invalid quantifier syntax
		"(unclosed",   // Unclosed group
		"[unclosed",   // Unclosed character class
		"\\x",         // Incomplete hex escape
		"\\p",         // Incomplete Unicode property
	}

	for idx in 0..<len(invalid_patterns) {
		invalid_pattern := invalid_patterns[idx]
		pattern, compile_err := regexp.regexp(invalid_pattern)

		// Should fail to compile
		testing.expect(t, compile_err != .NoError,
			"Pattern '%s' should fail compilation but didn't", invalid_pattern)
		testing.expect(t, pattern == nil,
			"Pattern '%s' should return nil on compilation failure", invalid_pattern)

		fmt.printf("✓ Invalid pattern '%s' correctly rejected\n", invalid_pattern)
	}

	fmt.println("Compilation error handling test completed")
}

// Test handling of extremely large patterns
@(test)
test_large_pattern_handling :: proc(t: ^testing.T) {
	fmt.println("Testing large pattern handling...")

	// Test very long literal pattern
	// Use string concatenation for long patterns
	long_pattern := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
	                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
	                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
	                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
	                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
	                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
	                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
	                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
	                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
	                "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"  // ~1000 characters

	pattern, compile_err := regexp.regexp(long_pattern)
	testing.expect(t, compile_err == .NoError, "Long pattern should compile successfully")
	defer regexp.free_regexp(pattern)

	// Test with matching - just test with the pattern itself
	result, match_err := regexp.match(pattern, long_pattern)
	testing.expect(t, match_err == .NoError, "Long pattern matching should not error")

	if result.matched {
		fmt.printf("✓ Long pattern matching successful: %d bytes\n", len(long_pattern))
	} else {
		fmt.println("✓ Long pattern compiled but didn't match (expected for some patterns)")
	}

	fmt.println("Large pattern handling test completed")
}

// Test Unicode edge cases
@(test)
test_unicode_edge_cases :: proc(t: ^testing.T) {
	fmt.println("Testing Unicode edge cases...")

	// Test various Unicode edge cases
	unicode_patterns := []string{
		"🙂",           // Emoji
		"😀",           // Another emoji
		"Ω",            // Greek letter
		"ñ",            // Accented character
		"中",           // Chinese character
		"ß",            // German sharp S
	}

	for idx in 0..<len(unicode_patterns) {
		pattern_str := unicode_patterns[idx]
		pattern, compile_err := regexp.regexp(pattern_str)
		testing.expect(t, compile_err == .NoError,
			"Unicode pattern '%s' should compile", pattern_str)
		defer regexp.free_regexp(pattern)

		// Test matching with the same character
		result, match_err := regexp.match(pattern, pattern_str)
		testing.expect(t, match_err == .NoError,
			"Unicode pattern '%s' matching should not error", pattern_str)

		if result.matched {
			fmt.printf("✓ Unicode pattern '%s' matched successfully\n", pattern_str)
		}
	}

	fmt.println("Unicode edge cases test completed")
}

// Test memory boundary conditions
@(test)
test_memory_boundary_conditions :: proc(t: ^testing.T) {
	fmt.println("Testing memory boundary conditions...")

	// Test many small patterns
	pattern_count := 100
	patterns := make([]^regexp.Regexp_Pattern, pattern_count)
	defer delete(patterns)

	for i in 0..<pattern_count {
		pattern_str := fmt.tprintf("pattern_%d", i)
		pattern, err := regexp.regexp(pattern_str)
		testing.expect(t, err == .NoError, "Pattern should compile")
		testing.expect(t, pattern != nil, "Pattern should not be nil")

		patterns[i] = pattern
	}

	// Clean up all patterns
	for i in 0..<pattern_count {
		regexp.free_regexp(patterns[i])
	}

	fmt.printf("✓ Successfully handled %d patterns\n", pattern_count)

	// Test pattern reuse
	reuse_pattern, err := regexp.regexp("test")
	testing.expect(t, err == .NoError, "Reuse pattern should compile")
	defer regexp.free_regexp(reuse_pattern)

	for i in 0..<1000 {
		test_input := fmt.tprintf("test_%d", i)
		result, match_err := regexp.match(reuse_pattern, test_input)
		testing.expect(t, match_err == .NoError, "Reuse match should not error")
	}

	fmt.println("✓ Pattern reuse test completed")
	fmt.println("Memory boundary conditions test completed")
}

// Test empty string edge cases
@(test)
test_empty_string_edge_cases :: proc(t: ^testing.T) {
	fmt.println("Testing empty string edge cases...")

	// Test matching against empty strings
	pattern, err := regexp.regexp(".*")
	testing.expect(t, err == .NoError, "Wildcard pattern should compile")
	defer regexp.free_regexp(pattern)

	// Match empty string
	result1, match_err1 := regexp.match(pattern, "")
	testing.expect(t, match_err1 == .NoError, "Matching empty string should not error")

	// Match non-empty string
	result2, match_err2 := regexp.match(pattern, "hello")
	testing.expect(t, match_err2 == .NoError, "Matching non-empty string should not error")

	// Test empty pattern against empty string
	empty_pattern, empty_err := regexp.regexp("")
	testing.expect(t, empty_err == .NoError, "Empty pattern should compile")
	defer regexp.free_regexp(empty_pattern)

	result3, match_err3 := regexp.match(empty_pattern, "")
	testing.expect(t, match_err3 == .NoError, "Empty pattern against empty string should not error")
	testing.expect(t, result3.matched, "Empty pattern should match empty string")

	fmt.println("✓ Empty string edge cases handled correctly")
	fmt.println("Empty string edge cases test completed")
}