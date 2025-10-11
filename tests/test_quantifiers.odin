package main

import "core:fmt"
import "core:testing"
import "regexp"

@(test)
test_star_quantifier :: proc(t: ^testing.T) {
	re, err := regexp.regexp("a*")
	defer regexp.free_regexp(re)
	
	testing.expect(t, err == regexp.ErrorCode.NoError, "Failed to parse 'a*'")
	
	// Test empty string (should match with 0 'a's)
	result, match_err := regexp.match(re, "")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match empty string")
	testing.expect(t, result.full_match.start == 0, "Empty match should start at 0")
	testing.expect(t, result.full_match.end == 0, "Empty match should end at 0")
	
	// Test single 'a'
	result, match_err = regexp.match(re, "a")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'a'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 1, "Match should end at 1")
	
	// Test multiple 'a's
	result, match_err = regexp.match(re, "aaa")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aaa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 3, "Match should end at 3")
}

@(test)
test_plus_quantifier :: proc(t: ^testing.T) {
	re, err := regexp.regexp("a+")
	defer regexp.free_regexp(re)
	
	testing.expect(t, err == regexp.ErrorCode.NoError, "Failed to parse 'a+'")
	
	// Test empty string (should not match)
	result, match_err := regexp.match(re, "")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, !result.matched, "Should not match empty string")
	
	// Test single 'a'
	result, match_err = regexp.match(re, "a")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'a'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 1, "Match should end at 1")
	
	// Test multiple 'a's
	result, match_err = regexp.match(re, "aaa")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aaa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 3, "Match should end at 3")
}

@(test)
test_question_quantifier :: proc(t: ^testing.T) {
	re, err := regexp.regexp("a?")
	defer regexp.free_regexp(re)
	
	testing.expect(t, err == regexp.ErrorCode.NoError, "Failed to parse 'a?'")
	
	// Test empty string (should match with 0 'a's)
	result, match_err := regexp.match(re, "")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match empty string")
	testing.expect(t, result.full_match.start == 0, "Empty match should start at 0")
	testing.expect(t, result.full_match.end == 0, "Empty match should end at 0")
	
	// Test single 'a'
	result, match_err = regexp.match(re, "a")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'a'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 1, "Match should end at 1")
	
	// Test 'aa' (should match first 'a' only)
	result, match_err = regexp.match(re, "aa")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 1, "Match should end at 1")
}

@(test)
test_exact_repeat :: proc(t: ^testing.T) {
	re, err := regexp.regexp("a{3}")
	defer regexp.free_regexp(re)
	
	testing.expect(t, err == regexp.ErrorCode.NoError, "Failed to parse 'a{3}'")
	
	// Test empty string (should not match)
	result, match_err := regexp.match(re, "")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, !result.matched, "Should not match empty string")
	
	// Test 'aa' (should not match)
	result, match_err = regexp.match(re, "aa")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, !result.matched, "Should not match 'aa'")
	
	// Test 'aaa' (should match)
	result, match_err = regexp.match(re, "aaa")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aaa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 3, "Match should end at 3")
	
	// Test 'aaaa' (should match first 3)
	result, match_err = regexp.match(re, "aaaa")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aaaa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 3, "Match should end at 3")
}

@(test)
test_range_repeat :: proc(t: ^testing.T) {
	re, err := regexp.regexp("a{2,4}")
	defer regexp.free_regexp(re)
	
	testing.expect(t, err == regexp.ErrorCode.NoError, "Failed to parse 'a{2,4}'")
	
	// Test empty string (should not match)
	result, match_err := regexp.match(re, "")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, !result.matched, "Should not match empty string")
	
	// Test 'a' (should not match)
	result, match_err = regexp.match(re, "a")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, !result.matched, "Should not match 'a'")
	
	// Test 'aa' (should match)
	result, match_err = regexp.match(re, "aa")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 2, "Match should end at 2")
	
	// Test 'aaa' (should match)
	result, match_err = regexp.match(re, "aaa")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aaa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 3, "Match should end at 3")
	
	// Test 'aaaa' (should match)
	result, match_err = regexp.match(re, "aaaa")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aaaa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 4, "Match should end at 4")
	
	// Test 'aaaaa' (should match first 4)
	result, match_err = regexp.match(re, "aaaaa")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aaaaa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 4, "Match should end at 4")
}

@(test)
test_min_repeat :: proc(t: ^testing.T) {
	re, err := regexp.regexp("a{2,}")
	defer regexp.free_regexp(re)
	
	testing.expect(t, err == regexp.ErrorCode.NoError, "Failed to parse 'a{2,}'")
	
	// Test empty string (should not match)
	result, match_err := regexp.match(re, "")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, !result.matched, "Should not match empty string")
	
	// Test 'a' (should not match)
	result, match_err = regexp.match(re, "a")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, !result.matched, "Should not match 'a'")
	
	// Test 'aa' (should match)
	result, match_err = regexp.match(re, "aa")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 2, "Match should end at 2")
	
	// Test 'aaaaa' (should match all)
	result, match_err = regexp.match(re, "aaaaa")
	testing.expect(t, err == regexp.ErrorCode.NoError, "Match should succeed")
	testing.expect(t, result.matched, "Should match 'aaaaa'")
	testing.expect(t, result.full_match.start == 0, "Match should start at 0")
	testing.expect(t, result.full_match.end == 5, "Match should end at 5")
}