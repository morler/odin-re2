package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Direct NFA Test ===")
	
	// Create arena and program directly
	arena := regexp.new_arena(1024)
	defer regexp.free_arena(arena)
	
	prog := regexp.new_program(arena, 10)
	
	// Manually create a simple program: match 'a' then match
	char_idx := regexp.add_instruction(prog, .Char, u32('a'))
	match_idx := regexp.add_instruction(prog, .Match, 0)
	
	fmt.printf("Created program with %d instructions\n", len(prog.instructions))
	fmt.printf("Instruction 0: %v (arg=%v)\n", regexp.inst_opcode(prog.instructions[0]), regexp.inst_arg(prog.instructions[0]))
	fmt.printf("Instruction 1: %v (arg=%v)\n", regexp.inst_opcode(prog.instructions[1]), regexp.inst_arg(prog.instructions[1]))
	
	// Test matching
	result, caps := regexp.simple_nfa_match(prog, "a")
	fmt.printf("Match result: %v\n", result)
	if result && len(caps) >= 2 {
		fmt.printf("Capture range: %d-%d\n", caps[0], caps[1])
	}
	
	fmt.println("Direct NFA test completed!")
}