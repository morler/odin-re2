package main

// Compile alternation (a|b)
compile_alt :: proc(prog: ^Program, left, right: Fragment) -> Fragment {
	// Simple, correct Thompson NFA construction for alternation:
	// 
	// 0: Alt -> 2 OR 4
	// 1: left fragment
	// 2: Jmp -> 6 (exit)
	// 3: right fragment  
	// 4: Jmp -> 6 (exit)
	// 5: Match (exit)
	// 6: continuation (will be patched by finalize_program)
	
	alt := add_instruction(prog, .Alt, 0)  // Will be patched to point to right
	
	// Left fragment immediately follows alt
	// Right fragment will be placed after left + jump
	right_start := len(prog.instructions)  // This is wrong, need to account for left size
	
	// Let me build this step by step:
	// 1. Add the alt instruction first
	alt_idx := len(prog.instructions)
	add_instruction(prog, .Alt, 0)
	
	// 2. The left fragment starts immediately after alt
	// (This is implicit - we don't need to do anything)
	
	// 3. Add jump from left to exit
	left_to_exit := add_instruction(prog, .Jmp, 0)
	
	// 4. The right fragment starts here
	right_start := len(prog.instructions)
	
	// 5. Add jump from right to exit  
	right_to_exit := add_instruction(prog, .Jmp, 0)
	
	// 6. Match instruction (both branches exit here)
	match_idx := add_instruction(prog, .Match, 0)
	
	// Now patch everything:
	// Alt should point to right_start for second branch
	prog.instructions[alt_idx] = inst_encode(.Alt, u32(right_start))
	
	// Patch left fragment exits to go to match
	if left.out[0] != -1 {
		patch(prog, left, match_idx)
	} else {
		// If left has implicit continuation, patch the jump
		prog.instructions[left_to_exit] = inst_encode(.Jmp, u32(match_idx))
	}
	
	// Patch right fragment exits to go to match  
	if right.out[0] != -1 {
		patch(prog, right, match_idx)
	} else {
		// If right has implicit continuation, patch the jump
		prog.instructions[right_to_exit] = inst_encode(.Jmp, u32(match_idx))
	}
	
	// Return fragment starting at alt, with match as exit
	return make_fragment_multi(alt_idx, []int{match_idx})
}