package main

import "core:testing"
import "core:fmt"
import "regexp"

// Test capture group compilation
@(test)
test_capture_group_compilation :: proc(t: ^testing.T) {
    pattern, err := regexp.regexp("(hello)")
    testing.expect(t, err == regexp.ErrorCode.NoError, "Capture group compilation failed: %v", regexp.error_string(err))
    defer regexp.free_regexp(pattern)
    
    result, match_err := regexp.match(pattern, "hello")
    testing.expect(t, match_err == regexp.ErrorCode.NoError, "Capture group matching failed: %v", regexp.error_string(match_err))
    testing.expect(t, result.matched, "Capture group should match 'hello'")
}

// Test alternation compilation
@(test)
test_alternation_compilation :: proc(t: ^testing.T) {
    pattern, err := regexp.regexp("hello|world")
    testing.expect(t, err == regexp.ErrorCode.NoError, "Alternation compilation failed: %v", regexp.error_string(err))
    defer regexp.free_regexp(pattern)
    
    result, match_err := regexp.match(pattern, "hello")
    testing.expect(t, match_err == regexp.ErrorCode.NoError, "Alternation matching failed: %v", regexp.error_string(match_err))
    testing.expect(t, result.matched, "Alternation should match 'hello'")
    
    result2, match_err2 := regexp.match(pattern, "world")
    testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Alternation matching failed: %v", regexp.error_string(match_err2))
    testing.expect(t, result2.matched, "Alternation should match 'world'")
}

// Test non-capturing group
@(test)
test_non_capturing_group :: proc(t: ^testing.T) {
    pattern, err := regexp.regexp("(?:hello)")
    testing.expect(t, err == regexp.ErrorCode.NoError, "Non-capturing group compilation failed: %v", regexp.error_string(err))
    defer regexp.free_regexp(pattern)
    
    result, match_err := regexp.match(pattern, "hello")
    testing.expect(t, match_err == regexp.ErrorCode.NoError, "Non-capturing group matching failed: %v", regexp.error_string(match_err))
    testing.expect(t, result.matched, "Non-capturing group should match 'hello'")
}

// Test nested groups
@(test)
test_nested_groups :: proc(t: ^testing.T) {
    pattern, err := regexp.regexp("((hello) world)")
    testing.expect(t, err == regexp.ErrorCode.NoError, "Nested groups compilation failed: %v", regexp.error_string(err))
    defer regexp.free_regexp(pattern)
    
    result, match_err := regexp.match(pattern, "hello world")
    testing.expect(t, match_err == regexp.ErrorCode.NoError, "Nested groups matching failed: %v", regexp.error_string(match_err))
    testing.expect(t, result.matched, "Nested groups should match 'hello world'")
}

// Test alternation with groups
@(test)
test_alternation_with_groups :: proc(t: ^testing.T) {
    pattern, err := regexp.regexp("(hello|world) test")
    testing.expect(t, err == regexp.ErrorCode.NoError, "Alternation with groups compilation failed: %v", regexp.error_string(err))
    defer regexp.free_regexp(pattern)
    
    result, match_err := regexp.match(pattern, "hello test")
    testing.expect(t, match_err == regexp.ErrorCode.NoError, "Alternation with groups matching failed: %v", regexp.error_string(match_err))
    testing.expect(t, result.matched, "Alternation with groups should match 'hello test'")
    
    result2, match_err2 := regexp.match(pattern, "world test")
    testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Alternation with groups matching failed: %v", regexp.error_string(match_err2))
    testing.expect(t, result2.matched, "Alternation with groups should match 'world test'")
}

// Test RE2 compliance for groups and alternation
@(test)
test_re2_compliance_groups :: proc(t: ^testing.T) {
    // Test case from RE2 test suite
    pattern, err := regexp.regexp("(a|b)+")
    testing.expect(t, err == regexp.ErrorCode.NoError, "RE2 compliance test compilation failed: %v", regexp.error_string(err))
    defer regexp.free_regexp(pattern)
    
    result, match_err := regexp.match(pattern, "aba")
    testing.expect(t, match_err == regexp.ErrorCode.NoError, "RE2 compliance test matching failed: %v", regexp.error_string(match_err))
    testing.expect(t, result.matched, "RE2 compliance: should match 'aba'")
}

// Test linear time verification for pathological group patterns
@(test)
test_linear_time_groups :: proc(t: ^testing.T) {
    // Test that (a|b)* doesn't cause exponential backtracking
    pattern, err := regexp.regexp("(a|b)*")
    testing.expect(t, err == regexp.ErrorCode.NoError, "Pathological group pattern compilation failed: %v", regexp.error_string(err))
    defer regexp.free_regexp(pattern)
    
    // Create a long string of 'a's and 'b's
    long_string := ""
    for i in 0..<1000 {
        if i % 2 == 0 {
            long_string += "a"
        } else {
            long_string += "b"
        }
    }
    
    result, match_err := regexp.match(pattern, long_string)
    testing.expect(t, match_err == regexp.ErrorCode.NoError, "Linear time test matching failed: %v", regexp.error_string(match_err))
    testing.expect(t, result.matched, "Linear time test should match long string")
}

// Test complex alternation
@(test)
test_complex_alternation :: proc(t: ^testing.T) {
    pattern, err := regexp.regexp("cat|dog|bird")
    testing.expect(t, err == regexp.ErrorCode.NoError, "Complex alternation compilation failed: %v", regexp.error_string(err))
    defer regexp.free_regexp(pattern)
    
    result, match_err := regexp.match(pattern, "cat")
    testing.expect(t, match_err == regexp.ErrorCode.NoError, "Complex alternation matching failed: %v", regexp.error_string(match_err))
    testing.expect(t, result.matched, "Complex alternation should match 'cat'")
    
    result2, match_err2 := regexp.match(pattern, "dog")
    testing.expect(t, match_err2 == regexp.ErrorCode.NoError, "Complex alternation matching failed: %v", regexp.error_string(match_err2))
    testing.expect(t, result2.matched, "Complex alternation should match 'dog'")
    
    result3, match_err3 := regexp.match(pattern, "bird")
    testing.expect(t, match_err3 == regexp.ErrorCode.NoError, "Complex alternation matching failed: %v", regexp.error_string(match_err3))
    testing.expect(t, result3.matched, "Complex alternation should match 'bird'")
    
    result4, match_err4 := regexp.match(pattern, "fish")
    testing.expect(t, match_err4 == regexp.ErrorCode.NoError, "Complex alternation matching failed: %v", regexp.error_string(match_err4))
    testing.expect(t, !result4.matched, "Complex alternation should not match 'fish'")
}