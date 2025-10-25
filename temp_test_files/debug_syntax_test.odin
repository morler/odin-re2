package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Debugging Regex Syntax Issues ===")
	
	// Test alternation
	fmt.println("\n1. Testing alternation 'a|b':")
	pattern1, err1 := regexp.regexp("a|b")
	if err1 == .NoError {
		result1, match_err1 := regexp.match(pattern1, "a")
		fmt.printf("  Pattern: 'a|b', Text: 'a' -> Match: %v\n", result1.matched)
		
		result2, match_err2 := regexp.match(pattern1, "b") 
		fmt.printf("  Pattern: 'a|b', Text: 'b' -> Match: %v\n", result2.matched)
		
		result3, match_err3 := regexp.match(pattern1, "c")
		fmt.printf("  Pattern: 'a|b', Text: 'c' -> Match: %v\n", result3.matched)
		regexp.free_regexp(pattern1)
	} else {
		fmt.printf("  Compilation failed: %v\n", err1)
	}
	
	// Test wildcard
	fmt.println("\n2. Testing wildcard 'a.c':")
	pattern2, err2 := regexp.regexp("a.c")
	if err2 == .NoError {
		result1, match_err1 := regexp.match(pattern2, "abc")
		fmt.printf("  Pattern: 'a.c', Text: 'abc' -> Match: %v\n", result1.matched)
		
		result2, match_err2 := regexp.match(pattern2, "axc")
		fmt.printf("  Pattern: 'a.c', Text: 'axc' -> Match: %v\n", result2.matched)
		regexp.free_regexp(pattern2)
	} else {
		fmt.printf("  Compilation failed: %v\n", err2)
	}
	
	// Test escape sequence
	fmt.println("\n3. Testing escape 'hello\\.world':")
	pattern3, err3 := regexp.regexp("hello\\.world")
	if err3 == .NoError {
		result1, match_err1 := regexp.match(pattern3, "hello.world")
		fmt.printf("  Pattern: 'hello\\.world', Text: 'hello.world' -> Match: %v\n", result1.matched)
		
		result2, match_err2 := regexp.match(pattern3, "helloworld")
		fmt.printf("  Pattern: 'hello\\.world', Text: 'helloworld' -> Match: %v\n", result2.matched)
		regexp.free_regexp(pattern3)
	} else {
		fmt.printf("  Compilation failed: %v\n", err3)
	}
	
	fmt.println("\n=== Debug Complete ===")
}