# API Contract - Odin RE2 Implementation

**Version**: 1.0.0  
**Date**: 2025-10-09  
**Purpose**: Public API specification for RE2-compatible regex engine

## Core API Functions

### regexp(pattern: string) -> (^Regexp_Pattern, ErrorCode)
**Purpose**: Compile a regular expression pattern
**Parameters**:
- `pattern: string` - Regular expression to compile
**Returns**:
- `^Regexp_Pattern` - Compiled pattern (nil on error)
- `ErrorCode` - Compilation status (NoError on success)
**Error Conditions**:
- ParseError: Invalid regex syntax
- MemoryError: Out of memory during compilation
- UTF8Error: Invalid UTF-8 in pattern
**Example**:
```odin
pattern, err := regexp("hello\\s+world")
if err != .NoError {
    // handle error
}
defer free_regexp(pattern)
```

### free_regexp(pattern: ^Regexp_Pattern)
**Purpose**: Free memory allocated for compiled pattern
**Parameters**:
- `pattern: ^Regexp_Pattern` - Pattern to free (nil-safe)
**Side Effects**: Releases all memory associated with pattern
**Requirements**: Must be called for every successful regexp() call

### match(pattern: ^Regexp_Pattern, text: string) -> (Match_Result, ErrorCode)
**Purpose**: Match compiled pattern against text
**Parameters**:
- `pattern: ^Regexp_Pattern` - Compiled pattern
- `text: string` - Text to search
**Returns**:
- `Match_Result` - Match result with captures
- `ErrorCode` - Match status
**Error Conditions**:
- InternalError: Pattern or system error
- UTF8Error: Invalid UTF-8 in input text
**Example**:
```odin
result, err := match(pattern, "hello   world")
if err == .NoError && result.matched {
    // process match
    fmt.printf("Found at %d-%d\n", result.full_match.start, result.full_match.end)
}
```

### match_string(pattern, text: string) -> (bool, ErrorCode)
**Purpose**: Convenience function for one-shot matching
**Parameters**:
- `pattern: string` - Regex pattern
- `text: string` - Text to search
**Returns**:
- `bool` - Whether pattern matched
- `ErrorCode` - Operation status
**Behavior**: Compiles and matches in one call, automatically cleans up

## Data Structures

### Regexp_Pattern
```odin
Regexp_Pattern :: struct {
    ast:     ^Regexp,    // Parsed AST
    arena:   ^Arena,     // Memory arena
    error:   ErrorCode,  // Compilation error
}
```

### Match_Result
```odin
Match_Result :: struct {
    matched:    bool,      // Whether pattern matched
    full_match: Range,     // Location of full match
    captures:   []Range,   // Capture group locations
    text:       string,    // Original input text
}
```

### Range
```odin
Range :: struct {
    start: int,  // Start position (inclusive)
    end:   int,  // End position (exclusive)
}
```

### ErrorCode
```odin
ErrorCode :: enum {
    NoError,
    ParseError,
    MemoryError,
    InternalError,
    UTF8Error,
    TooComplex,
    InvalidCapture,
    ErrorUnexpectedParen,
    ErrorTrailingBackslash,
    ErrorBadEscape,
    ErrorMissingParen,
    ErrorMissingBracket,
    ErrorInvalidRepeat,
    ErrorInvalidRepeatSize,
    ErrorInvalidCharacterClass,
    ErrorInvalidPerlOp,
    ErrorInvalidUTF8,
}
```

## Performance Guarantees

### Time Complexity
- **Compilation**: O(pattern_length) - Linear in pattern size
- **Matching**: O(input_length) - Linear in input size
- **Memory Usage**: Bounded by configurable DFA cache limits

### Memory Management
- All allocations use arena allocator for efficiency
- Patterns must be explicitly freed with free_regexp()
- No garbage collection dependencies
- Thread-safe for concurrent matching (same pattern can be used by multiple threads)

## RE2 Compatibility Requirements

### Supported Features
- All RE2 regex syntax (except backreferences)
- Unicode UTF-8 support
- Capturing groups and non-capturing groups
- Character classes and ranges
- Quantifiers: *, +, ?, {n}, {n,}, {n,m}
- Anchors: ^, $, \A, \z
- Word boundaries: \b, \B
- Alternation: |
- Escape sequences: \n, \t, \r, \\, etc.

### Unsupported Features (by design)
- Backreferences: \1, \2, etc. (breaks linear-time guarantee)
- Lookaround assertions: (?=...), (?!...) etc.
- Conditional patterns: (?(condition)...)
- Recursive patterns

### Error Compatibility
- Error codes match RE2 semantics
- Error messages follow RE2 format
- Parse error positions are byte offsets in pattern

## Usage Patterns

### Basic Matching
```odin
// Compile once, use many times
pattern, err := regexp("hello\\s+world")
defer free_regexp(pattern)

result, err := match(pattern, "hello   world")
if err == .NoError && result.matched {
    fmt.println("Match found!")
}
```

### One-shot Matching
```odin
matched, err := match_string("test\\d+", "example test123")
if err == .NoError && matched {
    fmt.println("Pattern matched!")
}
```

### Capture Groups
```odin
pattern, _ := regexp("(\\d+)-(\\d+)")
defer free_regexp(pattern)

result, _ := match(pattern, "123-456")
if result.matched && len(result.captures) >= 3 {
    fmt.printf("Full: %q\n", result.text[result.full_match.start:result.full_match.end])
    fmt.printf("Group 1: %q\n", result.text[result.captures[1].start:result.captures[1].end])
    fmt.printf("Group 2: %q\n", result.text[result.captures[2].start:result.captures[2].end])
}
```

## Thread Safety

### Concurrent Matching
- Multiple threads can safely use the same Regexp_Pattern simultaneously
- Each thread gets its own execution context
- No global state or mutable shared data

### Memory Safety
- Arena allocation is thread-local for matching operations
- Compilation creates immutable AST structures
- Pattern compilation is not thread-safe (use external synchronization)

## Implementation Constraints

### Memory Limits
- DFA state cache configurable (default 1MB)
- Maximum pattern complexity enforced
- Bounded recursion depth

### Performance Targets
- Within 2x of native RE2 performance
- Linear time guarantee for all inputs
- Memory usage proportional to pattern + input size

This API contract ensures 100% RE2 compatibility while leveraging Odin's performance characteristics and memory management model.