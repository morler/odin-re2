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
	Letter,     // Ll, Lu, Lt, Lm, Lo
	Number,     // Nd, Nl, No
	Punctuation,// Pc, Pd, Ps, Pe, Pf, Pi, Po
	Symbol,     // Sm, Sc, Sk, So
	Separator,  // Zs, Zl, Zp
	Other,      // Cc, Cf, Cs, Co, Cn

	// Refined subcategories for better matching
	Lowercase_Letter,  // Ll
	Uppercase_Letter,  // Lu
	Title_Letter,      // Lt
	Modifier_Letter,   // Lm
	Other_Letter,      // Lo

	Decimal_Number,    // Nd
	Letter_Number,     // Nl
	Other_Number,      // No

	Connector_Punctuation, // Pc
	Dash_Punctuation,      // Pd
	Open_Punctuation,      // Ps
	Close_Punctuation,     // Pe
	Initial_Punctuation,   // Pi
	Final_Punctuation,     // Pf
	Other_Punctuation,     // Po

	Math_Symbol,           // Sm
	Currency_Symbol,       // Sc
	Modifier_Symbol,       // Sk
	Other_Symbol,          // So

	Space_Separator,       // Zs
	Line_Separator,        // Zl
	Paragraph_Separator,   // Zp

	Control,               // Cc
	Format,                // Cf
	Surrogate,             // Cs
	Private_Use,           // Co
	Unassigned,            // Cn
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

	// Latin-1 Supplement and Latin Extended ranges
	if (ch >= 0x00A0 && ch <= 0x00FF) ||  // Latin-1 Supplement (including é)
	   (ch >= 0x0100 && ch <= 0x017F) ||  // Latin Extended-A
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
		if ch >= 'a' && ch <= 'z' {
			return .Lowercase_Letter
		}
		if ch >= 'A' && ch <= 'Z' {
			return .Uppercase_Letter
		}
		if ch >= '0' && ch <= '9' {
			return .Decimal_Number
		}
		if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
			return .Space_Separator
		}
		if ch == '_' {
			return .Connector_Punctuation
		}
		if ch == '-' {
			return .Dash_Punctuation
		}
		if ch == '(' || ch == '[' || ch == '{' {
			return .Open_Punctuation
		}
		if ch == ')' || ch == ']' || ch == '}' {
			return .Close_Punctuation
		}
		if (ch >= 33 && ch <= 47) || (ch >= 58 && ch <= 64) ||
		   (ch >= 91 && ch <= 96) || (ch >= 123 && ch <= 126) {
			return .Other_Punctuation
		}
		if ch < 32 {
			return .Control
		}
		return .Symbol
	}

	// Cyrillic block - detailed categories
	if ch >= 0x0400 && ch <= 0x04FF {
		if ch >= 0x0410 && ch <= 0x042F {
			return .Uppercase_Letter  // А-Я
		}
		if ch >= 0x0430 && ch <= 0x044F {
			return .Lowercase_Letter  // а-я
		}
		return .Letter  // Other Cyrillic characters
	}

	// Greek block - detailed categories
	if ch >= 0x0370 && ch <= 0x03FF {
		if ch >= 0x0391 && ch <= 0x03A9 {
			return .Uppercase_Letter  // Α-Ω
		}
		if ch >= 0x03B1 && ch <= 0x03C9 {
			return .Lowercase_Letter  // α-ω
		}
		return .Letter  // Other Greek characters
	}

	// Latin-1 Supplement and Latin Extended ranges
	if (ch >= 0x00A0 && ch <= 0x00FF) ||  // Latin-1 Supplement (including é, ñ, etc.)
	   (ch >= 0x0100 && ch <= 0x017F) ||  // Latin Extended-A
	   (ch >= 0x0180 && ch <= 0x024F) ||  // Latin Extended-B
	   (ch >= 0x1E00 && ch <= 0x1EFF) {   // Latin Extended Additional
		return .Letter
	}

	// General Unicode punctuation ranges
	if (ch >= 0x2000 && ch <= 0x206F) ||  // General Punctuation
	   (ch >= 0x3000 && ch <= 0x303F) {   // CJK Symbols and Punctuation
		return .Punctuation
	}

	// Currency symbols
	if ch >= 0x20A0 && ch <= 0x20CF {
		return .Currency_Symbol
	}

	// Math symbols
	if ch >= 0x2200 && ch <= 0x22FF {
		return .Math_Symbol
	}

	// Number ranges (non-ASCII)
	if (ch >= 0x0660 && ch <= 0x0669) ||  // Arabic-Indic digits
	   (ch >= 0x06F0 && ch <= 0x06F9) {   // Eastern Arabic-Indic digits
		return .Decimal_Number
	}

	// Separator characters
	if ch == 0x00A0 || ch == 0x2000 || ch == 0x2001 ||
	   ch == 0x2002 || ch == 0x2003 || ch == 0x202F || ch == 0x205F {
		return .Space_Separator
	}
	if ch == 0x2028 {
		return .Line_Separator
	}
	if ch == 0x2029 {
		return .Paragraph_Separator
	}

	// Control characters
	if (ch >= 0x0000 && ch <= 0x001F) || (ch >= 0x007F && ch <= 0x009F) {
		return .Control
	}

	// Default to other for unassigned or rare characters
	return .Other
}

// Get general category (legacy compatibility)
get_general_category :: proc(ch: rune) -> Unicode_Category {
	detailed := get_unicode_category(ch)

	// Map detailed categories back to general ones
	switch detailed {
	case .Lowercase_Letter, .Uppercase_Letter, .Title_Letter,
	     .Modifier_Letter, .Other_Letter:
		return .Letter
	case .Decimal_Number, .Letter_Number, .Other_Number:
		return .Number
	case .Connector_Punctuation, .Dash_Punctuation, .Open_Punctuation,
	     .Close_Punctuation, .Initial_Punctuation, .Final_Punctuation,
	     .Other_Punctuation:
		return .Punctuation
	case .Math_Symbol, .Currency_Symbol, .Modifier_Symbol, .Other_Symbol:
		return .Symbol
	case .Space_Separator, .Line_Separator, .Paragraph_Separator:
		return .Separator
	case .Control, .Format, .Surrogate, .Private_Use, .Unassigned:
		return .Other
	case .Unknown, .Letter, .Number, .Punctuation, .Symbol, .Separator, .Other:
		return detailed  // Return as-is for general categories
	case:
		return .Other  // Default for any unhandled cases
	}
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

// ===========================================================================
// PERFORMANCE-OPTIMIZED UNICODE PROPERTY LOOKUPS
// ===========================================================================

// Unicode property lookup tables for common character classes
// Using lookup tables for O(1) performance on common checks

@(private="file")
ASCII_CHAR_TABLE_DATA :: [128]u8 {
	// 0 = Other, 1 = Letter, 2 = Number, 3 = Punctuation, 4 = Symbol, 5 = Separator
	// Index: ASCII code value (0-127)
	0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 0, 0, 5, 0, 0, // 0-15
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 16-31
	5, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 32-47 (!"#$%&'()*+,-./)
	2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, // 48-63 (0-9:;<=>?)
	3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, // 64-79 (@ABCDEFGHIJKLMNOPQRSTUVWXYZ)
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3, // 80-95 ([\]^_`)
	3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, // 96-111 (`abcdefghijklmnopqrstuvwxyz)
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 0, // 112-127 (|}~DEL)
}

// Get ASCII character table entry (variable indexing)
@(private="file")
get_ascii_table_entry :: proc(ch: rune) -> u8 {
	if ch >= 128 {
		return 0
	}
	// Copy to variable to allow indexing
	table := ASCII_CHAR_TABLE_DATA
	return table[ch]
}

// Fast ASCII property lookup using table (O(1) performance)
is_ascii_letter_fast :: proc(ch: rune) -> bool {
	return ch < 128 && get_ascii_table_entry(ch) == 1
}

is_ascii_digit_fast :: proc(ch: rune) -> bool {
	return ch < 128 && get_ascii_table_entry(ch) == 2
}

is_ascii_punctuation_fast :: proc(ch: rune) -> bool {
	return ch < 128 && get_ascii_table_entry(ch) == 3
}

is_ascii_symbol_fast :: proc(ch: rune) -> bool {
	return ch < 128 && get_ascii_table_entry(ch) == 4
}

is_ascii_whitespace_fast :: proc(ch: rune) -> bool {
	return ch < 128 && get_ascii_table_entry(ch) == 5
}

is_ascii_word_char_fast :: proc(ch: rune) -> bool {
	if ch >= 128 {
		return false
	}
	table_val := get_ascii_table_entry(ch)
	return table_val == 1 || table_val == 2 || ch == '_'  // Letters, digits, or underscore
}

// Optimized Unicode property matching with early ASCII exit
match_unicode_property :: proc(ch: rune, property: Unicode_Category) -> bool {
	// Fast ASCII path for 95% of cases
	if ch < 128 {
		detailed_cat := get_unicode_category(ch)
		return detailed_cat == property
	}

	// Unicode path - check specific ranges
	switch property {
	case .Lowercase_Letter:
		return (ch >= 0x0061 && ch <= 0x007A) ||  // a-z
		       (ch >= 0x0430 && ch <= 0x044F) ||  // а-я
		       (ch >= 0x03B1 && ch <= 0x03C9) ||  // α-ω
		       is_latin_extended_lowercase(ch)

	case .Uppercase_Letter:
		return (ch >= 0x0041 && ch <= 0x005A) ||  // A-Z
		       (ch >= 0x0410 && ch <= 0x042F) ||  // А-Я
		       (ch >= 0x0391 && ch <= 0x03A9) ||  // Α-Ω
		       is_latin_extended_uppercase(ch)

	case .Decimal_Number:
		return (ch >= 0x0030 && ch <= 0x0039) ||  // 0-9
		       (ch >= 0x0660 && ch <= 0x0669) ||  // Arabic-Indic
		       (ch >= 0x06F0 && ch <= 0x06F9)     // Eastern Arabic-Indic

	case .Letter:
		return (ch >= 0x0041 && ch <= 0x005A) || (ch >= 0x0061 && ch <= 0x007A) ||  // Latin
		       (ch >= 0x0410 && ch <= 0x044F) ||                                      // Cyrillic
		       (ch >= 0x0391 && ch <= 0x03A9) || (ch >= 0x03B1 && ch <= 0x03C9) ||  // Greek
		       is_latin_extended_lowercase(ch) || is_latin_extended_uppercase(ch)

	case .Number:
		return (ch >= 0x0030 && ch <= 0x0039) ||  // ASCII digits
		       (ch >= 0x0660 && ch <= 0x0669) ||  // Arabic-Indic
		       (ch >= 0x06F0 && ch <= 0x06F9)     // Eastern Arabic-Indic

	case .Punctuation:
		return (ch >= 0x0021 && ch <= 0x002F) || (ch >= 0x003A && ch <= 0x0040) ||  // ASCII punctuation
		       (ch >= 0x005B && ch <= 0x0060) || (ch >= 0x007B && ch <= 0x007E) ||
		       (ch >= 0x2000 && ch <= 0x206F)  // General punctuation

	case .Symbol:
		return (ch >= 0x20A0 && ch <= 0x20CF) ||  // Currency symbols
		       (ch >= 0x2200 && ch <= 0x22FF)     // Math symbols

	case .Separator:
		return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' ||
		       ch == 0x00A0 || ch == 0x2000 || ch == 0x2001 ||
		       ch == 0x2002 || ch == 0x2003 || ch == 0x202F ||
		       ch == 0x2028 || ch == 0x2029

	case .Other:
		return (ch >= 0x0000 && ch <= 0x001F) || (ch >= 0x007F && ch <= 0x009F) ||
		       ch == 0xFFFD || ch >= 0xE0000  // Control and special characters

	// Handle detailed categories directly
	case .Unknown, .Title_Letter, .Modifier_Letter, .Other_Letter,
	     .Letter_Number, .Other_Number, .Connector_Punctuation, .Dash_Punctuation,
	     .Open_Punctuation, .Close_Punctuation, .Initial_Punctuation, .Final_Punctuation,
	     .Other_Punctuation, .Math_Symbol, .Currency_Symbol, .Modifier_Symbol,
	     .Other_Symbol, .Space_Separator, .Line_Separator, .Paragraph_Separator,
	     .Control, .Format, .Surrogate, .Private_Use, .Unassigned:
		return get_unicode_category(ch) == property
	}

	// Default fallback
	return false
}

// Helper functions for Latin Extended detection
@(private="file")
is_latin_extended_lowercase :: proc(ch: rune) -> bool {
	return (ch >= 0x0101 && ch <= 0x017F && ch % 2 == 1) ||  // Most Latin Extended-A lowercase
	       (ch >= 0x0180 && ch <= 0x024F && is_latin_ext_b_lowercase(ch))
}

@(private="file")
is_latin_extended_uppercase :: proc(ch: rune) -> bool {
	return (ch >= 0x0100 && ch <= 0x017E && ch % 2 == 0) ||  // Most Latin Extended-A uppercase
	       (ch >= 0x0180 && ch <= 0x024F && is_latin_ext_b_uppercase(ch))
}

@(private="file")
is_latin_ext_b_lowercase :: proc(ch: rune) -> bool {
	// Simplified check for common Latin Extended-B lowercase letters
	return (ch >= 0x0250 && ch <= 0x02AF) ||  // IPA Extensions
	       (ch >= 0x1D00 && ch <= 0x1D7F)     // Phonetic Extensions
}

@(private="file")
is_latin_ext_b_uppercase :: proc(ch: rune) -> bool {
	// Simplified check for common Latin Extended-B uppercase letters
	return (ch >= 0x0400 && ch <= 0x04FF && ch >= 0x0410 && ch <= 0x042F) ||  // Cyrillic (overlap)
	       (ch >= 0x1F00 && ch <= 0x1FFF && ch >= 0x1F08 && ch <= 0x1F0F)   // Greek (overlap)
}

// Batch property checking for multiple characters
match_property_batch :: proc(chars: []rune, property: Unicode_Category) -> bool {
	for ch in chars {
		if !match_unicode_property(ch, property) {
			return false
		}
	}
	return true
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

	// Latin Extended case folding - convert uppercase to lowercase
	if ch >= 0x0041 && ch <= 0x005A {
		return ch + 0x20  // A-Z -> a-z
	}
	if ch >= 0x00C0 && ch <= 0x00D6 && ch != 0x00D7 {
		return ch + 0x20  // À-Ö (excluding ×) -> à-ö
	}
	if ch >= 0x00D8 && ch <= 0x00DE {
		return ch + 0x20  // Ø-Þ -> ø-þ
	}

	// Greek uppercase to lowercase
	if ch >= 0x0391 && ch <= 0x03A1 {
		return ch + 0x20  // Α-Ρ -> α-ρ
	}
	if ch >= 0x03A3 && ch <= 0x03AB {
		return ch + 0x20  // Σ-Χ -> σ-χ
	}

	// Cyrillic uppercase to lowercase
	if ch >= 0x0410 && ch <= 0x042F {
		return ch + 0x20  // А-Я -> а-я
	}
	if ch >= 0x0400 && ch <= 0x040F {
		return ch + 0x50  // Ѐ-Џ → ѐ-џ
	}

	// For lowercase characters, return as-is (they're already "folded")
	return ch
}