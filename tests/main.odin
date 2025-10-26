package main

import "core:fmt"
import "../src/regexp"

// Test quantifier fixes
main :: proc() {
	fmt.println("=== Testing Quantifier Algorithm Fixes ===")
	
	// Test 1: Simple star quantifier
	test_star_quantifier()
	
	// Test 2: Plus quantifier
	test_plus_quantifier()
	
	// Test 3: Question mark quantifier
	test_question_quantifier()
	
	// Test 4: Repeat quantifier
	test_repeat_quantifier()
	
	// Test 5: Anchor handling
	test_anchor_handling()
	
	// Test 6: Performance comparison
	test_performance()
	
	fmt.println("=== All Tests Completed ===")
}

test_star_quantifier :: proc() {
	fmt.println("\n--- Testing Star Quantifier (*) ---")
	
	pattern, err := regexp.regexp("a*")
	if err != .NoError {
		fmt.printf("Failed to compile pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{
		"",
		"a",
		"aa",
		"aaa",
		"baaa",
		"aaaaab",
		"bbbb",
	}
	
	for text in test_cases {
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
			continue
		}
		
		if result.matched {
			matched_text := text[result.full_match.start:result.full_match.end]
			fmt.printf("✓ '%s' -> '%s' (pos %d-%d)\n", text, matched_text, result.full_match.start, result.full_match.end)
		} else {
			fmt.printf("✗ '%s' -> no match\n", text)
		}
	}
}

test_plus_quantifier :: proc() {
	fmt.println("\n--- Testing Plus Quantifier (+) ---")
	
	pattern, err := regexp.regexp("a+")
	if err != .NoError {
		fmt.printf("Failed to compile pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{
		"",
		"a",
		"aa",
		"aaa",
		"baaa",
		"aaaaab",
		"bbbb",
	}
	
	for text in test_cases {
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
			continue
		}
		
		if result.matched {
			matched_text := text[result.full_match.start:result.full_match.end]
			fmt.printf("✓ '%s' -> '%s' (pos %d-%d)\n", text, matched_text, result.full_match.start, result.full_match.end)
		} else {
			fmt.printf("✗ '%s' -> no match\n", text)
		}
	}
}

test_question_quantifier :: proc() {
	fmt.println("\n--- Testing Question Mark Quantifier (?) ---")
	
	pattern, err := regexp.regexp("a?")
	if err != .NoError {
		fmt.printf("Failed to compile pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{
		"",
		"a",
		"aa",
		"baa",
		"bbbb",
	}
	
	for text in test_cases {
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
			continue
		}
		
		if result.matched {
			matched_text := text[result.full_match.start:result.full_match.end]
			fmt.printf("✓ '%s' -> '%s' (pos %d-%d)\n", text, matched_text, result.full_match.start, result.full_match.end)
		} else {
			fmt.printf("✗ '%s' -> no match\n", text)
		}
	}
}

test_repeat_quantifier :: proc() {
	fmt.println("\n--- Testing Repeat Quantifier {n,m} ---")
	
	pattern, err := regexp.regexp("a{2,4}")
	if err != .NoError {
		fmt.printf("Failed to compile pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{
		"a",
		"aa",
		"aaa",
		"aaaa",
		"aaaaa",
		"baaaab",
		"bbbb",
	}
	
	for text in test_cases {
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
			continue
		}
		
		if result.matched {
			matched_text := text[result.full_match.start:result.full_match.end]
			fmt.printf("✓ '%s' -> '%s' (pos %d-%d)\n", text, matched_text, result.full_match.start, result.full_match.end)
		} else {
			fmt.printf("✗ '%s' -> no match\n", text)
		}
	}
}

test_anchor_handling :: proc() {
	fmt.println("\n--- Testing Anchor Handling (^ $) ---")
	
	// Test begin anchor
	begin_pattern, err := regexp.regexp("^start")
	if err != .NoError {
		fmt.printf("Failed to compile begin anchor pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(begin_pattern)
	
	// Test end anchor
	end_pattern, end_err := regexp.regexp("end$")
	if end_err != .NoError {
		fmt.printf("Failed to compile end anchor pattern: %v\n", end_err)
		return
	}
	defer regexp.free_regexp(end_pattern)
	
	test_cases := []string{
		"start of line",
		"not start",
		"end of line",
		"not at end",
		"start and end",
	}
	
	fmt.println("Begin anchor (^start):")
	for text in test_cases {
		result, match_err := regexp.match(begin_pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
			continue
		}
		
		if result.matched {
			fmt.printf("✓ '%s' -> match at pos %d\n", text, result.full_match.start)
		} else {
			fmt.printf("✗ '%s' -> no match\n", text)
		}
	}
	
	fmt.println("End anchor (end$):")
	for text in test_cases {
		result, match_err := regexp.match(end_pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
			continue
		}
		
		if result.matched {
			matched_text := text[result.full_match.start:result.full_match.end]
			fmt.printf("✓ '%s' -> '%s' at pos %d\n", text, matched_text, result.full_match.start)
		} else {
			fmt.printf("✗ '%s' -> no match\n", text)
		}
	}
}

test_performance :: proc() {
	fmt.println("\n--- Testing Performance ---")
	
	// Create a challenging pattern
	pattern, err := regexp.regexp("a.*b")
	if err != .NoError {
		fmt.printf("Failed to compile pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	// Create test text with many 'a's followed by 'b'
	text_builder: [2000]byte
	text_len := 0
	for i in 0..<1000 {
		text_builder[text_len] = 'a'
		text_len += 1
	}
	text_builder[text_len] = 'b'
	text_len += 1
	text := string(text_builder[:text_len])
	
	iterations := 100
	
	fmt.printf("Pattern: 'a.*b'\n")
	fmt.printf("Text length: %d (1000 'a's + 'b')\n", len(text))
	fmt.printf("Running %d matches...\n", iterations)
	
	matched_count := 0
	for i in 0..<iterations {
		result, match_err := regexp.match(pattern, text)
		if match_err == .NoError && result.matched {
			matched_count += 1
		}
	}
	
	fmt.printf("Successfully matched: %d/%d (%.1f%%)\n", matched_count, iterations, f32(matched_count) * 100.0 / f32(iterations))
	
	if matched_count == iterations {
		fmt.printf("✓ All matches successful - algorithm is working correctly\n")
	} else {
		fmt.printf("✗ Some matches failed - algorithm needs fixing\n")
	}
}
