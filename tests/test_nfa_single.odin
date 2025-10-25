package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("Testing single character NFA...")
	
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
		
		fmt.println("Instructions:", len(prog.inst))
		fmt.println("Start PC:", prog.start)
		
		// Print instructions
		for i in 0..<len(prog.inst) {
			inst := prog.inst[i]
			fmt.printf("  %d: %v, out=%d, arg=%d\n", i, inst.op, inst.out, inst.arg)
		}
		
		// Test NFA matcher
		matcher := regexp.new_matcher(prog, false, true)
		defer regexp.free_matcher(matcher)
		
		matched, caps := regexp.match_nfa(matcher, "a")
		fmt.println("\nNFA matcher result:")
		fmt.println("  Matched:", matched)
		if matched && len(caps) >= 2 {
			fmt.println("  Full match: [", caps[0], ",", caps[1], "]")
		}
	}
}