package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Manual NFA Test for ab*c ===")
	
	// Create a simple NFA program for "ab*c"
	// This should be:
	// 0: Rune1('a') -> 1
	// 1: Alt -> 2 (skip b) or 3 (match b)
	// 2: Jmp -> 4 (after b*)
	// 3: Rune1('b') -> 1 (back to alt for more b's)
	// 4: Rune1('c') -> 5
	// 5: Match
	
	prog := regexp.new_prog(10)
	
	// Add instructions manually
	regexp.add_inst(prog, .Rune1, 1, u32('a'))        // 0: match 'a', go to 1
	split_pc := regexp.add_inst(prog, .Alt, 0, 0)     // 1: split for b*
	regexp.add_inst(prog, .Jmp, 4, 0)                 // 2: skip b*, go to 4
	regexp.add_inst(prog, .Rune1, 1, u32('b'))        // 3: match 'b', go back to 1
	regexp.add_inst(prog, .Rune1, 5, u32('c'))        // 4: match 'c', go to 5
	regexp.add_inst(prog, .Match, 0, 0)               // 5: final match
	
	// Fix up the Alt instruction
	prog.inst[split_pc].out = 3  // first branch: match b
	prog.inst[split_pc].arg = 2  // second branch: skip b
	
	prog.start = 0
	
	// Test the manual program
	texts := []string{"ac", "abc", "abbc", "abbbc", "ab", "a"}
	
	for i := 0; i < len(texts); i += 1 {
		text := texts[i]
		fmt.printf("Testing '%s': ", text)
		
		// Use the simple NFA matcher
		matched, caps := regexp.simple_nfa_match(prog, text)
		if matched {
			match_text := text[caps[0]:caps[1]]
			fmt.printf("MATCH '%v' at [%d:%d]\n", match_text, caps[0], caps[1])
		} else {
			fmt.printf("NO MATCH\n")
		}
	}
	
	regexp.free_prog(prog)
}