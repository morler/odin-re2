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
	ranges: []Char_Range,
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
	
	// For User Story 1, only handle literals
	node := parse_literal(&parser)
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
		
		// For User Story 1, stop at any special regex character
		if is_special_char(ch) {
			break
		}
		
		// Handle escape sequences
		if ch == '\\' {
			advance(p) // Skip backslash
			if at_end(p) {
				return nil // Trailing backslash
			}
			
			escaped := advance(p)
			// For now, only handle simple escapes
			switch escaped {
			case 'n':
				append(&literal_bytes, '\n')
			case 't':
				append(&literal_bytes, '\t')
			case 'r':
				append(&literal_bytes, '\r')
			case '\\':
				append(&literal_bytes, '\\')
			case:
				// For User Story 1, treat unknown escapes as literal
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
		
	case .NoOp:
		// No data to clone
		
	case:
		// For User Story 1, only handle Literal and NoOp
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
	
	// For now, implement simple literal matching
	// TODO: Implement full NFA/DFA matching engine
	
	if pattern.ast == nil {
		return result, .InternalError
	}
	
	// Simple literal matching for User Story 1
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

// Simple literal matching implementation
match_literal_simple :: proc(ast: ^Regexp, text: string) -> (bool, int, int) {
	if ast == nil {
		return false, -1, -1
	}
	
	#partial switch ast.op {
	case .Literal:
		if ast.data != nil {
			lit_data := (^Literal_Data)(ast.data)
			lit_str := string(lit_data.value)
			
			// Find literal in text
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
		
	case .Concat:
		if ast.data != nil {
			concat_data := (^Concat_Data)(ast.data)
			if len(concat_data.subs) == 0 {
				// Empty concatenation matches at position 0
				return true, 0, 0
			}
			
			// For now, only handle single literal in concatenation
			if len(concat_data.subs) == 1 {
				return match_literal_simple(concat_data.subs[0], text)
			}
		}
		
	case .NoOp:
		// Empty pattern matches at position 0
		return true, 0, 0
		
	case:
		// For User Story 1, only handle Literal, Concat, and NoOp
		// Other types will be implemented later
	}
	
	return false, -1, -1
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