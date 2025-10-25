package main

import "core:testing"
import "core:fmt"
import "regexp"

// Test word boundary \b matching
@(test)
test_word_boundary_basic :: proc(t: ^testing.T) {
	// Test \b at beginning of word
	pattern1, compile_err1 := regexp.regexp("\\bhello")
	testing.expect(t, compile_err1 == regexp.ErrorCode.NoError, "Pattern compilation failed: %v", regexp.error_string(compile_err1))
	defer regexp.free_regexp(pattern1)
	
	result1, match_err1 := regexp.match(pattern1, "hello world")
	testing.expect(t, match_err1 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err1))
	testing.expect(t, result1.matched, "Pattern should match at word boundary")
	testing.expect(t, result1.full_match.start == 0, "Match should start at position 0")
	testing.expect(t, result1.full_match.end == 5, "Match should end at position 5")
	
	// Test \b not matching in middle of word
	result2, match_err2 := regexp.match(pattern1, "ahello world")
	testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err2))
	testing.expect(t, !result2.matched, "Pattern should not match in middle of word")
}

// Test word boundary \b at end of word
@(test)
test_word_boundary_end :: proc(t: ^testing.T) {
	pattern, compile_err := regexp.regexp("world\\b")
	testing.expect(t, compile_err == regexp.ErrorCode.NoError, "Pattern compilation failed: %v", regexp.error_string(compile_err))
	defer regexp.free_regexp(pattern)
	
	// Test matching at end of word
	result1, match_err1 := regexp.match(pattern, "hello world")
	testing.expect(t, match_err1 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err1))
	testing.expect(t, result1.matched, "Pattern should match at word boundary")
	testing.expect(t, result1.full_match.start == 6, "Match should start at position 6")
	testing.expect(t, result1.full_match.end == 11, "Match should end at position 11")
	
	// Test not matching when followed by word character
	result2, match_err2 := regexp.match(pattern, "hello worldly")
	testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err2))
	testing.expect(t, !result2.matched, "Pattern should not match when followed by word character")
}

// Test non-word boundary \B
@(test)
test_non_word_boundary :: proc(t: ^testing.T) {
	pattern, compile_err := regexp.regexp("\\Bhello\\B")
	testing.expect(t, compile_err == regexp.ErrorCode.NoError, "Pattern compilation failed: %v", regexp.error_string(compile_err))
	defer regexp.free_regexp(pattern)
	
	// Test matching inside word
	result1, match_err1 := regexp.match(pattern, "ahelloa")
	testing.expect(t, match_err1 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err1))
	testing.expect(t, result1.matched, "Pattern should match inside word")
	testing.expect(t, result1.full_match.start == 1, "Match should start at position 1")
	testing.expect(t, result1.full_match.end == 6, "Match should end at position 6")
	
	// Test not matching at word boundaries
	result2, match_err2 := regexp.match(pattern, "hello")
	testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err2))
	testing.expect(t, !result2.matched, "Pattern should not match at word boundaries")
}

// Test word boundary with numbers and underscores
@(test)
test_word_boundary_alphanumeric :: proc(t: ^testing.T) {
	pattern, compile_err := regexp.regexp("\\btest_123\\b")
	testing.expect(t, compile_err == regexp.ErrorCode.NoError, "Pattern compilation failed: %v", regexp.error_string(compile_err))
	defer regexp.free_regexp(pattern)
	
	// Test matching with underscore and numbers
	result1, match_err1 := regexp.match(pattern, "test_123 hello")
	testing.expect(t, match_err1 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err1))
	testing.expect(t, result1.matched, "Pattern should match alphanumeric word")
	
	// Test not matching when attached to other word chars
	result2, match_err2 := regexp.match(pattern, "mytest_123world")
	testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err2))
	testing.expect(t, !result2.matched, "Pattern should not match when attached to other word characters")
}

// Test word boundary at string boundaries
@(test)
test_word_boundary_string_edges :: proc(t: ^testing.T) {
	pattern, compile_err := regexp.regexp("\\bword\\b")
	testing.expect(t, compile_err == regexp.ErrorCode.NoError, "Pattern compilation failed: %v", regexp.error_string(compile_err))
	defer regexp.free_regexp(pattern)
	
	// Test at beginning of string
	result1, match_err1 := regexp.match(pattern, "word test")
	testing.expect(t, match_err1 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err1))
	testing.expect(t, result1.matched, "Pattern should match at beginning of string")
	
	// Test at end of string
	result2, match_err2 := regexp.match(pattern, "test word")
	testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err2))
	testing.expect(t, result2.matched, "Pattern should match at end of string")
	
	// Test entire string
	result3, match_err3 := regexp.match(pattern, "word")
	testing.expect(t, match_err3 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err3))
	testing.expect(t, result3.matched, "Pattern should match entire string")
}