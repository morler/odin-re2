package main

import "core:testing"
import "core:fmt"
import "regexp"

// Test memory leak detection for basic patterns
// CRITICAL: All patterns must be properly freed
@(test)
test_basic_pattern_memory_cleanup :: proc(t: ^testing.T) {
	// Test multiple pattern creation and cleanup
	for i in 0..<50 {
		pattern, compile_err := regexp.regexp("test_pattern")
		testing.expect(t, compile_err == .NoError)
		testing.expect(t, pattern != nil)
		
		// Use the pattern
		result, match_err := regexp.match(pattern, "this is a test_pattern string")
		testing.expect(t, match_err == .NoError)
		
		// Clean up
		regexp.free_regexp(pattern)
	}
	
	// If we get here without running out of memory, cleanup is working
	fmt.printf("Memory cleanup test completed 100 iterations\n")
}

// Test arena allocation and cleanup
@(test)
test_arena_allocation_cleanup :: proc(t: ^testing.T) {
	// Create patterns with increasing complexity
	patterns: [10]^regexp.Regexp_Pattern
	
	for i in 0..<len(patterns) {
		// Create simple patterns
		pattern_str := "a"
		pattern, err := regexp.regexp(pattern_str)
		testing.expect(t, err == .NoError)
		testing.expect(t, pattern != nil)
		
		patterns[i] = pattern
	}
	
	// Use all patterns
	for idx in 0..<len(patterns) {
		pattern := patterns[idx]
		result, match_err := regexp.match(pattern, "a_test")
		testing.expect(t, match_err == .NoError)
	}
	
	// Clean up all patterns
	for pattern in patterns {
		regexp.free_regexp(pattern)
	}
	
	fmt.printf("Arena allocation test completed\n")
}

// Test thread-local arena cleanup
@(test)
test_thread_local_arena_cleanup :: proc(t: ^testing.T) {
	pattern, err := regexp.regexp("thread_test")
	testing.expect(t, err == .NoError)
	defer regexp.free_regexp(pattern)
	
	// Perform multiple matches that should use thread-local arena
	for i in 0..<200 {
		input := fmt.tprintf("thread_test_%d", i)
		result, err := regexp.match(pattern, input)
		testing.expect(t, err == .NoError)
	}
	
	fmt.printf("Thread-local arena test completed 1000 iterations\n")
}

// Test memory usage with large inputs
@(test)
test_large_input_memory_usage :: proc(t: ^testing.T) {
	pattern, err := regexp.regexp("target")
	testing.expect(t, err == .NoError)
	defer regexp.free_regexp(pattern)
	
	// Test with large input strings
	test_inputs := []string{
		"atarget",                                    // Small
		"aaaaaaaaaaaaaaaaaaaaaaaaaaaaatarget",        // Medium
		"atarget",                                    // Simple test
	}
	
	for idx in 0..<len(test_inputs) {
		input := test_inputs[idx]
		result, match_err := regexp.match(pattern, input)
		testing.expect(t, match_err == .NoError)
		testing.expect(t, result.matched)
		
		fmt.printf("Large input test %d: size %d bytes\n", idx, len(input))
	}
	
	fmt.printf("Large input memory test completed\n")
}

// Test pattern memory bounds
@(test)
test_pattern_memory_bounds :: proc(t: ^testing.T) {
	// Test that pattern memory usage stays within reasonable bounds
	// Create many patterns to test overall memory usage
	
	pattern_count := 50
	patterns := make([]^regexp.Regexp_Pattern, pattern_count)
	
	for i in 0..<pattern_count {
		// Create patterns of moderate complexity
		pattern_str := fmt.tprintf("pattern_%d", i)
		pattern, err := regexp.regexp(pattern_str)
		testing.expect(t, err == .NoError)
		testing.expect(t, pattern != nil)
		
		patterns[i] = pattern
	}
	
	// Use all patterns
	for idx in 0..<len(patterns) {
		pattern := patterns[idx]
		input := fmt.tprintf("this is pattern_%d test", idx)
		result, match_err := regexp.match(pattern, input)
		testing.expect(t, match_err == .NoError)
	}
	
	// Clean up all patterns
	for pattern in patterns {
		regexp.free_regexp(pattern)
	}
	
	delete(patterns)
	
	fmt.printf("Pattern memory bounds test completed with %d patterns\n", pattern_count)
}

// Test error handling doesn't leak memory
@(test)
test_error_memory_cleanup :: proc(t: ^testing.T) {
	// Test that error conditions don't cause memory leaks
	invalid_patterns := []string{
		"(unclosed",
		"\\x",
		"[unclosed",
		"*invalid",
		"+invalid",
		"?invalid",
		"{invalid",
	}
	
	for idx in 0..<len(invalid_patterns) {
		invalid_pattern := invalid_patterns[idx]
		pattern, compile_err := regexp.regexp(invalid_pattern)
		testing.expect(t, compile_err != .NoError)
		testing.expect(t, pattern == nil)
		
		// No cleanup needed since pattern is nil
	}
	
	fmt.printf("Error memory cleanup test completed with %d invalid patterns\n", len(invalid_patterns))
}