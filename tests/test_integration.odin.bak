package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("Testing integrated NFA matcher...")
	
	// Test basic matching
	pattern, err := regexp.regexp("a")
	if err != .NoError {
		fmt.println("Failed to compile pattern:", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{"a", "b", "ab", "ba", ""}
	
	for test in test_cases {
		result, match_err := regexp.match(pattern, test)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", test, match_err)
		} else {
			fmt.printf("'%s' -> matched: %v", test, result.matched)
			if result.matched {
				fmt.printf(", range: [%d, %d]", result.full_match.start, result.full_match.end)
			}
			fmt.println()
		}
	}
	
	// Test character class
	fmt.println("\nTesting character class...")
	pattern2, err2 := regexp.regexp("[ab]")
	if err2 != .NoError {
		fmt.println("Failed to compile pattern2:", err2)
		return
	}
	defer regexp.free_regexp(pattern2)
	
	char_test_cases := []string{"a", "b", "c"}
	for char_test in char_test_cases {
		result, match_err := regexp.match(pattern2, char_test)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", char_test, match_err)
		} else {
			fmt.printf("'%s' -> matched: %v\n", char_test, result.matched)
		}
	}
	
	// Test concatenation
	fmt.println("\nTesting concatenation...")
	pattern3, err3 := regexp.regexp("ab")
	if err3 != .NoError {
		fmt.println("Failed to compile pattern3:", err3)
		return
	}
	defer regexp.free_regexp(pattern3)
	
	concat_test_cases := []string{"ab", "a", "b", "abc"}
	for concat_test in concat_test_cases {
		result, match_err := regexp.match(pattern3, concat_test)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", concat_test, match_err)
		} else {
			fmt.printf("'%s' -> matched: %v", concat_test, result.matched)
			if result.matched {
				fmt.printf(", range: [%d, %d]", result.full_match.start, result.full_match.end)
			}
			fmt.println()
		}
	}
}