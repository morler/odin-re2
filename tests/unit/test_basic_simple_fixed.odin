package main

import "core:fmt"
import regexp "../../core"

main :: proc() {
	fmt.println("=== Basic Regexp Tests ===")

	// Test 1: Simple literal match
	{
		pattern, err := regexp.regexp("hello")
		if err != .NoError {
			fmt.printf("✗ Compile error: %v\n", err)
			return
		}
		defer regexp.free_regexp(pattern)

		result, match_err := regexp.match(pattern, "hello world")
		if match_err != .NoError {
			fmt.printf("✗ Match error: %v\n", match_err)
			return
		}

		if result.matched {
			fmt.println("✓ Test 1 passed: 'hello' matches in 'hello world'")
		} else {
			fmt.println("✗ Test 1 failed: 'hello' should match in 'hello world'")
		}
	}

	// Test 2: Case sensitivity
	{
		pattern, err := regexp.regexp("hello")
		if err != .NoError {
			fmt.printf("✗ Compile error: %v\n", err)
			return
		}
		defer regexp.free_regexp(pattern)

		result, _ := regexp.match(pattern, "HELLO")
		if !result.matched {
			fmt.println("✓ Test 2 passed: 'hello' does not match 'HELLO' (case sensitive)")
		} else {
			fmt.println("✗ Test 2 failed: 'hello' should not match 'HELLO'")
		}
	}

	// Test 3: Dot pattern
	{
		pattern, err := regexp.regexp("h.llo")
		if err != .NoError {
			fmt.printf("✗ Compile error: %v\n", err)
			return
		}
		defer regexp.free_regexp(pattern)

		result, _ := regexp.match(pattern, "hello")
		if result.matched {
			fmt.println("✓ Test 3 passed: 'h.llo' matches 'hello'")
		} else {
			fmt.println("✗ Test 3 failed: 'h.llo' should match 'hello'")
		}
	}

	// Test 4: Character class
	{
		pattern, err := regexp.regexp("[aeiou]+")
		if err != .NoError {
			fmt.printf("✗ Compile error: %v\n", err)
			return
		}
		defer regexp.free_regexp(pattern)

		result, _ := regexp.match(pattern, "hello")
		if result.matched {
			fmt.println("✓ Test 4 passed: '[aeiou]+' matches vowels in 'hello'")
		} else {
			fmt.println("✗ Test 4 failed: '[aeiou]+' should match vowels")
		}
	}

	// Test 5: Star quantifier
	{
		pattern, err := regexp.regexp("l*")
		if err != .NoError {
			fmt.printf("✗ Compile error: %v\n", err)
			return
		}
		defer regexp.free_regexp(pattern)

		result, _ := regexp.match(pattern, "hello")
		if result.matched {
			fmt.println("✓ Test 5 passed: 'l*' quantifier works")
		} else {
			fmt.println("✗ Test 5 failed: 'l*' should match")
		}
	}

	fmt.println("=== All basic tests completed ===")
}