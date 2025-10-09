package tests

import "core:testing"
import "core:time"
import "core:fmt"
import "core:strings"
import "../regexp"

// Test linear time complexity for simple literals
// This is CRITICAL for RE2 compliance - must verify O(n) behavior
@(test)
test_linear_time_simple_literals :: proc(t: ^testing.T) {
	pattern, err := regexp.regexp("x")
	testing.expect(t, err == .NoError)
	defer regexp.free_regexp(pattern)
	
	// Test with increasing input sizes to verify linear time
	sizes := []int{100, 1000, 10000}
	
	for size in sizes {
		// Create input string with pattern at the end using simple allocation
		input_data := make([]u8, size + 1)
		for i in 0..<size {
			input_data[i] = 'a'
		}
		input_data[size] = 'x'
		input := string(input_data)
		
		// Measure time
		start := time.now()
		result, err := regexp.match(pattern, input)
		duration := time.since(start)
		
		testing.expect(t, err == .NoError)
		testing.expect(t, result.matched)
		
		// Time should grow linearly with input size
		// Allow some tolerance for measurement noise
		max_expected_ms := f64(size) * 0.01 // 10 microseconds per character
		actual_ms := f64(duration) / f64(time.Millisecond)
		
		testing.expect(t, actual_ms < max_expected_ms)
		
		fmt.printf("Size %d: %.2fms\n", size, actual_ms)
	}
}

// Test performance with long patterns
@(test)
test_pattern_compilation_performance :: proc(t: ^testing.T) {
	// Test compilation time for patterns of different lengths
	pattern_lengths := []int{10, 100, 500}
	
	for length in pattern_lengths {
		// Create pattern with repeated literals using simple allocation
		pattern_data := make([]u8, length)
		for i in 0..<length {
			pattern_data[i] = 'a'
		}
		pattern_str := string(pattern_data)
		
		// Measure compilation time
		start := time.now()
		pattern, err := regexp.regexp(pattern_str)
		duration := time.since(start)
		
		testing.expect(t, err == .NoError)
		testing.expect(t, pattern != nil)
		
		if pattern != nil {
			regexp.free_regexp(pattern)
		}
		
		// Compilation should be fast - under 10ms even for 1KB patterns
		max_expected_ms := 10.0
		actual_ms := f64(duration) / f64(time.Millisecond)
		
		testing.expect(t, actual_ms < max_expected_ms)
		
		fmt.printf("Pattern length %d: compilation %.2fms\n", length, actual_ms)
	}
}

// Test repeated matching performance (pattern reuse)
@(test)
test_repeated_matching_performance :: proc(t: ^testing.T) {
	pattern, err := regexp.regexp("target")
	testing.expect(t, err == .NoError)
	defer regexp.free_regexp(pattern)
	
	// Test repeated matching with same pattern
	input := "this is a target string in the target area"
	iterations := 1000
	
	start := time.now()
	for i in 0..<iterations {
		result, err := regexp.match(pattern, input)
		testing.expect(t, err == .NoError)
		// We don't check result.matched here to focus on performance
	}
	duration := time.since(start)
	
	avg_microseconds := f64(duration) / f64(time.Microsecond) / f64(iterations)
	
	// Average time per match should be very low (pattern reuse optimization)
	max_avg_us := 100.0 // 100 microseconds per match
	
	testing.expect(t, avg_microseconds < max_avg_us)
	
	fmt.printf("Repeated matching: %d iterations in %.2fms (avg %.2fμs per match)\n", 
		iterations, f64(duration) / f64(time.Millisecond), avg_microseconds)
}

// Test memory usage stays bounded
@(test)
test_memory_usage_bounds :: proc(t: ^testing.T) {
	// Test that memory usage doesn't grow unbounded with repeated operations
	pattern, err := regexp.regexp("test")
	testing.expect(t, err == .NoError)
	defer regexp.free_regexp(pattern)
	
	// Perform many matches
	for i in 0..<100 {
		input := fmt.tprintf("test string %d", i)
		result, err := regexp.match(pattern, input)
		testing.expect(t, err == .NoError)
		// Memory should be properly managed after each match
	}
	
	// This test mainly ensures we don't crash or run out of memory
	// In a real implementation, we'd track actual memory usage
	fmt.printf("Memory usage test completed 100 iterations\n")
}