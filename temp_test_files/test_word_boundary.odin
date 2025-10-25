package main

import "core:fmt"
import "./regexp"

main :: proc() {
	fmt.println("Testing word boundary...")
	
	// Test word boundary
	pattern, err := regexp.regexp("\\bword\\b")
	if err != .NoError {
		fmt.printf("Failed to compile pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	fmt.println("Pattern compiled successfully")
	
	// Test case 1: should match
	text1 := "this word is isolated"
	fmt.printf("Testing text1: '%s'\n", text1)
	fmt.printf("Length: %d\n", len(text1))
	
	// Test word boundary check manually
	for i in 0..<len(text1) {
		if text1[i] == 'w' {
			fmt.printf("Found 'w' at position %d\n", i)
			// Check if this is a word boundary
			left_char := rune(0)
			right_char := rune(text1[i])
			if i > 0 {
				left_char = rune(text1[i-1])
			}
			fmt.printf("Left: '%c', Right: '%c'\n", left_char, right_char)
		}
	}
	
	result1, err1 := regexp.match(pattern, text1)
	if err1 != .NoError {
		fmt.printf("Match error: %v\n", err1)
		return
	}
	fmt.printf("Matched: %v\n", result1.matched)
	if result1.matched {
		match_text := text1[result1.full_match.start:result1.full_match.end]
		fmt.printf("Match: '%s' (range: %d-%d)\n", match_text, result1.full_match.start, result1.full_match.end)
	} else {
		fmt.printf("No match found\n")
	}
	
	// Test case 2: should not match
	text2 := "swordplay"
	result2, err2 := regexp.match(pattern, text2)
	if err2 != .NoError {
		fmt.printf("Match error: %v\n", err2)
		return
	}
	fmt.printf("\nText2: '%s'\n", text2)
	fmt.printf("Matched: %v\n", result2.matched)
}