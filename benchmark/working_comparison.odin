package main

import "core:fmt"
import "core:time"
import "core:strings"
import "../regexp"

TestCase :: struct {
	name:     string,
	pattern:  string,
	text:     string,
	expected: bool,
	category: string,
}

PerformanceTest :: struct {
	name:       string,
	pattern:    string,
	text_gen:   proc() -> string,
	iterations: int,
}

// Generate test text
generate_long_text :: proc() -> string {
	return "The quick brown fox jumps over the lazy dog. " * 50
}

generate_repetitive_text :: proc() -> string {
	base := "abc123def456ghi789"
	result := ""
	for i := 0; i < 100; i += 1 {
		if i == 0 {
			result = base
		} else {
			// Use string builder for efficiency
			builder := fmt.sbprint(result, base)
			result = fmt.sbtoa(builder)
		}
	}
	return result
}

// Run comprehensive functionality tests
run_functionality_tests :: proc() {
	fmt.println("=== Odin RE2 Functionality Tests ===")
	fmt.println()
	
	test_cases := []TestCase{
		// Basic literals
		{"simple_literal", "hello", "hello world", true, "basic"},
		{"not_found", "xyz", "hello world", false, "basic"},
		{"empty_pattern", "", "anything", true, "basic"},
		{"empty_text", "hello", "", false, "basic"},
		
		// Anchors
		{"start_anchor", "^hello", "hello world", true, "anchors"},
		{"start_anchor_fail", "^hello", "world hello", false, "anchors"},
		{"end_anchor", "world$", "hello world", true, "anchors"},
		{"end_anchor_fail", "world$", "world hello", false, "anchors"},
		{"both_anchors", "^hello world$", "hello world", true, "anchors"},
		
		// Character classes
		{"simple_class", "[abc]", "b", true, "classes"},
		{"class_range", "[a-z]", "m", true, "classes"},
		{"class_negated", "[^abc]", "d", true, "classes"},
		{"class_fail", "[abc]", "d", false, "classes"},
		
		// Quantifiers
		{"star_zero", "ab*c", "ac", true, "quantifiers"},
		{"star_many", "ab*c", "abbbbc", true, "quantifiers"},
		{"plus_one", "ab+c", "abc", true, "quantifiers"},
		{"plus_many", "ab+c", "abbbbc", true, "quantifiers"},
		{"plus_zero_fail", "ab+c", "ac", false, "quantifiers"},
		{"question_present", "ab?c", "abc", true, "quantifiers"},
		{"question_absent", "ab?c", "ac", true, "quantifiers"},
		
		// Alternation
		{"simple_alt", "cat|dog", "cat", true, "alternation"},
		{"alt_second", "cat|dog", "dog", true, "alternation"},
		{"alt_fail", "cat|dog", "bird", false, "alternation"},
		{"multiple_alt", "a|b|c|d", "c", true, "alternation"},
		
		// Groups
		{"simple_group", "(ab)+", "abab", true, "groups"},
		{"nested_group", "(a(b)c)+", "abcabc", true, "groups"},
		
		// Escape sequences
		{"digit_escape", "\\d", "5", true, "escapes"},
		{"digit_escape_fail", "\\d", "x", false, "escapes"},
		{"word_escape", "\\w", "a", true, "escapes"},
		{"space_escape", "\\s", " ", true, "escapes"},
	}
	
	// Group by category
	categories := map[string] []TestCase{}
	for test in test_cases {
		if _, ok := categories[test.category]; !ok {
			categories[test.category] = []TestCase{}
		}
		append(&categories[test.category], test)
	}
	
	total_passed := 0
	total_tests := len(test_cases)
	
	for category_name, tests in categories {
		fmt.printf("--- %s ---\n", strings.title(category_name))
		category_passed := 0
		
		for test in tests {
			fmt.printf("  %s: ", test.name)
			
			pattern, err := regexp.regexp(test.pattern)
			if err != .NoError {
				fmt.printf("FAIL (compile: %v)\n", err)
				continue
			}
			defer regexp.free_regexp(pattern)
			
			result, match_err := regexp.match(pattern, test.text)
			if match_err != .NoError {
				fmt.printf("FAIL (match: %v)\n", match_err)
				continue
			}
			
			if result.matched == test.expected {
				fmt.printf("PASS\n")
				category_passed += 1
				total_passed += 1
			} else {
				fmt.printf("FAIL (expected %v, got %v)\n", test.expected, result.matched)
			}
		}
		
		fmt.printf("  Category: %d/%d passed\n", category_passed, len(tests))
		fmt.println()
	}
	
	fmt.printf("=== Overall Results ===\n")
	fmt.printf("Total: %d/%d tests passed (%.1f%%)\n", 
		total_passed, total_tests, f64(total_passed) / f64(total_tests) * 100.0)
}

// Run performance tests
run_performance_tests :: proc() {
	fmt.println()
	fmt.println("=== Performance Tests ===")
	fmt.println()
	
	perf_tests := []PerformanceTest{
		{
			"literal_match",
			"hello",
			generate_long_text,
			1000,
		},
		{
			"complex_pattern",
			"[a-z]+\\d+[a-z]+",
			generate_repetitive_text,
			500,
		},
		{
			"anchor_pattern",
			"^The.*dog\\.$",
			generate_long_text,
			1000,
		},
	}
	
	for test in perf_tests {
		fmt.printf("--- %s ---\n", test.name)
		
		pattern, err := regexp.regexp(test.pattern)
		if err != .NoError {
			fmt.printf("Pattern compilation failed: %v\n", err)
			continue
		}
		defer regexp.free_regexp(pattern)
		
		text := test.text_gen()
		
		fmt.printf("Pattern: %s\n", test.pattern)
		fmt.printf("Text length: %d bytes\n", len(text))
		fmt.printf("Iterations: %d\n", test.iterations)
		
		start := time.now()
		for i := 0; i < test.iterations; i += 1 {
			regexp.match(pattern, text)
		}
		end := time.now()
		
		duration := time.diff(end, start)
		
		fmt.printf("Total time: %v\n", duration)
		fmt.println()
	}
}

main :: proc() {
	run_functionality_tests()
	run_performance_tests()
}