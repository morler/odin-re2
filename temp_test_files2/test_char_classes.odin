package main

import "core:fmt"
import "../regexp"

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
	
	test_strings := []string{"apple", "banana", "cherry", "date"}
	for s in test_strings {
		result, err := regexp.match(pattern1, s)
		if err != regexp.ErrorCode.NoError {
			fmt.printf("Error matching '%s': %v\n", s, err)
			continue
		}
		fmt.printf("'%s' -> %v\n", s, result.matched)
	}
	
	// Test 2: Range [a-z]
	fmt.println("\n2. Testing [a-z]...")
	pattern2, compile_err2 := regexp.regexp("[a-z]")
	if compile_err2 != regexp.ErrorCode.NoError {
		fmt.printf("Error: %v\n", compile_err2)
		return
	}
	defer regexp.free_regexp(pattern2)
	
	test_strings2 := []string{"a", "A", "1", "z", "Z"}
	for s in test_strings2 {
		result, match_err2 := regexp.match(pattern2, s)
		if match_err2 != regexp.ErrorCode.NoError {
			fmt.printf("Error matching '%s': %v\n", s, match_err2)
			continue
		}
		fmt.printf("'%s' -> %v\n", s, result.matched)
	}
	
	// Test 3: Negated class [^0-9]
	fmt.println("\n3. Testing [^0-9]...")
	pattern3, compile_err3 := regexp.regexp("[^0-9]")
	if compile_err3 != regexp.ErrorCode.NoError {
		fmt.printf("Error: %v\n", compile_err3)
		return
	}
	defer regexp.free_regexp(pattern3)
	
	test_strings3 := []string{"a", "5", "Z", "0"}
	for s in test_strings3 {
		result, match_err3 := regexp.match(pattern3, s)
		if match_err3 != regexp.ErrorCode.NoError {
			fmt.printf("Error matching '%s': %v\n", s, match_err3)
			continue
		}
		fmt.printf("'%s' -> %v\n", s, result.matched)
	}
	
	// Test 4: Any character .
	fmt.println("\n4. Testing . (any character)...")
	pattern4, compile_err4 := regexp.regexp(".")
	if compile_err4 != regexp.ErrorCode.NoError {
		fmt.printf("Error: %v\n", compile_err4)
		return
	}
	defer regexp.free_regexp(pattern4)
	
	test_strings4 := []string{"a", "1", "\n", ""}
	for s in test_strings4 {
		result, match_err4 := regexp.match(pattern4, s)
		if match_err4 != regexp.ErrorCode.NoError {
			fmt.printf("Error matching '%s': %v\n", s, match_err4)
			continue
		}
		fmt.printf("'%s' -> %v\n", s, result.matched)
	}
	
	// Test 5: Alternation a|b
	fmt.println("\n5. Testing a|b...")
	pattern5, compile_err5 := regexp.regexp("a|b")
	if compile_err5 != regexp.ErrorCode.NoError {
		fmt.printf("Error: %v\n", compile_err5)
		return
	}
	defer regexp.free_regexp(pattern5)
	
	test_strings5 := []string{"a", "b", "c", "ab"}
	for s in test_strings5 {
		result, match_err5 := regexp.match(pattern5, s)
		if match_err5 != regexp.ErrorCode.NoError {
			fmt.printf("Error matching '%s': %v\n", s, match_err5)
			continue
		}
		fmt.printf("'%s' -> %v\n", s, result.matched)
	}
	
	fmt.println("\n=== Character Classes Test Complete ===")
}