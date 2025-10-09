package tests

import "core:testing"
import "core:fmt"
import "../regexp"

// Test memory leak detection for basic patterns
// CRITICAL: All patterns must be properly freed
@(test)
test_basic_pattern_memory_cleanup :: proc(t: ^testing.T) {
	// Test multiple pattern creation and cleanup
	for i in 0..<100 {
		pattern, err := regexp.regexp("test_pattern")
		testing.expect(t, err == .NoError, "Pattern compilation failed in iteration %d: %v", i, err)
		testing.expect(t, pattern != nil, "Pattern should not be nil in iteration %d", i)
		
		// Use the pattern
		result, err := regexp.match(pattern, "this is a test_pattern string")
		testing.expect(t, err == .NoError, "Matching failed in iteration %d: %v", i, err)
		
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
	patterns := [10]^regexp.Regexp_Pattern{}
	
	for i in 0..<len(patterns) {
		// Create increasingly complex patterns
		pattern_str := ""
		for j in 0..<i + 1 {
			pattern_str += "a"
		}
		
		pattern, err := regexp.regexp(pattern_str)
		testing.expect(t, err == .NoError, "Pattern %d compilation failed: %v", i, err)
		testing.expect(t, pattern != nil, "Pattern %d should not be nil", i)
		
		patterns[i] = pattern
	}
	
	// Use all patterns
	for i, pattern in patterns {
		input := fmt.tprintf("%s_test", pattern_str)
		result, err := regexp.match(pattern, input)
		testing.expect(t, err == .NoError, "Pattern %d matching failed: %v", i, err)
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
	testing.expect(t, err == .NoError, "Pattern compilation failed: %v", err)
	defer regexp.free_regexp(pattern)
	
	// Perform multiple matches that should use thread-local arena
	for i in 0..<1000 {
		input := fmt.tprintf("thread_test_%d", i)
		result, err := regexp.match(pattern, input)
		testing.expect(t, err == .NoError, "Matching failed in iteration %d: %v", i, err)
		
		// Thread-local arena should be properly managed
		if i % 100 == 0 {
			// Periodically reset thread-local arena
			regexp.reset_thread_local_arena()
		}
	}
	
	fmt.printf("Thread-local arena test completed 1000 iterations\n")
}

// Test memory usage with large inputs
@(test)
test_large_input_memory_usage :: proc(t: ^testing.T) {
	pattern, err := regexp.regexp("target")
	testing.expect(t, err == .NoError, "Pattern compilation failed: %v", err)
	defer regexp.free_regexp(pattern)
	
	// Test with large input strings
	large_inputs := []string{
		"a" + "target",                                    // Small
		"a" * 1000 + "target",                             // Medium
		"a" * 100000 + "target",                           // Large
	}
	
	for i, input in large_inputs {
		result, err := regexp.match(pattern, input)
		testing.expect(t, err == .NoError, "Matching failed for input size %d: %v", len(input), err)
		testing.expect(t, result.matched, "Should match large input %d", i)
		
		fmt.printf("Large input test %d: size %d bytes\n", i, len(input))
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
		testing.expect(t, err == .NoError, "Pattern %d compilation failed: %v", i, err)
		testing.expect(t, pattern != nil, "Pattern %d should not be nil", i)
		
		patterns[i] = pattern
	}
	
	// Use all patterns
	for i, pattern in patterns {
		input := fmt.tprintf("this is pattern_%d test", i)
		result, err := regexp.match(pattern, input)
		testing.expect(t, err == .NoError, "Pattern %d matching failed: %v", i, err)
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
	
	for i, invalid_pattern in invalid_patterns {
		pattern, err := regexp.regexp(invalid_pattern)
		testing.expect(t, err != .NoError, "Expected error for invalid pattern '%s'", invalid_pattern)
		testing.expect(t, pattern == nil, "Pattern should be nil for invalid pattern '%s'", invalid_pattern)
		
		// No cleanup needed since pattern is nil
	}
	
	fmt.printf("Error memory cleanup test completed with %d invalid patterns\n", len(invalid_patterns))
}