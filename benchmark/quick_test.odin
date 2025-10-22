package main

import "core:fmt"
import "core:time"
import "../regexp"

// Simple test structure
Test :: struct {
	name:    string,
	pattern: string,
	text:    string,
	expect:  bool,
}

// Run basic tests
run_basic_tests :: proc() {
	tests := []Test{
		{"literal", "hello", "hello world", true},
		{"not_found", "xyz", "hello world", false},
		{"empty", "", "anything", true},
		{"anchor", "^hello", "hello world", true},
		{"char_class", "[abc]", "b", true},
		{"star", "ab*c", "ac", true},
		{"plus", "ab+c", "abc", true},
		{"question", "ab?c", "ac", true},
		{"alternation", "cat|dog", "cat", true},
	}
	
	fmt.println("=== Odin RE2 Basic Test ===")
	fmt.println()
	
	passed := 0
	total := len(tests)
	
	for test in tests {
		fmt.printf("Testing %s: ", test.name)
		
		pattern, err := regexp.regexp(test.pattern)
		if err != .NoError {
			fmt.printf("FAIL (compile error: %v)\n", err)
			continue
		}
		defer regexp.free_regexp(pattern)
		
		result, match_err := regexp.match(pattern, test.text)
		if match_err != .NoError {
			fmt.printf("FAIL (match error: %v)\n", match_err)
			continue
		}
		
		if result.matched == test.expect {
			fmt.printf("PASS\n")
			passed += 1
		} else {
			fmt.printf("FAIL (expected %v, got %v)\n", test.expect, result.matched)
		}
	}
	
	fmt.println()
	fmt.printf("Results: %d/%d tests passed (%.1f%%)\n", 
		passed, total, f64(passed) / f64(total) * 100.0)
	
	// Test performance
	fmt.println()
	fmt.println("=== Performance Test ===")
	
	pattern, err := regexp.regexp("hello")
	if err == .NoError {
		defer regexp.free_regexp(pattern)
		
		// Use a simpler text for testing
		text := "hello world hello world hello world hello world hello world hello world hello world hello world hello world hello world"
		iterations := 1000
		
		start := time.now()
		for i := 0; i < iterations; i += 1 {
			regexp.match(pattern, text)
		}
		end := time.now()
		
		duration := time.diff(end, start)
		
		fmt.printf("Pattern: 'hello'\n")
		fmt.printf("Text size: %d bytes\n", len(text))
		fmt.printf("Iterations: %d\n", iterations)
		fmt.printf("Total time: %v\n", duration)
		fmt.printf("Performance test completed\n")
	}
}

main :: proc() {
	run_basic_tests()
}