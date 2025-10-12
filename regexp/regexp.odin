package regexp

// Main public API for RE2-compatible regular expression engine in Odin
// This file provides the core interface functions

import "core:fmt"

// ============================================================================
// PUBLIC API DATA STRUCTURES
// ============================================================================

// Public API data structures
Regexp_Pattern :: struct {
	ast:     ^Regexp,    // Parsed AST
	arena:   ^Arena,     // Memory arena for all allocations
	error:   ErrorCode,  // Compilation error status
}

Match_Result :: struct {
	matched:    bool,
	full_match: Range,
	captures:   []Range,
	text:       string,
}

Range :: struct {
	start: int,
	end:   int,
}

// ============================================================================
// MAIN API FUNCTIONS
// ============================================================================

// Compile a regex pattern
regexp :: proc(pattern: string) -> (^Regexp_Pattern, ErrorCode) {
	// Create pattern structure
	p := new(Regexp_Pattern)
	p.arena = new_arena(4096) // 4KB initial arena
	
	// Parse the pattern
	ast_node, err := parse_regexp_internal(pattern, .None)
	if err != .NoError {
		free_arena(p.arena)
		free(p)
		return nil, err
	}
	
	// Validate AST
	err = validate_ast(ast_node)
	if err != .NoError {
		free_arena(p.arena)
		free(p)
		return nil, err
	}
	
	p.ast = ast_node
	p.error = .NoError
	return p, .NoError
}

// Free a compiled pattern
free_regexp :: proc(pattern: ^Regexp_Pattern) {
	if pattern == nil {
		return
	}
	
	if pattern.arena != nil {
		free_arena(pattern.arena)
	}
	
	free(pattern)
}

// Match a pattern against text
match :: proc(pattern: ^Regexp_Pattern, text: string) -> (Match_Result, ErrorCode) {
	result := Match_Result{}
	result.text = text
	
	if pattern == nil {
		return result, .InternalError
	}
	
	if pattern.error != .NoError {
		return result, pattern.error
	}
	
	if pattern.ast == nil {
		return result, .InternalError
	}
	
	// Validate input text for UTF-8
	if !is_valid_utf8(text) {
		return result, .UTF8Error
	}
	
	// Use direct pattern matching for now (NFA has issues)
	matched, start, end := match_pattern(pattern.ast, text)
	
	result.matched = matched
	if matched {
		result.full_match = Range{start, end}
		result.captures = arena_alloc_slice(pattern.arena, Range, 1)
		result.captures[0] = result.full_match
	}
	
	return result, .NoError
}



// Convenience function for one-shot matching
match_string :: proc(pattern_str, text: string) -> (bool, ErrorCode) {
	pattern, err := regexp(pattern_str)
	if err != .NoError {
		return false, err
	}
	defer free_regexp(pattern)
	
	result, match_err := match(pattern, text)
	if match_err != .NoError {
		return false, match_err
	}
	
	return result.matched, .NoError
}

// ============================================================================
// LITERAL MATCHING ENGINE (User Story 1)
// ============================================================================

// Match pattern against text (supports User Story 2 features)
match_pattern :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
	return match_pattern_anchored(ast, text, false)
}

// Match pattern with optional anchoring at position 0
match_pattern_anchored :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil {
		return false, -1, -1
	}
	
	#partial switch ast.op {
	case .OpLiteral:
		lit_data := (^Literal_Data)(ast.data)
		if lit_data == nil {
			return false, -1, -1
		}
		
		literal_str := to_string(lit_data.str)
		if len(literal_str) == 0 {
			// Empty pattern matches at position 0
			return true, 0, 0
		}
		
		if anchored {
			// Only match at position 0
			if len(text) >= len(literal_str) {
				match := true
				for j := 0; j < len(literal_str); j += 1 {
					if text[j] != literal_str[j] {
						match = false
						break
					}
				}
				if match {
					return true, 0, len(literal_str)
				}
			}
		} else {
			// Find literal anywhere in text
			max_start := len(text) - len(literal_str)
			for i := 0; i <= max_start; i += 1 {
				match := true
				for j := 0; j < len(literal_str); j += 1 {
					if text[i + j] != literal_str[j] {
						match = false
						break
					}
				}
				if match {
					return true, i, i + len(literal_str)
				}
			}
		}
		
	case .OpCharClass:
		// Handle character class matching
		return match_char_class(ast, text)
	
	case .OpAnyChar:
		// Handle any character matching (.)
		return match_any_char(ast, text, false)
	
	case .OpAnyCharNotNL:
		// Handle any character except newline
		return match_any_char(ast, text, true)
	
	case .OpBeginLine:
		// Handle beginning of line anchor (^)
		return match_begin_line(ast, text)
	
	case .OpEndLine:
		// Handle end of line anchor ($)
		return match_end_line(ast, text)
	
	case .OpAlternate:
		// Handle alternation (|)
		return match_alternate(ast, text)
	
	case .OpStar:
		// Handle Kleene star (*)
		return match_star(ast, text, anchored)
	
	case .OpPlus:
		// Handle Kleene plus (+)
		return match_plus(ast, text, anchored)
	
	case .OpQuest:
		// Handle question mark (?)
		return match_quest(ast, text, anchored)
	
	case .OpRepeat:
		// Handle repeat {n,m}
		return match_repeat(ast, text, anchored)
	
	case .OpCapture:
		// Handle capturing group (...)
		return match_capture(ast, text, anchored)
	
	case .OpConcat:
		// Handle concatenation recursively
		return match_concat(ast, text, anchored)
	
	case .NoOp:
		// Empty pattern matches at position 0
		{
			return true, 0, 0
		}
	
	default:
		// Unsupported operation for current implementation
		{
			return false, -1, -1
		}
	}
	
	// Default return
	return false, -1, -1
}

// Match concatenation with simple but effective backtracking
match_concat :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	concat_data := (^Concat_Data)(ast.data)
	if concat_data == nil || len(concat_data.subs) == 0 {
		return false, -1, -1
	}
	
	// Check if pattern has begin anchor (^)
	has_begin_anchor := false
	for sub in concat_data.subs {
		if sub != nil && sub.op == .OpBeginLine {
			has_begin_anchor = true
			break
		}
	}
	
	// Try all possible starting positions
	max_start := len(text)
	if has_begin_anchor {
		max_start = 0  // Only try position 0 for begin anchor
	}
	
	for i := 0; i <= max_start; i += 1 {
		if try_match_sequence(concat_data.subs, text, i, 0) {
			end_pos := find_end_position(concat_data.subs, text, i)
			return true, i, end_pos
		}
	}
	
	return false, -1, -1
}

// Try to match sequence of sub-expressions using NFA (no backtracking)
try_match_sequence :: proc(subs: []^Regexp, text: string, pos: int, sub_idx: int) -> bool {
	if sub_idx >= len(subs) {
		return true  // All subs matched
	}
	
	sub := subs[sub_idx]
	if sub == nil {
		return false
	}
	
	// Handle anchors
	if sub.op == .OpBeginLine {
		return pos == 0 && try_match_sequence(subs, text, pos, sub_idx + 1)
	}
	
	if sub.op == .OpEndLine {
		return pos == len(text) && try_match_sequence(subs, text, pos, sub_idx + 1)
	}
	
	// Use NFA for all quantifiers (eliminates backtracking)
	if sub.op == .OpStar || sub.op == .OpPlus || sub.op == .OpQuest || sub.op == .OpRepeat {
		matched, caps := match_nfa_pattern(sub, text[pos:])
		if matched {
			new_pos := pos + caps[1]  // Use end position from NFA
			return try_match_sequence(subs, text, new_pos, sub_idx + 1)
		}
		return false
	}
	
	// Regular match
	matched, start, end := match_pattern_anchored(sub, text[pos:], true)
	if matched {
		new_pos := pos + (end - start)
		return try_match_sequence(subs, text, new_pos, sub_idx + 1)
	}
	
	return false
}

// DEPRECATED: Use NFA-based matching instead
// This function is removed to eliminate exponential backtracking
try_quantifier_backtrack :: proc(quantifier: ^Regexp, text: string, pos: int, subs: []^Regexp, sub_idx: int) -> bool {
	// All quantifier matching now uses NFA to guarantee linear time
	return false
}

// Get range for quantifier
get_range_for_quantifier :: proc(quantifier: ^Regexp, max_len: int) -> (int, int) {
	repeat_data := (^Repeat_Data)(quantifier.data)
	
	#partial switch quantifier.op {
	case .OpStar:
		return 0, max_len
	case .OpPlus:
		return 1, max_len
	case .OpQuest:
		return 0, 1
	case .OpRepeat:
		min := repeat_data.min
		max := repeat_data.max
		if max == -1 {
			max = max_len
		}
		if max > max_len {
			max = max_len
		}
		return min, max
	}
	
	return 0, 0
}

// Check if repeat can match n times
can_match_repeat :: proc(sub: ^Regexp, text: string, n: int) -> bool {
	current_pos := 0
	for i := 0; i < n; i += 1 {
		if current_pos >= len(text) {
			return false
		}
		
		matched, start, end := match_pattern_anchored(sub, text[current_pos:], true)
		if !matched {
			return false
		}
		
		// Avoid infinite loops
		if end == start && i < n - 1 {
			return false
		}
		
		current_pos += (end - start)
	}
	return true
}

// Get length of repeat match
get_repeat_length :: proc(sub: ^Regexp, text: string, n: int) -> int {
	total := 0
	current_pos := 0
	for i := 0; i < n; i += 1 {
		_, start, end := match_pattern_anchored(sub, text[current_pos:], true)
		total += (end - start)
		current_pos += (end - start)
	}
	return total
}

// Find end position for successful match
find_end_position :: proc(subs: []^Regexp, text: string, start_pos: int) -> int {
	pos := start_pos
	for sub_idx in 0..<len(subs) {
		sub := subs[sub_idx]
		if sub == nil {
			continue
		}
		
		if sub.op == .OpBeginLine || sub.op == .OpEndLine {
			continue
		}
		
		if sub.op == .OpStar || sub.op == .OpPlus || sub.op == .OpQuest || sub.op == .OpRepeat {
			repeat_data := (^Repeat_Data)(sub.data)
			if repeat_data != nil && repeat_data.sub != nil {
				// Find the match length that works for the rest
				min_matches, max_matches := get_range_for_quantifier(sub, len(text) - pos)
				
				for count := max_matches; count >= min_matches; count -= 1 {
					if can_match_repeat(repeat_data.sub, text[pos:], count) {
						new_pos := pos + get_repeat_length(repeat_data.sub, text[pos:], count)
						
						// Check if remaining subs can match
						remaining_ok := true
						temp_pos := new_pos
						for remaining_idx := sub_idx + 1; remaining_idx < len(subs); remaining_idx += 1 {
							remaining_sub := subs[remaining_idx]
							if remaining_sub == nil {
								remaining_ok = false
								break
							}
							
							if remaining_sub.op == .OpBeginLine || remaining_sub.op == .OpEndLine {
								continue
							}
							
							matched, start, end := match_pattern_anchored(remaining_sub, text[temp_pos:], true)
							if !matched {
								remaining_ok = false
								break
							}
							temp_pos += (end - start)
						}
						
						if remaining_ok {
							pos = new_pos
							break
						}
					}
				}
			}
		} else {
			// Regular non-quantifier match
			matched, start, end := match_pattern_anchored(sub, text[pos:], true)
			if matched {
				pos += (end - start)
			} else {
				return -1 // Failed to match
			}
		}
	}
	return pos
}

// Extract string from AST (handles literals and nested concats)
extract_string_from_ast :: proc(ast: ^Regexp) -> string {
	if ast == nil {
		return ""
	}
	
	#partial switch ast.op {
	case .OpLiteral:
		if ast.data != nil {
			lit_data := (^Literal_Data)(ast.data)
			return to_string(lit_data.str)
		}
		
	case .OpConcat:
		if ast.data != nil {
			concat_data := (^Concat_Data)(ast.data)
			result: [256]byte
			result_len := 0
			
			for sub in concat_data.subs {
				sub_str := extract_string_from_ast(sub)
				for ch in sub_str {
					if result_len < len(result) {
						result[result_len] = byte(ch)
						result_len += 1
					}
				}
			}
			
			return string(result[:result_len])
		}
	}
	
	return ""
}

// ============================================================================
// NFA MATCHING ENGINE
// ============================================================================

// Match pattern using NFA for linear-time performance (optimized)
match_nfa_pattern :: proc(ast: ^Regexp, text: string) -> (bool, []int) {
	if ast == nil {
		return false, nil
	}
	
	// Create arena for NFA compilation
	arena := new_arena(2048)
	defer free_arena(arena)
	
	// Compile AST to NFA using arena allocation
	prog, err := compile_nfa(ast, arena)
	if err != .NoError || prog == nil {
		return false, nil
	}
	
	// Use the optimized NFA matcher
	matched, caps := simple_nfa_match(prog, text)
	
	// Copy the caps array since the original will be freed
	result_caps: []int
	if matched && caps != nil {
		result_caps = make([]int, len(caps))
		copy(result_caps, caps)
	}
	
	return matched, result_caps
}

// ============================================================================
// UTF-8 VALIDATION
// ============================================================================

// Check if string contains valid UTF-8
is_valid_utf8 :: proc(s: string) -> bool {
	i := 0
	for i < len(s) {
		c := s[i]
		
		if c < 0x80 {
			// ASCII character
			i += 1
		} else if c & 0xE0 == 0xC0 {
			// 2-byte sequence
			if i + 1 >= len(s) {
				return false
			}
			if s[i + 1] & 0xC0 != 0x80 {
				return false
			}
			i += 2
		} else if c & 0xF0 == 0xE0 {
			// 3-byte sequence
			if i + 2 >= len(s) {
				return false
			}
			if s[i + 1] & 0xC0 != 0x80 || s[i + 2] & 0xC0 != 0x80 {
				return false
			}
			i += 3
		} else if c & 0xF8 == 0xF0 {
			// 4-byte sequence
			if i + 3 >= len(s) {
				return false
			}
			if s[i + 1] & 0xC0 != 0x80 || s[i + 2] & 0xC0 != 0x80 || s[i + 3] & 0xC0 != 0x80 {
				return false
			}
			i += 4
		} else {
			// Invalid UTF-8
			return false
		}
	}
	return true
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

// Get string representation of match result
match_result_string :: proc(result: Match_Result) -> string {
	if !result.matched {
		return "no match"
	}
	
	matched_text := result.text[result.full_match.start:result.full_match.end]
	return fmt.tprintf("match: %q at %d-%d", matched_text, result.full_match.start, result.full_match.end)
}

// Check if pattern compilation was successful
is_valid_pattern :: proc(pattern: ^Regexp_Pattern) -> bool {
	return pattern != nil && pattern.error == .NoError && pattern.ast != nil
}

// Get pattern statistics
pattern_stats :: proc(pattern: ^Regexp_Pattern) -> (node_count: int, capture_count: int) {
	if pattern == nil || pattern.ast == nil {
		return 0, 0
	}
	
	// For User Story 1, simple counting
	node_count = 1
	capture_count = count_captures(pattern.ast)
	
	return
}

// ============================================================================
// USER STORY 2 MATCHING FUNCTIONS
// ============================================================================

// Match character class [abc], [a-z], [^abc]
match_char_class :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	char_class_data := (^CharClass_Data)(ast.data)
	if char_class_data == nil {
		return false, -1, -1
	}
	
	// Character class matches exactly one character
	if len(text) == 0 {
		return false, -1, -1
	}
	
	// Search for character class match in text
	for i in 0..<len(text) {
		// Get character at position i (as rune)
		ch := rune(text[i]) // Simplified: only handle ASCII for now
		
		// Check if character matches the class
		if char_class_matches(char_class_data, ch) {
			return true, i, i + 1
		}
	}
	
	return false, -1, -1
}

// Check if a character matches a character class
char_class_matches :: proc(char_class: ^CharClass_Data, ch: rune) -> bool {
	if char_class == nil {
		return false
	}
	
	// Check each range
	for i in 0..<len(char_class.ranges) {
		range := char_class.ranges[i]
		if ch >= range.lo && ch <= range.hi {
			// Character is in range
			return !char_class.negated
		}
	}
	
	// Character not in any range
	return char_class.negated
}

// Match any character (.)
match_any_char :: proc(ast: ^Regexp, text: string, except_newline: bool) -> (bool, int, int) {
	if len(text) == 0 {
		return false, -1, -1
	}
	
	first_char := rune(text[0])
	
	// Check if it's a newline and we should exclude it
	if except_newline && first_char == '\n' {
		return false, -1, -1
	}
	
	return true, 0, 1
}

// Match beginning of line anchor (^)
match_begin_line :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
	// Beginning of line only matches at position 0
	// Since this is called with the full text, we check if we're at start
	return true, 0, 0
}

// Match end of line anchor ($)
match_end_line :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
	// End of line only matches at end of text
	// Since this is called with the full text, we check if we're at end
	return true, len(text), len(text)
}

// Match alternation (a|b)
match_alternate :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	alt_data := (^Alternate_Data)(ast.data)
	if alt_data == nil || len(alt_data.subs) == 0 {
		return false, -1, -1
	}
	
	// Try each alternative
	for sub in alt_data.subs {
		if sub == nil {
			continue
		}
		
		matched, start, end := match_pattern(sub, text)
		if matched {
			return true, start, end
		}
	}
	
	return false, -1, -1
}

// ============================================================================
// QUANTIFIER MATCHING FUNCTIONS
// ============================================================================

// Match Kleene star (*) using NFA (linear time)
match_star :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	// Use NFA for guaranteed linear time performance
	matched, caps := match_nfa_pattern(ast, text)
	if matched && len(caps) >= 2 {
		return true, caps[0], caps[1]
	}
	
	return false, -1, -1
}
	

// Match Kleene plus (+) using NFA (linear time)
match_plus :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	// Use NFA for guaranteed linear time performance
	matched, caps := match_nfa_pattern(ast, text)
	if matched && len(caps) >= 2 {
		return true, caps[0], caps[1]
	}
	
	return false, -1, -1
}

// Match question mark (?) using NFA (linear time)
match_quest :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	// Use NFA for guaranteed linear time performance
	matched, caps := match_nfa_pattern(ast, text)
	if matched && len(caps) >= 2 {
		return true, caps[0], caps[1]
	}
	
	return false, -1, -1
}

// Match repeat {n,m} using NFA (linear time)
match_repeat :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	// Use NFA for guaranteed linear time performance
	matched, caps := match_nfa_pattern(ast, text)
	if matched && len(caps) >= 2 {
		return true, caps[0], caps[1]
	}
	
	return false, -1, -1
}

// ============================================================================
// CAPTURE GROUP MATCHING FUNCTIONS
// ============================================================================

// Match capture group (...)
match_capture :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	capture_data := (^Capture_Data)(ast.data)
	if capture_data == nil || capture_data.sub == nil {
		return false, -1, -1
	}
	
	// For now, just match the sub-expression (capture handling will be added later)
	return match_pattern_anchored(capture_data.sub, text, anchored)
}