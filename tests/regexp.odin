package regexp

// ============================================================================
// MAIN REGEXP ENGINE - RE2-compatible implementation in Odin
// ============================================================================
// This file contains the complete regex engine including:
// • Public API (regexp, match, free_regexp)
// • Literal matching engine (User Story 1)
// • NFA-based matching for complex patterns
// • UTF-8 validation and character class handling
// • Quantifier and capture group support
// • ASCII fast path optimizations
// ============================================================================

import "core:fmt"

// Initialize the regexp package with performance optimizations
init_regexp_package :: proc() {
	// Initialize ASCII classification table for fast path
	init_ascii_classification()
	
	// Initialize SIMD support if available
	init_simd_support()
}

// ============================================================================
// REMOVED RECURSION DEPTH MONITORING
// ============================================================================
// Recursion depth monitoring has been removed along with all recursive backtracking
// functions. The NFA engine uses iterative algorithms that don't require recursion
// depth tracking or stack overflow protection.

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
@public
regexp :: proc(pattern: string) -> (^Regexp_Pattern, ErrorCode) {
	// Initialize performance optimizations
	init_regexp_package()
	
	// Create pattern structure
	p := new(Regexp_Pattern)
	p.arena = new_arena(4096) // 4KB initial arena
	
	// Parse the pattern (returns in temporary arena)
	ast_node, err := parse_regexp_internal(pattern, .None)
	if err != .NoError {
		free_arena(p.arena)
		free(p)
		return nil, err
	}
	
	// Clone AST to permanent arena
	cloned_ast := clone_node(ast_node, p.arena)
	if cloned_ast == nil {
		free_arena(p.arena)
		free(p)
		return nil, .InternalError
	}

	// Validate cloned AST
	err = validate_ast(cloned_ast)
	if err != .NoError {
		free_arena(p.arena)
		free(p)
		return nil, err
	}
	
	p.ast = cloned_ast
	p.error = .NoError
	return p, .NoError
}

// Free a compiled pattern
@public
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
	
	// Use NFA-based matching for linear-time performance guarantee
	matched, caps := match_nfa_pattern(pattern.ast, text)
	start := 0
	end := 0
	if matched && len(caps) >= 2 {
		start = caps[0]
		end = caps[1]
	}
	
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

// REMOVED: match_pattern and match_pattern_anchored functions
// These recursive backtracking functions have been removed to ensure
// linear-time performance guarantee. All matching now uses NFA-based
// algorithms through match_nfa_pattern function.

// REMOVED: match_concat function
// This concatenation matching function has been removed as part of
// eliminating recursive backtracking. Concatenation is now handled
// by the NFA engine for linear-time performance.

// REMOVED: try_match_sequence function
// This sequence matching function has been removed as part of
// eliminating recursive backtracking. Sequence matching is now
// handled entirely by the NFA engine.

// REMOVED: try_quantifier_backtrack function
// This quantifier backtrack function has been removed as part of
// eliminating recursive backtracking. All quantifier matching now
// uses the NFA engine for guaranteed linear-time performance.

// REMOVED: get_range_for_quantifier, can_match_repeat, get_repeat_length functions
// These helper functions were used by recursive backtracking and have been removed.
// Quantifier range calculations are now handled by the NFA compilation process.

// REMOVED: find_end_position function
// This function was used by recursive backtracking to calculate match positions.
// Position calculations are now handled by the NFA engine's capture groups.

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
@public
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
	
	// ASCII fast path optimization
	if ch >= 0 && ch < 128 {
		return char_class_matches_ascii_fast(char_class, ch)
	}
	
	// Unicode fallback for non-ASCII characters
	return char_class_matches_unicode(char_class, ch)
}

// Fast ASCII character class matching using O(1) classification
char_class_matches_ascii_fast :: proc(char_class: ^CharClass_Data, ch: rune) -> bool {
	// Initialize ASCII classification if not already done
	// This should be called once at program startup
	when false {
		init_ascii_classification()
	}
	
	// Special case: simple ASCII ranges can be optimized
	if len(char_class.ranges) == 1 {
		range := char_class.ranges[0]
		// Check if it's a simple ASCII range like [a-z], [A-Z], [0-9]
		if range.lo >= 0 && range.hi < 128 {
			if ch >= range.lo && ch <= range.hi {
				return !char_class.negated
			} else {
				return char_class.negated
			}
		}
	}
	
	// Special case: common ASCII character classes
	if len(char_class.ranges) == 2 {
		// Check for [a-zA-Z] pattern
		if char_class.ranges[0].lo == 'a' && char_class.ranges[0].hi == 'z' &&
		   char_class.ranges[1].lo == 'A' && char_class.ranges[1].hi == 'Z' {
			matched := is_ascii_letter(ch)
			return char_class.negated ? !matched : matched
		}
		
		// Check for [0-9] pattern
		if char_class.ranges[0].lo == '0' && char_class.ranges[0].hi == '9' &&
		   len(char_class.ranges) == 1 {
			matched := is_ascii_number(ch)
			return char_class.negated ? !matched : matched
		}
	}
	
	// For ASCII word characters [a-zA-Z0-9_]
	if len(char_class.ranges) == 3 {
		if char_class.ranges[0].lo == 'a' && char_class.ranges[0].hi == 'z' &&
		   char_class.ranges[1].lo == 'A' && char_class.ranges[1].hi == 'Z' &&
		   char_class.ranges[2].lo == '0' && char_class.ranges[2].hi == '9' {
			matched := is_ascii_word_char(ch)
			return char_class.negated ? !matched : matched
		}
	}
	
	// Fallback to range checking for ASCII (still faster than Unicode)
	for i in 0..<len(char_class.ranges) {
		range := char_class.ranges[i]
		if ch >= range.lo && ch <= range.hi {
			return !char_class.negated
		}
	}
	return char_class.negated
}

// Unicode character class matching (fallback)
char_class_matches_unicode :: proc(char_class: ^CharClass_Data, ch: rune) -> bool {
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

// Match beginning of line anchor (^) - position-aware
match_begin_line :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
	// Beginning of line anchor matches at the beginning of the text
	// This function is called with the current text slice, so we need to
	// determine if this slice is at the beginning of the original text
	
	// For now, assume we're at position 0 (this needs context in concat matching)
	// In a full implementation, we'd track the absolute position in the original text
	
	return true, 0, 0
}

// Match end of line anchor ($) - position-aware
match_end_line :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
	// End of line anchor matches at the end of the text or before newline
	// This function is called with the current text slice
	
	// Check if we're at the end of the current text slice
	text_end := len(text)
	
	// Also check if we're before a newline (multiline mode support)
	if text_end > 0 && text[text_end - 1] == '\n' {
		// Position before the newline is also a valid end-of-line
		return true, text_end - 1, text_end - 1
	}
	
	// Regular end of text
	return true, text_end, text_end
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
		
		// Use NFA matching for each alternative
		matched, caps := match_nfa_pattern(sub, text)
		start := 0
		end := 0
		if matched && len(caps) >= 2 {
			start = caps[0]
			end = caps[1]
		}
		if matched {
			return true, start, end
		}
	}
	
	return false, -1, -1
}

// ============================================================================
// REMOVED QUANTIFIER MATCHING FUNCTIONS
// ============================================================================
// All quantifier matching functions (match_star, match_plus, match_quest, match_repeat)
// have been removed to eliminate recursive backtracking. Quantifier matching is now
// handled entirely by the NFA engine, which provides guaranteed linear-time performance.

// ============================================================================
// CAPTURE GROUP MATCHING FUNCTIONS
// ============================================================================

// REMOVED: match_capture function
// Capture group matching has been removed as part of eliminating recursive backtracking.
// Capture group handling is now managed by the NFA engine's capture group mechanism.

// ============================================================================
// DEBUG FUNCTIONS
// ============================================================================

// Debug compilation process step by step
debug_compilation :: proc(pattern_str: string) -> bool {
	fmt.printf("=== 调试编译过程: '%s' ===\n", pattern_str)

	// 步骤 1: 调用 parse_regexp_internal
	fmt.println("步骤 1: 调用 parse_regexp_internal")
	ast_node, err := parse_regexp_internal(pattern_str, .None)
	if err != .NoError {
		fmt.printf("parse_regexp_internal 失败: %v\n", err)
		return false
	}

	if ast_node == nil {
		fmt.println("parse_regexp_internal 返回 nil AST")
		return false
	}

	fmt.println("parse_regexp_internal 成功")

	// 步骤 2: 验证原始 AST
	fmt.println("步骤 2: 验证原始 AST")
	validation_err := validate_ast(ast_node)
	if validation_err != .NoError {
		fmt.printf("原始 AST 验证失败: %v\n", validation_err)
		return false
	}
	fmt.println("原始 AST 验证成功")

	// 步骤 3: 克隆 AST
	fmt.println("步骤 3: 克隆 AST")
	new_arena := new_arena(4096)
	defer free_arena(new_arena)

	cloned_ast := clone_node(ast_node, new_arena)
	if cloned_ast == nil {
		fmt.println("AST 克隆失败")
		return false
	}
	fmt.println("AST 克隆成功")

	// 步骤 4: 验证克隆的 AST
	fmt.println("步骤 4: 验证克隆的 AST")
	validation_err = validate_ast(cloned_ast)
	if validation_err != .NoError {
		fmt.printf("克隆 AST 验证失败: %v\n", validation_err)
		return false
	}
	fmt.println("克隆 AST 验证成功")

	fmt.println("=== 所有步骤成功 ===")
	return true
}