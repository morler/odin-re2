package regexp

// Error handling for RE2-compatible regex engine
// Provides comprehensive error codes and context information matching RE2 semantics

import "core:fmt"
import "core:strings"
// Provides comprehensive error codes and context information matching RE2 semantics

// Error codes matching RE2's error semantics exactly
ErrorCode :: enum {
	NoError,                    // No error occurred
	ParseError,                 // Invalid regex syntax
	MemoryError,                // Out of memory during compilation or matching
	InternalError,              // Internal logic error (should never happen)
	UTF8Error,                  // Invalid UTF-8 encoding in pattern or input
	TooComplex,                 // Pattern too complex for computational budget
	InvalidCapture,             // Invalid capture group reference
	ErrorUnexpectedParen,       // Unexpected parenthesis
	ErrorTrailingBackslash,     // Trailing backslash at end of pattern
	ErrorBadEscape,             // Invalid escape sequence
	ErrorMissingParen,          // Missing closing parenthesis
	ErrorMissingBracket,        // Missing closing bracket in character class
	ErrorInvalidRepeat,         // Invalid repeat operator (e.g., **)
	ErrorInvalidRepeatSize,     // Invalid repeat size (e.g., {a,b})
	ErrorInvalidCharacterClass, // Invalid character class syntax
	ErrorInvalidPerlOp,         // Invalid Perl-style operator
	ErrorInvalidUTF8,           // Invalid UTF-8 sequence
}

// Error context information for detailed error reporting
Error_Info :: struct {
	code:     ErrorCode,  // Error type
	pos:      int,        // Position in pattern where error occurred
	message:  string,     // Human-readable error message
	pattern:  string,     // Original pattern (for context)
}

// Create a new error info structure
make_error :: proc(code: ErrorCode, pos: int, message: string, pattern: string) -> Error_Info {
	return Error_Info{code, pos, message, pattern}
}

// Create error with formatted message
make_errorf :: proc(code: ErrorCode, pos: int, pattern: string, format: string, args: ..any) -> Error_Info {
	message := fmt.tprintf(format, ..args)
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
		return "expression too complex"
	case .InvalidCapture:
		return "invalid capture group"
	case .ErrorUnexpectedParen:
		return "unexpected parenthesis"
	case .ErrorTrailingBackslash:
		return "trailing backslash"
	case .ErrorBadEscape:
		return "bad escape sequence"
	case .ErrorMissingParen:
		return "missing closing parenthesis"
	case .ErrorMissingBracket:
		return "missing closing bracket"
	case .ErrorInvalidRepeat:
		return "invalid repeat operator"
	case .ErrorInvalidRepeatSize:
		return "invalid repeat size"
	case .ErrorInvalidCharacterClass:
		return "invalid character class"
	case .ErrorInvalidPerlOp:
		return "invalid Perl operator"
	case .ErrorInvalidUTF8:
		return "invalid UTF-8 sequence"
	}
	return "unknown error"
}

// Get detailed error description
error_description :: proc(info: Error_Info) -> string {
	if info.code == .NoError {
		return "no error"
	}
	
	if info.pos >= 0 && info.pos < len(info.pattern) {
		// Show context around error position
		start := max(0, info.pos - 10)
		end := min(len(info.pattern), info.pos + 10)
		context := info.pattern[start:end]
		
		return fmt.tprintf("%s at position %d: %q", info.message, info.pos, context)
	}
	
	return info.message
}

// Check if error code indicates success
is_success :: proc(code: ErrorCode) -> bool {
	return code == .NoError
}

// Check if error code indicates failure
is_error :: proc(code: ErrorCode) -> bool {
	return code != .NoError
}

// Check if error is recoverable (can continue with other patterns)
is_recoverable :: proc(code: ErrorCode) -> bool {
	switch code {
	case .ParseError, .UTF8Error, .InvalidCapture, .ErrorUnexpectedParen,
	     .ErrorTrailingBackslash, .ErrorBadEscape, .ErrorMissingParen,
	     .ErrorMissingBracket, .ErrorInvalidRepeat, .ErrorInvalidRepeatSize,
	     .ErrorInvalidCharacterClass, .ErrorInvalidPerlOp, .ErrorInvalidUTF8:
		return true
	case .MemoryError, .InternalError, .TooComplex:
		return false
	case .NoError:
		return true
	}
	return false
}

// Common error creation functions for specific scenarios

// Create parse error at position
parse_error :: proc(pos: int, pattern: string, message: string) -> Error_Info {
	return make_error(.ParseError, pos, message, pattern)
}

// Create memory error
memory_error :: proc(message: string) -> Error_Info {
	return make_error(.MemoryError, -1, message, "")
}

// Create internal error (should never happen in production)
internal_error :: proc(message: string) -> Error_Info {
	return make_error(.InternalError, -1, message, "")
}

// Create UTF-8 error
utf8_error :: proc(pos: int, pattern: string, message: string) -> Error_Info {
	return make_error(.UTF8Error, pos, message, pattern)
}

// Create complexity error
complexity_error :: proc(message: string) -> Error_Info {
	return make_error(.TooComplex, -1, message, "")
}

// Error formatting utilities

// Format error position with arrow indicator
format_error_position :: proc(pattern: string, pos: int) -> string {
	if pos < 0 || pos >= len(pattern) {
		return pattern
	}
	
	// Build pattern with position indicator
	builder := strings.make_builder()
	defer strings.destroy_builder(builder)
	
	// Add pattern line
	strings.write_string(builder, pattern)
	strings.write_byte(builder, '\n')
	
	// Add position indicator line
	for i in 0..<pos {
		strings.write_byte(builder, ' ')
	}
	strings.write_byte(builder, '^')
	
	return strings.to_string(builder)
}

// Validate error info structure
validate_error_info :: proc(info: Error_Info) -> bool {
	// Position should be valid for pattern
	if info.pos >= 0 && info.pos >= len(info.pattern) {
		return false
	}
	
	// Message should not be empty for errors
	if info.code != .NoError && len(info.message) == 0 {
		return false
	}
	
	return true
}

// Error recovery suggestions
get_error_suggestion :: proc(code: ErrorCode) -> string {
	switch code {
	case .ErrorTrailingBackslash:
		return "Remove the trailing backslash or escape it as \\\\"
	case .ErrorMissingParen:
		return "Add the missing closing parenthesis or escape the opening one"
	case .ErrorMissingBracket:
		return "Add the missing closing bracket or escape the opening one"
	case .ErrorInvalidRepeat:
		return "Check repeat operator syntax (e.g., use * instead of **)"
	case .ErrorBadEscape:
		return "Check escape sequence syntax or use raw string literals"
	case .ErrorInvalidCharacterClass:
		return "Check character class syntax (e.g., [a-z] not [a-])"
	case .TooComplex:
		return "Simplify the pattern or break it into smaller parts"
	case .MemoryError:
		return "Free unused patterns or increase available memory"
	case .UTF8Error:
		return "Ensure pattern and input text contain valid UTF-8"
	case:
		return "Check pattern syntax and consult documentation"
	}
}