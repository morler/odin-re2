package main

import "core:fmt"
import "../regexp"

main :: proc() {
	fmt.println("=== Testing Alternation Operator ===")
	
	tests := []struct {
		pattern: string,
		text:    string,
		expect:  bool,
	}{
		{"a|b", "a", true},
		{"a|b", "b", true},
		{"a|b", "c", false},
		{"hello|world", "hello", true},
		{"hello|world", "world", true},
		{"hello|world", "test", false},
		{"cat|dog|bird", "cat", true},
		{"cat|dog|bird", "dog", true},
		{"cat|dog|bird", "bird", true},
		{"cat|dog|bird", "fish", false},
	}
	
	passed := 0
	total := len(tests)
	
	for test in tests {
		pattern, err := regexp.regexp(test.pattern)
		if err != .NoError {
			fmt.printf("❌ Failed to compile pattern '%s': %v\n", test.pattern, err)
			continue
		}
		defer regexp.free_regexp(pattern)
		
		result, _ := regexp.match(pattern, test.text)
		
		if result.matched == test.expect {
			fmt.printf("✅ '%s' on '%s' -> %v\n", test.pattern, test.text, result.matched)
			passed += 1
		} else {
			fmt.printf("❌ '%s' on '%s' -> expected %v, got %v\n", 
				test.pattern, test.text, test.expect, result.matched)
		}
	}
	
	fmt.printf("\n=== Results: %d/%d tests passed ===\n", passed, total)
	
	if passed == total {
		fmt.println("🎉 All alternation tests passed!")
	}
}