package tests

import "core:testing"
import "core:fmt"
import "../regexp"

// Test basic literal pattern compilation
// This test should FAIL initially, then pass after parser implementation
@(test)
test_literal_pattern_compilation :: proc(t: ^testing.T) {
	// Test simple literal pattern
	pattern, err := regexp.regexp("hello")
	testing.expect(t, err == .NoError, "Expected no error when parsing 'hello', got: %v", regexp.error_string(err))
	testing.expect(t, pattern != nil, "Pattern should not be nil on successful compilation")
	
	defer regexp.free_regexp(pattern)
	
	// Test empty pattern
	empty_pattern, err2 := regexp.regexp("")
	testing.expect(t, err2 == .NoError, "Expected no error when parsing empty pattern, got: %v", regexp.error_string(err2))
	testing.expect(t, empty_pattern != nil, "Empty pattern should not be nil")
	
	defer regexp.free_regexp(empty_pattern)
	
	// Test single character
	single_pattern, err3 := regexp.regexp("a")
	testing.expect(t, err3 == .NoError, "Expected no error when parsing 'a', got: %v", regexp.error_string(err3))
	testing.expect(t, single_pattern != nil, "Single character pattern should not be nil")
	
	defer regexp.free_regexp(single_pattern)
}

// Test patterns that are treated as literals in User Story 1
@(test)
test_invalid_pattern_compilation :: proc(t: ^testing.T) {
	// For User Story 1, all patterns are treated as literals
	// These will be implemented as error cases in future user stories
	
	// Test unmatched parenthesis (treated as literal for now)
	pattern1, err1 := regexp.regexp("(unclosed")
	testing.expect(t, err1 == .NoError, "Pattern compilation should succeed in User Story 1")
	testing.expect(t, pattern1 != nil, "Pattern should not be nil in User Story 1")
	defer regexp.free_regexp(pattern1)
	
	// Test that it matches as literal
	result1, match_err1 := regexp.match(pattern1, "(unclosed")
	testing.expect(t, match_err1 == .NoError, "Literal matching should succeed")
	testing.expect(t, result1.matched, "Should match as literal")
	
	// Test invalid escape sequence (treated as literal for now)
	pattern2, err2 := regexp.regexp("\\x")
	testing.expect(t, err2 == .NoError, "Pattern compilation should succeed in User Story 1")
	testing.expect(t, pattern2 != nil, "Pattern should not be nil in User Story 1")
	defer regexp.free_regexp(pattern2)
	
	// Test that it matches as literal
	result2, match_err2 := regexp.match(pattern2, "\\x")
	testing.expect(t, match_err2 == .NoError, "Literal matching should succeed")
	testing.expect(t, result2.matched, "Should match as literal")
}

// Test pattern compilation with special characters as literals
@(test)
test_special_character_literals :: proc(t: ^testing.T) {
	// Test pattern with dots as literal characters (not regex operators)
	pattern1, err1 := regexp.regexp("a.b")
	testing.expect(t, err1 == .NoError, "Expected no error when parsing 'a.b', got: %v", regexp.error_string(err1))
	defer regexp.free_regexp(pattern1)
	
	// Test pattern with stars as literal characters
	pattern2, err2 := regexp.regexp("a*b")
	testing.expect(t, err2 == .NoError, "Expected no error when parsing 'a*b', got: %v", regexp.error_string(err2))
	defer regexp.free_regexp(pattern2)
	
	// Test pattern with question marks as literal characters
	pattern3, err3 := regexp.regexp("a?b")
	testing.expect(t, err3 == .NoError, "Expected no error when parsing 'a?b', got: %v", regexp.error_string(err3))
	defer regexp.free_regexp(pattern3)
}

// Test Unicode literal patterns
@(test)
test_unicode_literal_patterns :: proc(t: ^testing.T) {
	// Test simple Unicode characters
	pattern1, err1 := regexp.regexp("你好")
	testing.expect(t, err1 == .NoError, "Expected no error when parsing Unicode pattern, got: %v", regexp.error_string(err1))
	testing.expect(t, pattern1 != nil, "Unicode pattern should not be nil")
	defer regexp.free_regexp(pattern1)
	
	// Test mixed ASCII and Unicode
	pattern2, err2 := regexp.regexp("hello世界")
	testing.expect(t, err2 == .NoError, "Expected no error when parsing mixed pattern, got: %v", regexp.error_string(err2))
	defer regexp.free_regexp(pattern2)
}