package regexp

import "core:testing"

// Optimized UTF-8 processing for regex matching
// Focuses on 95% ASCII cases with fast Unicode fallback

// ASCII character classification for O(1) character classification
ASCII_Char_Class :: enum u8 {
	None = 0,
	Letter,
	Number,
	Whitespace,
	Punctuation,
	Symbol,
	Control,
	Binary_Digit,  // For binary patterns
	Hex_Digit,      // For hexadecimal patterns  
	Octal_Digit,    // For octal patterns
}

// Pre-computed ASCII classification table (128 entries + 1 for safety)
ASCII_CLASS_TABLE: [129]ASCII_Char_Class

// Initialize ASCII classification table
init_ascii_classification :: proc() {
	// Initialize all to None
	for i in 0..<len(ASCII_CLASS_TABLE) {
		ASCII_CLASS_TABLE[i] = .None
	}
	
	// Fill in ASCII letters (A-Z, a-z)
	for i in u8('A')..=u8('Z') {
		ASCII_CLASS_TABLE[i] = .Letter
	}
	for i in u8('a')..=u8('z') {
		ASCII_CLASS_TABLE[i] = .Letter
	}
	
	// Fill in numbers (0-9)
	for i in u8('0')..=u8('9') {
		ASCII_CLASS_TABLE[i] = .Number
	}
	
	// Fill in whitespace
	ASCII_CLASS_TABLE[u8(' ')] = .Whitespace
	ASCII_CLASS_TABLE[u8('\t')] = .Whitespace
	ASCII_CLASS_TABLE[u8('\n')] = .Whitespace
	ASCII_CLASS_TABLE[u8('\r')] = .Whitespace
	ASCII_CLASS_TABLE[u8('\v')] = .Whitespace
	ASCII_CLASS_TABLE[u8('\f')] = .Whitespace
	
	// Fill in common punctuation
	for c in "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~" {
		if int(c) < len(ASCII_CLASS_TABLE) {
			ASCII_CLASS_TABLE[int(c)] = .Punctuation
		}
	}
	
	// Fill in control characters (0-31, 127)
	for i in 0..=31 {
		ASCII_CLASS_TABLE[i] = .Control
	}
	ASCII_CLASS_TABLE[127] = .Control // DEL
	
	// Fill in binary digits (subset of numbers)
	for i in u8('0')..=u8('1') {
		// Keep as Number, binary check is separate function
	}
	
	// Fill in hex digits (0-9, A-F, a-f)
	for i in u8('A')..=u8('F') {
		// Keep as Letter/Above, hex check is separate
	}
	for i in u8('a')..=u8('f') {
		// Keep as Letter/Above, hex check is separate
	}
	
	// Fill in octal digits (0-7)
	for i in u8('0')..=u8('7') {
		// Keep as Number, octal check is separate
	}
}

// Fast ASCII character classification - O(1) lookup
is_ascii_char_class :: proc(ch: rune) -> ASCII_Char_Class {
	if ch < 0 || ch >= 128 {
		return .None
	}
	return ASCII_CLASS_TABLE[int(ch)]
}

// Specialized fast checks for common patterns
is_ascii_letter :: proc(ch: rune) -> bool {
	if ch < 0 || ch >= 128 {
		return false
	}
	cls := ASCII_CLASS_TABLE[int(ch)]
	return cls == .Letter
}

is_ascii_number :: proc(ch: rune) -> bool {
	if ch < 0 || ch >= 128 {
		return false
	}
	cls := ASCII_CLASS_TABLE[int(ch)]
	return cls == .Number
}

is_ascii_whitespace :: proc(ch: rune) -> bool {
	if ch < 0 || ch >= 128 {
		return false
	}
	cls := ASCII_CLASS_TABLE[int(ch)]
	return cls == .Whitespace
}

is_ascii_word_char :: proc(ch: rune) -> bool {
	if ch < 0 || ch >= 128 {
		return false
	}
	cls := ASCII_CLASS_TABLE[int(ch)]
	return cls == .Letter || cls == .Number || ch == '_'
}

// Specialized checks for number bases
is_ascii_binary_digit :: proc(ch: rune) -> bool {
	return ch == '0' || ch == '1'
}

is_ascii_hex_digit :: proc(ch: rune) -> bool {
	if ch >= 0 || ch < 128 {
		cls := ASCII_CLASS_TABLE[int(ch)]
		if cls == .Number {
			return true // 0-9
		}
		// A-F, a-f
		return (ch >= 'A' && ch <= 'F') || (ch >= 'a' && ch <= 'f')
	}
	return false
}

is_ascii_octal_digit :: proc(ch: rune) -> bool {
	return ch >= '0' && ch <= '7'
}

// Fast ASCII range check for character classes like [a-z]
is_ascii_in_range :: proc(ch: rune, start: rune, end: rune) -> bool {
	return ch >= start && ch <= end && ch < 128
}

// Fast ASCII set membership test for small sets
is_ascii_in_set :: proc(ch: rune, set: []rune) -> bool {
	if ch < 0 || ch >= 128 {
		return false
	}
	for c in set {
		if c == ch {
			return true
		}
	}
	return false
}

// UTF-8 decoder state machine
UTF8_Decoder :: struct {
	state:      u8,     // Current decoder state
	codepoint:  u32,    // Accumulated codepoint
	bytes_left: u8,     // Bytes remaining to decode
}

// Initialize UTF-8 decoder
init_utf8_decoder :: proc() -> UTF8_Decoder {
	return UTF8_Decoder{
		state = 0,
		codepoint = 0,
		bytes_left = 0,
	}
}

// Fast UTF-8 character decoder with ASCII optimization
// Returns (rune, bytes_consumed, is_valid)
decode_utf8_char_fast :: proc(data: []u8, start: int) -> (rune, int, bool) {
	if start >= len(data) {
		return 0, 0, false
	}

	first_byte := data[start]

	// Fast ASCII path (95% of cases)
	if first_byte < 0x80 {
		return rune(first_byte), 1, true
	}

	// Unicode path - optimized UTF-8 decoding
	if first_byte < 0xC0 {
		// Invalid UTF-8 (continuation byte without start)
		return 0xFFFD, 1, false  // Replacement character
	}

	// Determine sequence length from first byte
	bytes_needed: u8
	codepoint_bits: u8
	mask: u8

	if first_byte < 0xE0 {
		// 2-byte sequence
		bytes_needed = 2
		codepoint_bits = 5
		mask = 0x1F
	} else if first_byte < 0xF0 {
		// 3-byte sequence
		bytes_needed = 3
		codepoint_bits = 4
		mask = 0x0F
	} else if first_byte < 0xF5 {
		// 4-byte sequence
		bytes_needed = 4
		codepoint_bits = 3
		mask = 0x07
	} else {
		// Invalid UTF-8 start byte
		return 0xFFFD, 1, false
	}

	// Check if we have enough bytes
	if start + int(bytes_needed) > len(data) {
		return 0xFFFD, 1, false  // Incomplete sequence
	}

	// Extract initial codepoint bits
	codepoint := u32(first_byte & mask)

	// Process continuation bytes
	for i in 1..<bytes_needed {
		cont_byte := data[start + int(i)]
		if cont_byte < 0x80 || cont_byte >= 0xC0 {
			// Invalid continuation byte
			return 0xFFFD, int(i), false
		}
		codepoint = (codepoint << 6) | u32(cont_byte & 0x3F)
	}

	// Validate codepoint ranges
	if codepoint > 0x10FFFF || (0xD800 <= codepoint && codepoint <= 0xDFFF) {
		return 0xFFFD, int(bytes_needed), false  // Invalid Unicode codepoint
	}

	return rune(codepoint), int(bytes_needed), true
}

// Fast UTF-8 iterator for sequential processing (optimized version)
UTF8_Iterator_Fast :: struct {
	data:    []u8,
	pos:     int,
	current: rune,
	valid:   bool,
}

// Create UTF-8 iterator from string slice
make_utf8_iterator_fast :: proc(text: []u8) -> UTF8_Iterator_Fast {
	iter := UTF8_Iterator_Fast{
		data = text,
		pos = 0,
		current = 0,
		valid = false,
	}

	// Load first character
	if len(text) > 0 {
		iter.current, _, iter.valid = decode_utf8_char_fast(text, 0)
	}

	return iter
}

// Check if iterator has more characters
utf8_has_more_fast :: proc(iter: ^UTF8_Iterator_Fast) -> bool {
	return iter.pos < len(iter.data)
}

// Get current character without advancing
utf8_peek_fast :: proc(iter: ^UTF8_Iterator_Fast) -> rune {
	return iter.current
}

// Advance to next character
utf8_advance_fast :: proc(iter: ^UTF8_Iterator_Fast) -> bool {
	if iter.pos >= len(iter.data) {
		return false
	}

	// Decode next character
	char, bytes_consumed, valid := decode_utf8_char_fast(iter.data, iter.pos)

	if valid {
		iter.pos += bytes_consumed
		iter.current = char
		iter.valid = true
		return true
	} else {
		// Skip invalid byte and move to next position
		iter.pos += 1
		iter.current = 0xFFFD  // Replacement character
		iter.valid = false
		return iter.pos < len(iter.data)
	}
}

// Get current character and advance
utf8_next_fast :: proc(iter: ^UTF8_Iterator_Fast) -> (rune, bool) {
	if !utf8_has_more_fast(iter) {
		return 0, false
	}

	current_char := iter.current
	has_next := utf8_advance_fast(iter)
	return current_char, has_next
}

// Count characters in UTF-8 string (optimized)
count_utf8_chars_fast :: proc(data: []u8) -> int {
	count := 0
	pos := 0

	for pos < len(data) {
		_, bytes_consumed, _ := decode_utf8_char_fast(data, pos)
		pos += bytes_consumed
		count += 1
	}

	return count
}

// Validate UTF-8 sequence
is_valid_utf8_fast :: proc(data: []u8) -> bool {
	pos := 0

	for pos < len(data) {
		_, bytes_consumed, valid := decode_utf8_char_fast(data, pos)
		if !valid {
			return false
		}
		pos += bytes_consumed
	}

	return true
}

// Fast UTF-8 to rune conversion for single character
utf8_to_rune_fast :: proc(data: []u8) -> rune {
	if len(data) == 0 {
		return 0
	}

	char, _, _ := decode_utf8_char_fast(data, 0)
	return char
}

// Optimized UTF-8 string length calculation
utf8_length_fast :: proc(data: []u8) -> int {
	// For UTF-8, byte length and character length are different
	// This returns character count
	return count_utf8_chars_fast(data)
}

// Batch UTF-8 character processing for performance
process_utf8_batch :: proc(data: []u8, callback: proc(rune, int) -> bool) -> bool {
	pos := 0

	for pos < len(data) {
		char, bytes_consumed, valid := decode_utf8_char_fast(data, pos)
		if !valid {
			char = 0xFFFD  // Use replacement character for invalid sequences
		}

		if !callback(char, pos) {
			return false  // Early termination requested
		}

		pos += bytes_consumed
	}

	return true
}

// Unicode-aware case folding for UTF-8 sequences
utf8_case_fold :: proc(data: []u8, output: []u8) -> int {
	if len(data) == 0 {
		return 0
	}

	input_pos := 0
	output_pos := 0

	for input_pos < len(data) && output_pos < len(output) {
		char, bytes_consumed, valid := decode_utf8_char_fast(data, input_pos)

		if !valid {
			char = 0xFFFD
			bytes_consumed = 1
		}

		// Apply case folding
		folded_char := unicode_fold_case(char)

		// Convert back to UTF-8 (simplified for ASCII and common cases)
		if folded_char < 0x80 {
			output[output_pos] = u8(folded_char)
			output_pos += 1
		} else if folded_char < 0x800 && output_pos + 1 < len(output) {
			output[output_pos] = u8(0xC0 | (folded_char >> 6))
			output[output_pos + 1] = u8(0x80 | (folded_char & 0x3F))
			output_pos += 2
		} else {
			// For simplicity, just use original character for complex cases
			copy(output[output_pos:], data[input_pos:input_pos + bytes_consumed])
			output_pos += bytes_consumed
		}

		input_pos += bytes_consumed
	}

	return output_pos
}

// ============================================================================
// SIMD OPTIMIZATIONS
// ============================================================================

// SIMD support detection and feature flags
SIMD_Feature_Set :: struct {
	has_sse2:    bool,
	has_sse4_2:  bool,
	has_avx2:     bool,
	has_neon:     bool, // ARM NEON
}

// Global SIMD feature detection
simd_features: SIMD_Feature_Set

// Detect SIMD capabilities at runtime
detect_simd_features :: proc() -> SIMD_Feature_Set {
	features := SIMD_Feature_Set{}
	
	// For now, assume SSE2 is available on x86-64
	// In a real implementation, this would use CPUID instructions
	// or platform-specific detection
	when ODIN_ARCH == "amd64" {
		features.has_sse2 = true
		// Could detect more features with CPUID
	} else when ODIN_ARCH == "arm64" {
		features.has_neon = true
	}
	
	return features
}

// Initialize SIMD support
init_simd_support :: proc() {
	simd_features = detect_simd_features()
}

// SIMD-optimized character class matching for [a-z] patterns
// Uses SSE2 for 16-character parallel comparison
simd_char_class_a_to_z :: proc(text: []u8, start: int) -> bool {
	if !simd_features.has_sse2 {
		// Fallback to scalar version
		return char_class_a_to_z_scalar(text, start)
	}
	
	// Check if we have enough characters for SIMD
	if start >= len(text) {
		return false
	}
	
	ch := text[start]
	
	// SSE2 optimized version would use 16-byte parallel comparison
	// For now, implement simple scalar version as placeholder
	return char_class_a_to_z_scalar(text, start)
}

// Scalar fallback for [a-z] character class
char_class_a_to_z_scalar :: proc(text: []u8, start: int) -> bool {
	if start >= len(text) {
		return false
	}
	
	ch := text[start]
	return ch >= 'a' && ch <= 'z'
}

// SIMD-optimized character class matching for [A-Z] patterns
simd_char_class_A_to_Z :: proc(text: []u8, start: int) -> bool {
	if !simd_features.has_sse2 {
		return char_class_A_to_Z_scalar(text, start)
	}
	
	if start >= len(text) {
		return false
	}
	
	ch := text[start]
	
	// SSE2 optimized version would be implemented here
	return char_class_A_to_Z_scalar(text, start)
}

// Scalar fallback for [A-Z] character class
char_class_A_to_Z_scalar :: proc(text: []u8, start: int) -> bool {
	if start >= len(text) {
		return false
	}
	
	ch := text[start]
	return ch >= 'A' && ch <= 'Z'
}

// SIMD-optimized character class matching for [0-9] patterns
simd_char_class_0_to_9 :: proc(text: []u8, start: int) -> bool {
	if !simd_features.has_sse2 {
		return char_class_0_to_9_scalar(text, start)
	}
	
	if start >= len(text) {
		return false
	}
	
	ch := text[start]
	
	// SSE2 optimized version would be implemented here
	return char_class_0_to_9_scalar(text, start)
}

// Scalar fallback for [0-9] character class
char_class_0_to_9_scalar :: proc(text: []u8, start: int) -> bool {
	if start >= len(text) {
		return false
	}
	
	ch := text[start]
	return ch >= '0' && ch <= '9'
}

// Generic SIMD character class matcher
simd_char_class_match :: proc(text: []u8, start: int, char_class: ^CharClass_Data) -> bool {
	if char_class == nil || start >= len(text) {
		return false
	}
	
	// For now, use ASCII fast path
	ch := text[start]
	if ch >= 128 {
		return false // Non-ASCII
	}
	
	// Check against ranges (could be SIMD optimized)
	for i in 0..<len(char_class.ranges) {
		range := char_class.ranges[i]
		if ch >= u8(range.lo) && ch <= u8(range.hi) {
			return !char_class.negated
		}
	}
	
	return char_class.negated
}

// ============================================================================
// ASCII CLASSIFICATION TESTS
// ============================================================================

// Test ASCII character classification functionality
@test
test_ascii_char_classification :: proc(t: ^testing.T) {
	// Initialize the ASCII classification table
	init_ascii_classification()
	
	// Test letter classification
	testing.expect(t, is_ascii_char_class('a') == .Letter)
	testing.expect(t, is_ascii_char_class('z') == .Letter)
	testing.expect(t, is_ascii_char_class('A') == .Letter)
	testing.expect(t, is_ascii_char_class('Z') == .Letter)
	
	// Test number classification
	testing.expect(t, is_ascii_char_class('0') == .Number)
	testing.expect(t, is_ascii_char_class('5') == .Number)
	testing.expect(t, is_ascii_char_class('9') == .Number)
	
	// Test whitespace classification
	testing.expect(t, is_ascii_char_class(' ') == .Whitespace)
	testing.expect(t, is_ascii_char_class('\t') == .Whitespace)
	testing.expect(t, is_ascii_char_class('\n') == .Whitespace)
	testing.expect(t, is_ascii_char_class('\r') == .Whitespace)
	
	// Test punctuation classification
	testing.expect(t, is_ascii_char_class('!') == .Punctuation)
	testing.expect(t, is_ascii_char_class('.') == .Punctuation)
	testing.expect(t, is_ascii_char_class(',') == .Punctuation)
	
	// Test control character classification
	testing.expect(t, is_ascii_char_class(0) == .Control)
	testing.expect(t, is_ascii_char_class(27) == .Control) // ESC
	testing.expect(t, is_ascii_char_class(127) == .Control) // DEL
	
	// Test non-ASCII characters
	testing.expect(t, is_ascii_char_class('世') == .None)
	testing.expect(t, is_ascii_char_class(128) == .None)
	testing.expect(t, is_ascii_char_class(255) == .None)
}