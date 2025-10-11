package main

import "core:fmt"
import "regexp"

main :: proc() {
	// Test the regexp package
	pattern, err := regexp.regexp("hello")
	if err != regexp.ErrorCode.NoError {
		fmt.printf("Pattern compilation failed: %v\n", regexp.error_string(err))
		return
	}
	defer regexp.free_regexp(pattern)
	
	result, match_err := regexp.match(pattern, "hello world")
	if match_err != regexp.ErrorCode.NoError {
		fmt.printf("Matching failed: %v\n", regexp.error_string(match_err))
		return
	}
	
	fmt.printf("Match result: %v\n", result.matched)
	if result.matched {
		fmt.printf("Match range: %d-%d\n", result.full_match.start, result.full_match.end)
	}
	
	// Test convenience function
	matched, convenience_err := regexp.match_string("test", "this is a test")
	if convenience_err != regexp.ErrorCode.NoError {
		fmt.printf("Convenience matching failed: %v\n", regexp.error_string(convenience_err))
		return
	}
	
	fmt.printf("Convenience match result: %v\n", matched)
}