package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("Testing NFA with detailed debug...")
	
	// Test single character
	pattern, err := regexp.regexp("a")
	if err != .NoError {
		fmt.println("Failed to compile pattern:", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	ast := pattern.ast
	if ast != nil {
		prog, compile_err := regexp.compile_nfa(ast)
		if compile_err != .NoError {
			fmt.println("Failed to compile NFA:", compile_err)
			return
		}
		defer regexp.free_prog(prog)
		
		fmt.println("Testing with text: 'a'")
		
		// Test NFA matcher
		matcher := regexp.new_matcher(prog, false, true)
		defer regexp.free_matcher(matcher)
		
		fmt.println("Matcher created:")
		fmt.println("  Program length:", len(matcher.prog.inst))
		fmt.println("  Start PC:", matcher.prog.start)
		fmt.println("  Anchored:", matcher.anchored)
		fmt.println("  Longest:", matcher.longest)
		
		matched, caps := regexp.match_nfa(matcher, "a")
		fmt.println("\nFinal result:")
		fmt.println("  Matched:", matched)
		if matched && len(caps) >= 2 {
			fmt.println("  Captures:", caps)
			fmt.println("  Full match: [", caps[0], ",", caps[1], "]")
		} else {
			fmt.println("  No captures or match failed")
		}
	}
}