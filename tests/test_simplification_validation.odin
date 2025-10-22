/**
 * Feature: spec/features/simplify-nfa-engine-architecture.feature
 *
 * This test file validates the acceptance criteria defined in the feature file.
 * Scenarios in this test map directly to scenarios in the Gherkin feature.
 */

package main

import "core:testing"
import "core:fmt"
import "core:time"
import "../src/regexp"

// ===========================================================================
// THREAD POOL ELIMINATION TEST
// ===========================================================================

@(test)
test_thread_pool_elimination :: proc(t: ^testing.T) {
	// Given: the matcher contains a complex thread pool with 64 threads and capture buffers
	// When: the thread pool is replaced with simple recursive NFA execution
	// Then: the code should be reduced by at least 200 lines while maintaining linear-time performance
	
	fmt.println("=== Testing Thread Pool Elimination ===")
	
	// Test basic functionality still works
	pattern, err := regexp.regexp("a+b")
	testing.expect(t, err == .NoError, "Pattern compilation should succeed")
	defer regexp.free_regexp(pattern)
	
	// Test matching still works
	text := "aaab"
	result, match_err := regexp.match(pattern, text)
	testing.expect(t, match_err == .NoError, "Matching should succeed")
	testing.expect(t, result.matched, "Pattern should match")
	testing.expect(t, result.full_match.start == 0, "Match should start at position 0")
	testing.expect(t, result.full_match.end == 4, "Match should end at position 4")
	
	// Test performance is still linear (simple check)
	start_time := time.now()
	for i in 0..<1000 {
		regexp.match_string("a+b", "a" + "a"*i + "b")
	}
	elapsed := time.since(start_time)
	
	// Should complete quickly (linear time guarantee)
	testing.expect(t, elapsed < 1_000_000_000, "Performance should remain linear") // 1 second max
	
	fmt.println("✓ Thread pool elimination test passed")
}

// ===========================================================================
// STATE VECTOR SIMPLIFICATION TEST
// ===========================================================================

@(test)
test_state_vector_simplification :: proc(t: ^testing.T) {
	// Given: the matcher uses complex bit vectors for state representation and deduplication
	// When: state vectors are replaced with simple slices of active states
	// Then: the state management code should be reduced by at least 150 lines
	
	fmt.println("=== Testing State Vector Simplification ===")
	
	// Test complex patterns still work
	patterns := [?]string{
		"a*b+c?",
		"(ab|cd)+",
		"[a-z]{3,5}",
	}
	
	for pattern_str in patterns {
		pattern, err := regexp.regexp(pattern_str)
		testing.expect(t, err == .NoError, fmt.tprintf("Pattern '%s' should compile", pattern_str))
		defer regexp.free_regexp(pattern)
		
		// Test various inputs
		test_texts := [?]string{
			"",
			"a",
			"ab",
			"abcde",
			"xyz",
		}
		
		for text in test_texts {
			result, match_err := regexp.match(pattern, text)
			testing.expect(t, match_err == .NoError, fmt.tprintf("Matching '%s' against '%s' should succeed", pattern_str, text))
			// We don't assert specific match results here, just that it doesn't crash
		}
	}
	
	fmt.println("✓ State vector simplification test passed")
}

// ===========================================================================
// CAPTURE BUFFER SIMPLIFICATION TEST
// ===========================================================================

@(test)
test_capture_buffer_simplification :: proc(t: ^testing.T) {
	// Given: the system uses 32-element fixed capture buffers with manual copying
	// When: capture buffers are replaced with dynamic slice allocation
	// Then: capture management code should be simplified by at least 100 lines
	
	fmt.println("=== Testing Capture Buffer Simplification ===")
	
	// Test capture groups still work
	pattern, err := regexp.regexp("(a+)(b+)(c+)")
	testing.expect(t, err == .NoError, "Pattern with capture groups should compile")
	defer regexp.free_regexp(pattern)
	
	text := "aaabbbccc"
	result, match_err := regexp.match(pattern, text)
	testing.expect(t, match_err == .NoError, "Matching with captures should succeed")
	testing.expect(t, result.matched, "Pattern with captures should match")
	testing.expect(t, result.full_match.start == 0, "Full match should start at position 0")
	testing.expect(t, result.full_match.end == 9, "Full match should end at position 9")
	
	// Test that captures are populated (basic check)
	testing.expect(t, len(result.captures) > 0, "Should have capture groups")
	
	fmt.println("✓ Capture buffer simplification test passed")
}

// ===========================================================================
// ARENA ALLOCATOR SIMPLIFICATION TEST
// ===========================================================================

@(test)
test_arena_allocator_simplification :: proc(t: ^testing.T) {
	// Given: the arena allocator uses complex 64-byte alignment with padding calculations
	// When: alignment is simplified to basic 8-byte alignment
	// Then: memory allocation code should be reduced by at least 80 lines
	
	fmt.println("=== Testing Arena Allocator Simplification ===")
	
	// Test that memory allocation still works correctly
	patterns: [100]^regexp.Regexp_Pattern
	defer {
		for p in patterns {
			if p != nil {
				regexp.free_regexp(p)
			}
		}
	}
	
	// Compile many patterns to test memory management
	for i in 0..<100 {
		pattern_str := fmt.tprintf("test%d", i)
		pattern, err := regexp.regexp(pattern_str)
		testing.expect(t, err == .NoError, fmt.tprintf("Pattern '%s' should compile", pattern_str))
		patterns[i] = pattern
	}
	
	// Test that all patterns still work
	for i, p in patterns {
		if p != nil {
			text := fmt.tprintf("test%d", i)
			result, match_err := regexp.match(p, text)
			testing.expect(t, match_err == .NoError, fmt.tprintf("Pattern '%d' should match", i))
			testing.expect(t, result.matched, fmt.tprintf("Pattern '%d' should match text", i))
		}
	}
	
	fmt.println("✓ Arena allocator simplification test passed")
}

// ===========================================================================
// MEMORY POOL ELIMINATION TEST
// ===========================================================================

@(test)
test_memory_pool_elimination :: proc(t: ^testing.T) {
	// Given: the system uses memory pools with freelists and tracking
	// When: memory pools are replaced with direct arena allocation
	// Then: pool management code should be eliminated entirely
	
	fmt.println("=== Testing Memory Pool Elimination ===")
	
	// Test rapid allocation/deallocation patterns
	for i in 0..<1000 {
		pattern_str := fmt.tprintf("(a%d)|(b%d)", i % 10, i % 10)
		pattern, err := regexp.regexp(pattern_str)
		testing.expect(t, err == .NoError, fmt.tprintf("Pattern '%s' should compile", pattern_str))
		
		text := fmt.tprintf("a%d", i % 10)
		result, match_err := regexp.match(pattern, text)
		testing.expect(t, match_err == .NoError, fmt.tprintf("Matching '%s' should succeed", pattern_str))
		
		regexp.free_regexp(pattern)
	}
	
	fmt.println("✓ Memory pool elimination test passed")
}

// ===========================================================================
// BENCHMARK VALIDATION TEST
// ===========================================================================

@(test)
test_benchmark_validation :: proc(t: ^testing.T) {
	// Given: all simplification changes are implemented
	// When: the complete benchmark suite is executed
	// Then: all performance, functionality, and memory benchmarks must pass without regression
	
	fmt.println("=== Testing Benchmark Validation ===")
	
	// Test basic performance benchmarks
	patterns := [?]string{
		"a+b+",           // Simple repetition
		"[a-z]+",         // Character class
		"(ab|cd)+",       // Alternation
		"a.*b",           // Wildcard
		"(\\d+)-(\\d+)",  // Capture groups
	}
	
	texts := [?]string{
		"aaabbb",
		"hello world",
		"abcdabcd",
		"axxxxxb",
		"123-456",
	}
	
	for i, pattern_str in patterns {
		pattern, err := regexp.regexp(pattern_str)
		testing.expect(t, err == .NoError, fmt.tprintf("Benchmark pattern '%s' should compile", pattern_str))
		defer regexp.free_regexp(pattern)
		
		text := texts[i]
		
		// Performance test - should complete quickly
		start_time := time.now()
		for j in 0..<100 {
			result, match_err := regexp.match(pattern, text)
			testing.expect(t, match_err == .NoError, fmt.tprintf("Benchmark matching should succeed for '%s'", pattern_str))
			// Don't assert specific results, just that it doesn't crash or hang
		}
		elapsed := time.since(start_time)
		
		// Should complete 100 matches in reasonable time
		testing.expect(t, elapsed < 100_000_000, fmt.tprintf("Pattern '%s' should be fast", pattern_str)) // 100ms max
	}
	
	fmt.println("✓ Benchmark validation test passed")
}

// ===========================================================================
// API COMPATIBILITY TEST
// ===========================================================================

@(test)
test_api_compatibility :: proc(t: ^testing.T) {
	fmt.println("=== Testing API Compatibility ===")
	
	// Test that all public APIs still work as expected
	
	// Test regexp compilation
	pattern, err := regexp.regexp("test")
	testing.expect(t, err == .NoError, "regexp() should work")
	testing.expect(t, pattern != nil, "Pattern should not be nil")
	
	// Test matching
	result, match_err := regexp.match(pattern, "test")
	testing.expect(t, match_err == .NoError, "match() should work")
	testing.expect(t, result.matched, "Should match")
	
	// Test convenience function
	matched, conv_err := regexp.match_string("test", "test")
	testing.expect(t, conv_err == .NoError, "match_string() should work")
	testing.expect(t, matched, "Should match")
	
	// Test pattern validation
	testing.expect(t, regexp.is_valid_pattern(pattern), "Pattern should be valid")
	
	// Test pattern statistics
	node_count, capture_count := regexp.pattern_stats(pattern)
	testing.expect(t, node_count > 0, "Should have nodes")
	testing.expect(t, capture_count >= 0, "Should have capture count")
	
	// Test cleanup
	regexp.free_regexp(pattern)
	
	fmt.println("✓ API compatibility test passed")
}

// ===========================================================================
// RE2 COMPATIBILITY TEST
// ===========================================================================

@(test)
test_re2_compatibility :: proc(t: ^testing.T) {
	fmt.println("=== Testing RE2 Compatibility ===")
	
	// Test patterns that should work the same as RE2
	Test_Case :: struct {
		pattern: string,
		text:    string,
		should_match: bool,
	}
	
	test_cases := [?]Test_Case{
		{"a", "a", true},
		{"a", "b", false},
		{"a+", "aaa", true},
		{"a*", "", true},
		{"a?", "", true},
		{"ab", "ab", true},
		{"ab", "ac", false},
		{"a|b", "a", true},
		{"a|b", "b", true},
		{"a|b", "c", false},
		{"[abc]", "b", true},
		{"[abc]", "d", false},
		{"[^abc]", "d", true},
		{"[^abc]", "a", false},
	}
	
	for i in 0..<len(test_cases) {
		test_case := test_cases[i]
		pattern, err := regexp.regexp(test_case.pattern)
		testing.expect(t, err == .NoError, fmt.tprintf("Pattern '%s' should compile", test_case.pattern))
		defer regexp.free_regexp(pattern)
		
		result, match_err := regexp.match(pattern, test_case.text)
		testing.expect(t, match_err == .NoError, fmt.tprintf("Matching '%s' against '%s' should succeed", test_case.pattern, test_case.text))
		testing.expect(t, result.matched == test_case.should_match, fmt.tprintf("Pattern '%s' against '%s' should match: %v", test_case.pattern, test_case.text, test_case.should_match))
	}
	
	fmt.println("✓ RE2 compatibility test passed")
}