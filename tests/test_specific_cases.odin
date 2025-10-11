package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("Testing specific failing cases...")
	
	test_cases := []struct {
		pattern: string,
		input:   string,
		expect:  bool,
	}{
		{"abc", "abcd", true},
		{"abc", "xabc", true},
		{"abc", "xabcy", true},
		{"abc", "ab", false},
		{"abc", "bc", false},
	}
	
	for test_case in test_cases {
		fmt.printf("\nTesting pattern '%s' against '%s' (expect %v)...\n", 
			test_case.pattern, test_case.input, test_case.expect)
		
		pattern, err := regexp.regexp(test_case.pattern)
		if err != .NoError {
			fmt.println("Failed to compile pattern:", err)
			continue
		}
		defer regexp.free_regexp(pattern)
		
		result, match_err := regexp.match(pattern, test_case.input)
		if match_err != .NoError {
			fmt.printf("Error matching: %v\n", match_err)
		} else {
			fmt.printf("Result: matched=%v, expected=%v", result.matched, test_case.expect)
			if result.matched {
				fmt.printf(", range: [%d, %d]", result.full_match.start, result.full_match.end)
			}
			fmt.println()
			
			if result.matched != test_case.expect {
				fmt.printf("*** TEST FAILURE ***\n")
			}
		}
	}
}