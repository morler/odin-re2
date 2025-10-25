package main

import "core:fmt"
import "regexp"

// Test new regex features: Unicode properties, lookbehinds, and mode modifiers

main :: proc() {
	fmt.println("Testing new regex features...")
	
	// Test Unicode properties
	test_unicode_properties()
	
	// Test lookbehind assertions
	test_lookbehind()
	
	// Test mode modifiers
	test_mode_modifiers()
	
	fmt.println("All tests completed!")
}

test_unicode_properties :: proc() {
	fmt.println("\n=== Testing Unicode Properties ===")
	
	patterns := []string{
		"\\p{L}+",     // One or more letters
		"\\p{N}+",     // One or more numbers  
		"\\P{L}+",     // One or more non-letters
		"\\p{Lu}+",    // One or more uppercase letters
		"\\p{Ll}+",    // One or more lowercase letters
	}
	
	texts := []string{
		"Hello123",
		"世界",
		"123ABC",
		"!@#$%",
		"MixedCASE",
	}
	
	for pattern_idx, pattern in patterns {
		fmt.printf("Pattern: %s\n", pattern)
		pat, err := regexp.regexp(pattern)
		if err != .NoError {
			fmt.printf("  Error compiling pattern: %v\n", err)
			continue
		}
		defer regexp.free_regexp(pat)
		
		for text_idx, text in texts {
			result, err := regexp.match(pat, text)
			if err != .NoError {
				fmt.printf("  Error matching '%s': %v\n", text, err)
				continue
			}
			
			if result.matched {
				matched_text := text[result.full_match.start:result.full_match.end]
				fmt.printf("  '%s' -> matches '%s'\n", text, matched_text)
			} else {
				fmt.printf("  '%s' -> no match\n", text)
			}
		}
	}
}

test_lookbehind :: proc() {
	fmt.println("\n=== Testing Lookbehind Assertions ===")
	
	patterns := []string{
		"(?<=\\d)\\w+",    // Word preceded by digit
		"(?<!\\d)\\w+",    // Word not preceded by digit
		"(?<=test)\\w+",   // Word preceded by "test"
	}
	
	texts := []string{
		"123abc456def",
		"hello world",
		"testcase",
		"notest",
	}
	
	for pattern_idx, pattern in patterns {
		fmt.printf("Pattern: %s\n", pattern)
		pat, err := regexp.regexp(pattern)
		if err != .NoError {
			fmt.printf("  Error compiling pattern: %v\n", err)
			continue
		}
		defer regexp.free_regexp(pat)
		
		for text_idx, text in texts {
			result, err := regexp.match(pat, text)
			if err != .NoError {
				fmt.printf("  Error matching '%s': %v\n", text, err)
				continue
			}
			
			if result.matched {
				matched_text := text[result.full_match.start:result.full_match.end]
				fmt.printf("  '%s' -> matches '%s'\n", text, matched_text)
			} else {
				fmt.printf("  '%s' -> no match\n", text)
			}
		}
	}
}

test_mode_modifiers :: proc() {
	fmt.println("\n=== Testing Mode Modifiers ===")
	
	patterns := []string{
		"(?i)hello",      // Case insensitive
		"(?m)^start$",    // Multiline mode
		"(?s).+",         // Dotall mode (dot matches newlines)
		"(?im)HELLO",     // Multiple flags
		"(?i:case)",      // Non-capturing group with flag
	}
	
	texts := []string{
		"HELLO world",
		"start\nend",
		"line1\nline2",
		"MIXED case",
		"justcase",
	}
	
	for pattern_idx, pattern in patterns {
		fmt.printf("Pattern: %s\n", pattern)
		pat, err := regexp.regexp(pattern)
		if err != .NoError {
			fmt.printf("  Error compiling pattern: %v\n", err)
			continue
		}
		defer regexp.free_regexp(pat)
		
		for text_idx, text in texts {
			result, err := regexp.match(pat, text)
			if err != .NoError {
				fmt.printf("  Error matching '%s': %v\n", text, err)
				continue
			}
			
			if result.matched {
				matched_text := text[result.full_match.start:result.full_match.end]
				fmt.printf("  '%s' -> matches '%s'\n", text, matched_text)
			} else {
				fmt.printf("  '%s' -> no match\n", text)
			}
		}
	}
}