package regexp

// Regular expression parser for RE2-compatible regex engine
// Implements literal parsing for User Story 1

import "core:fmt"
import "base:runtime"

// Parser state for tracking position and context
Parser :: struct {
	pattern:    string,
	pos:        int,
	arena:      ^Arena,
	flags:      Parse_Flags,
	capture_num: int, // Next capture group number
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
	return Parser{pattern, 0, arena, flags, 0}
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

	// Parse full regular expression (User Story 2+)
	node := parse_alternation(&parser)
	if node == nil {
		return nil, .ParseError
	}

	// Should have consumed all input
	if !at_end(&parser) {
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

// ===== User Story 2+ Parsing Functions =====

// Parse alternation (lowest precedence)
parse_alternation :: proc(p: ^Parser) -> ^Regexp {
	node := parse_concat(p)
	
	for !at_end(p) && peek(p) == '|' {
		advance(p) // Consume '|'
		right := parse_concat(p)
		if right == nil {
			return nil
		}
		alts := [2]^Regexp{node, right}
		node = make_alternate(p.arena, alts[:])
	}
	
	return node
}

// Parse concatenation (medium precedence)
parse_concat :: proc(p: ^Parser) -> ^Regexp {
	nodes: [32]^Regexp // Fixed array for efficiency
	count := 0
	
	for !at_end(p) {
		ch := peek(p)
		if ch == '|' || ch == ')' {
			break // End of this concatenation
		}
		
		node := parse_term(p)
		if node == nil {
			return nil
		}
		
		if count < len(nodes) {
			nodes[count] = node
			count += 1
		}
	}
	
	if count == 0 {
		return make_literal(p.arena, "") // Empty concatenation
	}
	if count == 1 {
		return nodes[0]
	}
	
	// Build concatenation tree
	result := nodes[0]
	for i in 1..<count {
		concats := [2]^Regexp{result, nodes[i]}
		result = make_concat(p.arena, concats[:])
	}
	
	return result
}

// Parse term (highest precedence) - literals, char classes, groups, etc.
parse_term :: proc(p: ^Parser) -> ^Regexp {
	if at_end(p) {
		return nil
	}
	
	ch := peek(p)
	
	// Handle character classes
	if ch == '[' {
		return parse_char_class(p)
	}
	
	// Handle groups
	if ch == '(' {
		return parse_group(p)
	}
	
	// Handle special characters
	if ch == '.' {
		advance(p)
		return make_any_char(p.arena, false)
	}
	
	// Handle anchors
	if ch == '^' {
		advance(p)
		return make_anchor(p.arena, .OpBeginLine)
	}
	
	if ch == '$' {
		advance(p)
		return make_anchor(p.arena, .OpEndLine)
	}
	
	// Handle escaped characters
	if ch == '\\' {
		return parse_escape(p)
	}
	
	// Handle quantifiers (should be handled after parsing the base term)
	// This will be handled in parse_quantified_term
	
	// Default: parse as literal
	return parse_literal_char(p)
}

// Parse character class [a-z] or [^a-z]
parse_char_class :: proc(p: ^Parser) -> ^Regexp {
	if at_end(p) || peek(p) != '[' {
		return nil
	}
	
	advance(p) // Consume '['
	
	// Check for negation
	negated := false
	if !at_end(p) && peek(p) == '^' {
		negated = true
		advance(p) // Consume '^'
	}
	
	ranges: [64]Char_Range // Fixed array for efficiency
	range_count := 0
	
	// Parse ranges
	for !at_end(p) && peek(p) != ']' {
		if range_count >= len(ranges) {
			return nil // Too many ranges
		}
		
		// Parse first character
		if at_end(p) {
			return nil
		}
		
		ch1 := parse_char_class_char(p)
		if ch1 == -1 {
			return nil
		}
		
		// Check if it's a range
		if !at_end(p) && peek(p) == '-' {
			advance(p) // Consume '-'
			
			if at_end(p) || peek(p) == ']' {
				// '-' is literal, not range
				ranges[range_count] = Char_Range{ch1, ch1}
				range_count += 1
				continue
			}
			
			ch2 := parse_char_class_char(p)
			if ch2 == -1 {
				return nil
			}
			
			if ch1 > ch2 {
				return nil // Invalid range
			}
			
			ranges[range_count] = Char_Range{ch1, ch2}
			range_count += 1
		} else {
			// Single character
			ranges[range_count] = Char_Range{ch1, ch1}
			range_count += 1
		}
	}
	
	if at_end(p) || peek(p) != ']' {
		return nil // Unclosed character class
	}
	
	advance(p) // Consume ']'
	
	// Create ranges slice
	ranges_slice := make([]Char_Range, range_count)
	for i in 0..<range_count {
		ranges_slice[i] = ranges[i]
	}
	
	return make_char_class(p.arena, ranges_slice, negated)
}

// Parse a single character from character class
parse_char_class_char :: proc(p: ^Parser) -> rune {
	if at_end(p) {
		return -1
	}
	
	ch := peek(p)
	
	// Handle escaped characters
	if ch == '\\' {
		advance(p) // Consume '\\'
		if at_end(p) {
			return -1
		}
		
		escaped := peek(p)
		advance(p)
		
		switch escaped {
		case 'n': return '\n'
		case 't': return '\t'
		case 'r': return '\r'
		case 'f': return '\f'
		case 'v': return '\v'
		case '\\': return '\\'
		case '-': return '-'
		case ']': return ']'
		case '^': return '^'
		case:
			// For now, return the escaped character as-is
			return rune(escaped)
		}
	}
	
	advance(p)
	return rune(ch)
}

// Parse group (capturing or non-capturing)
parse_group :: proc(p: ^Parser) -> ^Regexp {
	if at_end(p) || peek(p) != '(' {
		return nil
	}
	
	advance(p) // Consume '('
	
	// Check for non-capturing group (?:...)
	non_capturing := false
	if !at_end(p) && peek(p) == '?' {
		advance(p) // Consume '?'
		if !at_end(p) && peek(p) == ':' {
			advance(p) // Consume ':'
			non_capturing = true
		} else {
			return nil // Unsupported group type
		}
	}
	
	// Parse group content
	node := parse_alternation(p)
	if node == nil {
		return nil
	}
	
	if at_end(p) || peek(p) != ')' {
		return nil // Unclosed group
	}
	
	advance(p) // Consume ')'
	
	if non_capturing {
		return node // Non-capturing group, just return the content
	} else {
		// Capturing group - assign a capture number
		capture_num := p.capture_num
		p.capture_num += 1
		return make_capture(p.arena, capture_num, node)
	}
}

// Parse escaped sequence
parse_escape :: proc(p: ^Parser) -> ^Regexp {
	if at_end(p) || peek(p) != '\\' {
		return nil
	}
	
	advance(p) // Consume '\\'
	
	if at_end(p) {
		return nil // Trailing backslash
	}
	
	ch := peek(p)
	advance(p)
	
	switch ch {
	case 'n': return make_literal(p.arena, "\n")
	case 't': return make_literal(p.arena, "\t")
	case 'r': return make_literal(p.arena, "\r")
	case 'f': return make_literal(p.arena, "\f")
	case 'v': return make_literal(p.arena, "\v")
	case '\\': return make_literal(p.arena, "\\")
	case '.': return make_literal(p.arena, ".")
	case '*': return make_literal(p.arena, "*")
	case '+': return make_literal(p.arena, "+")
	case '?': return make_literal(p.arena, "?")
	case '(': return make_literal(p.arena, "(")
	case ')': return make_literal(p.arena, ")")
	case '[': return make_literal(p.arena, "[")
	case ']': return make_literal(p.arena, "]")
	case '{': return make_literal(p.arena, "{")
	case '}': return make_literal(p.arena, "}")
	case '|': return make_literal(p.arena, "|")
	case '^': return make_literal(p.arena, "^")
	case '$': return make_literal(p.arena, "$")
	case:
		// For now, treat unknown escapes as literal character
		if !at_end(p) {
			ch := byte(peek(p))
			advance(p)
			return make_literal(p.arena, string([]byte{ch}))
		}
		return nil
	}
}

// Parse literal character
parse_literal_char :: proc(p: ^Parser) -> ^Regexp {
	if at_end(p) {
		return nil
	}
	
	ch := peek(p)
	advance(p)
	
	// Check for quantifier after literal
	if !at_end(p) {
		next_ch := peek(p)
		if next_ch == '*' || next_ch == '+' || next_ch == '?' || next_ch == '{' {
			// Put the character back and let parse_quantified_term handle it
			p.pos -= 1
			return parse_quantified_term(p)
		}
	}
	
	// Convert rune to string using UTF-8 encoding
	if ch <= 0x7F {
		// ASCII character - single byte
		return make_literal(p.arena, string([]byte{byte(ch)}))
	} else {
		// For now, handle only ASCII
		return make_literal(p.arena, "")
	}
}

// Parse term with optional quantifier
parse_quantified_term :: proc(p: ^Parser) -> ^Regexp {
	// Parse the base term
	base := parse_term_base(p)
	if base == nil {
		return nil
	}
	
	// Check for quantifier
	if at_end(p) {
		return base
	}
	
	ch := peek(p)
	switch ch {
	case '*':
		advance(p)
		return make_star(p.arena, base)
	case '+':
		advance(p)
		return make_plus(p.arena, base)
	case '?':
		advance(p)
		return make_quest(p.arena, base)
	case '{':
		return parse_repeat(p, base)
	case:
		return base
	}
}

// Parse base term (without quantifier)
parse_term_base :: proc(p: ^Parser) -> ^Regexp {
	if at_end(p) {
		return nil
	}
	
	ch := peek(p)
	
	// Handle character classes
	if ch == '[' {
		return parse_char_class(p)
	}
	
	// Handle groups
	if ch == '(' {
		return parse_group(p)
	}
	
	// Handle special characters
	if ch == '.' {
		advance(p)
		return make_any_char(p.arena, false)
	}
	
	// Handle anchors
	if ch == '^' {
		advance(p)
		return make_anchor(p.arena, .OpBeginLine)
	}
	
	if ch == '$' {
		advance(p)
		return make_anchor(p.arena, .OpEndLine)
	}
	
	// Handle escaped characters
	if ch == '\\' {
		return parse_escape(p)
	}
	
	// Default: parse as literal character
	if at_end(p) {
		return nil
	}
	
	advance(p)
	return make_literal(p.arena, string([]byte{byte(ch)}))
}

// Parse repeat quantifier {n,m}
parse_repeat :: proc(p: ^Parser, base: ^Regexp) -> ^Regexp {
	if at_end(p) || peek(p) != '{' {
		return nil
	}
	
	advance(p) // Consume '{'
	
	// Parse minimum
	min_str := ""
	
	if min_str == "" {
		return nil // Expected number
	}
	
	min := 0
	for ch in min_str {
		min = min * 10 + (int(ch) - int('0'))
	}
	
	// Check for comma
	max := min
	has_max := false
	
	if !at_end(p) && peek(p) == ',' {
		advance(p) // Consume ','
		has_max = true
		
		// Parse maximum (optional)
		max_digits := [10]byte{}
		max_len := 0
		for !at_end(p) && is_digit(byte(peek(p))) && max_len < 10 {
			max_digits[max_len] = byte(peek(p))
			max_len += 1
			advance(p)
		}
		
		if max_len > 0 {
			max = 0
			for i in 0..<max_len {
				max = max * 10 + int(max_digits[i] - '0')
			}
		} else {
			// {n,} means n or more
			max = -1
		}
	}
	
	if at_end(p) || peek(p) != '}' {
		return nil // Unclosed repeat
	}
	
	advance(p) // Consume '}'
	
	return make_repeat(p.arena, .OpRepeat, base, min, max, false)
}

// Check if character is digit
is_digit :: proc(ch: byte) -> bool {
	return ch >= '0' && ch <= '9'
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
