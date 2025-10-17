package regexp

// Unicode Script and Property Support for Common Scripts
// Focused on Latin, Greek, and Cyrillic scripts for practical performance

// Unicode script types for common scripts
Unicode_Script :: enum {
	Unknown,
	Latin,
	Greek,
	Cyrillic,
	Common,  // Characters that appear in multiple scripts
}

// Unicode character categories (simplified)
Unicode_Category :: enum {
	Unknown,
	Letter,    // Ll, Lu, Lt, Lm, Lo
	Number,    // Nd, Nl, No
	Punctuation, // Pc, Pd, Ps, Pe, Pf, Pi, Po
	Symbol,    // Sm, Sc, Sk, So
	Separator, // Zs, Zl, Zp
	Other,     // Cc, Cf, Cs, Co, Cn
}

// Unicode character information
Unicode_Info :: struct {
	script:   Unicode_Script,
	category: Unicode_Category,
	is_ascii: bool,
}

// Get Unicode script for a character
get_unicode_script :: proc(ch: rune) -> Unicode_Script {
	// Fast ASCII path
	if ch < 128 {
		return .Latin
	}

	// Latin Extended ranges
	if (ch >= 0x0100 && ch <= 0x017F) ||  // Latin Extended-A
	   (ch >= 0x0180 && ch <= 0x024F) ||  // Latin Extended-B
	   (ch >= 0x1E00 && ch <= 0x1EFF) {   // Latin Extended Additional
		return .Latin
	}

	// Greek ranges
	if (ch >= 0x0370 && ch <= 0x03FF) ||  // Greek and Coptic
	   (ch >= 0x1F00 && ch <= 0x1FFF) {   // Greek Extended
		return .Greek
	}

	// Cyrillic ranges
	if (ch >= 0x0400 && ch <= 0x04FF) ||  // Cyrillic
	   (ch >= 0x0500 && ch <= 0x052F) ||  // Cyrillic Supplement
	   (ch >= 0x2DE0 && ch <= 0x2DFF) ||  // Cyrillic Extended-A
	   (ch >= 0xA640 && ch <= 0xA69F) {   // Cyrillic Extended-B
		return .Cyrillic
	}

	// Common script ranges
	if (ch >= 0x0300 && ch <= 0x036F) ||  // Combining Diacritical Marks
	   (ch >= 0x2000 && ch <= 0x206F) ||  // General Punctuation
	   (ch >= 0x2070 && ch <= 0x209F) ||  // Superscripts and Subscripts
	   (ch >= 0x20A0 && ch <= 0x20CF) {   // Currency Symbols
		return .Common
	}

	return .Unknown
}

// Get Unicode category for a character
get_unicode_category :: proc(ch: rune) -> Unicode_Category {
	// Fast ASCII path
	if ch < 128 {
		if (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') {
			return .Letter
		}
		if ch >= '0' && ch <= '9' {
			return .Number
		}
		if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
			return .Separator
		}
		if (ch >= 33 && ch <= 47) || (ch >= 58 && ch <= 64) ||
		   (ch >= 91 && ch <= 96) || (ch >= 123 && ch <= 126) {
			return .Punctuation
		}
		return .Symbol
	}

	// Unicode categories (simplified)
	if ch >= 0x0400 && ch <= 0x04FF {
		// Cyrillic block - mostly letters
		if ch >= 0x0410 && ch <= 0x044F {
			return .Letter  // Cyrillic letters
		}
		if ch >= 0x0400 && ch <= 0x04FF {
			return .Letter  // Rest of Cyrillic
		}
	}

	if ch >= 0x0370 && ch <= 0x03FF {
		// Greek block
		if ch >= 0x0391 && ch <= 0x03A9 || ch >= 0x03B1 && ch <= 0x03C9 {
			return .Letter  // Greek letters
		}
		if ch >= 0x0370 && ch <= 0x03FF {
			return .Letter  // Rest of Greek
		}
	}

	// General Unicode ranges
	if (ch >= 0x0041 && ch <= 0x005A) || (ch >= 0x0061 && ch <= 0x007A) {
		return .Letter
	}

	if (ch >= 0x0030 && ch <= 0x0039) {
		return .Number
	}

	// Common punctuation ranges
	if (ch >= 0x2000 && ch <= 0x206F) || (ch >= 0x0020 && ch <= 0x002F) ||
	   (ch >= 0x003A && ch <= 0x0040) || (ch >= 0x005B && ch <= 0x0060) ||
	   (ch >= 0x007B && ch <= 0x007E) {
		return .Punctuation
	}

	// Separator characters
	if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' ||
	   ch == 0x00A0 || ch == 0x2000 || ch == 0x2001 || ch == 0x2002 || ch == 0x2003 {
		return .Separator
	}

	return .Other
}

// Get comprehensive Unicode info
get_unicode_info :: proc(ch: rune) -> Unicode_Info {
	return Unicode_Info{
		script   = get_unicode_script(ch),
		category = get_unicode_category(ch),
		is_ascii = ch < 128,
	}
}

// Check if character belongs to a specific script
is_script :: proc(ch: rune, script: Unicode_Script) -> bool {
	return get_unicode_script(ch) == script
}

// Check if character belongs to a specific category
is_category :: proc(ch: rune, category: Unicode_Category) -> bool {
	return get_unicode_category(ch) == category
}

// Fast ASCII checks (95% of cases)
is_ascii_letter :: proc(ch: rune) -> bool {
	return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
}

is_ascii_digit :: proc(ch: rune) -> bool {
	return ch >= '0' && ch <= '9'
}

is_ascii_whitespace :: proc(ch: rune) -> bool {
	return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

is_ascii_word_char :: proc(ch: rune) -> bool {
	return is_ascii_letter(ch) || is_ascii_digit(ch) || ch == '_'
}

// Unicode case folding for case-insensitive matching
unicode_fold_case :: proc(ch: rune) -> rune {
	// Fast ASCII path
	if ch < 128 {
		if ch >= 'A' && ch <= 'Z' {
			return ch + ('a' - 'A')
		}
		return ch
	}

	// Greek, Cyrillic, Latin Extended case folding
	// Latin
	if ch >= 0x0041 && ch <= 0x005A {
		return ch + 0x20  // A-Z -> a-z
	}
	if ch >= 0x00C0 && ch <= 0x00D6 && ch != 0x00D7 {
		return ch + 0x20  // À-Ö (excluding ×)
	}
	if ch >= 0x00D8 && ch <= 0x00DE {
		return ch + 0x20  // Ø-Þ
	}

	// Greek
	if ch >= 0x0391 && ch <= 0x03A1 {
		return ch + 0x20  // Α-Ρ
	}
	if ch >= 0x03A3 && ch <= 0x03AB {
		return ch + 0x20  // Σ-Χ
	}

	// Cyrillic
	if ch >= 0x0410 && ch <= 0x042F {
		return ch + 0x20  // А-Я -> а-я
	}
	if ch >= 0x0400 && ch <= 0x040F {
		return ch + 0x50  // Ѐ-Џ → ѐ-џ
	}

	return ch  // No change for other characters
}