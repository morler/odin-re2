package main

import "core:testing"
import "core:fmt"
import "regexp"

// Test basic literal pattern matching
// This test should FAIL initially, then pass after matching engine implementation
@(test)
test_basic_literal_matching :: proc(t: ^testing.T) {
	// Test simple literal match
	pattern, compile_err := regexp.regexp("hello")
	testing.expect(t, compile_err == regexp.ErrorCode.NoError, "Pattern compilation failed: %v", regexp.error_string(compile_err))
	defer regexp.free_regexp(pattern)
	
	result, match_err := regexp.match(pattern, "hello world")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err))
	testing.expect(t, result.matched, "Pattern should match 'hello' in 'hello world'")
	testing.expect(t, result.full_match.start == 0, "Match should start at position 0")
	testing.expect(t, result.full_match.end == 5, "Match should end at position 5")
}

// Test exact string matching
@(test)
test_exact_string_matching :: proc(t: ^testing.T) {
	pattern, compile_err := regexp.regexp("hello")
	testing.expect(t, compile_err == regexp.ErrorCode.NoError, "Pattern compilation failed: %v", regexp.error_string(compile_err))
	defer regexp.free_regexp(pattern)
	
	// Test exact match
	result, match_err := regexp.match(pattern, "hello")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err))
	testing.expect(t, result.matched, "Pattern should match exact string")
	testing.expect(t, result.full_match.start == 0, "Match should start at position 0")
	testing.expect(t, result.full_match.end == 5, "Match should end at position 5")
}

// Test no match scenarios
@(test)
test_no_match_scenarios :: proc(t: ^testing.T) {
	pattern, compile_err := regexp.regexp("hello")
	testing.expect(t, compile_err == regexp.ErrorCode.NoError, "Pattern compilation failed: %v", regexp.error_string(compile_err))
	defer regexp.free_regexp(pattern)
	
	// Test no match
	result_no_match, match_err1 := regexp.match(pattern, "world")
	testing.expect(t, match_err1 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err1))
	testing.expect(t, !result_no_match.matched, "Pattern should not match 'world'")
	
	// Test empty string
	result_empty, match_err2 := regexp.match(pattern, "")
	testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err2))
	testing.expect(t, !result_empty.matched, "Pattern should not match empty string")
	
	// Test partial match (should still match)
	result_partial, match_err3 := regexp.match(pattern, "shello")
	testing.expect(t, match_err3 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err3))
	testing.expect(t, result_partial.matched, "Pattern should match partial string")
	testing.expect(t, result_partial.full_match.start == 1, "Match should start at position 1")
	testing.expect(t, result_partial.full_match.end == 6, "Match should end at position 6")
}

// Test empty pattern matching
@(test)
test_empty_pattern_matching :: proc(t: ^testing.T) {
	pattern, compile_err := regexp.regexp("")
	testing.expect(t, compile_err == regexp.ErrorCode.NoError, "Empty pattern compilation failed: %v", regexp.error_string(compile_err))
	defer regexp.free_regexp(pattern)
	
	// Empty pattern should match empty string
	result_empty, match_err1 := regexp.match(pattern, "")
	testing.expect(t, match_err1 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err1))
	
	// Empty pattern should match any string (at position 0)
	result_any, match_err2 := regexp.match(pattern, "hello")
	testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Matching failed: %v", regexp.error_string(match_err2))
	testing.expect(t, result_empty.matched, "Empty pattern should match empty string")
	testing.expect(t, result_empty.full_match.start == 0, "Empty match should start at 0")
	testing.expect(t, result_empty.full_match.end == 0, "Empty match should end at 0")
	
	// Empty pattern should match any string (at position 0)
	testing.expect(t, result_any.matched, "Empty pattern should match any string")
	testing.expect(t, result_any.full_match.start == 0, "Empty match should start at 0")
	testing.expect(t, result_any.full_match.end == 0, "Empty match should end at 0")
}

// Test Unicode pattern matching
@(test)
test_unicode_pattern_matching :: proc(t: ^testing.T) {
	pattern, compile_err := regexp.regexp("你好")
	testing.expect(t, compile_err == regexp.ErrorCode.NoError, "Unicode pattern compilation failed: %v", regexp.error_string(compile_err))
	defer regexp.free_regexp(pattern)
	
	// Test Unicode match
	result, match_err := regexp.match(pattern, "你好世界")
	testing.expect(t, match_err == regexp.ErrorCode.NoError, "Unicode matching failed: %v", regexp.error_string(match_err))
	testing.expect(t, result.matched, "Unicode pattern should match")
	
	// Note: Byte positions for UTF-8
	// "你好" is 6 bytes in UTF-8 (3 bytes per Chinese character)
	testing.expect(t, result.full_match.start == 0, "Unicode match should start at byte 0")
	testing.expect(t, result.full_match.end == 6, "Unicode match should end at byte 6")
}

// Test escape sequence handling
@(test)
test_escape_sequence_handling :: proc(t: ^testing.T) {
	// Test backslash escape sequences
	pattern1, compile_err1 := regexp.regexp("hello\\sworld")
	testing.expect(t, compile_err1 == regexp.ErrorCode.NoError, "Pattern with \\s compilation failed: %v", regexp.error_string(compile_err1))
	defer regexp.free_regexp(pattern1)
	
	// For now, treat \\s as literal "\s" (special chars will be implemented in User Story 2)
	result1, match_err1 := regexp.match(pattern1, "hello\\sworld")
	testing.expect(t, match_err1 == regexp.ErrorCode.NoError, "Escape sequence matching failed: %v", regexp.error_string(match_err1))
	testing.expect(t, result1.matched, "Pattern with escape should match literal")
	
	// Test escaped backslash
	pattern2, compile_err2 := regexp.regexp("hello\\\\world")
	testing.expect(t, compile_err2 == regexp.ErrorCode.NoError, "Pattern with \\\\ compilation failed: %v", regexp.error_string(compile_err2))
	defer regexp.free_regexp(pattern2)
	
	result2, match_err2 := regexp.match(pattern2, "hello\\\\world")
	testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Escaped backslash matching failed: %v", regexp.error_string(match_err2))
	testing.expect(t, result2.matched, "Pattern with escaped backslash should match")
	
	// Test escaped special characters
	pattern3, compile_err3 := regexp.regexp("hello\\.world")
	testing.expect(t, compile_err3 == regexp.ErrorCode.NoError, "Pattern with \\. compilation failed: %v", regexp.error_string(compile_err3))
	defer regexp.free_regexp(pattern3)
	
	// For now, treat \. as literal "\." (dot special behavior will be implemented in User Story 2)
	result3, match_err3 := regexp.match(pattern3, "hello\\.world")
	testing.expect(t, match_err3 == regexp.ErrorCode.NoError, "Escaped dot matching failed: %v", regexp.error_string(match_err3))
	testing.expect(t, result3.matched, "Pattern with escaped dot should match literal")
}

// Test convenience function match_string
@(test)
test_match_string_convenience :: proc(t: ^testing.T) {
	// Test successful match
	matched1, err1 := regexp.match_string("hello", "hello world")
	testing.expect(t, err1 == regexp.ErrorCode.NoError, "Convenience matching failed: %v", regexp.error_string(err1))
	
	// Test no match
	matched2, err2 := regexp.match_string("hello", "world")
	testing.expect(t, err2 == regexp.ErrorCode.NoError, "Convenience matching failed: %v", regexp.error_string(err2))
	
	// Test empty pattern
	matched3, err3 := regexp.match_string("", "anything")
	testing.expect(t, err3 == regexp.ErrorCode.NoError, "Empty pattern matching failed: %v", regexp.error_string(err3))
	testing.expect(t, matched3, "Empty pattern should match any string")
}