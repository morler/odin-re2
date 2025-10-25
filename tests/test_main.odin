package main

import "core:testing"
import "regexp"

main :: proc() {
	// Simple test of the regexp package
	pattern, err := regexp.regexp("hello")
	if err != regexp.ErrorCode.NoError {
		fmt.printf("Pattern compilation failed: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	result, err := regexp.match(pattern, "hello world")
	if err != regexp.ErrorCode.NoError {
		fmt.printf("Matching failed: %v\n", err)
		return
	}
	
	fmt.printf("Match result: %v\n", result.matched)
	fmt.printf("Match range: %d-%d\n", result.full_match.start, result.full_match.end)
}