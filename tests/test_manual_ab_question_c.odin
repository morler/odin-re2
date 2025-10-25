package main

import "core:fmt"
import "regexp"

main :: proc() {
	fmt.println("=== Manual NFA Test for ab?c ===")
	
	// Create a manual NFA for "ab?c"
	// Structure should be:
	// 0: Rune1('a') -> 1
	// 1: Alt -> 2 (match b) or 5 (skip b)
	// 2: Rune1('b') -> 3
	// 3: Jmp -> 5 (continue after b?)
	// 4: (unused, skip branch goes directly to 5)
	// 5: Rune1('c') -> 6
	// 6: Match
	
	prog := regexp.new_prog(10)
	
	// Add instructions
	regexp.add_inst(prog, .Rune1, 1, u32('a'))        // 0: match 'a'
	split_pc := regexp.add_inst(prog, .Alt, 0, 0)     // 1: split for b?
	regexp.add_inst(prog, .Rune1, 3, u32('b'))        // 2: match 'b'
	regexp.add_inst(prog, .Jmp, 5, 0)                 // 3: jump to after b?
	regexp.add_inst(prog, .Rune1, 6, u32('c'))        // 4: match 'c' (this will be 5 after linking)
	regexp.add_inst(prog, .Match, 0, 0)               // 5: final match
	
	// Fix up the Alt instruction
	prog.inst[split_pc].out = 2  // first branch: match b
	prog.inst[split_pc].arg = 4  // second branch: skip b, go to c
	
	prog.start = 0
	
	// Test
	texts := []string{"ac", "abc", "abbc"}
	
	for i := 0; i < len(texts); i += 1 {
		text := texts[i]
		fmt.printf("Testing '%s': ", text)
		
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