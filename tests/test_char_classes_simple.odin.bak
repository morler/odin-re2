package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Character Classes Test ===")
	
	// Test 1: Simple character class [abc]
	fmt.println("\n1. Testing [abc]...")
	pattern1, err := regexp.regexp("[abc]")
	if err != regexp.ErrorCode.NoError {
		fmt.printf("Error: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern1)
	
	result, match_err := regexp.match(pattern1, "apple")
	if match_err != regexp.ErrorCode.NoError {
		fmt.printf("Error matching: %v\n", match_err)
	} else {
		fmt.printf("apple -> %v\n", result.matched)
	}
	
	result, match_err = regexp.match(pattern1, "xyz")
	if match_err != regexp.ErrorCode.NoError {
		fmt.printf("Error matching: %v\n", match_err)
	} else {
		fmt.printf("xyz -> %v\n", result.matched)
	}
	
	// Test 2: Range [a-z]
	fmt.println("\n2. Testing [a-z]...")
	pattern2, err2 := regexp.regexp("[a-z]")
	if err2 != regexp.ErrorCode.NoError {
		fmt.printf("Error: %v\n", err2)
		return
	}
	defer regexp.free_regexp(pattern2)
	
	result, match_err = regexp.match(pattern2, "a")
	if match_err != regexp.ErrorCode.NoError {
		fmt.printf("Error matching: %v\n", match_err)
	} else {
		fmt.printf("a -> %v\n", result.matched)
	}
	
	result, match_err = regexp.match(pattern2, "A")
	if match_err != regexp.ErrorCode.NoError {
		fmt.printf("Error matching: %v\n", match_err)
	} else {
		fmt.printf("A -> %v\n", result.matched)
	}
	
	// Test 3: Any character .
	fmt.println("\n3. Testing . (any character)...")
	pattern3, err3 := regexp.regexp(".")
	if err3 != regexp.ErrorCode.NoError {
		fmt.printf("Error: %v\n", err3)
		return
	}
	defer regexp.free_regexp(pattern3)
	
	result, match_err = regexp.match(pattern3, "a")
	if match_err != regexp.ErrorCode.NoError {
		fmt.printf("Error matching: %v\n", match_err)
	} else {
		fmt.printf("a -> %v\n", result.matched)
	}
	
	result, match_err = regexp.match(pattern3, "")
	if match_err != regexp.ErrorCode.NoError {
		fmt.printf("Error matching: %v\n", match_err)
	} else {
		fmt.printf("empty -> %v\n", result.matched)
	}
	
	fmt.println("\n=== Character Classes Test Complete ===")
}