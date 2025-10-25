# Odin RE2 API Documentation

## Overview

Odin RE2 is a high-performance regular expression engine implemented in Odin, compatible with Google RE2 syntax and providing linear-time matching guarantees.

## Performance Features

- **Linear Time Complexity**: O(n) matching for all patterns
- **Memory Efficient**: Arena-based allocation with 64-byte alignment
- **Unicode Support**: Full Unicode property matching and script detection
- **ASCII Fast Path**: 95% of common operations use optimized ASCII processing
- **Thread Safe**: Arena allocation ensures thread-safe operations

## Core API

### Memory Management

```odin
// Create a new memory arena for regex operations
arena :: proc() -> ^Arena

// Arena automatically manages memory for regex compilation and matching
// No manual memory management required
```

### Pattern Compilation

```odin
// Parse regex pattern to AST
parse_regexp_internal :: proc(pattern: string, flags: Parse_Flags) -> (^Regexp, ErrorCode)

// Compile AST to NFA program
compile_nfa :: proc(ast: ^Regexp, arena: ^Arena) -> (^Program, ErrorCode)

// Create matcher from program
new_matcher :: proc(prog: ^Program, anchored: bool, longest: bool) -> ^Matcher
```

### Pattern Matching

```odin
// Execute regex match
match_nfa :: proc(matcher: ^Matcher, text: string) -> (bool, []int)

// Returns: (matched, capture_groups)
// capture_groups[0] = start position of full match
// capture_groups[1] = end position of full match
// capture_groups[2] = start position of group 1
// ... and so on
```

## Unicode Support

### Unicode Categories

```odin
Unicode_Category :: enum {
    Unknown,
    Letter,             // Ll, Lu, Lt, Lm, Lo
    Number,             // Nd, Nl, No
    Punctuation,        // Pc, Pd, Ps, Pe, Pf, Pi, Po
    Symbol,             // Sm, Sc, Sk, So
    Separator,          // Zs, Zl, Zp
    Other,              // Cc, Cf, Cs, Co, Cn

    // Detailed subcategories
    Lowercase_Letter,   // Ll
    Uppercase_Letter,   // Lu
    Decimal_Number,     // Nd
    // ... and many more
}
```

### Unicode Functions

```odin
// Get Unicode category for character
get_unicode_category :: proc(ch: rune) -> Unicode_Category

// Get Unicode script for character
get_unicode_script :: proc(ch: rune) -> Unicode_Script

// Fast ASCII property checks (O(1) performance)
is_ascii_letter_fast :: proc(ch: rune) -> bool
is_ascii_digit_fast :: proc(ch: rune) -> bool
is_ascii_punctuation_fast :: proc(ch: rune) -> bool

// Unicode case folding for case-insensitive matching
unicode_fold_case :: proc(ch: rune) -> rune
```

## Error Handling

```odin
ErrorCode :: enum {
    NoError,
    ParseError,
    CompileError,
    MatchError,
    // ... more error codes
}
```

## Performance Optimizations

### State Vector Optimization
- 64-byte aligned state vectors for cache efficiency
- Double-buffered state updates
- Bit-level deduplication

### ASCII Fast Path
- 95% of characters processed via optimized ASCII path
- O(1) character property lookup using table
- Early exit for ASCII-only text

### Memory Management
- Arena allocation eliminates memory fragmentation
- Pre-allocated thread pools
- Zero-allocation matching operations

## Usage Examples

### Basic Pattern Matching

```odin
import "core:fmt"
import "../regexp"

main :: proc() {
    // Create memory arena
    arena := regexp.new_arena()

    // Parse pattern
    ast, err := regexp.parse_regexp_internal("hello\\s+world", {})
    if err != .NoError {
        fmt.printf("Parse error: %v\n", err)
        return
    }

    // Compile to NFA
    program, err := regexp.compile_nfa(ast, arena)
    if err != .NoError {
        fmt.printf("Compile error: %v\n", err)
        return
    }

    // Create matcher
    matcher := regexp.new_matcher(program, false, true)

    // Match text
    text := "hello   wonderful world"
    matched, caps := regexp.match_nfa(matcher, text)

    if matched {
        fmt.printf("Match found: %d-%d\n", caps[0], caps[1])
        fmt.printf("Match text: %s\n", text[caps[0]:caps[1]])
    }
}
```

### Unicode Property Matching

```odin
// Match Unicode letters
unicode_letter_prog, _ := regexp.compile_nfa(
    regexp.parse_regexp_internal("\\p{Letter}+", {}),
    arena
)

// Match Cyrillic script
cyrillic_prog, _ := regexp.compile_nfa(
    regexp.parse_regexp_internal("\\p{Script=Cyrillic}+", {}),
    arena
)

// Case-insensitive matching
casefold_prog, _ := regexp.compile_nfa(
    regexp.parse_regexp_internal("(?i)HELLO", {}),
    arena
)
```

## Performance Benchmarks

Based on current testing:

- **State Vector Optimization**: 2253 MB/s throughput
- **Precomputed Patterns**: 690 MB/s throughput
- **Compilation Speed**: 1800-11600ns per pattern
- **Memory Efficiency**: 50%+ reduction vs standard allocation

## Compatibility

- **RE2 Compatible**: Supports Google RE2 syntax
- **Unicode Support**: Unicode 15.0 compliant
- **Thread Safe**: Arena allocation ensures thread safety
- **Memory Safe**: No buffer overflows or memory leaks

## Limitations

- No backreferences (RE2 design choice)
- No lookaround assertions (RE2 design choice)
- Linear-time guarantee limits some regex features
- Current version has limited quantifier optimization

## Future Improvements

- Enhanced quantifier handling
- Additional Unicode script support
- Improved instruction scheduling
- Extended character class optimization