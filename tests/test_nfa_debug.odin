package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("Testing NFA implementation with debug...")
	
	// Test simple literal matching
	pattern, err := regexp.regexp("hello")
	if err != .NoError {
		fmt.println("Failed to compile pattern:", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	// Test the old matcher first
	result, match_err := regexp.match(pattern, "hello world")
	if match_err != .NoError {
		fmt.println("Failed to match:", match_err)
		return
	}
	
	fmt.println("Old matcher result:")
	if result.matched {
		fmt.println("  Match found!")
		fmt.println("  Full match:", result.full_match)
	} else {
		fmt.println("  No match found")
	}
	
	// Test NFA directly
	ast := pattern.ast
	if ast != nil {
		prog, compile_err := regexp.compile_nfa(ast)
		if compile_err != .NoError {
			fmt.println("Failed to compile NFA:", compile_err)
			return
		}
		defer regexp.free_prog(prog)
		
		fmt.println("\nNFA compiled successfully!")
		fmt.println("Instructions:", len(prog.inst))
		fmt.println("Start PC:", prog.start)
		fmt.println("Capture groups:", prog.num_cap)
		
		// Print instructions
		fmt.println("\nInstructions:")
		for i in 0..<len(prog.inst) {
			inst := prog.inst[i]
			fmt.printf("  %d: %v, out=%d, arg=%d\n", i, inst.op, inst.out, inst.arg)
		}
		
		// Test NFA matcher
		matcher := regexp.new_matcher(prog, false, true)
		defer regexp.free_matcher(matcher)
		
		matched, caps := regexp.match_nfa(matcher, "hello world")
		fmt.println("\nNFA matcher result:")
		fmt.println("  Matched:", matched)
		if matched && len(caps) >= 2 {
			fmt.println("  Capture positions:", caps)
			fmt.println("  Full match: [", caps[0], ",", caps[1], "]")
		}
	}
}