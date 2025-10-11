package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("Testing NFA implementation...")
	
	// Test simple literal matching
	pattern, err := regexp.regexp("hello")
	if err != .NoError {
		fmt.println("Failed to compile pattern:", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	result, match_err := regexp.match(pattern, "hello world")
	if match_err != .NoError {
		fmt.println("Failed to match:", match_err)
		return
	}
	
	if result.matched {
		fmt.println("Match found!")
		fmt.println("Full match:", result.full_match)
	} else {
		fmt.println("No match found")
	}
	
	// Test NFA compilation directly
	ast := pattern.ast
	if ast != nil {
		prog, compile_err := regexp.compile_nfa(ast)
		if compile_err != .NoError {
			fmt.println("Failed to compile NFA:", compile_err)
		} else {
			fmt.println("NFA compiled successfully!")
			fmt.println("Instructions:", len(prog.inst))
			fmt.println("Start PC:", prog.start)
			fmt.println("Capture groups:", prog.num_cap)
			regexp.free_prog(prog)
		}
	}
}