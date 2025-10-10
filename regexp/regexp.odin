package regexp

// Main public API for RE2-compatible regular expression engine in Odin
// This file provides the core interface functions

import "core:testing"

// ============================================================================
// ERROR HANDLING (from errors.odin)
// ============================================================================

// Error codes matching RE2's error semantics
ErrorCode :: enum {
	NoError,
	ParseError,              // Invalid regex syntax
	MemoryError,             // Out of memory
	InternalError,           // Internal logic error
	UTF8Error,              // Invalid UTF-8 encoding
	TooComplex,             // Pattern too complex for budget
	InvalidCapture,         // Invalid capture group reference
	ErrorUnexpectedParen,   // Unexpected parenthesis
	ErrorTrailingBackslash, // Trailing backslash
	ErrorBadEscape,         // Invalid escape sequence
	ErrorMissingParen,      // Missing closing parenthesis
	ErrorMissingBracket,    // Missing closing bracket
	ErrorInvalidRepeat,     // Invalid repeat operator
	ErrorInvalidRepeatSize, // Invalid repeat size
	ErrorInvalidCharacterClass, // Invalid character class
	ErrorInvalidPerlOp,     // Invalid Perl operator
	ErrorInvalidUTF8,       // Invalid UTF-8 sequence
}

// Error context information for detailed error reporting
Error_Info :: struct {
	code:     ErrorCode,
	pos:      int,        // Position in pattern where error occurred
	message:  string,     // Human-readable error message
	pattern:  string,     // Original pattern (for context)
}

// Create a new error info structure
make_error :: proc(code: ErrorCode, pos: int, message: string, pattern: string) -> Error_Info {
	return Error_Info{code, pos, message, pattern}
}

// Get string representation of error code
error_string :: proc(code: ErrorCode) -> string {
	switch code {
	case .NoError:
		return "no error"
	case .ParseError:
		return "parse error"
	case .MemoryError:
		return "out of memory"
	case .InternalError:
		return "internal error"
	case .UTF8Error:
		return "invalid UTF-8"
	case .TooComplex:
		return "pattern too complex"
	case .InvalidCapture:
		return "invalid capture reference"
	case .ErrorUnexpectedParen:
		return "unexpected parenthesis"
	case .ErrorTrailingBackslash:
		return "trailing backslash"
	case .ErrorBadEscape:
		return "bad escape sequence"
	case .ErrorMissingParen:
		return "missing parenthesis"
	case .ErrorMissingBracket:
		return "missing bracket"
	case .ErrorInvalidRepeat:
		return "invalid repeat"
	case .ErrorInvalidRepeatSize:
		return "invalid repeat size"
	case .ErrorInvalidCharacterClass:
		return "invalid character class"
	case .ErrorInvalidPerlOp:
		return "invalid Perl operator"
	case .ErrorInvalidUTF8:
		return "invalid UTF-8"
	}
	return "unknown error"
}

// ============================================================================
// MEMORY MANAGEMENT (from memory.odin)
// ============================================================================

// Simple arena allocator for efficient memory management
Arena :: struct {
	data:    []byte,
	offset:  int,
	capacity: int,
}

// Create a new arena with specified initial capacity
new_arena :: proc(capacity: int) -> ^Arena {
	arena := new(Arena)
	arena.data = make([]byte, capacity)
	arena.offset = 0
	arena.capacity = capacity
	return arena
}

// Allocate memory from arena
arena_alloc :: proc(arena: ^Arena, size: int) -> rawptr {
	if arena == nil {
		return nil
	}
	
	if arena.offset + size > arena.capacity {
		// Grow the arena
		new_capacity := arena.capacity * 2
		if new_capacity < arena.offset + size {
			new_capacity = arena.offset + size
		}
		
		new_data := make([]byte, new_capacity)
		copy(new_data, arena.data)
		delete(arena.data)
		arena.data = new_data
		arena.capacity = new_capacity
	}
	
	ptr := &arena.data[arena.offset]
	arena.offset += size
	return ptr
}

// Reset arena to free all allocations
reset_arena :: proc(arena: ^Arena) {
	if arena != nil {
		arena.offset = 0
	}
}

// Free arena memory
free_arena :: proc(arena: ^Arena) {
	if arena != nil {
		delete(arena.data)
		free(arena)
	}
}

// ============================================================================
// AST DEFINITIONS (from ast.odin)
// ============================================================================

// Regular expression operators (matching RE2 exactly)
Regexp_Op :: enum {
	NoOp,           // No operation (empty regex)
	Literal,        // Literal string
	CharClass,      // Character class [a-z]
	AnyChar,        // Any character .
	AnyCharNotNL,   // Any character except newline
	BeginLine,      // Beginning of line ^
	EndLine,        // End of line $
	BeginText,      // Beginning of text \A
	EndText,        // End of text \z
	WordBoundary,   // Word boundary \b
	NoWordBoundary, // Not word boundary \B
	Capture,        // Capturing group ()
	Star,           // Kleene star *
	Plus,           // Kleene plus +
	Quest,          // Question mark ?
	Repeat,         // Repeat {n,m}
	Concat,         // Concatenation
	Alternate,      // Alternation |
}

// Flags for regular expressions
Flags :: enum {
	None,
	NonGreedy     = 1 << 0, // Non-greedy matching
	CaseInsensitive = 1 << 1, // Case insensitive
	DotAll        = 1 << 2, // Dot matches all characters
	MultiLine     = 1 << 3, // Multi-line matching
	Unicode       = 1 << 4, // Unicode support
}

// Parse flags for parser
Parse_Flags :: enum {
	None,
	Literal       = 1 << 0, // Parse as literal
	PerlX         = 1 << 1, // Perl extensions
	PerlClasses   = 1 << 2, // Perl character classes
	UnicodeGroups = 1 << 3, // Unicode character groups
}

// Data for literal string
Literal_Data :: struct {
	value: []byte,
	flags: Flags,
}

// Data for character class
CharClass_Data :: struct {
	ranges: [32]Char_Range,  // Fixed size for simplicity
	count:  int,
	negated: bool,
}

// Character range
Char_Range :: struct {
	lo: rune,
	hi: rune,
}

// Data for capture group
Capture_Data :: struct {
	index: int,
	sub:   ^Regexp,
	name:  string,
}

// Data for repetition
Repeat_Data :: struct {
	min:  int,
	max:  int,
	sub:  ^Regexp,
	flags: Flags,
}

// Data for concatenation and alternation
Concat_Data :: struct {
	subs: []^Regexp,
}

// Main regular expression AST node
Regexp :: struct {
	op:    Regexp_Op,
	flags: Flags,
	data:  rawptr, // Type-specific data
}

// ============================================================================
// PARSER (from parser.odin)
// ============================================================================

// Parser state for tracking position and context
Parser :: struct {
	pattern: string,
	pos:     int,
	arena:   ^Arena,
	flags:   Parse_Flags,
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
		node := alloc_regexp(&parser, .NoOp)
		return node, .NoError
	}
	
	// For User Story 2, handle literals and character classes
	node := parse_alternation(&parser)
	if node == nil {
		return nil, .ParseError
	}
	
	// Clone the node to a new arena since parser arena will be freed
	result_arena := new_arena(4096)
	result := clone_regexp(result_arena, node)
	
	return result, .NoError
}

// Allocate a new regexp node in arena
alloc_regexp :: proc(p: ^Parser, op: Regexp_Op) -> ^Regexp {
	node := (^Regexp)(arena_alloc(p.arena, size_of(Regexp)))
	node.op = op
	node.flags = .None
	node.data = nil
	return node
}

// Parse a literal string
parse_literal :: proc(p: ^Parser) -> ^Regexp {
	// Collect literal characters
	literal_bytes: [dynamic]byte
	for !at_end(p) {
		ch := peek(p)
		
		// Stop at any special regex character (except escape)
		if is_special_char(ch) && ch != '\\' {
			break
		}
		
		// Handle escape sequences
		if ch == '\\' {
			advance(p) // Skip backslash
			if at_end(p) {
				return nil // Trailing backslash
			}
			
			escaped := advance(p)
			// Handle simple escapes
			switch escaped {
			case 'n':
				append(&literal_bytes, '\n')
			case 't':
				append(&literal_bytes, '\t')
			case 'r':
				append(&literal_bytes, '\r')
			case '\\':
				append(&literal_bytes, '\\')
			case '.', '|', '(', ')', '[', ']', '{', '}', '^', '$', '*', '+', '?':
				// Escape special character
				append(&literal_bytes, byte(escaped))
			case:
				// Unknown escape, treat as literal
				append(&literal_bytes, byte(escaped))
			}
		} else {
			append(&literal_bytes, byte(advance(p)))
		}
	}
	
	if len(literal_bytes) == 0 {
		return nil
	}
	
	// Create literal node
	node := alloc_regexp(p, .Literal)
	
	// Allocate literal data
	data := (^Literal_Data)(arena_alloc(p.arena, size_of(Literal_Data)))
	data.value = literal_bytes[:]
	data.flags = .None
	node.data = data
	
	return node
}

// Parse alternation (highest precedence)
parse_alternation :: proc(p: ^Parser) -> ^Regexp {
	// Parse first term
	left := parse_concat(p)
	if left == nil {
		return nil
	}
	
	// Check for alternation
	if !at_end(p) && peek(p) == '|' {
		advance(p) // Skip '|'
		
		// Parse right side
		right := parse_alternation(p)
		if right == nil {
			return nil
		}
		
		// Create alternation node
		node := alloc_regexp(p, .Alternate)
		data := (^Concat_Data)(arena_alloc(p.arena, size_of(Concat_Data)))
		data.subs = make([]^Regexp, 2)
		data.subs[0] = left
		data.subs[1] = right
		node.data = data
		
		return node
	}
	
	return left
}

// Parse concatenation
parse_concat :: proc(p: ^Parser) -> ^Regexp {
	terms: [dynamic]^Regexp
	
	// Parse first term
	first := parse_term(p)
	if first == nil {
		return nil
	}
	append(&terms, first)
	
	// Parse additional terms
	for !at_end(p) {
		ch := peek(p)
		if ch == '|' || ch == ')' {
			break // End of this concatenation
		}
		
		term := parse_term(p)
		if term == nil {
			break
		}
		append(&terms, term)
	}
	
	// If only one term, return it directly
	if len(terms) == 1 {
		return terms[0]
	}
	
	// Create concatenation node
	node := alloc_regexp(p, .Concat)
	data := (^Concat_Data)(arena_alloc(p.arena, size_of(Concat_Data)))
	data.subs = terms[:]
	node.data = data
	
	return node
}

// Parse term (literal, character class, or grouped expression)
parse_term :: proc(p: ^Parser) -> ^Regexp {
	if at_end(p) {
		return nil
	}
	
	ch := peek(p)
	
	// Handle character classes
	if ch == '[' {
		return parse_character_class(p)
	}
	
	// Handle grouped expressions
	if ch == '(' {
		return parse_group(p)
	}
	
	// Handle special characters
	if ch == '.' {
		advance(p) // Skip '.'
		node := alloc_regexp(p, .AnyChar)
		return node
	}
	
	if ch == '^' {
		advance(p) // Skip '^'
		node := alloc_regexp(p, .BeginLine)
		return node
	}
	
	if ch == '$' {
		advance(p) // Skip '$'
		node := alloc_regexp(p, .EndLine)
		return node
	}
	
	// Handle literals
	return parse_literal(p)
}

// Parse character class [abc] or [^abc]
parse_character_class :: proc(p: ^Parser) -> ^Regexp {
	if at_end(p) || peek(p) != '[' {
		return nil
	}
	
	advance(p) // Skip '['
	
	// Check for negation
	negated := false
	if !at_end(p) && peek(p) == '^' {
		advance(p) // Skip '^'
		negated = true
	}
	
// Parse character ranges using a temporary dynamic array
	temp_ranges: [dynamic]Char_Range
	
	for !at_end(p) {
		ch := advance(p)
		
		if ch == ']' {
			break // End of character class
		}
		
		// Handle escape sequences
		if ch == '\\' {
			if at_end(p) {
				return nil // Trailing backslash
			}
			ch = advance(p)
			// Handle escaped characters
			switch ch {
			case 'n': ch = '\n'
			case 't': ch = '\t'
			case 'r': ch = '\r'
			case '\\': ch = '\\'
			case '-': ch = '-'
			case ']': ch = ']'
			}
		}
		
		// Check for range [a-z]
		if !at_end(p) && peek(p) == '-' {
			advance(p) // Skip '-'
			if at_end(p) {
				return nil // Incomplete range
			}
			
			end_ch := advance(p)
			if end_ch == ']' {
				// Treat as literal '-'
				append(&temp_ranges, Char_Range{ch, ch})
				append(&temp_ranges, Char_Range{'-', '-'})
				break
			}
			
			// Handle escape in range end
			if end_ch == '\\' {
				if at_end(p) {
					return nil
				}
				end_ch = advance(p)
				switch end_ch {
				case 'n': end_ch = '\n'
				case 't': end_ch = '\t'
				case 'r': end_ch = '\r'
				case '\\': end_ch = '\\'
				}
			}
			
			// Add range
			if ch <= end_ch {
				append(&temp_ranges, Char_Range{ch, end_ch})
			}
		} else {
			// Single character
			append(&temp_ranges, Char_Range{ch, ch})
		}
	}
	
	// Create character class node
	node := alloc_regexp(p, .CharClass)
	data := (^CharClass_Data)(arena_alloc(p.arena, size_of(CharClass_Data)))
	
	// Copy ranges to fixed-size array
	data.count = min(len(temp_ranges), 32)
	for i in 0..<data.count {
		data.ranges[i] = temp_ranges[i]
	}
	data.negated = negated
	node.data = data
	
	return node
}

// Parse grouped expression (...)
parse_group :: proc(p: ^Parser) -> ^Regexp {
	if at_end(p) || peek(p) != '(' {
		return nil
	}
	
	advance(p) // Skip '('
	
	// Parse alternation inside group
	sub := parse_alternation(p)
	if sub == nil {
		return nil
	}
	
	// Expect closing ')'
	if at_end(p) || peek(p) != ')' {
		return nil
	}
	advance(p) // Skip ')'
	
	// For now, treat as non-capturing group
	return sub
}

// Check if character is special regex character
is_special_char :: proc(ch: rune) -> bool {
	switch ch {
	case '\\', '|', '(', ')', '[', ']', '{', '}', '^', '$', '.', '*', '+', '?':
		return true
	case:
		return false
	}
}

// Clone a regexp node to a new arena
clone_regexp :: proc(arena: ^Arena, src: ^Regexp) -> ^Regexp {
	if src == nil {
		return nil
	}
	
	dst := (^Regexp)(arena_alloc(arena, size_of(Regexp)))
	dst.op = src.op
	dst.flags = src.flags
	dst.data = nil
	
	// Clone data based on type
	#partial switch src.op {
	case .Literal:
		if src.data != nil {
			src_data := (^Literal_Data)(src.data)
			dst_data := (^Literal_Data)(arena_alloc(arena, size_of(Literal_Data)))
			
			// Copy literal value
			dst_data.value = make([]byte, len(src_data.value))
			copy(dst_data.value, src_data.value)
			dst_data.flags = src_data.flags
			dst.data = dst_data
		}
		
	case .CharClass:
		if src.data != nil {
			src_data := (^CharClass_Data)(src.data)
			dst_data := (^CharClass_Data)(arena_alloc(arena, size_of(CharClass_Data)))
			
			// Copy character class data
			dst_data.count = src_data.count
			dst_data.negated = src_data.negated
			for i in 0..<src_data.count {
				dst_data.ranges[i] = src_data.ranges[i]
			}
			dst.data = dst_data
		}
		
	case .Concat, .Alternate:
		if src.data != nil {
			src_data := (^Concat_Data)(src.data)
			dst_data := (^Concat_Data)(arena_alloc(arena, size_of(Concat_Data)))
			
			// Copy sub-expressions
			dst_data.subs = make([]^Regexp, len(src_data.subs))
			for i in 0..<len(src_data.subs) {
				dst_data.subs[i] = clone_regexp(arena, src_data.subs[i])
			}
			dst.data = dst_data
		}
		
	case .AnyChar, .AnyCharNotNL, .BeginLine, .EndLine:
		// No data to clone
		
	case .NoOp:
		// No data to clone
		
	case:
		// For User Story 2, handle basic types
		// Other types will be implemented later
	}
	
	return dst
}

// ============================================================================
// PUBLIC API
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

// Main API functions

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
	
	// Use simple literal matching for now (NFA needs more debugging)
	matched, start, end := match_literal_simple(pattern.ast, text)
	
	result.matched = matched
	if matched {
		result.full_match = Range{start, end}
		// No captures for simple literals
		result.captures = make([]Range, 1)
		result.captures[0] = result.full_match
	}
	
	return result, .NoError
}

// NFA-based matching implementation (temporarily disabled)
// match_with_nfa :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
// 	// Create NFA program from AST
// 	prog := new_prog(64)
// 	defer free_prog(prog)
// 	
// 	// Compile AST to NFA
// 	compile_err := compile_to_nfa(ast, prog)
// 	if compile_err != .NoError {
// 		return false, -1, -1
// 	}
// 	
// 	// Create matcher
// 	matcher := new_matcher(prog, false, true) // Not anchored, longest match
// 	defer free_matcher(matcher)
// 	
// 	// Execute NFA
// 	matched, caps := match_nfa(matcher, text)
// 	
// 	if matched && len(caps) >= 2 {
// 		return true, caps[0], caps[1]
// 	}
// 	
// 	return false, -1, -1
// }

// Simple literal matching implementation
match_literal_simple :: proc(ast: ^Regexp, text: string, anchor_start: bool = false) -> (bool, int, int) {
	if ast == nil {
		return false, -1, -1
	}
	
	#partial switch ast.op {
	case .Literal:
		if ast.data != nil {
			lit_data := (^Literal_Data)(ast.data)
			lit_str := string(lit_data.value)
			
			if anchor_start {
				// Match only at beginning
				if len(lit_str) <= len(text) {
					match := true
					for j in 0..<len(lit_str) {
						if text[j] != lit_str[j] {
							match = false
							break
						}
					}
					if match {
						return true, 0, len(lit_str)
					}
				}
			} else {
				// Find literal anywhere in text
				for i in 0..<len(text) {
					if i + len(lit_str) <= len(text) {
						match := true
						for j in 0..<len(lit_str) {
							if text[i + j] != lit_str[j] {
								match = false
								break
							}
						}
						if match {
							return true, i, i + len(lit_str)
						}
					}
				}
			}
		}
		
	case .CharClass:
		if ast.data != nil {
			char_data := (^CharClass_Data)(ast.data)
			
			// Find first character matching the class
			for i in 0..<len(text) {
				r := rune(text[i])
				if matches_char_class(char_data, r) {
					return true, i, i + 1
				}
			}
		}
		
	case .AnyChar:
		// Any character matches
		if len(text) > 0 {
			return true, 0, 1
		}
		
	case .AnyCharNotNL:
		// Any character except newline
		if len(text) > 0 && text[0] != '\n' {
			return true, 0, 1
		}
		
	case .BeginLine:
		// Match at beginning of string only
		// For simple matching, we only match at position 0
		return true, 0, 0
		
	case .EndLine:
		// Match at end of string only  
		// For simple matching, we only match at the end
		return true, len(text), len(text)
		
	case .Concat:
		if ast.data != nil {
			concat_data := (^Concat_Data)(ast.data)
			if len(concat_data.subs) == 0 {
				// Empty concatenation matches at position 0
				return true, 0, 0
			}
			
			// Handle concatenation by matching each part sequentially
			return match_concatenation(concat_data.subs, text, 0)
		}
		
	case .Alternate:
		if ast.data != nil {
			concat_data := (^Concat_Data)(ast.data)
			// Try each alternative
			for sub in concat_data.subs {
				matched, start, end := match_literal_simple(sub, text)
				if matched {
					return true, start, end
				}
			}
		}
		
	case .NoOp:
		// Empty pattern matches at position 0
		return true, 0, 0
		
	case:
		// For User Story 2, handle basic types
		// Other types will be implemented later
	}
	
	return false, -1, -1
}

// Check if character matches character class
matches_char_class :: proc(char_data: ^CharClass_Data, r: rune) -> bool {
	if char_data == nil {
		return false
	}
	
	if char_data.count == 0 {
		return char_data.negated
	}
	
	for i in 0..<char_data.count {
		range := char_data.ranges[i]
		if range.lo <= r && r <= range.hi {
			// Character found in range
			return !char_data.negated  // true for normal, false for negated
		}
	}
	
	// Character not found in any range
	return char_data.negated  // false for normal, true for negated
}

// Match concatenation of multiple patterns
match_concatenation :: proc(subs: []^Regexp, text: string, start_pos: int) -> (bool, int, int) {
	if len(subs) == 0 {
		return true, start_pos, start_pos
	}
	
	if len(subs) == 1 {
		matched, match_start, match_end := match_literal_simple(subs[0], text[start_pos:], true)
		if matched {
			return true, start_pos + match_start, start_pos + match_end
		}
		return false, -1, -1
	}
	
	// Handle first component specially based on its type
	first := subs[0]
	
	if first.op == .BeginLine {
		// BeginLine must match at position 0
		if start_pos != 0 {
			return false, -1, -1
		}
		
	// Match remaining parts at position 0
	remaining_matched, _, remaining_end := match_concatenation(subs[1:], text, 0)
	if remaining_matched {
		return true, 0, remaining_end
	}
	return false, -1, -1
	}
	
	if first.op == .EndLine {
		// EndLine must match at end of text - but it's usually the LAST component
		// For patterns like "a$", the EndLine comes last
		if len(subs) == 1 {
			// Just EndLine alone
			return start_pos == len(text), start_pos, start_pos
		}
		
		// If EndLine is not last, match remaining parts first, then check EndLine
		remaining_matched, remaining_start, remaining_end := match_concatenation(subs[1:], text, start_pos)
		if remaining_matched && remaining_end == len(text) {
			return true, remaining_start, len(text)
		}
		return false, -1, -1
	}
	
	// For other types, try all possible matches
	if first.op == .Literal && len(subs) > 1 && subs[1].op == .EndLine {
		// Special case for "a$" - try to find 'a' at the end
		if first.data != nil {
			lit_data := (^Literal_Data)(first.data)
			lit_str := string(lit_data.value)
			
			// Look for literal at the end of text
			if len(lit_str) <= len(text) {
				pos := len(text) - len(lit_str)
				match := true
				for j in 0..<len(lit_str) {
					if text[pos + j] != lit_str[j] {
						match = false
						break
					}
				}
				if match {
					return true, pos, len(text)
				}
			}
		}
		return false, -1, -1
	}
	
	// Normal matching for other cases
	matched, match_start, match_end := match_literal_simple(first, text[start_pos:], true)
	if !matched {
		return false, -1, -1
	}
	
	// Match remaining parts normally
	remaining_matched, remaining_start, remaining_end := match_concatenation(subs[1:], text, start_pos + match_end)
	if !remaining_matched {
		return false, -1, -1
	}
	
	return true, start_pos + match_start, remaining_start + remaining_end
}

// Convenience function for one-shot matching
match_string :: proc(pattern, text: string) -> (bool, ErrorCode) {
	compiled, compile_err := regexp(pattern)
	if compile_err != .NoError {
		return false, compile_err
	}
	defer free_regexp(compiled)
	
	result, match_err := match(compiled, text)
	if match_err != .NoError {
		return false, match_err
	}
	
	return result.matched, .NoError
}

// Thread-local arena management (placeholder implementations)
reset_thread_local_arena :: proc() {
	// TODO: Implement proper thread-local arena reset
}

@(test)
test_basic_api :: proc(t: ^testing.T) {
	// Test basic API functionality
	pattern, compile_err := regexp("hello")
	testing.expect(t, compile_err == .NoError, "Pattern compilation failed: %v", error_string(compile_err))
	testing.expect(t, pattern != nil, "Pattern should not be nil")
	defer free_regexp(pattern)
	
	result, match_err := match(pattern, "hello world")
	testing.expect(t, match_err == .NoError, "Matching failed: %v", error_string(match_err))
	testing.expect(t, result.matched, "Should match 'hello' in 'hello world'")
}

@(test)
test_match_string_convenience :: proc(t: ^testing.T) {
	matched, err := match_string("test", "this is a test")
	testing.expect(t, err == .NoError, "Convenience matching failed: %v", error_string(err))
	testing.expect(t, matched, "Should match 'test' in string")
}