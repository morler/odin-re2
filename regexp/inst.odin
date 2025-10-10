package regexp



// RE2-compatible instruction set for NFA execution
// Based on Russ Cox's RE2 implementation

// Instruction opcodes matching RE2's Prog format
Inst_Op :: enum u8 {
	Alt,           // Alternate: alt to two different instructions
	AltMatch,      // Alternate with match: alt or succeed
	Capture,       // Capture group: start/end capture
	EmptyWidth,    // Empty width assertion: ^, $, \b, etc.
	Fail,          // Always fail
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