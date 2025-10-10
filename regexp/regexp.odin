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
	
	// Use literal matching for User Story 1
	matched, start, end := match_literal(pattern.ast, text)
	
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

// Match literal pattern against text
match_literal :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
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
		
		// Find literal in text
		for i in 0..<(len(text) - len(literal_str) + 1) {
			match := true
			for j in 0..<len(literal_str) {
				if text[i + j] != literal_str[j] {
					match = false
					break
				}
			}
			if match {
				return true, i, i + len(literal_str)
			}
		}
		
		return false, -1, -1
	
	case .NoOp:
		// Empty pattern matches at position 0
		{
			return true, 0, 0
		}
	
	default:
		// For User Story 1, only handle literals and empty patterns
		{
			return false, -1, -1
		}
	}
	
	// Default return
	return false, -1, -1
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