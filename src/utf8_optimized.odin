package regexp

// Optimized UTF-8 processing for regex matching
// Focuses on 95% ASCII cases with fast Unicode fallback

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