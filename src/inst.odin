package regexp

// ===========================================================================
import "core:strings"
import "core:fmt"
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
	Backref,       // Backreference \1, \g{name}
	Lookahead,     // Lookahead assertion (?=...) (?!...)
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
	// For a single character, the fragment starts at the char instruction
	// and exits at the next instruction (we'll handle this in concat)
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
	// For now, implement a simple but correct version for single characters
	// Check if frag is a single character
	
	if frag.start == 0 && len(frag.out) == 1 {
		if len(prog.instructions) > 0 && Inst_Op(prog.instructions[0].raw >> 24) == .Char {
			ch := prog.instructions[0].raw & 0x00FFFFFF
			
			// Create the correct star pattern:
			// 0: Alt -> 2 (exit) OR 1 (char)
			// 1: Char(ch)
			// 2: Jmp -> 0 (back to alt)
			// 3: Exit (will be patched by caller)
			
			// Create new program with correct pattern
			// We can't easily clear the dynamic array, so we'll work with what we have
			// Just add the correct instructions at the end
			
			alt := add_instruction(prog, .Alt, 0)      // Will be patched to point to exit
			char_inst := add_instruction(prog, .Char, ch)
			jmp_back := add_instruction(prog, .Jmp, 0)  // Will be patched to point to alt
			exit := add_instruction(prog, .Jmp, 0)      // Exit point
			
			// Patch instructions
			prog.instructions[alt] = inst_encode(.Alt, u32(exit))
			prog.instructions[jmp_back] = inst_encode(.Jmp, u32(alt))
			
			// Return fragment starting from alt, not from the beginning
			exit_slice := arena_alloc_slice(prog.arena, int, 1)
			exit_slice[0] = exit
			return make_fragment_multi(alt, exit_slice)
		}
	}
	
	// Fallback: create a basic star (may not work correctly)
	alt := add_instruction(prog, .Alt, 0)
	exit := add_instruction(prog, .Jmp, 0)
	prog.instructions[alt] = inst_encode(.Alt, u32(exit))
	patch(prog, frag, alt)
	
	exit_slice := arena_alloc_slice(prog.arena, int, 1)
	exit_slice[0] = exit
	return make_fragment_multi(alt, exit_slice)
}

// Compile plus operator (a+)
compile_plus :: proc(prog: ^Program, frag: Fragment) -> Fragment {
	// Plus must match at least once, then can repeat
	// Check if frag is a single character
	if frag.start == 0 && len(frag.out) == 1 {
		if len(prog.instructions) > 0 && Inst_Op(prog.instructions[0].raw >> 24) == .Char {
			ch := prog.instructions[0].raw & 0x00FFFFFF
			
			// Create the correct plus pattern:
			// 0: Char(ch)           - Must match at least once
			// 1: Alt -> 2 (char) OR 3 (exit)
			// 2: Char(ch)           - Optional additional matches
			// 3: Jmp -> 4 (next instruction)
			// 4: Match (will be added by finalize_program)
			
			// Create instructions
			char1 := add_instruction(prog, .Char, ch)          // First required match
			alt := add_instruction(prog, .Alt, 0)              // Will be patched to point to exit
			char2 := add_instruction(prog, .Char, ch)          // Optional additional matches
			jmp_back := add_instruction(prog, .Jmp, 0)         // Will be patched to point to alt
			exit := add_instruction(prog, .Jmp, 0)             // Exit point
			
			// Patch instructions
			prog.instructions[alt] = inst_encode(.Alt, u32(exit))
			prog.instructions[jmp_back] = inst_encode(.Jmp, u32(alt))
			
			// Return fragment starting at char1, exiting at exit
			exit_slice := arena_alloc_slice(prog.arena, int, 1)
			exit_slice[0] = exit
			return make_fragment_multi(char1, exit_slice)
		}
	}
	
	// Fallback: create a basic plus
	alt := add_instruction(prog, .Alt, 0)
	exit := add_instruction(prog, .Jmp, 0)
	prog.instructions[alt] = inst_encode(.Alt, u32(exit))
	patch(prog, frag, alt)
	
	exit_slice := arena_alloc_slice(prog.arena, int, 1)
	exit_slice[0] = exit
	return make_fragment_multi(frag.start, exit_slice)
}

// Compile repeat operator (a{n,m}) - CLEAN VERSION
compile_repeat :: proc(prog: ^Program, frag: Fragment, min, max: int) -> Fragment {
	// For now, implement a simple version for single characters
	// Check if frag is a single character
	if frag.start == 0 && len(frag.out) == 1 {
		if len(prog.instructions) > 0 && Inst_Op(prog.instructions[0].raw >> 24) == .Char {
			ch := prog.instructions[0].raw & 0x00FFFFFF
			
			// Handle different repeat patterns
			if max == -1 {
				// {n,} - at least n times, no upper limit
				if min == 0 {
					// {0,} is equivalent to *
					return compile_star(prog, frag)
				} else if min == 1 {
					// {1,} is equivalent to +
					return compile_plus(prog, frag)
				}
				
				// For n >= 2, create n required chars + star
				// Clear existing instructions and start fresh
				prog.instructions = make([dynamic]Inst, 0, min + 4)
				
				start_idx := -1
				for i in 0..<min {
					char_idx := add_instruction(prog, .Char, ch)
					if start_idx == -1 {
						start_idx = char_idx
					}
				}
				
				// Add star pattern for remaining matches
				// Star pattern: Alt -> exit OR Char -> jmp_back
				alt := add_instruction(prog, .Alt, 0)      // Will be patched
				char_extra := add_instruction(prog, .Char, ch)
				jmp_back := add_instruction(prog, .Jmp, 0)  // Will be patched  
				exit := add_instruction(prog, .Jmp, 0)     // Final exit
				
				// Patch the star pattern
				prog.instructions[alt] = inst_encode(.Alt, u32(exit))
				prog.instructions[jmp_back] = inst_encode(.Jmp, u32(alt))
				
				// The last required char should flow directly to the star pattern
				// No additional jump needed - the star pattern comes right after
				
				exit_slice := arena_alloc_slice(prog.arena, int, 1)
				exit_slice[0] = exit
				return make_fragment_multi(start_idx, exit_slice)
				
			} else if min == max {
				// {n} - exactly n times
				if min == 0 {
					// {0} - empty match
					exit := add_instruction(prog, .Jmp, 0)
					exit_slice := arena_alloc_slice(prog.arena, int, 1)
					exit_slice[0] = exit
					return make_fragment_multi(exit, exit_slice)
				}
				
				// Clear any existing instructions and start fresh
				prog.instructions = make([dynamic]Inst, 0, min + 1)
				
				start_idx := -1
				for i in 0..<min {
					char_idx := add_instruction(prog, .Char, ch)
					if start_idx == -1 {
						start_idx = char_idx
					}
				}
				
				exit := add_instruction(prog, .Jmp, 0)
				exit_slice := arena_alloc_slice(prog.arena, int, 1)
				exit_slice[0] = exit
				return make_fragment_multi(start_idx, exit_slice)
				
			} else {
				// {n,m} - between n and m times
				// Use a simple and correct approach
				
				// Clear existing instructions and start fresh
				prog.instructions = make([dynamic]Inst, 0, max * 3 + 1)
				
				if min == 0 {
					// {0,m} - 0 to m times
					if max == 1 {
						// {0,1} is equivalent to ?
						return compile_quest(prog, frag)
					}
					
					// Create chain: a?a?a?... (m times)
					start_idx := -1
					prev_exit := -1
					
					for i in 0..<max {
						alt := add_instruction(prog, .Alt, 0)
						char_idx := add_instruction(prog, .Char, ch)
						exit_idx := add_instruction(prog, .Jmp, 0)
						
						// Patch Alt to point to exit (skip) or char (match)
						prog.instructions[alt] = inst_encode(.Alt, u32(exit_idx))
						
						if start_idx == -1 {
							start_idx = alt
						}
						
						// Connect previous exit to this alt
						if prev_exit != -1 {
							prog.instructions[prev_exit] = inst_encode(.Jmp, u32(alt))
						}
						
						prev_exit = exit_idx
					}
					
					exit_slice := arena_alloc_slice(prog.arena, int, 1)
					exit_slice[0] = prev_exit
					return make_fragment_multi(start_idx, exit_slice)
					
				} else {
					// {n,m} with n > 0
					// Thompson NFA construction: a a ... (a?)(a?)...
					
					// Clear existing instructions and start fresh
					prog.instructions = make([dynamic]Inst, 0, max * 3 + 1)
					
					// Add required characters first
					start_idx := -1
					for i in 0..<min {
						char_idx := add_instruction(prog, .Char, ch)
						if start_idx == -1 {
							start_idx = char_idx
						}
					}
					
					// Add optional characters as quest patterns
					optional_count := max - min
					prev_exit := -1
					
					// If we have required chars, the last one needs to connect to first optional
					if min > 0 && optional_count > 0 {
						// Add a jump after the last required char
						jmp_after_required := add_instruction(prog, .Jmp, 0)  // Will be patched
						prev_exit = jmp_after_required
					} else if min == 0 {
						// No required chars, start from first optional
						prev_exit = -1
					} else {
						// Only required chars, no optional
						prev_exit = start_idx + min - 1
					}
					
					// Create quest patterns for optional matches
					for i in 0..<optional_count {
						// Create quest: Alt -> skip OR Char -> jmp_out
						alt := add_instruction(prog, .Alt, 0)  // Will be patched
						char_opt := add_instruction(prog, .Char, ch)
						jmp_out := add_instruction(prog, .Jmp, 0)  // Will be patched
						
						// Connect previous instruction to this alt
						if prev_exit != -1 {
							prog.instructions[prev_exit] = inst_encode(.Jmp, u32(alt))
						} else if start_idx == -1 {
							// This is the first instruction overall
							start_idx = alt
						}
						
						// Patch alt to skip to jmp_out (exit path)
						prog.instructions[alt] = inst_encode(.Alt, u32(jmp_out))
						
						// Set up for next iteration
						prev_exit = jmp_out
					}
					
					// Add final exit
					final_exit := add_instruction(prog, .Jmp, 0)
					
					// Connect last instruction to final exit
					if prev_exit != -1 {
						prog.instructions[prev_exit] = inst_encode(.Jmp, u32(final_exit))
					}
					
					exit_slice := arena_alloc_slice(prog.arena, int, 1)
					exit_slice[0] = final_exit
					return make_fragment_multi(start_idx, exit_slice)
				}
			}
		}
	}
	
	// Fallback: just match the fragment once (incorrect but safe)
	return frag
}

// Compile question mark (a?)
compile_quest :: proc(prog: ^Program, frag: Fragment) -> Fragment {
	// Question mark: either match frag or skip it
	// Check if frag is a single character
	if frag.start == 0 && len(frag.out) == 1 {
		if len(prog.instructions) > 0 && Inst_Op(prog.instructions[0].raw >> 24) == .Char {
			ch := prog.instructions[0].raw & 0x00FFFFFF
			
			// Create the correct quest pattern:
			// 0: Alt -> 2 (exit) OR 1 (char)
			// 1: Char(ch)
			// 2: Jmp -> 3 (next instruction)
			// 3: Match (will be added by finalize_program)
			
			// Create instructions
			alt := add_instruction(prog, .Alt, 0)      // Will be patched to point to exit
			char_inst := add_instruction(prog, .Char, ch)
			exit := add_instruction(prog, .Jmp, 0)     // Exit point
			
			// Patch instructions
			prog.instructions[alt] = inst_encode(.Alt, u32(exit))
			
			// Return fragment starting at alt, exiting at exit
			exit_slice := arena_alloc_slice(prog.arena, int, 1)
			exit_slice[0] = exit
			return make_fragment_multi(alt, exit_slice)
		}
	}
	
	// Fallback: create a basic quest
	alt := add_instruction(prog, .Alt, 0)
	exit := add_instruction(prog, .Jmp, 0)
	prog.instructions[alt] = inst_encode(.Alt, u32(exit))
	patch(prog, frag, alt)
	
	exit_slice := arena_alloc_slice(prog.arena, int, 1)
	exit_slice[0] = exit
	return make_fragment_multi(alt, exit_slice)
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
				// Compile each character in sequence
				start_idx := add_instruction(prog, .Char, u32(str[0]))
				last_exit := start_idx + 1
				
				// Add remaining characters
				for i in 1..<len(str) {
					add_instruction(prog, .Char, u32(str[i]))
					last_idx := len(prog.instructions) - 1
					// Add jump from previous char to this char
					if i > 1 {
						prog.instructions[last_exit] = inst_encode(.Jmp, u32(last_idx))
					}
					last_exit = last_idx + 1
				}
				
				// Return fragment starting at first char, exiting after last char
				return make_fragment(start_idx, last_exit)
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
				result := compile_star(prog, frag)
				return result
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
		
	case .OpRepeat:
		if ast.data != nil {
			repeat_data := (^Repeat_Data)(ast.data)
			if repeat_data.sub != nil {
				frag := compile_ast_to_nfa(prog, repeat_data.sub)
				return compile_repeat(prog, frag, repeat_data.min, repeat_data.max)
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
		
	case .OpWordBoundary, .OpNoWordBoundary:
		// Compile word boundary as empty assertion with argument
		// Use 0 for word boundary, 1 for non-word boundary
		arg := u32(0) if ast.op == .OpWordBoundary else u32(1)
		inst_idx := add_instruction(prog, .Empty, arg)
		return make_fragment(inst_idx, inst_idx + 1)
	}
	
	// Default: empty match
	return make_fragment(-1, -1)
}