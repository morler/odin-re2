package main

import "core:fmt"
import "core:testing"
import "regexp"

@(test)
test_simple_literal :: proc(t: ^testing.T) {
	re, err := regexp.regexp("hello")
	defer regexp.free_regexp(re)
	
	testing.expect(t, err == regexp.ErrorCode.NoError, "Failed to parse 'hello'")
	
	result, match_err := regexp.match(re, "hello world")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'hello' in 'hello world'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 5, "Match should end at 5")
}

@(test)
test_empty_pattern :: proc(t: ^testing.T) {
	re, err := regexp.regexp("")
	defer regexp.free_regexp(re)
	
	testing.expect(t, err == regexp.ErrorCode.NoError, "Failed to parse empty pattern")
	
	result, match_err := regexp.match(re, "anything")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Empty pattern should match")
	testing.expect(t, result.full_match.start == 0, "Empty match should start at 0")
	testing.expect(t, result.full_match.end == 0, "Empty match should end at 0")
}