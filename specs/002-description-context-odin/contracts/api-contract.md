# API Contract: Odin RE2 Performance Optimization

**Date**: 2025-10-12  
**Branch**: 002-description-context-odin  
**Purpose**: Define public API contracts maintaining 100% backward compatibility

## Core API Functions

### 1. Pattern Compilation API

#### `compile(pattern: string, flags: Regex_Flags) -> (^Regex_Pattern, Error)`

**Description**: Compiles a regex pattern into an optimized NFA program.

**Parameters**:
- `pattern`: Raw regex pattern string (UTF-8)
- `flags`: Compilation flags controlling behavior

**Returns**:
- `^Regex_Pattern`: Compiled pattern object (nil on error)
- `Error`: Compilation error details (nil on success)

**Error Conditions**:
- Invalid regex syntax
- Unsupported features
- Memory allocation failure
- Pattern too complex

**Performance Requirements**:
- Compilation time: < 10ms for typical patterns
- Memory usage: < 100KB for most patterns
- Cache lookup: < 1μs for cached patterns

**Thread Safety**: Thread-safe for concurrent compilation

#### `free_pattern(pattern: ^Regex_Pattern)`

**Description**: Releases resources associated with a compiled pattern.

**Parameters**:
- `pattern`: Pattern to free (nil-safe)

**Side Effects**:
- Removes pattern from compilation cache if present
- Releases arena memory
- Updates cache statistics

### 2. Pattern Matching API

#### `match_pattern(pattern: ^Regex_Pattern, text: string) -> Match_Result`

**Description**: Executes pattern matching against input text.

**Parameters**:
- `pattern`: Compiled regex pattern
- `text`: Target text for matching (UTF-8)

**Returns**:
- `Match_Result`: Complete match information including captures

**Performance Requirements**:
- Simple patterns: < 1ms on 60-character text
- Complex patterns: < 10ms on 60-character text
- Memory usage: < 1MB per operation
- Linear time complexity guaranteed

**Thread Safety**: Safe for concurrent matching with same pattern

#### `match_string(pattern: ^Regex_Pattern, text: string) -> bool`

**Description**: Simple boolean match test (optimized path).

**Parameters**:
- `pattern`: Compiled regex pattern
- `text`: Target text for matching

**Returns**:
- `bool`: True if pattern matches text

**Performance Requirements**:
- 50% faster than `match_pattern` for simple cases
- Same memory guarantees as `match_pattern`

### 3. Iterator API

#### `find_all(pattern: ^Regex_Pattern, text: string) -> Match_Iterator`

**Description**: Creates iterator for finding all non-overlapping matches.

**Parameters**:
- `pattern`: Compiled regex pattern
- `text`: Target text for searching

**Returns**:
- `Match_Iterator`: Iterator over all matches

**Iterator Methods**:
```odin
next :: proc(iter: ^Match_Iterator) -> (Match_Result, bool)
reset :: proc(iter: ^Match_Iterator)
```

**Performance Requirements**:
- O(n) total time for all matches
- Constant memory overhead per iteration
- No repeated pattern compilation

### 4. Utility API

#### `get_version() -> string`

**Description**: Returns library version information.

**Returns**:
- `string`: Version string in format "major.minor.patch"

#### `get_performance_metrics() -> Performance_Metrics`

**Description**: Returns aggregated performance statistics.

**Returns**:
- `Performance_Metrics`: Global performance data

**Thread Safety**: Thread-safe, returns snapshot

#### `clear_cache()`

**Description**: Clears the pattern compilation cache.

**Side Effects**:
- Releases all cached patterns
- Resets cache statistics
- Frees associated arena memory

## Data Type Contracts

### Regex_Flags

```odin
Regex_Flags :: struct #packed {
    case_insensitive: bool,  // Ignore case in matching
    multiline:        bool,  // ^ and $ match line boundaries
    dot_all:          bool,  // . matches newlines
    unicode:          bool,  // Unicode character classes
    anchored:         bool,  // Match only at beginning
    non_greedy:       bool,  // Non-greedy quantifiers
    _reserved:        u10,   // Future use
}
```

**Constraints**:
- Reserved bits must be zero
- Flag combinations must be logically consistent
- Default value: all flags false

### Match_Result

```odin
Match_Result :: struct {
    success:        bool,            // Match found
    start_pos:      int,             // Start byte position
    end_pos:        int,             // End byte position
    captures:       []Capture_Group, // Capture groups
    match_time_ns:  u64,             // Execution time
    memory_used:    u32,             // Memory consumed
}
```

**Constraints**:
- `success` false ⇒ `start_pos = end_pos = -1`
- `captures[0]` = full match if `success` true
- All positions are byte offsets, not rune offsets
- `captures` length = pattern capture count

### Capture_Group

```odin
Capture_Group :: struct {
    present: bool,    // Group participated in match
    start:   int,     // Start position (-1 if not present)
    end:     int,     // End position (-1 if not present)
}
```

**Constraints**:
- `present` false ⇒ `start = end = -1`
- `start <= end` when `present` true
- Positions are within input text bounds

### Error Type

```odin
Error :: struct {
    code:    Error_Code,    // Error classification
    message: string,        // Human-readable description
    position: int,          // Position in pattern (if applicable)
}

Error_Code :: enum {
    None,                   // No error
    Invalid_Syntax,         // Regex syntax error
    Unsupported_Feature,    // Feature not implemented
    Memory_Exhausted,       // Out of memory
    Pattern_Too_Large,      // Pattern exceeds limits
    Invalid_UTF8,          // Invalid UTF-8 in text
}
```

**Constraints**:
- `message` provides actionable error information
- `position` is -1 if not applicable to error type
- Error codes are mutually exclusive

## Performance Contracts

### Time Complexity Guarantees

| Operation | Worst Case | Typical Case | Guarantee |
|-----------|------------|--------------|-----------|
| Pattern Compilation | O(m²) | O(m) | < 10ms for m < 1KB |
| Simple Matching | O(n) | O(n) | Linear time |
| Complex Matching | O(n×m) | O(n+k) | No exponential behavior |
| Iterator Next | O(k) | O(1) | Amortized O(1) |

Where:
- n = input text length
- m = pattern length  
- k = match length

### Memory Usage Guarantees

| Component | Maximum Usage | Growth Rate | Notes |
|-----------|---------------|-------------|-------|
| Pattern Storage | 100KB | O(m) | Per pattern |
| Matching Operation | 1MB | O(n) | Per operation |
| Thread Pool | 64KB | Fixed | Pre-allocated |
| Cache Storage | 10MB | Configurable | LRU eviction |

### Concurrency Guarantees

- **Pattern Sharing**: Compiled patterns are immutable and thread-safe
- **Concurrent Matching**: Unlimited concurrent operations with independent performance
- **Cache Access**: Thread-safe with minimal contention
- **Memory Isolation**: Each operation uses isolated arena allocation

## Compatibility Requirements

### API Compatibility

**Must Preserve**:
- All existing function signatures
- All existing data structure layouts
- All existing error codes and messages
- All existing behavior semantics

**Allowed Changes**:
- Internal implementation optimizations
- Performance improvements
- Memory usage reductions
- Additional error information

**Forbidden Changes**:
- Function signature modifications
- Data structure layout changes
- Behavior semantic changes
- Error code removal or modification

### Semantic Compatibility

**Matching Behavior**:
- All RE2 syntax features must work identically
- Unicode handling must be preserved
- Capture group semantics must be identical
- Anchor behavior must be consistent

**Error Handling**:
- Same error conditions for same inputs
- Same error messages (or more informative)
- Same error codes
- Same error positions in patterns

## Testing Contracts

### Unit Test Requirements

Each API function must have tests covering:
- Normal operation paths
- Error conditions
- Edge cases (empty strings, complex patterns)
- Performance regression detection
- Thread safety validation

### Integration Test Requirements

Integration tests must verify:
- End-to-end matching workflows
- Cache behavior and performance
- Concurrent operation correctness
- Memory usage within bounds
- Performance targets achieved

### Benchmark Requirements

Performance benchmarks must measure:
- Compilation time for various pattern complexities
- Matching time for different text sizes
- Memory usage patterns
- Cache hit/miss ratios
- Concurrent operation scalability

## Quality Gates

### Pre-merge Requirements

- All existing tests must pass without modification
- New performance tests must meet targets
- Code coverage must not decrease
- Static analysis must find no new issues
- Documentation must be updated

### Release Requirements

- Performance targets achieved on all platforms
- Memory usage within specified bounds
- No regressions in compatibility tests
- Documentation complete and accurate
- Performance benchmarks stable

This API contract ensures that the performance optimization maintains complete backward compatibility while delivering the required improvements in speed and memory efficiency.