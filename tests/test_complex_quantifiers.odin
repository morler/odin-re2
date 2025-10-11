package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Testing Complex Quantifier Patterns ===")
	
	Test_Case :: struct {
		pattern: string,
		text:    string,
		expect:  string,  // Expected match text, or "NO MATCH"
	}
	
	test_cases := []Test_Case{
		{"ab*c", "ac", "ac"},           // b* matches zero b's
		{"ab*c", "abc", "abc"},         // b* matches one b
		{"ab*c", "abbc", "abbc"},       // b* matches two b's
		{"ab*c", "abbbc", "abbbc"},     // b* matches three b's
		{"ab*c", "ab", "NO MATCH"},     // Missing c
		{"ab*c", "a", "NO MATCH"},      // Missing c
		
		{"ab+c", "ac", "NO MATCH"},     // b+ requires at least one b
		{"ab+c", "abc", "abc"},         // b+ matches one b
		{"ab+c", "abbc", "abbc"},       // b+ matches two b's
		{"ab+c", "abbbc", "abbbc"},     // b+ matches three b's
		
		{"ab?c", "ac", "ac"},           // b? matches zero b's
		{"ab?c", "abc", "abc"},         // b? matches one b
		{"ab?c", "abbc", "NO MATCH"},   // b? can't match two b's
		
		{"a*b+", "b", "b"},             // a* matches zero, b+ matches one
		{"a*b+", "ab", "ab"},           // a* matches one, b+ matches one
		{"a*b+", "aaab", "aaab"},       // a* matches three, b+ matches one
		{"a*b+", "aaabbb", "aaab"},     // a* matches three, b+ matches one (greedy but leftmost)
	}
	
	for i := 0; i < len(test_cases); i += 1 {
		test := test_cases[i]
		fmt.printf("Pattern: %-6s Text: %-6s -> ", test.pattern, test.text)
		
		re, err := regexp.regexp(test.pattern)
		if err != .NoError {
			fmt.printf("COMPILE ERROR: %v\n", err)
			continue
		}
		defer regexp.free_regexp(re)
		
		result, result_err := regexp.match(re, test.text)
		if result_err != .NoError {
			fmt.printf("MATCH ERROR: %v\n", result_err)
			continue
		}
		
		if result.matched {
			match_text := test.text[result.full_match.start:result.full_match.end]
			if test.expect == "NO MATCH" {
				fmt.printf("UNEXPECTED MATCH: '%v' (expected no match)\n", match_text)
			} else if match_text == test.expect {
				fmt.printf("✓ MATCH: '%v'\n", match_text)
			} else {
				fmt.printf("✗ WRONG MATCH: '%v' (expected '%v')\n", match_text, test.expect)
			}
		} else {
			if test.expect == "NO MATCH" {
				fmt.printf("✓ NO MATCH (correct)\n")
			} else {
				fmt.printf("✗ NO MATCH (expected '%v')\n", test.expect)
			}
		}
	}
}