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
	testing.expect(t, err == .NoError, "Expected no error when parsing 'hello', got: %v", err)
	testing.expect(t, pattern != nil, "Pattern should not be nil on successful compilation")
	
	defer regexp.free_regexp(pattern)
	
	// Test empty pattern
	empty_pattern, err := regexp.regexp("")
	testing.expect(t, err == .NoError, "Expected no error when parsing empty pattern, got: %v", err)
	testing.expect(t, empty_pattern != nil, "Empty pattern should not be nil")
	
	defer regexp.free_regexp(empty_pattern)
	
	// Test single character
	single_pattern, err := regexp.regexp("a")
	testing.expect(t, err == .NoError, "Expected no error when parsing 'a', got: %v", err)
	testing.expect(t, single_pattern != nil, "Single character pattern should not be nil")
	
	defer regexp.free_regexp(single_pattern)
}

// Test invalid patterns that should fail compilation
@(test)
test_invalid_pattern_compilation :: proc(t: ^testing.T) {
	// Test unmatched parenthesis (should fail)
	pattern, err := regexp.regexp("(unclosed")
	testing.expect(t, err != .NoError, "Expected error when parsing unclosed parenthesis")
	testing.expect(t, pattern == nil, "Pattern should be nil on compilation error")
	
	// Test invalid escape sequence (should fail)
	pattern, err = regexp.regexp("\\x")
	testing.expect(t, err != .NoError, "Expected error when parsing invalid escape")
	testing.expect(t, pattern == nil, "Pattern should be nil on compilation error")
}

// Test pattern compilation with special characters as literals
@(test)
test_special_character_literals :: proc(t: ^testing.T) {
	// Test pattern with dots as literal characters (not regex operators)
	pattern, err := regexp.regexp("a.b")
	testing.expect(t, err == .NoError, "Expected no error when parsing 'a.b', got: %v", err)
	defer regexp.free_regexp(pattern)
	
	// Test pattern with stars as literal characters
	pattern, err = regexp.regexp("a*b")
	testing.expect(t, err == .NoError, "Expected no error when parsing 'a*b', got: %v", err)
	defer regexp.free_regexp(pattern)
	
	// Test pattern with question marks as literal characters
	pattern, err = regexp.regexp("a?b")
	testing.expect(t, err == .NoError, "Expected no error when parsing 'a?b', got: %v", err)
	defer regexp.free_regexp(pattern)
}

// Test Unicode literal patterns
@(test)
test_unicode_literal_patterns :: proc(t: ^testing.T) {
	// Test simple Unicode characters
	pattern, err := regexp.regexp("你好")
	testing.expect(t, err == .NoError, "Expected no error when parsing Unicode pattern, got: %v", err)
	testing.expect(t, pattern != nil, "Unicode pattern should not be nil")
	defer regexp.free_regexp(pattern)
	
	// Test mixed ASCII and Unicode
	pattern, err = regexp.regexp("hello世界")
	testing.expect(t, err == .NoError, "Expected no error when parsing mixed pattern, got: %v", err)
	defer regexp.free_regexp(pattern)
}