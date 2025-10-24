package main

import "core:testing"
import "core:fmt"
import "../regexp"

// Import test files by including their content
// Note: This is a workaround for Odin's test system

@(test)
test_basic_functionality :: proc(t: ^testing.T) {
	fmt.println("Running basic functionality test...")
	
	// Test basic compilation
	pattern, err := regexp.regexp("hello")
	testing.expect(t, err == .NoError, "Pattern compilation failed")
	defer regexp.free_regexp(pattern)
	
	// Test basic matching
	result, match_err := regexp.match(pattern, "hello world")
	testing.expect(t, match_err == .NoError, "Matching failed")
	testing.expect(t, result.matched, "Pattern should match 'hello' in 'hello world'")
	testing.expect(t, result.full_match.start == 0, "Match should start at position 0")
	testing.expect(t, result.full_match.end == 5, "Match should end at position 5")
	
	fmt.println("Basic functionality test passed!")
}

@(test)
test_convenience_function :: proc(t: ^testing.T) {
	fmt.println("Running convenience function test...")
	
	// Test one-shot matching with simple pattern
	matched, err := regexp.match_string("test", "example test123")
	testing.expect(t, err == .NoError, "Convenience matching failed")
	testing.expect(t, matched, "Should match 'test' in 'example test123'")
	
	fmt.println("Convenience function test passed!")
}