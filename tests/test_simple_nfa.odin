package main

import "core:fmt"
import "regexp"

// Simple NFA test without using the complex matcher
test_simple_nfa :: proc() {
	fmt.println("Testing simple NFA execution...")
	
	// Create a simple program manually
	prog := regexp.new_prog(10)
	defer regexp.free_prog(prog)
	
	// Add instruction to match 'a'
	rune_pc := regexp.add_inst(prog, .Rune1, 0, u32('a'))
	match_pc := regexp.add_inst(prog, .Match, 0, 0)
	
	// Link rune to match
	prog.inst[rune_pc].out = match_pc
	prog.start = rune_pc
	
	fmt.println("Program:")
	for i in 0..<len(prog.inst) {
		inst := prog.inst[i]
		fmt.printf("  %d: %v, out=%d, arg=%d\n", i, inst.op, inst.out, inst.arg)
	}
	
	// Simple execution
	text := "a"
	fmt.println("\nExecuting on text:", text)
	
	pos := 0
	pc := prog.start
	
	// Execute rune instruction
	if pc < u32(len(prog.inst)) {
		inst := prog.inst[pc]
		fmt.printf("Executing instruction %d: %v\n", pc, inst.op)
		
		if inst.op == .Rune1 && pos < len(text) && rune(text[pos]) == rune(inst.arg) {
			fmt.println("Rune matched!")
			pos += 1
			pc = inst.out
			
			// Execute match instruction
			if pc < u32(len(prog.inst)) {
				inst = prog.inst[pc]
				fmt.printf("Executing instruction %d: %v\n", pc, inst.op)
				
				if inst.op == .Match {
					fmt.println("Match found!")
					fmt.println("Position:", pos)
					return
				}
			}
		} else {
			fmt.println("Rune did not match")
		}
	}
	
	fmt.println("No match found")
}

main :: proc() {
	test_simple_nfa()
}