package regexp

// ===========================================================================
import "core:strings"
// THOMPSON NFA INSTRUCTION SET
// ===========================================================================

// Simplified Thompson NFA opcodes for linear-time execution
Inst_Op :: enum u8 {
	Char,          // Single character match
	Alt,           // Alternation (branch)
	Jmp,           // Unconditional jump
	Match,         // Successful match
	Cap,           // Capture group: start/end capture
	Empty,         // Empty-width assertion: ^, $, \b, etc.
tAny,           // Any character match
	AnyNotNL,      // Any character except newline
	Class,         // Character class
}

// Compact 32-bit instruction encoding for optimal cache performance
// Layout: [8 bits opcode][24 bits argument]
Inst :: struct {
	raw: u32,
}

// Helper functions for instruction encoding/decoding
inst_encode :: proc(op: Inst_Op, arg: u32) -> Inst {
	return Inst{u32(op) << 24 | u32(arg)}
}

inst_opcode :: proc(inst: Inst) -> Inst_Op {
	return Inst_Op(inst.raw >> 24)
}

inst_arg :: proc(inst: Inst) -> u32 {
	return u32(inst.raw & 0x00FFFFFF)
}

// ===========================================================================
// NFA PROGRAM MANAGEMENT
// ===========================================================================

// NFA Program with arena-based allocation
Program :: struct {
	instructions: [dynamic]Inst,
	capture_count: int,
	arena: ^Arena,
}

// Create new program with arena allocation
new_program :: proc(arena: ^Arena, capacity: int) -> ^Program {
	prog := (^Program)(arena_alloc(arena, size_of(Program)))
	prog.instructions = make([dynamic]Inst, 0, capacity)
	prog.capture_count = 0
	prog.arena = arena
	return prog
}

// Add instruction to program
add_instruction :: proc(prog: ^Program, op: Inst_Op, arg: u32) -> int {
	inst := inst_encode(op, arg)
	append(&prog.instructions, inst)
	return len(prog.instructions) - 1
}

// ===========================================================================
// THOMPSON NFA CONSTRUCTION
// ===========================================================================

// Fragment represents a partially built NFA
Fragment :: struct {
	start: int,    // Start instruction index
	out:  []int,   // List of exit points to patch
}

// Create fragment with single exit point
make_fragment :: proc(start: int, out: int) -> Fragment {
	return Fragment{start, []int{out}}
}

// Create fragment with multiple exit points
make_fragment_multi :: proc(start: int, outs: []int) -> Fragment {
	return Fragment{start, outs}
}

// Patch exit points of fragment
patch :: proc(prog: ^Program, frag: Fragment, target: int) {
	for out in frag.out {
		if out >= 0 && out < len(prog.instructions) {
			prog.instructions[out] = inst_encode(.Jmp, u32(target))
		}
	}
}

// Compile character literal to NFA
compile_char :: proc(prog: ^Program, ch: rune) -> Fragment {
	inst_idx := add_instruction(prog, .Char, u32(ch))
	return make_fragment(inst_idx, inst_idx + 1)
}

// Compile alternation (a|b)
compile_alt :: proc(prog: ^Program, left, right: Fragment) -> Fragment {
	// Create jump instructions for alternation
	jmp1 := add_instruction(prog, .Alt, 0)  // Will be patched to left.start
	jmp2 := add_instruction(prog, .Jmp, 0)   // Will be patched to right.start
	
	// Patch the alt instruction
	prog.instructions[jmp1] = inst_encode(.Alt, u32(left.start))
	prog.instructions[jmp2] = inst_encode(.Jmp, u32(right.start))
	
	// Combine exit points
	outs_slice := make([]int, len(left.out) + len(right.out))
	copy(outs_slice, left.out)
	copy(outs_slice[len(left.out):], right.out)
	
	return make_fragment_multi(jmp1, outs_slice)
}

// Compile concatenation (ab)
compile_concat :: proc(prog: ^Program, left, right: Fragment) -> Fragment {
	// Patch left's exits to right's start
	patch(prog, left, right.start)
	return make_fragment_multi(right.start, right.out)
}

// Compile star operator (a*)
compile_star :: proc(prog: ^Program, frag: Fragment) -> Fragment {
	// Create star loop: Alt -> frag.start -> Jmp -> back to Alt
	alt := add_instruction(prog, .Alt, 0)  // Will be patched to frag.start
	jmp := add_instruction(prog, .Jmp, 0)   // Will be patched to alt
	
	// Patch instructions
	prog.instructions[alt] = inst_encode(.Alt, u32(frag.start))
	prog.instructions[jmp] = inst_encode(.Jmp, u32(alt))
	
	// Patch fragment's exits to jump
	patch(prog, frag, jmp)
	
	// Star can exit immediately or after loop
	return make_fragment_multi(alt, []int{alt, jmp})
}

// Compile plus operator (a+)
compile_plus :: proc(prog: ^Program, frag: Fragment) -> Fragment {
	// Plus is like star but must match at least once
	star_frag := compile_star(prog, frag)
	patch(prog, frag, star_frag.start)
	return make_fragment_multi(frag.start, star_frag.out)
}

// Compile question mark (a?)
compile_quest :: proc(prog: ^Program, frag: Fragment) -> Fragment {
	// Question mark: either match frag or skip it
	alt := add_instruction(prog, .Alt, 0)  // Will be patched to frag.start
	jmp := add_instruction(prog, .Jmp, 0)   // Will be patched after frag
	
	// Patch instructions
	prog.instructions[alt] = inst_encode(.Alt, u32(frag.start))
	prog.instructions[jmp] = inst_encode(.Jmp, u32(0))  // Will be patched later
	
	// Patch fragment's exits to after the jmp
	patch(prog, frag, jmp + 1)
	
	// Can either take alt or skip to jmp + 1
	return make_fragment_multi(alt, []int{jmp + 1})
}

// Finalize program with match instruction
finalize_program :: proc(prog: ^Program, frag: Fragment) {
	// Patch all exits to match instruction
	match_idx := add_instruction(prog, .Match, 0)
	patch(prog, frag, match_idx)
}

// ===========================================================================
// MAIN NFA COMPILER
// ===========================================================================

// Compile AST to Thompson NFA
compile_nfa :: proc(ast: ^Regexp, arena: ^Arena) -> (^Program, ErrorCode) {
	if ast == nil {
		return nil, .ParseError
	}
	
	prog := new_program(arena, 64)
	frag := compile_ast_to_nfa(prog, ast)
	finalize_program(prog, frag)
	
	return prog, .NoError
}

// Compile AST node to NFA fragment
compile_ast_to_nfa :: proc(prog: ^Program, ast: ^Regexp) -> Fragment {
	if ast == nil {
		return make_fragment(-1, -1)
	}
	
	#partial switch ast.op {
	case .OpLiteral:
		if ast.data != nil {
			lit_data := (^Literal_Data)(ast.data)
			str := string_view_to_string(lit_data.str)
			if len(str) > 0 {
				return compile_char(prog, rune(str[0]))
			}
		}
		
	case .OpConcat:
		if ast.data != nil {
			concat_data := (^Concat_Data)(ast.data)
			if len(concat_data.subs) > 0 {
				result := compile_ast_to_nfa(prog, concat_data.subs[0])
				for i in 1..<len(concat_data.subs) {
					next := compile_ast_to_nfa(prog, concat_data.subs[i])
					result = compile_concat(prog, result, next)
				}
				return result
			}
		}
		
	case .OpAlternate:
		if ast.data != nil {
			alt_data := (^Alternate_Data)(ast.data)
			if len(alt_data.subs) > 0 {
				result := compile_ast_to_nfa(prog, alt_data.subs[0])
				for i in 1..<len(alt_data.subs) {
					next := compile_ast_to_nfa(prog, alt_data.subs[i])
					result = compile_alt(prog, result, next)
				}
				return result
			}
		}
		
	case .OpStar:
		if ast.data != nil {
			repeat_data := (^Repeat_Data)(ast.data)
			if repeat_data.sub != nil {
				frag := compile_ast_to_nfa(prog, repeat_data.sub)
				return compile_star(prog, frag)
			}
		}
		
	case .OpPlus:
		if ast.data != nil {
			repeat_data := (^Repeat_Data)(ast.data)
			if repeat_data.sub != nil {
				frag := compile_ast_to_nfa(prog, repeat_data.sub)
				return compile_plus(prog, frag)
			}
		}
		
	case .OpQuest:
		if ast.data != nil {
			repeat_data := (^Repeat_Data)(ast.data)
			if repeat_data.sub != nil {
				frag := compile_ast_to_nfa(prog, repeat_data.sub)
				return compile_quest(prog, frag)
			}
		}

	case .OpCapture:
		if ast.data != nil {
			cap_data := (^Capture_Data)(ast.data)
			if cap_data.sub != nil {
				// For now, just compile the sub-expression (ignore capture semantics)
				// TODO: Add proper capture group handling with Cap instructions
				return compile_ast_to_nfa(prog, cap_data.sub)
			}
		}
	}

	// Default: empty match
	return make_fragment(-1, -1)
}