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
	
	// Use pattern matching for User Story 2
	matched, start, end := match_pattern(pattern.ast, text)
	
	result.matched = matched
	if matched {
		result.full_match = Range{start, end}
		// No captures for simple literals
		result.captures = make([]Range, 1)
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

// Match concatenation by sequentially matching all sub-expressions
match_concat :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	concat_data := (^Concat_Data)(ast.data)
	if concat_data == nil || len(concat_data.subs) == 0 {
		return false, -1, -1
	}
	
	// Special handling for patterns with anchors
	has_begin_anchor := false
	has_end_anchor := false
	
	for sub in concat_data.subs {
		if sub != nil {
			if sub.op == .OpBeginLine {
				has_begin_anchor = true
			}
			if sub.op == .OpEndLine {
				has_end_anchor = true
			}
		}
	}
	
	// If pattern has anchors, restrict matching positions
	start_pos := 0
	end_pos := len(text)
	
	if has_begin_anchor {
		start_pos = 0  // Can only start at position 0
	}
	if has_end_anchor {
		end_pos = 0    // Can only end at len(text)
	}
	
	// For patterns with begin anchor, only try position 0
	if has_begin_anchor {
		i := 0
		current_pos := i
		total_match := true
		
		// Try to match each sub-expression sequentially
		for sub in concat_data.subs {
			if sub == nil {
				total_match = false
				break
			}
			
			// Special handling for anchors
			if sub.op == .OpBeginLine {
				// Already at position 0, zero-width match
				continue
			}
			
			if sub.op == .OpEndLine {
				if current_pos != len(text) {
					total_match = false
					break
				}
				// Zero-width match, don't advance position
				continue
			}
			
			// Match this sub-expression at the current position (anchored)
			sub_matched, sub_start, sub_end := match_pattern_anchored(sub, text[current_pos:], true)
			if !sub_matched {
				total_match = false
				break
			}
			
			// Advance position by the width of this match
			match_width := sub_end - sub_start
			current_pos += match_width
		}
		
		if total_match {
			// Successful match of all sub-expressions
			return true, i, current_pos
		}
	} else {
		// No begin anchor, try all positions
		max_start := len(text)
		for i := 0; i <= max_start; i += 1 {
			current_pos := i
			total_match := true
			
			// Try to match each sub-expression sequentially
			for sub in concat_data.subs {
				if sub == nil {
					total_match = false
					break
				}
				
				// Special handling for end anchor
				if sub.op == .OpEndLine {
					if current_pos != len(text) {
						total_match = false
						break
					}
					// Zero-width match, don't advance position
					continue
				}
				
				// Match this sub-expression at the current position (anchored)
				sub_matched, sub_start, sub_end := match_pattern_anchored(sub, text[current_pos:], true)
				if !sub_matched {
					total_match = false
					break
				}
				
				// Advance position by the width of this match
				current_pos += (sub_end - sub_start)
			}
			
			if total_match {
				// Successful match of all sub-expressions
				return true, i, current_pos
			}
		}
	}
	
	return false, -1, -1
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
	
	// Get first character from text (as rune)
	first_char := rune(text[0]) // Simplified: only handle ASCII for now
	
	// Check if character matches the class
	matches := char_class_matches(char_class_data, first_char)
	
	if matches {
		return true, 0, 1
	}
	
	return false, -1, -1
}

// Check if a character matches a character class
char_class_matches :: proc(char_class: ^CharClass_Data, ch: rune) -> bool {
	if char_class == nil {
		return false
	}
	
	// Check each range
	for range in char_class.ranges {
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
	// This should only be called when actually at position 0
	return true, 0, 0
}

// Match end of line anchor ($)
match_end_line :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
	// End of line only matches at end of text
	// This should only be called when actually at end of text
	return true, 0, 0
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

// Match Kleene star (*)
match_star :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	repeat_data := (^Repeat_Data)(ast.data)
	if repeat_data == nil || repeat_data.sub == nil {
		return false, -1, -1
	}
	
	// Star matches 0 or more occurrences
	// Try to match as many as possible, then backtrack
	
	max_matches := len(text) + 1 // Maximum possible matches
	best_match := -1
	
	// Try from max matches down to 0
	for count := max_matches; count >= 0; count -= 1 {
		current_pos := 0
		all_matched := true
		
		// Try to match 'count' occurrences
		for i := 0; i < count; i += 1 {
			sub_matched, sub_start, sub_end := match_pattern_anchored(repeat_data.sub, text[current_pos:], true)
			if !sub_matched {
				all_matched = false
				break
			}
			
			// For zero-width matches, avoid infinite loops
			if sub_end == sub_start {
				all_matched = false
				break
			}
			
			current_pos += (sub_end - sub_start)
			if current_pos > len(text) {
				all_matched = false
				break
			}
		}
		
		if all_matched {
			best_match = current_pos
			break
		}
	}
	
	if best_match >= 0 {
		return true, 0, best_match
	}
	
	return false, -1, -1
}

// Match Kleene plus (+)
match_plus :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	repeat_data := (^Repeat_Data)(ast.data)
	if repeat_data == nil || repeat_data.sub == nil {
		return false, -1, -1
	}
	
	// Plus matches 1 or more occurrences
	// First match one occurrence, then try to match as many more as possible
	
	// Match first occurrence (required)
	first_matched, first_start, first_end := match_pattern_anchored(repeat_data.sub, text, true)
	if !first_matched {
		return false, -1, -1
	}
	
	// For zero-width first match, just return it
	if first_end == first_start {
		return true, first_start, first_end
	}
	
	current_pos := first_end
	
	// Try to match additional occurrences greedily
	test_pos := current_pos
	for {
		sub_matched, sub_start, sub_end := match_pattern_anchored(repeat_data.sub, text[test_pos:], true)
		if !sub_matched {
			break
		}
		
		// For zero-width matches, avoid infinite loops
		if sub_end == sub_start {
			break
		}
		
		test_pos += (sub_end - sub_start)
		if test_pos > len(text) {
			break
		}
	}
	
	// Return the full match
	return true, first_start, test_pos
}

// Match question mark (?)
match_quest :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	repeat_data := (^Repeat_Data)(ast.data)
	if repeat_data == nil || repeat_data.sub == nil {
		return false, -1, -1
	}
	
	// Question mark matches 0 or 1 occurrence
	// Try to match one occurrence first
	sub_matched, sub_start, sub_end := match_pattern_anchored(repeat_data.sub, text, true)
	if sub_matched {
		return true, sub_start, sub_end
	}
	
	// If no match, return empty match (0 occurrences)
	return true, 0, 0
}

// Match repeat {n,m}
match_repeat :: proc(ast: ^Regexp, text: string, anchored: bool) -> (bool, int, int) {
	if ast == nil || ast.data == nil {
		return false, -1, -1
	}
	
	repeat_data := (^Repeat_Data)(ast.data)
	if repeat_data == nil || repeat_data.sub == nil {
		return false, -1, -1
	}
	
	min := repeat_data.min
	max := repeat_data.max
	if max == -1 {
		max = len(text) + 1 // Unlimited
	}
	
	// Clamp max to reasonable value
	if max > len(text) + 1 {
		max = len(text) + 1
	}
	
	// Try to match from max down to min occurrences
	for count := max; count >= min; count -= 1 {
		current_pos := 0
		all_matched := true
		
		// Try to match 'count' occurrences
		for i := 0; i < count; i += 1 {
			sub_matched, sub_start, sub_end := match_pattern_anchored(repeat_data.sub, text[current_pos:], true)
			if !sub_matched {
				all_matched = false
				break
			}
			
			// For zero-width matches, avoid infinite loops
			if sub_end == sub_start && i < count - 1 {
				all_matched = false
				break
			}
			
			current_pos += (sub_end - sub_start)
			if current_pos > len(text) {
				all_matched = false
				break
			}
		}
		
		if all_matched {
			return true, 0, current_pos
		}
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