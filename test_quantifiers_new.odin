package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Quantifiers Test ===")
	
	tests := []struct {
		pattern: string,
		text:    string,
		expect:  bool,
		desc:    string,
	}{
		// Star (*) tests
		{"a*", "", true, "Star: empty string"},
		{"a*", "a", true, "Star: single a"},
		{"a*", "aaa", true, "Star: multiple a's"},
		{"a*", "bbb", true, "Star: zero a's in other text"},
		{"ab*", "a", true, "Star: a followed by zero b's"},
		{"ab*", "ab", true, "Star: a followed by one b"},
		{"ab*", "abbb", true, "Star: a followed by multiple b's"},
		
		// Plus (+) tests
		{"a+", "", false, "Plus: empty string should fail"},
		{"a+", "a", true, "Plus: single a"},
		{"a+", "aaa", true, "Plus: multiple a's"},
		{"a+", "bbb", false, "Plus: no a's should fail"},
		{"ab+", "a", false, "Plus: a with no b should fail"},
		{"ab+", "ab", true, "Plus: a followed by one b"},
		{"ab+", "abbb", true, "Plus: a followed by multiple b's"},
		
		// Question mark (?) tests
		{"a?", "", true, "Quest: empty string"},
		{"a?", "a", true, "Quest: single a"},
		{"a?", "aaa", true, "Quest: first a matches"},
		{"a?", "bbb", true, "Quest: zero a's matches"},
		{"ab?", "a", true, "Quest: a with optional b (no b)"},
		{"ab?", "ab", true, "Quest: a with optional b (with b)"},
		{"ab?", "abb", true, "Quest: a with optional b (extra b ignored)"},
		
		// Repeat {n,m} tests
		{"a{2}", "aa", true, "Repeat: exactly 2 a's"},
		{"a{2}", "a", false, "Repeat: exactly 2 a's (too few)"},
		{"a{2}", "aaa", true, "Repeat: exactly 2 a's (extra ignored)"},
		{"a{2,4}", "aa", true, "Repeat: 2-4 a's (2)"},
		{"a{2,4}", "aaa", true, "Repeat: 2-4 a's (3)"},
		{"a{2,4}", "aaaa", true, "Repeat: 2-4 a's (4)"},
		{"a{2,4}", "a", false, "Repeat: 2-4 a's (too few)"},
		{"a{2,}", "aa", true, "Repeat: 2+ a's (2)"},
		{"a{2,}", "aaaaa", true, "Repeat: 2+ a's (5)"},
		{"a{0,2}", "", true, "Repeat: 0-2 a's (0)"},
		{"a{0,2}", "a", true, "Repeat: 0-2 a's (1)"},
		{"a{0,2}", "aa", true, "Repeat: 0-2 a's (2)"},
		
		// Complex combinations
		{"a*b+", "b", true, "Complex: zero a's, one b"},
		{"a*b+", "ab", true, "Complex: one a, one b"},
		{"a*b+", "aaab", true, "Complex: multiple a's, one b"},
		{"a*b+", "aaabbb", true, "Complex: multiple a's, multiple b's"},
		{"a*b+", "a", false, "Complex: a but no b should fail"},
		{"(ab)+", "ab", true, "Complex: group repeated once"},
		{"(ab)+", "abab", true, "Complex: group repeated twice"},
		{"(ab)+", "a", false, "Complex: incomplete group should fail"},
	}
	
	passed := 0
	total := len(tests)
	
	for i in 0..<len(tests) {
		test_case := tests[i]
		fmt.printf("%d. %s\n", i+1, test_case.desc)
		fmt.printf("   Pattern: %s, Text: %s\n", test_case.pattern, test_case.text)
		
		// Compile regex
		regex, err := regexp.regexp(test_case.pattern)
		if err != .NoError {
			fmt.printf("   ❌ Failed to compile pattern: %v\n", err)
			continue
		}
		defer regexp.free_regexp(regex)
		
		// Test match
		result, match_err := regexp.match(regex, test_case.text)
		if match_err != .NoError {
			fmt.printf("   ❌ Match error: %v\n", match_err)
			continue
		}
		
		if result.matched == test_case.expect {
			fmt.printf("   ✅ %v (expected %v)\n", result.matched, test_case.expect)
			passed += 1
		} else {
			fmt.printf("   ❌ %v (expected %v)\n", result.matched, test_case.expect)
		}
	}
	
	fmt.printf("\n=== Test Results ===\n")
	fmt.printf("Passed: %d/%d (%.1f%%)\n", passed, total, f32(passed) / f32(total) * 100.0)
	
	if passed == total {
		fmt.println("🎉 All quantifier tests passed!")
	} else {
		fmt.println("⚠️  Some tests failed. Need to fix issues.")
	}
}