package regexp

// Unicode property support for RE2-compatible regex engine
// Implements basic Unicode property matching

import "core:unicode/utf8"
import "core:unicode"

// Unicode property categories (basic set for common usage)
Unicode_Property :: enum {
	None,
	Letter,          // L - All letters
	Upper,           // Lu - Uppercase letters
	Lower,           // Ll - Lowercase letters
	Number,          // N - All numbers
	Digit,           // Nd - Decimal digits
	Punctuation,     // P - All punctuation
	Symbol,          // S - All symbols
	Space,           // Z - All whitespace
	Mark,            // M - All marks
}

// Parse Unicode property name
parse_unicode_property :: proc(name: string) -> Unicode_Property {
	switch name {
	case "L", "Letter":
		return .Letter
	case "Lu", "Upper":
		return .Upper
	case "Ll", "Lower":
		return .Lower
	case "N", "Number":
		return .Number
	case "Nd", "Digit":
		return .Digit
	case "P", "Punctuation":
		return .Punctuation
	case "S", "Symbol":
		return .Symbol
	case "Z", "Space":
		return .Space
	case "M", "Mark":
		return .Mark
	}
	return .None
}

// Check if rune matches Unicode property
matches_unicode_property :: proc(r: rune, prop: Unicode_Property) -> bool {
	switch prop {
	case .Letter:
		return unicode.is_letter(r)
	case .Upper:
		return unicode.is_upper(r)
	case .Lower:
		return unicode.is_lower(r)
	case .Number:
		return unicode.is_digit(r) || is_other_number(r)
	case .Digit:
		return unicode.is_digit(r)
	case .Punctuation:
		return unicode.is_punct(r)
	case .Symbol:
		return unicode.is_symbol(r)
	case .Space:
		return unicode.is_space(r)
	case .Mark:
		return false // TODO: Implement mark property check
	case .None:
		return false
	}
	return false
}

// Helper for other number types (Roman numerals, fractions, etc.)
is_other_number :: proc(r: rune) -> bool {
	// Basic implementation - can be expanded
	// Check for common number-like characters
	return (r >= 'ⅰ' && r <= 'ⅿ') || // Roman numerals lowercase
	       (r >= 'Ⅰ' && r <= 'Ⅻ') || // Roman numerals uppercase
	       (r >= '¼' && r <= '¾') || // Fractions
	       r == '↉' // Zero fraction
}

// Case folding for case-insensitive matching
case_fold_rune :: proc(r: rune) -> rune {
	// Basic case folding - can be expanded for full Unicode support
	if unicode.is_upper(r) {
		return unicode.to_lower(r)
	}
	return r
}

// Check if two runes match case-insensitively
matches_case_insensitive :: proc(a: rune, b: rune) -> bool {
	return case_fold_rune(a) == case_fold_rune(b)
}

// Get character ranges for Unicode property
get_unicode_property_ranges :: proc(prop: Unicode_Property, arena: ^Arena) -> []Char_Range {
	switch prop {
	case .Letter:
		// Basic Latin letters + extended
		result := arena_alloc_slice(arena, Char_Range, 3)
		result[0] = Char_Range{'A', 'Z'}
		result[1] = Char_Range{'a', 'z'}
		result[2] = Char_Range{'À', 'ÿ'} // Latin-1 supplement
		return result
	case .Upper:
		result := arena_alloc_slice(arena, Char_Range, 2)
		result[0] = Char_Range{'A', 'Z'}
		result[1] = Char_Range{'À', 'Þ'}
		return result
	case .Lower:
		result := arena_alloc_slice(arena, Char_Range, 2)
		result[0] = Char_Range{'a', 'z'}
		result[1] = Char_Range{'à', 'ÿ'}
		return result
	case .Number:
		result := arena_alloc_slice(arena, Char_Range, 3)
		result[0] = Char_Range{'0', '9'}
		result[1] = Char_Range{'Ⅰ', 'Ⅻ'} // Roman numerals
		result[2] = Char_Range{'ⅰ', 'ⅿ'} // Enclosed alphanumerics
		return result
	case .Digit:
		result := arena_alloc_slice(arena, Char_Range, 1)
		result[0] = Char_Range{'0', '9'}
		return result
	case .Punctuation:
		result := arena_alloc_slice(arena, Char_Range, 4)
		result[0] = Char_Range{'!', '/'}
		result[1] = Char_Range{':', '@'}
		result[2] = Char_Range{'[', '`'}
		result[3] = Char_Range{'{', '~'}
		return result
	case .Symbol:
		result := arena_alloc_slice(arena, Char_Range, 4)
		result[0] = Char_Range{'$', '$'}
		result[1] = Char_Range{'+', '+'}
		result[2] = Char_Range{'<', '>'}
		result[3] = Char_Range{'^', '^'}
		return result
	case .Space:
		result := arena_alloc_slice(arena, Char_Range, 5)
		result[0] = Char_Range{' ', ' '}
		result[1] = Char_Range{'\t', '\r'}
		result[2] = Char_Range{'\f', '\f'}
		result[3] = Char_Range{'\v', '\v'}
		return result
	case .Mark:
		// Basic combining marks
		result := arena_alloc_slice(arena, Char_Range, 3)
		result[0] = Char_Range{'̀', '̂'}
		result[1] = Char_Range{'̃', '̃'}
		result[2] = Char_Range{'̄', '̄'}
		return result
	case .None:
		return nil
	}
	return nil // Add default return
}