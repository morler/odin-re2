/**
 * Feature: spec/features/pattern-compilation.feature
 *
 * This test file validates the acceptance criteria defined in the feature file.
 * Scenarios in this test map directly to scenarios in the Gherkin feature.
 */

package main

import "core:fmt"
import "core:testing"
import "../src/regexp"

// Test data for pattern compilation scenarios
test_compile_simple_literal :: proc() {
	// Given I have a simple literal pattern string 'hello'
	pattern := "hello"
	
	// When I call parse_regexp_internal with the pattern and no flags
	ast, err := regexp.parse_regexp_internal(pattern, {})
	
	// Then I should receive a valid AST node with no error
	if err != .NoError {
		fmt.printf("FAIL: Expected no error for simple literal pattern, got %v\n", err)
		return
	}
	if ast == nil {
		fmt.printf("FAIL: Expected valid AST node for simple literal pattern, got nil\n")
		return
	}
	fmt.printf("PASS: Simple literal pattern compiled successfully\n")
}

test_compile_empty_pattern :: proc() {
	// Given I have an empty pattern string
	pattern := ""
	
	// When I call parse_regexp_internal with the empty pattern
	ast, err := regexp.parse_regexp_internal(pattern, {})
	
	// Then I should receive an empty literal AST node with no error
	if err != .NoError {
		fmt.printf("FAIL: Expected no error for empty pattern, got %v\n", err)
		return
	}
	if ast == nil {
		fmt.printf("FAIL: Expected valid AST node for empty pattern, got nil\n")
		return
	}
	fmt.printf("PASS: Empty pattern compiled successfully\n")
}

test_compile_pattern_with_escape_sequences :: proc() {
	// Given I have a pattern string 'hello\\sworld' with escape sequences
	pattern := "hello\\sworld"
	
	// When I call parse_regexp_internal with the pattern containing escape sequences
	ast, err := regexp.parse_regexp_internal(pattern, {})
	
	// Then I should receive a valid AST node with properly parsed escape sequences
	if err != .NoError {
		fmt.printf("FAIL: Expected no error for pattern with escape sequences, got %v\n", err)
		return
	}
	if ast == nil {
		fmt.printf("FAIL: Expected valid AST node for pattern with escape sequences, got nil\n")
		return
	}
	fmt.printf("PASS: Pattern with escape sequences compiled successfully\n")
}

test_handle_invalid_pattern_syntax :: proc() {
	// Given I have an invalid pattern string with trailing backslash
	pattern := "hello\\"
	
	// When I call parse_regexp_internal with the invalid pattern
	ast, err := regexp.parse_regexp_internal(pattern, {})
	
	// Then I should receive a ParseError and nil AST node
	if err != .ParseError {
		fmt.printf("FAIL: Expected ParseError for invalid pattern, got %v\n", err)
		return
	}
	if ast != nil {
		fmt.printf("FAIL: Expected nil AST node for invalid pattern, got non-nil\n")
		return
	}
	fmt.printf("PASS: Invalid pattern correctly rejected\n")
}

main :: proc() {
	fmt.println("Running pattern compilation tests...")
	
	// Run individual tests
	test_compile_simple_literal()
	test_compile_empty_pattern()
	test_compile_pattern_with_escape_sequences()
	test_handle_invalid_pattern_syntax()
	
	fmt.println("All pattern compilation tests completed!")
}