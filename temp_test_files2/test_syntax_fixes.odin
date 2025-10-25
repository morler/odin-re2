package main

import "core:fmt"
import "../regexp"

// Test cases for basic regex syntax support
test_syntax_basic :: proc() {
	fmt.println("=== Basic Regex Syntax Tests ===")
	
	// Test 1: Alternation operator |
	fmt.println("\n1. Testing alternation 'a|b':")
	pattern1, err1 := regexp.regexp("a|b")
	if err1 == .NoError {
		defer regexp.free_regexp(pattern1)
		
		result1a, _ := regexp.match(pattern1, "a")
		result1b, _ := regexp.match(pattern1, "b")
		result1c, _ := regexp.match(pattern1, "c")
		
		fmt.printf("  'a|b' on 'a' -> %v (expected: true)\n", result1a.matched)
		fmt.printf("  'a|b' on 'b' -> %v (expected: true)\n", result1b.matched)
		fmt.printf("  'a|b' on 'c' -> %v (expected: false)\n", result1c.matched)
	} else {
		fmt.printf("  Compilation failed: %v\n", err1)
	}
	
	// Test 2: Wildcard character .
	fmt.println("\n2. Testing wildcard 'a.c':")
	pattern2, err2 := regexp.regexp("a.c")
	if err2 == .NoError {
		defer regexp.free_regexp(pattern2)
		
		result2a, _ := regexp.match(pattern2, "abc")
		result2b, _ := regexp.match(pattern2, "axc")
		result2c, _ := regexp.match(pattern2, "ac")
		
		fmt.printf("  'a.c' on 'abc' -> %v (expected: true)\n", result2a.matched)
		fmt.printf("  'a.c' on 'axc' -> %v (expected: true)\n", result2b.matched)
		fmt.printf("  'a.c' on 'ac' -> %v (expected: false)\n", result2c.matched)
	} else {
		fmt.printf("  Compilation failed: %v\n", err2)
	}
	
	// Test 3: Escape sequence \.
	fmt.println("\n3. Testing escape 'hello\\.world':")
	pattern3, err3 := regexp.regexp("hello\\.world")
	if err3 == .NoError {
		defer regexp.free_regexp(pattern3)
		
		result3a, _ := regexp.match(pattern3, "hello.world")
		result3b, _ := regexp.match(pattern3, "helloworld")
		
		fmt.printf("  'hello\\.world' on 'hello.world' -> %v (expected: true)\n", result3a.matched)
		fmt.printf("  'hello\\.world' on 'helloworld' -> %v (expected: false)\n", result3b.matched)
	} else {
		fmt.printf("  Compilation failed: %v\n", err3)
	}
	
	// Test 4: Basic quantifier {3}
	fmt.println("\n4. Testing quantifier 'a{3}':")
	pattern4, err4 := regexp.regexp("a{3}")
	if err4 == .NoError {
		defer regexp.free_regexp(pattern4)
		
		result4a, _ := regexp.match(pattern4, "aaa")
		result4b, _ := regexp.match(pattern4, "aa")
		result4c, _ := regexp.match(pattern4, "aaaa")
		
		fmt.printf("  'a{3}' on 'aaa' -> %v (expected: true)\n", result4a.matched)
		fmt.printf("  'a{3}' on 'aa' -> %v (expected: false)\n", result4b.matched)
		fmt.printf("  'a{3}' on 'aaaa' -> %v (expected: false)\n", result4c.matched)
	} else {
		fmt.printf("  Compilation failed: %v\n", err4)
	}
}

main :: proc() {
	test_syntax_basic()
	fmt.println("\n=== Test Complete ===")
}