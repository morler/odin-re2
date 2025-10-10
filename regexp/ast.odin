package regexp

// Abstract Syntax Tree for RE2-compatible regex engine
// Core data structures matching RE2 exactly for compatibility

import "core:unicode"
import "core:mem"

// Regular expression operation types (must match RE2 exactly)
Regexp_Op :: enum {
	NoOp,           // No operation
	OpLiteral,      // Literal string
	OpCharClass,    // Character class [a-z]
	OpAnyChar,      // Any character .
	OpAnyCharNotNL, // Any character except newline
	OpBeginLine,    // Beginning of line ^
	OpEndLine,      // End of line $
	OpBeginText,    // Beginning of text \A
	OpEndText,      // End of text \z
	OpWordBoundary, // Word boundary \b
	OpNoWordBoundary, // Not word boundary \B
	OpCapture,      // Capturing group (parentheses)
	OpStar,         // Kleene star *
	OpPlus,         // Plus +
	OpQuest,        // Question mark ?
	OpRepeat,       // Repeat {n,m}
	OpConcat,       // Concatenation
	OpAlternate,    // Alternation |
}

// Regex flags for behavior modification
Flags :: struct {
	NonGreedy:      bool, // Non-greedy matching
	CaseInsensitive: bool, // Case insensitive matching
	DotAll:         bool, // Dot matches all characters including newline
	MultiLine:      bool, // Multi-line mode for ^ and $
	Unicode:        bool, // Unicode character classes
}

// Character range for character classes
Char_Range :: struct {
	lo: rune, // Range start (inclusive)
	hi: rune, // Range end (inclusive)
}

// Character class data
CharClass_Data :: struct {
	ranges:   []Char_Range, // Character ranges
	negated:  bool,         // Negated class [^a-z]
}

// Literal string data
Literal_Data :: struct {
	str: String_View, // Literal string
}

// Capture group data
Capture_Data :: struct {
	cap:    int,    // Capture group number
	sub:    ^Regexp, // Sub-expression
	name:   string, // Named capture (future feature)
}

// Repeat data for quantifiers
Repeat_Data :: struct {
	min:    int,     // Minimum repetitions
	max:    int,     // Maximum repetitions (-1 for unlimited)
	sub:    ^Regexp, // Sub-expression
	non_greedy: bool, // Non-greedy flag
}

// Concatenation data (array of sub-expressions)
Concat_Data :: struct {
	subs: []^Regexp, // Sub-expressions in order
}

// Alternation data (array of choices)
Alternate_Data :: struct {
	subs: []^Regexp, // Alternative expressions
}

// Main AST node structure
Regexp :: struct {
	op:    Regexp_Op, // Operation type
	flags: Flags,     // Regex flags
	data:  rawptr,    // Type-specific data pointer
}

// ============================================================================
// AST Node Creation Functions
// ============================================================================

// Create literal node
make_literal :: proc(arena: ^Arena, str: string) -> ^Regexp {
	node := (^Regexp)(arena_alloc(arena, size_of(Regexp)))
	node^ = Regexp{
		op = .OpLiteral,
		flags = {},
		data = arena_alloc(arena, size_of(Literal_Data)),
	}
	
	lit_data := (^Literal_Data)(node.data)
	lit_data^ = Literal_Data{str = make_string_view(str)}
	
	return node
}

// Create character class node
make_char_class :: proc(arena: ^Arena, ranges: []Char_Range, negated: bool) -> ^Regexp {
	node := (^Regexp)(arena_alloc(arena, size_of(Regexp)))
	node^ = Regexp{
		op = .OpCharClass,
		flags = {},
		data = arena_alloc(arena, size_of(CharClass_Data)),
	}
	
	cc_data := (^CharClass_Data)(node.data)
	cc_data.ranges = make([]Char_Range, len(ranges))
	mem.copy(cc_data.ranges, ranges, len(ranges) * size_of(Char_Range))
	cc_data.negated = negated
	
	return node
}

// Create any character node
make_any_char :: proc(arena: ^Arena, not_nl: bool) -> ^Regexp {
	node := (^Regexp)(arena_alloc(arena, size_of(Regexp)))
	node^ = Regexp{
		op = not_nl ? .OpAnyCharNotNL : .OpAnyChar,
		flags = {},
		data = nil,
	}
	return node
}

// Create anchor node
make_anchor :: proc(arena: ^Arena, op: Regexp_Op) -> ^Regexp {
	assert(op == .OpBeginLine || op == .OpEndLine || 
	       op == .OpBeginText || op == .OpEndText ||
	       op == .OpWordBoundary || op == .OpNoWordBoundary)
	
	node := (^Regexp)(arena_alloc(arena, size_of(Regexp)))
	node^ = Regexp{
		op = op,
		flags = {},
		data = nil,
	}
	return node
}

// Create capture group node
make_capture :: proc(arena: ^Arena, cap: int, sub: ^Regexp) -> ^Regexp {
	node := (^Regexp)(arena_alloc(arena, size_of(Regexp)))
	node^ = Regexp{
		op = .OpCapture,
		flags = {},
		data = arena_alloc(arena, size_of(Capture_Data)),
	}
	
	cap_data := (^Capture_Data)(node.data)
	cap_data^ = Capture_Data{cap = cap, sub = sub}
	
	return node
}

// Create quantifier node
make_repeat :: proc(arena: ^Arena, op: Regexp_Op, sub: ^Regexp, min: int, max: int, non_greedy: bool) -> ^Regexp {
	assert(op == .OpStar || op == .OpPlus || op == .OpQuest || op == .OpRepeat)
	
	node := (^Regexp)(arena_alloc(arena, size_of(Regexp)))
	node^ = Regexp{
		op = op,
		flags = Flags{NonGreedy = non_greedy},
		data = arena_alloc(arena, size_of(Repeat_Data)),
	}
	
	rep_data := (^Repeat_Data)(node.data)
	rep_data^ = Repeat_Data{
		min = min,
		max = max,
		sub = sub,
		non_greedy = non_greedy,
	}
	
	return node
}

// Create concatenation node
make_concat :: proc(arena: ^Arena, subs: []^Regexp) -> ^Regexp {
	if len(subs) == 1 {
		return subs[0] // Optimize single-element concatenation
	}
	
	node := (^Regexp)(arena_alloc(arena, size_of(Regexp)))
	node^ = Regexp{
		op = .OpConcat,
		flags = {},
		data = arena_alloc(arena, size_of(Concat_Data)),
	}
	
	concat_data := (^Concat_Data)(node.data)
	concat_data.subs = make([]^Regexp, len(subs))
	mem.copy(concat_data.subs, subs, len(subs) * size_of(^Regexp))
	
	return node
}

// Create alternation node
make_alternate :: proc(arena: ^Arena, subs: []^Regexp) -> ^Regexp {
	if len(subs) == 1 {
		return subs[0] // Optimize single-element alternation
	}
	
	node := (^Regexp)(arena_alloc(arena, size_of(Regexp)))
	node^ = Regexp{
		op = .OpAlternate,
		flags = {},
		data = arena_alloc(arena, size_of(Alternate_Data)),
	}
	
	alt_data := (^Alternate_Data)(node.data)
	alt_data.subs = make([]^Regexp, len(subs))
	mem.copy(alt_data.subs, subs, len(subs) * size_of(^Regexp))
	
	return node
}

// ============================================================================
// AST Utility Functions
// ============================================================================

// Get string representation of operation type
op_string :: proc(op: Regexp_Op) -> string {
	switch op {
	case .NoOp:
		return "NoOp"
	case .OpLiteral:
		return "Literal"
	case .OpCharClass:
		return "CharClass"
	case .OpAnyChar:
		return "AnyChar"
	case .OpAnyCharNotNL:
		return "AnyCharNotNL"
	case .OpBeginLine:
		return "BeginLine"
	case .OpEndLine:
		return "EndLine"
	case .OpBeginText:
		return "BeginText"
	case .OpEndText:
		return "EndText"
	case .OpWordBoundary:
		return "WordBoundary"
	case .OpNoWordBoundary:
		return "NoWordBoundary"
	case .OpCapture:
		return "Capture"
	case .OpStar:
		return "Star"
	case .OpPlus:
		return "Plus"
	case .OpQuest:
		return "Quest"
	case .OpRepeat:
		return "Repeat"
	case .OpConcat:
		return "Concat"
	case .OpAlternate:
		return "Alternate"
	}
	return "Unknown"
}

// Check if node can match empty string
can_match_empty :: proc(node: ^Regexp) -> bool {
	if node == nil {
		return true
	}
	
	switch node.op {
	case .NoOp:
		return true
	case .OpLiteral:
		return false
	case .OpCharClass:
		return false
	case .OpAnyChar, .OpAnyCharNotNL:
		return false
	case .OpBeginLine, .OpEndLine, .OpBeginText, .OpEndText:
		return true
	case .OpWordBoundary, .OpNoWordBoundary:
		return true
	case .OpCapture:
		cap_data := (^Capture_Data)(node.data)
		return can_match_empty(cap_data.sub)
	case .OpStar:
		return true
	case .OpPlus:
		rep_data := (^Repeat_Data)(node.data)
		return can_match_empty(rep_data.sub)
	case .OpQuest:
		return true
	case .OpRepeat:
		rep_data := (^Repeat_Data)(node.data)
		return rep_data.min == 0 || can_match_empty(rep_data.sub)
	case .OpConcat:
		concat_data := (^Concat_Data)(node.data)
		for sub in concat_data.subs {
			if !can_match_empty(sub) {
				return false
			}
		}
		return true
	case .OpAlternate:
		alt_data := (^Alternate_Data)(node.data)
		for sub in alt_data.subs {
			if can_match_empty(sub) {
				return true
			}
		}
		return false
	}
	return false
}

// Count capture groups in AST
count_captures :: proc(node: ^Regexp) -> int {
	if node == nil {
		return 0
	}
	
	switch node.op {
	case .OpCapture:
		cap_data := (^Capture_Data)(node.data)
		return 1 + count_captures(cap_data.sub)
	case .OpConcat:
		concat_data := (^Concat_Data)(node.data)
		total := 0
		for sub in concat_data.subs {
			total += count_captures(sub)
		}
		return total
	case .OpAlternate:
		alt_data := (^Alternate_Data)(node.data)
		total := 0
		for sub in alt_data.subs {
			total += count_captures(sub)
		}
		return total
	case .OpStar, .OpPlus, .OpQuest, .OpRepeat:
		rep_data := (^Repeat_Data)(node.data)
		return count_captures(rep_data.sub)
	}
	return 0
}

// Simplify AST by removing unnecessary nodes
simplify :: proc(arena: ^Arena, node: ^Regexp) -> ^Regexp {
	if node == nil {
		return nil
	}
	
	switch node.op {
	case .OpConcat:
		concat_data := (^Concat_Data)(node.data)
		new_subs := make([]^Regexp, 0, len(concat_data.subs))
		
		for sub in concat_data.subs {
			simplified := simplify(arena, sub)
			if simplified != nil {
				if simplified.op == .OpConcat {
					// Flatten nested concatenations
					nested_data := (^Concat_Data)(simplified.data)
					for nested_sub in nested_data.subs {
						append(&new_subs, nested_sub)
					}
				} else {
					append(&new_subs, simplified)
				}
			}
		}
		
		if len(new_subs) == 0 {
			return nil
		} else if len(new_subs) == 1 {
			return new_subs[0]
		} else {
			return make_concat(arena, new_subs)
		}
		
	case .OpAlternate:
		alt_data := (^Alternate_Data)(node.data)
		new_subs := make([]^Regexp, 0, len(alt_data.subs))
		
		for sub in alt_data.subs {
			simplified := simplify(arena, sub)
			if simplified != nil {
				if simplified.op == .OpAlternate {
					// Flatten nested alternations
					nested_data := (^Alternate_Data)(simplified.data)
					for nested_sub in nested_data.subs {
						append(&new_subs, nested_sub)
					}
				} else {
					append(&new_subs, simplified)
				}
			}
		}
		
		if len(new_subs) == 0 {
			return nil
		} else if len(new_subs) == 1 {
			return new_subs[0]
		} else {
			return make_alternate(arena, new_subs)
		}
		
	case .OpStar, .OpPlus, .OpQuest, .OpRepeat:
		rep_data := (^Repeat_Data)(node.data)
		simplified_sub := simplify(arena, rep_data.sub)
		if simplified_sub == nil {
			return nil
		}
		return make_repeat(arena, node.op, simplified_sub, rep_data.min, rep_data.max, rep_data.non_greedy)
		
	case .OpCapture:
		cap_data := (^Capture_Data)(node.data)
		simplified_sub := simplify(arena, cap_data.sub)
		if simplified_sub == nil {
			return nil
		}
		return make_capture(arena, cap_data.cap, simplified_sub)
	}
	
	return node
}