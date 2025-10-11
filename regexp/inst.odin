package regexp



// RE2-compatible instruction set for NFA execution
// Based on Russ Cox's RE2 implementation

// Instruction opcodes matching RE2's Prog format
Inst_Op :: enum u8 {
	Alt,           // Alternate: two possible paths
	AltMatch,      // Alternate with match: alt or succeed
	Capture,       // Capture group: start/end capture
	EmptyWidth,    // Empty width assertion: ^, $, \b, etc.
	Fail,          // Always fail
	Jmp,           // Unconditional jump
	Match,         // Literal match
	Rune,          // Rune match (character class)
	Rune1,         // Single rune match
	RuneAny,       // Any character match
	RuneAnyNotNL,  // Any character except newline
	// Additional instructions for RE2 compatibility
}

// Instruction structure for NFA execution
Inst :: struct {
	op: Inst_Op,
	out: u32,        // Primary output instruction index
	arg: u32,        // Secondary argument (depends on op)
}

// Empty width flags for assertions
EmptyOp :: enum u8 {
	BeginText        = 1 << 0, // \A
	EndText          = 1 << 1, // \z
	BeginLine        = 1 << 2, // ^
	EndLine          = 1 << 3, // $
	WordBoundary     = 1 << 4, // \b
	NoWordBoundary   = 1 << 5, // \B
	AllEmptyWidth    = BeginText | EndText | BeginLine | EndLine | WordBoundary | NoWordBoundary,
}

// Capture instruction data
Capture_Inst :: struct {
	index: int,      // Capture group index
	is_start: bool,  // true for start, false for end
}

// Rune match instruction data
Rune_Inst :: struct {
	ranges: []Rune_Range,
	lo:    rune,
	hi:    rune,
	foldcase: bool,  // Case-insensitive matching
}

// Character range for rune matching
Rune_Range :: struct {
	lo: rune,
	hi: rune,
}

// Program structure containing all instructions
Prog :: struct {
	inst:    [dynamic]Inst,
	start:   u32,       // Start instruction index
	num_cap: u32,       // Number of capture groups
}

// Create a new program with specified capacity
new_prog :: proc(capacity: int) -> ^Prog {
	prog := new(Prog)
	prog.inst = make([dynamic]Inst, 0, capacity)
	prog.start = 0
	prog.num_cap = 0
	return prog
}

// Free program memory
free_prog :: proc(prog: ^Prog) {
	if prog != nil {
		delete(prog.inst)
		free(prog)
	}
}

// Add an instruction to the program
add_inst :: proc(prog: ^Prog, op: Inst_Op, out: u32, arg: u32) -> u32 {
	index := u32(len(prog.inst))
	append(&prog.inst, Inst{op, out, arg})
	return index
}

// Get string representation of instruction opcode
inst_op_string :: proc(op: Inst_Op) -> string {
	switch op {
	case .Alt:
		return "Alt"
	case .AltMatch:
		return "AltMatch"
	case .Capture:
		return "Capture"
	case .EmptyWidth:
		return "EmptyWidth"
	case .Fail:
		return "Fail"
	case .Jmp:
		return "Jmp"
	case .Match:
		return "Match"
	case .Rune:
		return "Rune"
	case .Rune1:
		return "Rune1"
	case .RuneAny:
		return "RuneAny"
	case .RuneAnyNotNL:
		return "RuneAnyNotNL"
	}
	return "Unknown"
}

// Check if empty width operation matches at position
match_empty_width :: proc(op: EmptyOp, text: string, pos: int) -> bool {
	if op == .BeginText {
		if pos != 0 {
			return false
		}
	}
	
	if op == .EndText {
		if pos != len(text) {
			return false
		}
	}
	
	if op == .BeginLine {
		if pos != 0 && text[pos-1] != '\n' {
			return false
		}
	}
	
	if op == .EndLine {
		if pos != len(text) && text[pos] != '\n' {
			return false
		}
	}
	
	if op == .WordBoundary || op == .NoWordBoundary {
		is_word_char_before := pos > 0 && is_word_char(rune(text[pos-1]))
		is_word_char_after := pos < len(text) && is_word_char(rune(text[pos]))
		
		is_boundary := is_word_char_before != is_word_char_after
		
		if op == .WordBoundary {
			return is_boundary
		} else {
			return !is_boundary
		}
	}
	
	return true
}

// Check if rune is a word character (for word boundaries)
is_word_char :: proc(r: rune) -> bool {
	return ('a' <= r && r <= 'z') || ('A' <= r && r <= 'Z') || ('0' <= r && r <= '9') || r == '_'
}

// ===========================================================================
// NFA COMPILER - AST to NFA conversion
// =========================================================================

// Compile AST to NFA program using Thompson's construction
compile_nfa :: proc(ast: ^Regexp) -> (^Prog, ErrorCode) {
	if ast == nil {
		return nil, .InternalError
	}
	
	prog := new_prog(128)
	
	// Count capture groups first
	prog.num_cap = u32(count_captures(ast) + 1) // +1 for group 0
	
	// Compile AST starting from root
	start_pc, err := compile_regexp(prog, ast)
	if err != .NoError {
		free_prog(prog)
		return nil, err
	}
	
	prog.start = start_pc
	
	return prog, .NoError
}

// Compile a regex node to NFA
compile_regexp :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast == nil || prog == nil {
		return 0, .InternalError
	}
	
	#partial switch ast.op {
	case .NoOp:
		// Empty pattern - just return a match instruction
		match_pc := add_inst(prog, .Match, 0, 0)
		return match_pc, .NoError
		
	case .OpLiteral:
		return compile_literal(prog, ast)
		
	case .OpCharClass:
		return compile_char_class(prog, ast)
		
	case .OpAnyChar:
		return compile_any_char(prog, false)
		
	case .OpAnyCharNotNL:
		return compile_any_char(prog, true)
		
	case .OpBeginLine:
		return compile_empty_width(prog, .BeginLine)
		
	case .OpEndLine:
		return compile_empty_width(prog, .EndLine)
		
	case .OpBeginText:
		return compile_empty_width(prog, .BeginText)
		
	case .OpEndText:
		return compile_empty_width(prog, .EndText)
		
	case .OpWordBoundary:
		return compile_empty_width(prog, .WordBoundary)
		
	case .OpNoWordBoundary:
		return compile_empty_width(prog, .NoWordBoundary)
		
	case .OpCapture:
		return compile_capture(prog, ast)
		
	case .OpStar:
		return compile_star(prog, ast)
		
	case .OpPlus:
		return compile_plus(prog, ast)
		
	case .OpQuest:
		return compile_quest(prog, ast)
		
	case .OpRepeat:
		return compile_repeat(prog, ast)
		
	case .OpConcat:
		return compile_concat(prog, ast)
		
	case .OpAlternate:
		return compile_alternate(prog, ast)
	}
	
	return 0, .InternalError
}

// Compile literal string
compile_literal :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast.data == nil {
		return 0, .InternalError
	}
	
	lit_data := (^Literal_Data)(ast.data)
	str := to_string(lit_data.str)
	
 	if len(str) == 0 {
 		// Empty literal - just match
 		match_pc := add_inst(prog, .Match, 0, 0)
 		return match_pc, .NoError
 	}
	
	// Add rune instructions for each character
	first_pc := u32(0)
	prev_pc := u32(0)
	
	for i := 0; i < len(str); i += 1 {
		r := rune(str[i])
		rune_pc := add_inst(prog, .Rune1, 0, u32(r))
		
		if i == 0 {
			first_pc = rune_pc
		} else {
			// Link previous instruction to this one
			prog.inst[prev_pc].out = rune_pc
		}
		
		prev_pc = rune_pc
	}
	
	// Add final match instruction
	match_pc := add_inst(prog, .Match, 0, 0)
	prog.inst[prev_pc].out = match_pc
	
	return first_pc, .NoError
}

// Compile character class
compile_char_class :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast.data == nil {
		return 0, .InternalError
	}
	
	cc_data := (^CharClass_Data)(ast.data)
	
	// For now, handle simple single-range character classes
	// In a full implementation, we'd need to handle multiple ranges
	if len(cc_data.ranges) == 0 {
		return 0, .InternalError
	}
	
	// If only one range and lo == hi, use simple Rune1
	if len(cc_data.ranges) == 1 && cc_data.ranges[0].lo == cc_data.ranges[0].hi {
		rune_pc := add_inst(prog, .Rune1, 0, u32(cc_data.ranges[0].lo))
		match_pc := add_inst(prog, .Match, 0, 0)
		prog.inst[rune_pc].out = match_pc
		return rune_pc, .NoError
	}
	
	// For multiple characters (like [ab]), create alternation
	// This is simplified - just handle individual characters for now
	if len(cc_data.ranges) == 2 && 
	   cc_data.ranges[0].lo == cc_data.ranges[0].hi && 
	   cc_data.ranges[1].lo == cc_data.ranges[1].hi {
		
		// Create Alt instruction
		alt_pc := add_inst(prog, .Alt, 0, 0)
		
		// First alternative
		rune1_pc := add_inst(prog, .Rune1, 0, u32(cc_data.ranges[0].lo))
		match1_pc := add_inst(prog, .Match, 0, 0)
		prog.inst[rune1_pc].out = match1_pc
		
		// Second alternative  
		rune2_pc := add_inst(prog, .Rune1, 0, u32(cc_data.ranges[1].lo))
		match2_pc := add_inst(prog, .Match, 0, 0)
		prog.inst[rune2_pc].out = match2_pc
		
		// Link Alt to both alternatives
		prog.inst[alt_pc].out = rune1_pc
		prog.inst[alt_pc].arg = rune2_pc
		
		return alt_pc, .NoError
	}
	
	// Default: use first range (simplified)
	range := cc_data.ranges[0]
	rune_pc := add_inst(prog, .Rune1, 0, u32(range.lo))
	match_pc := add_inst(prog, .Match, 0, 0)
	prog.inst[rune_pc].out = match_pc
	
	return rune_pc, .NoError
}

// Compile any character
compile_any_char :: proc(prog: ^Prog, except_newline: bool) -> (u32, ErrorCode) {
	op: Inst_Op
	if except_newline {
		op = .RuneAnyNotNL
	} else {
		op = .RuneAny
	}
	
	any_pc := add_inst(prog, op, 0, 0)
	
	// Add match instruction
	match_pc := add_inst(prog, .Match, 0, 0)
	prog.inst[any_pc].out = match_pc
	
	return any_pc, .NoError
}

// Compile empty-width assertion
compile_empty_width :: proc(prog: ^Prog, empty_op: EmptyOp) -> (u32, ErrorCode) {
	empty_pc := add_inst(prog, .EmptyWidth, 0, u32(empty_op))
	
	// Add match instruction
	match_pc := add_inst(prog, .Match, 0, 0)
	prog.inst[empty_pc].out = match_pc
	
	return empty_pc, .NoError
}

// Compile capture group
compile_capture :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast.data == nil {
		return 0, .InternalError
	}
	
	cap_data := (^Capture_Data)(ast.data)
	
	// Entry capture instruction
	entry_pc := add_inst(prog, .Capture, 0, u32(cap_data.cap * 2))
	
	// Compile sub-expression
	sub_pc, err := compile_regexp(prog, cap_data.sub)
	if err != .NoError {
		return 0, err
	}
	
	// Link entry to sub
	prog.inst[entry_pc].out = sub_pc
	
	// Exit capture instruction
	exit_pc := add_inst(prog, .Capture, 0, u32(cap_data.cap * 2 + 1))
	
	// Find the last instruction and link it to exit
	// This is simplified - in practice we'd need to walk the sub-program
	// For now, assume sub ends with a Match instruction
	if len(prog.inst) > 0 {
		last_inst := len(prog.inst) - 1
		if prog.inst[last_inst].op == .Match {
			prog.inst[last_inst].out = exit_pc
		}
	}
	
	// Add final match instruction
	match_pc := add_inst(prog, .Match, 0, 0)
	prog.inst[exit_pc].out = match_pc
	
	return entry_pc, .NoError
}

// Find the last instruction in a program fragment starting from pc
find_last_inst :: proc(prog: ^Prog, start_pc: u32) -> u32 {
	if start_pc >= u32(len(prog.inst)) {
		return start_pc
	}
	
	// Simple implementation: just return the current last instruction
	// In a full implementation, we'd need to follow jumps and handle branches
	return u32(len(prog.inst) - 1)
}

// Compile star quantifier (*) using Thompson's construction
compile_star :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast.data == nil {
		return 0, .InternalError
	}
	
	rep_data := (^Repeat_Data)(ast.data)
	
	// Create the star structure:
	// split_pc: Alt -> sub_pc or exit_pc
	// sub_pc: compiled sub-expression (ends with Jmp back to split_pc)
	// exit_pc: continues to next instruction
	
	split_pc := add_inst(prog, .Alt, 0, 0)  // Will be filled later
	
	// Compile sub-expression
	sub_pc, err := compile_regexp(prog, rep_data.sub)
	if err != .NoError {
		return 0, err
	}
	
	// Link split to sub-expression
	prog.inst[split_pc].out = sub_pc
	
	// Create jump back to split for repetition
	jump_back_pc := add_inst(prog, .Jmp, split_pc, 0)
	
	// Find and modify the Match instruction at the end of sub-expression
	// Replace it with a jump to our jump_back instruction
	found := false
	for i := len(prog.inst) - 1; i >= 0; i -= 1 {
		if prog.inst[i].op == .Match && u32(i) >= sub_pc {
			prog.inst[i].op = .Jmp
			prog.inst[i].out = jump_back_pc
			found = true
			break
		}
	}
	
	if !found {
		// Fallback: add a jump from the last instruction
		if len(prog.inst) > 0 {
			last_idx := len(prog.inst) - 1
			prog.inst[last_idx].out = jump_back_pc
		}
	}
	
	// Set the second branch of split to exit (skip the star)
	prog.inst[split_pc].arg = jump_back_pc + 1
	
	// Add a placeholder Match instruction that will be linked by concat compilation
	add_inst(prog, .Match, 0, 0)
	
	return split_pc, .NoError
}

// Compile plus quantifier (+) using Thompson's construction
compile_plus :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast.data == nil {
		return 0, .InternalError
	}
	
	rep_data := (^Repeat_Data)(ast.data)
	
	// Compile sub-expression (must match at least once)
	sub_pc, err := compile_regexp(prog, rep_data.sub)
	if err != .NoError {
		return 0, err
	}
	
	// Create split for additional matches: either match more or exit
	split_pc := add_inst(prog, .Alt, 0, 0) // Will be filled later
	
	// Find and modify the Match instruction at the end of sub-expression
	// Replace it with a jump to our split instruction
	found := false
	for i := len(prog.inst) - 1; i >= 0; i -= 1 {
		if prog.inst[i].op == .Match && u32(i) >= sub_pc {
			prog.inst[i].op = .Jmp
			prog.inst[i].out = split_pc
			found = true
			break
		}
	}
	
	if !found {
		// Fallback: add a jump from the last instruction
		if len(prog.inst) > 0 {
			last_idx := len(prog.inst) - 1
			prog.inst[last_idx].out = split_pc
		}
	}
	
	// First branch: match sub-expression again
	prog.inst[split_pc].out = sub_pc
	
	// Second branch: exit to match instruction
	prog.inst[split_pc].arg = split_pc + 1
	
	// Add final match instruction
	add_inst(prog, .Match, 0, 0)
	
	return sub_pc, .NoError
}

// Compile question mark quantifier (?) using Thompson's construction
compile_quest :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast.data == nil {
		return 0, .InternalError
	}
	
	rep_data := (^Repeat_Data)(ast.data)
	
	// Create split: either match sub-expression or skip it
	split_pc := add_inst(prog, .Alt, 0, 0) // Will be filled later
	
	// Compile sub-expression
	sub_pc, err := compile_regexp(prog, rep_data.sub)
	if err != .NoError {
		return 0, err
	}
	
	// First branch: match sub-expression
	prog.inst[split_pc].out = sub_pc
	
	// Second branch: skip sub-expression  
	prog.inst[split_pc].arg = split_pc + 1
	
	// For ? quantifier, we DON'T replace the Match instruction in sub-expression
	// The sub-expression should keep its Match instruction, which will jump to our final match
	
	// Add final match instruction (both branches converge here)
	final_match_pc := add_inst(prog, .Match, 0, 0)
	
	// Link the sub-expression's Match instruction to our final match
	// Find the Match instruction at the end of sub-expression
	for i := len(prog.inst) - 1; i >= 0; i -= 1 {
		if prog.inst[i].op == .Match && u32(i) >= sub_pc && u32(i) < final_match_pc {
			prog.inst[i].out = final_match_pc
			break
		}
	}
	
	return split_pc, .NoError
}

// Compile repeat quantifier {n,m} - simplified implementation
compile_repeat :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast.data == nil {
		return 0, .InternalError
	}
	
	rep_data := (^Repeat_Data)(ast.data)
	
	// For simplicity, implement as a star with minimum count check
	// In a full implementation, we'd use loops for efficiency
	
	if rep_data.min == 0 {
		// Just treat as star
		return compile_star(prog, ast)
	} else if rep_data.min == 1 && rep_data.max == -1 {
		// Treat as plus
		return compile_plus(prog, ast)
	} else {
		// For now, just implement as plus (simplified)
		return compile_plus(prog, ast)
	}
}

// Compile concatenation
compile_concat :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast.data == nil {
		return 0, .InternalError
	}
	
	concat_data := (^Concat_Data)(ast.data)
	if len(concat_data.subs) == 0 {
		return 0, .InternalError
	}
	
	// Check if all sub-expressions are single-character literals
	all_single_literals := true
	for i in 0..<len(concat_data.subs) {
		sub := concat_data.subs[i]
		if sub.op != .OpLiteral {
			all_single_literals = false
			break
		}
		lit_data := (^string)(sub.data)
		if len(lit_data^) != 1 {
			all_single_literals = false
			break
		}
	}
	
	// Handle optimized case: all single-character literals
	if all_single_literals {
		// Create rune instructions for each character
		rune_pcs := make([]u32, len(concat_data.subs))
		
		for i in 0..<len(concat_data.subs) {
			sub := concat_data.subs[i]
			lit_data := (^string)(sub.data)
			rune_pcs[i] = add_inst(prog, .Rune1, 0, u32(lit_data^[0]))
		}
		
		// Link them together
		for i in 0..<len(rune_pcs)-1 {
			prog.inst[rune_pcs[i]].out = rune_pcs[i+1]
		}
		
		// Add match instruction at the end
		match_pc := add_inst(prog, .Match, 0, 0)
		prog.inst[rune_pcs[len(rune_pcs)-1]].out = match_pc
		
		return rune_pcs[0], .NoError
	}
	
	// For non-literal cases, use a simpler approach
	// Compile all sub-expressions first, then link them
	sub_pcs := make([]u32, len(concat_data.subs))
	
	for i in 0..<len(concat_data.subs) {
		sub_pc, sub_err := compile_regexp(prog, concat_data.subs[i])
		if sub_err != .NoError {
			return 0, sub_err
		}
		sub_pcs[i] = sub_pc
	}
	
	// Now link them: replace each sub's Match with Jmp to next sub
	for i in 0..<len(sub_pcs)-1 {
		// Find the Match instruction for sub i and replace with Jmp to sub i+1
		// Search from the end backwards to find the last Match
		for j := len(prog.inst) - 1; j >= 0; j -= 1 {
			if prog.inst[j].op == .Match && prog.inst[j].out == 0 {
				// Check if this Match belongs to current sub by checking if it's after sub's start
				if u32(j) >= sub_pcs[i] && (i == len(sub_pcs)-1 || u32(j) < sub_pcs[i+1]) {
					prog.inst[j].op = .Jmp
					prog.inst[j].out = sub_pcs[i+1]
					break
				}
			}
		}
	}
	
	return sub_pcs[0], .NoError
}

// Compile alternation
compile_alternate :: proc(prog: ^Prog, ast: ^Regexp) -> (u32, ErrorCode) {
	if ast.data == nil {
		return 0, .InternalError
	}
	
	alt_data := (^Alternate_Data)(ast.data)
	if len(alt_data.subs) == 0 {
		return 0, .InternalError
	}
	
	if len(alt_data.subs) == 1 {
		// Single alternative - just compile it
		return compile_regexp(prog, alt_data.subs[0])
	}
	
	// Handle simple case of 2 alternatives
	if len(alt_data.subs) == 2 {
		// Create Alt instruction
		alt_pc := add_inst(prog, .Alt, 0, 0)
		
		// Compile first alternative
		first_pc, err := compile_regexp(prog, alt_data.subs[0])
		if err != .NoError {
			return 0, err
		}
		
		// Compile second alternative
		second_pc, second_err := compile_regexp(prog, alt_data.subs[1])
		if second_err != .NoError {
			return 0, second_err
		}
		
		// Link Alt to both alternatives
		prog.inst[alt_pc].out = first_pc
		prog.inst[alt_pc].arg = second_pc
		
		return alt_pc, .NoError
	}
	
	// For more alternatives, use the general approach (simplified)
	return compile_regexp(prog, alt_data.subs[0])
}