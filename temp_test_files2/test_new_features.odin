package main

import "core:fmt"
import "../regexp"

// Test new regex features: Unicode properties, lookbehind, mode modifiers
main :: proc() {
	fmt.println("Testing new regex features...")
	
	// Test 1: Unicode property \p{L}
	test_unicode_property()
	
	// Test 2: Lookbehind assertions
	test_lookbehind()
	
	// Test 3: Case-insensitive matching
	test_case_insensitive()
	
	// Test 4: Multiline mode
	test_multiline()
	
	// Test 5: Dotall mode
	test_dotall()
	
	fmt.println("All tests completed!")
}

test_unicode_property :: proc() {
	fmt.println("\n=== Unicode Property Tests ===")
	
	pattern, err := regexp(`\p{L}`)
	if err != .NoError {
		fmt.printf("Failed to compile \\p{L}: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{"a", "Z", "é", "5", "!"}
	for text in test_cases {
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
		} else if result.matched {
			fmt.printf("✓ \\p{L} matches '%s'\n", text)
		} else {
			fmt.printf("✗ \\p{L} does not match '%s'\n", text)
		}
	}
	
	// Test negated property \P{N}
	pattern2, err2 := regexp(`\P{N}`)
	if err2 != .NoError {
		fmt.printf("Failed to compile \\P{N}: %v\n", err2)
		return
	}
	defer regexp.free_regexp(pattern2)
	
	test_cases2 := []string{"a", "b", "5"}
	for text in test_cases2 {
		result2, match_err2 := regexp.match(pattern2, text)
		if match_err2 != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err2)
		} else if result2.matched {
			fmt.printf("✓ \\P{N} matches '%s'\n", text)
		} else {
			fmt.printf("✗ \\P{N} does not match '%s'\n", text)
		}
	}
}

test_lookbehind :: proc() {
	fmt.println("\n=== Lookbehind Tests ===")
	
	// Test positive lookbehind
	pattern, err := regexp(`(?<=abc)def`)
	if err != .NoError {
		fmt.printf("Failed to compile lookbehind: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{"abcdef", "xyzdef", "abc"}
	for text in test_cases {
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
		} else if result.matched {
			fmt.printf("✓ (?<=abc)def matches '%s'\n", text)
		} else {
			fmt.printf("✗ (?<=abc)def does not match '%s'\n", text)
		}
	}
	
	// Test negative lookbehind
	pattern2, err2 := regexp(`(?<!abc)def`)
	if err2 != .NoError {
		fmt.printf("Failed to compile negative lookbehind: %v\n", err2)
		return
	}
	defer regexp.free_regexp(pattern2)
	
	test_cases2 := []string{"abcdef", "xyzdef"}
	for text in test_cases2 {
		result2, match_err2 := regexp.match(pattern2, text)
		if match_err2 != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err2)
		} else if result2.matched {
			fmt.printf("✓ (?<!abc)def matches '%s'\n", text)
		} else {
			fmt.printf("✗ (?<!abc)def does not match '%s'\n", text)
		}
	}
}

test_case_insensitive :: proc() {
	fmt.println("\n=== Case-Insensitive Tests ===")
	
	pattern, err := regexp(`(?i)abc`)
	if err != .NoError {
		fmt.printf("Failed to compile (?i)abc: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{"abc", "ABC", "AbC", "xyz"}
	for text in test_cases {
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
		} else if result.matched {
			fmt.printf("✓ (?i)abc matches '%s'\n", text)
		} else {
			fmt.printf("✗ (?i)abc does not match '%s'\n", text)
		}
	}
}

test_multiline :: proc() {
	fmt.println("\n=== Multiline Tests ===")
	
	pattern, err := regexp(`(?m)^abc`)
	if err != .NoError {
		fmt.printf("Failed to compile (?m)^abc: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{"abc", "xyz\nabc", "xyz abc"}
	for text in test_cases {
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
		} else if result.matched {
			fmt.printf("✓ (?m)^abc matches '%s'\n", text)
		} else {
			fmt.printf("✗ (?m)^abc does not match '%s'\n", text)
		}
	}
}

test_dotall :: proc() {
	fmt.println("\n=== Dotall Tests ===")
	
	pattern, err := regexp(`(?s)abc.*def`)
	if err != .NoError {
		fmt.printf("Failed to compile (?s)abc.*def: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	test_cases := []string{"abcXYZdef", "abc\ndef", "abcXYZ\ndef"}
	for text in test_cases {
		result, match_err := regexp.match(pattern, text)
		if match_err != .NoError {
			fmt.printf("Error matching '%s': %v\n", text, match_err)
		} else if result.matched {
			fmt.printf("✓ (?s)abc.*def matches '%s'\n", text)
		} else {
			fmt.printf("✗ (?s)abc.*def does not match '%s'\n", text)
		}
	}
}