package regexp

// Regular expression parser for RE2-compatible regex engine
// Implements literal parsing for User Story 1

import "core:fmt"
import "base:runtime"

// Parser state for tracking position and context
Parser :: struct {
	pattern: string,
	pos:     int,
	arena:   ^Arena,
	flags:   Parse_Flags,
}

// Parse flags for parser behavior
Parse_Flags :: enum {
	None,
	Literal       = 1 << 0, // Parse as literal
	PerlX         = 1 << 1, // Perl extensions
	PerlClasses   = 1 << 2, // Perl character classes
	UnicodeGroups = 1 << 3, // Unicode character groups
}

// Create a new parser for the given pattern
new_parser :: proc(pattern: string, flags: Parse_Flags, arena: ^Arena) -> Parser {
	return Parser{pattern, 0, arena, flags}
}

// Get current character from parser
peek :: proc(p: ^Parser) -> rune {
	if p.pos >= len(p.pattern) {
		return 0 // End of string
	}
	return rune(p.pattern[p.pos])
}

// Advance parser position
advance :: proc(p: ^Parser) -> rune {
	if p.pos >= len(p.pattern) {
		return 0
	}
	ch := rune(p.pattern[p.pos])
	p.pos += 1
	return ch
}

// Check if we're at end of pattern
at_end :: proc(p: ^Parser) -> bool {
	return p.pos >= len(p.pattern)
}

// Parse a regular expression (main entry point)
parse_regexp_internal :: proc(pattern: string, flags: Parse_Flags) -> (^Regexp, ErrorCode) {
	arena := new_arena(4096)
	defer free_arena(arena)
	
	parser := new_parser(pattern, flags, arena)
	
	if at_end(&parser) {
		// Empty pattern
		node := make_literal(arena, "")
		return clone_to_new_arena(node), .NoError
	}
	
	// For User Story 1, parse as literal string
	node := parse_literal(&parser)
	if node == nil {
		return nil, .ParseError
	}
	
	// Clone the node to a new arena since parser arena will be freed
	return clone_to_new_arena(node), .NoError
}

// Parse literal string (for User Story 1)
parse_literal :: proc(p: ^Parser) -> ^Regexp {
	start_pos := p.pos
	
	// For User Story 1, treat entire pattern as literal
	// In future versions, this will handle escape sequences and special characters
	for !at_end(p) {
		ch := peek(p)
		
		// Handle escape sequences
		if ch == '\\' {
			advance(p) // Skip backslash
			if at_end(p) {
				return nil // Trailing backslash
			}
			// For now, just include the escaped character as-is
			// Future versions will handle special escape sequences
		}
		
		advance(p)
	}
	
	// Extract literal string
	literal_str := p.pattern[start_pos:p.pos]
	return make_literal(p.arena, literal_str)
}

// Clone AST node to a new arena (for memory management)
clone_to_new_arena :: proc(original: ^Regexp) -> ^Regexp {
	if original == nil {
		return nil
	}
	
	new_arena := new_arena(4096)
	return clone_node(original, new_arena)
}

// Clone a single AST node
clone_node :: proc(node: ^Regexp, arena: ^Arena) -> ^Regexp {
	if node == nil {
		return nil
	}
	
	switch node.op {
	case .OpLiteral:
		lit_data := (^Literal_Data)(node.data)
		return make_literal(arena, to_string(lit_data.str))
	
	case .OpCharClass:
		cc_data := (^CharClass_Data)(node.data)
		return make_char_class(arena, cc_data.ranges, cc_data.negated)
	
	case .OpAnyChar, .OpAnyCharNotNL:
		return make_any_char(arena, node.op == .OpAnyCharNotNL)
	
	case .OpBeginLine, .OpEndLine, .OpBeginText, .OpEndText, .OpWordBoundary, .OpNoWordBoundary:
		return make_anchor(arena, node.op)
	
	case .OpCapture:
		cap_data := (^Capture_Data)(node.data)
		sub_cloned := clone_node(cap_data.sub, arena)
		return make_capture(arena, cap_data.cap, sub_cloned)
	
	case .OpStar, .OpPlus, .OpQuest, .OpRepeat:
		rep_data := (^Repeat_Data)(node.data)
		sub_cloned := clone_node(rep_data.sub, arena)
		return make_repeat(arena, node.op, sub_cloned, rep_data.min, rep_data.max, rep_data.non_greedy)
	
	case .OpConcat:
		concat_data := (^Concat_Data)(node.data)
		cloned_subs: []^Regexp
		cloned_subs, _ = runtime.make_slice([]^Regexp, len(concat_data.subs))
		for i in 0..<len(concat_data.subs) {
			cloned_subs[i] = clone_node(concat_data.subs[i], arena)
		}
		return make_concat(arena, cloned_subs)
	
	case .OpAlternate:
		alt_data := (^Alternate_Data)(node.data)
		cloned_subs: []^Regexp
		cloned_subs, _ = runtime.make_slice([]^Regexp, len(alt_data.subs))
		for i in 0..<len(alt_data.subs) {
			cloned_subs[i] = clone_node(alt_data.subs[i], arena)
		}
		return make_alternate(arena, cloned_subs)
	
	case .NoOp:
		return make_literal(arena, "")
	}
	
	return nil
}

// Validate parsed AST
validate_ast :: proc(node: ^Regexp) -> ErrorCode {
	if node == nil {
		return .InternalError
	}
	
	switch node.op {
	case .OpLiteral:
		lit_data := (^Literal_Data)(node.data)
		if lit_data == nil {
			return .InternalError
		}
	
	case .OpCharClass:
		cc_data := (^CharClass_Data)(node.data)
		if cc_data == nil {
			return .InternalError
		}
	
	case .OpCapture:
		cap_data := (^Capture_Data)(node.data)
		if cap_data == nil || cap_data.sub == nil {
			return .InternalError
		}
		return validate_ast(cap_data.sub)
	
	case .OpStar, .OpPlus, .OpQuest, .OpRepeat:
		rep_data := (^Repeat_Data)(node.data)
		if rep_data == nil || rep_data.sub == nil {
			return .InternalError
		}
		if rep_data.min < 0 || (rep_data.max >= 0 && rep_data.max < rep_data.min) {
			return .ErrorInvalidRepeatSize
		}
		return validate_ast(rep_data.sub)
	
	case .OpConcat:
		concat_data := (^Concat_Data)(node.data)
		if concat_data == nil || len(concat_data.subs) == 0 {
			return .InternalError
		}
		for sub in concat_data.subs {
			err := validate_ast(sub)
			if err != .NoError {
				return err
			}
		}
	
	case .OpAlternate:
		alt_data := (^Alternate_Data)(node.data)
		if alt_data == nil || len(alt_data.subs) == 0 {
			return .InternalError
		}
		for sub in alt_data.subs {
			err := validate_ast(sub)
			if err != .NoError {
				return err
			}
		}
	
	case .NoOp, .OpAnyChar, .OpAnyCharNotNL, .OpBeginLine, .OpEndLine, .OpBeginText, .OpEndText, .OpWordBoundary, .OpNoWordBoundary:
		// These nodes have no data to validate
		return .NoError
	}
	
	return .NoError
}

// Get error position information
get_error_context :: proc(pattern: string, pos: int) -> string {
	if pos < 0 || pos >= len(pattern) {
		return pattern
	}
	
	start := max(0, pos - 10)
	end := min(len(pattern), pos + 10)
	ctx := pattern[start:end]
	
	return fmt.tprintf("%s (error at position %d)", ctx, pos)
}