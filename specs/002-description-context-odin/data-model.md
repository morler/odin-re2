# Data Model: Odin RE2 Performance Optimization

**Date**: 2025-10-12  
**Branch**: 002-description-context-odin  
**Purpose**: Define core entities and relationships for optimized regex engine

## Core Entities

### 1. Regex Pattern

**Description**: Represents a compiled regular expression with optimized NFA representation.

**Fields**:
```odin
Regex_Pattern :: struct {
    prog:          ^Prog,           // Compiled NFA program
    arena:         ^Arena,          // Memory arena for program data
    inst_count:    u32,             // Number of instructions
    capture_count: u32,             // Number of capture groups
    flags:         Regex_Flags,     // Compilation flags
    cache_key:     u64,             // Hash for pattern cache lookup
}

Regex_Flags :: struct #packed {
    case_insensitive: bool,
    multiline:        bool,
    dot_all:          bool,
    unicode:          bool,
    anchored:         bool,
    non_greedy:       bool,
    _reserved:        u10,           // Future flags
}
```

**Validation Rules**:
- `prog` must not be nil after successful compilation
- `inst_count` must be > 0 for valid patterns
- `capture_count` includes implicit group 0
- `cache_key` must be unique for pattern text + flags combination

**State Transitions**:
```
Source Text → Parser → AST → NFA Compiler → Regex_Pattern
     ↓              ↓        ↓           ↓              ↓
  Raw Text   →   Parsed   →  Optimized  →  Compiled   →  Ready
```

### 2. Text Input

**Description**: Represents target text for pattern matching with UTF-8 handling.

**Fields**:
```odin
Text_Input :: struct {
    data:      []byte,          // Raw UTF-8 bytes
    length:    int,             // Byte length
    rune_count: int,            // Unicode rune count
    iterator:  UTF8_Iterator,   // Efficient rune iteration
}

UTF8_Iterator :: struct {
    data:   []byte,
    pos:    int,
    width:  int,
    current: rune,
}
```

**Validation Rules**:
- `data` must be valid UTF-8 encoding
- `length` equals `len(data)`
- `rune_count` computed during initialization
- `iterator.pos` always <= `length`

**Relationships**:
- Text_Input → Matcher (1:many) - Same text can be matched against multiple patterns
- Text_Input → UTF8_Iterator (1:1) - Iterator for efficient rune access

### 3. Match Result

**Description**: Represents the outcome of a regex matching operation.

**Fields**:
```odin
Match_Result :: struct {
    success:        bool,            // Whether match was found
    start_pos:      int,             // Start byte position
    end_pos:        int,             // End byte position  
    captures:       []Capture_Group, // Capture group results
    match_time_ns:  u64,             // Performance metric
    memory_used:    u32,             // Memory usage tracking
}

Capture_Group :: struct {
    present: bool,    // Whether group participated in match
    start:   int,     // Start position (-1 if not present)
    end:     int,     // End position (-1 if not present)
}
```

**Validation Rules**:
- `success` false implies `start_pos` = `end_pos` = -1
- `captures[0]` always represents the full match if `success` is true
- `captures` length equals pattern's `capture_count`
- `start_pos` <= `end_pos` when `present` is true

**State Transitions**:
```
Matcher Execution → State Processing → Result Construction → Match_Result
```

### 4. Performance Metrics

**Description**: Tracks timing and memory usage for optimization validation.

**Fields**:
```odin
Performance_Metrics :: struct {
    compile_time_ns:    u64,    // Pattern compilation time
    match_time_ns:      u64,    // Pattern matching time
    peak_memory_bytes:  u32,    // Peak memory usage
    instructions_executed: u64, // Total NFA instructions processed
    states_processed:   u64,    // Total NFA states visited
    cache_hits:         u32,    // Pattern cache hits
    cache_misses:       u32,    // Pattern cache misses
}
```

**Validation Rules**:
- All timing values in nanoseconds
- Memory values in bytes
- `cache_hits + cache_misses` = total pattern compilations
- `states_processed` >= `instructions_executed`

### 5. Compilation Cache

**Description**: Manages pre-compiled patterns for efficient reuse.

**Fields**:
```odin
Compilation_Cache :: struct {
    entries:    []Cache_Entry,   // Cache entries
    capacity:   u32,             // Maximum entries
    count:      u32,             // Current entries
    arena:      ^Arena,          // Memory for cached data
    mutex:      sync.Mutex,      // Thread safety
}

Cache_Entry :: struct {
    pattern_hash: u64,           // Hash of pattern + flags
    regex:        ^Regex_Pattern, // Compiled pattern
    access_count: u32,           // LRU tracking
    last_access:  u64,           // Timestamp
}
```

**Validation Rules**:
- `count` <= `capacity`
- `pattern_hash` unique across all entries
- `regex` not nil for valid entries
- LRU eviction when `count` == `capacity`

## Entity Relationships

### Primary Relationship Flow
```
Text_Input + Regex_Pattern → Matcher → Match_Result + Performance_Metrics
```

### Detailed Relationship Map

```
Regex_Pattern (1) ──────┐
                        ├─→ Matcher (1) ──→ Match_Result (many)
                        │                    │
Text_Input (many) ──────┘                    ├─→ Performance_Metrics (1)
                                             │
Compilation_Cache (1) ──────────────────────┘
```

### Cardinality Rules
- **Regex_Pattern → Matcher**: 1-to-many (same pattern, different texts)
- **Text_Input → Matcher**: 1-to-many (same text, different patterns)  
- **Matcher → Match_Result**: 1-to-many (multiple matches possible)
- **Matcher → Performance_Metrics**: 1-to-1 (one metric set per operation)
- **Compilation_Cache → Regex_Pattern**: 1-to-many (cache stores many patterns)

## Data Flow Patterns

### 1. Pattern Compilation Flow
```
Source Text → Parser → AST → NFA Builder → Instruction Optimizer → Regex_Pattern
     ↓           ↓        ↓         ↓              ↓                    ↓
  Validation  Syntax   Semantic  Code Gen      Peephole            Cache
             Check    Analysis                Optimization        Storage
```

### 2. Pattern Matching Flow
```
Regex_Pattern + Text_Input → Matcher Initialization → NFA Simulation → Result Construction
              ↓                         ↓                        ↓                    ↓
         Cache Lookup              Thread Pool           State Processing    Capture Group
                                      Prep              & Transition         Resolution
```

### 3. Performance Monitoring Flow
```
Operation Start → Timer Start → Memory Tracking → Operation End → Timer Stop → Metrics Aggregation
       ↓               ↓              ↓               ↓             ↓                ↓
   Baseline      High-Resolution    Arena Usage    Success/Fail   Duration        Storage
   Capture       Timer              Monitoring     Detection      Calculation     & Report
```

## State Management

### Thread-Safe States
- **Compilation_Cache**: Protected by mutex for concurrent access
- **Regex_Pattern**: Immutable after compilation, safe for sharing
- **Performance_Metrics**: Thread-local aggregation, global reporting

### Arena Lifecycle
```
Arena Creation → Pattern Compilation → Matching Operations → Arena Destruction
      ↓                ↓                      ↓                    ↓
   Initial         All allocations        No new allocations    All memory
   Allocation      from arena             during matching       released
```

### State Transitions for Matcher
```
Idle → Initializing → Running → Finished → Cleanup
  ↓         ↓           ↓          ↓         ↓
Ready   Thread Prep  NFA Sim   Result    Memory
         & State      Execution  Build     Release
         Setup
```

## Optimization Constraints

### Memory Constraints
- **Per-Operation**: < 1MB total memory usage
- **Growth Rate**: O(n) where n = input text length
- **Arena Size**: Bounded by maximum pattern complexity
- **Thread Pool**: Fixed size (64 threads) to prevent unbounded growth

### Performance Constraints
- **Simple Patterns**: < 1ms on 60-character text
- **Complex Patterns**: < 10ms on 60-character text
- **Linear Scaling**: Time proportional to text length
- **Concurrent Operations**: Unlimited with independent optimization

### Compatibility Constraints
- **API Compatibility**: 100% backward compatibility required
- **Semantic Compatibility**: All RE2 features preserved
- **Error Handling**: Existing error messages and codes maintained
- **Thread Safety**: Safe for concurrent matching operations

## Validation Rules Summary

### Input Validation
- All regex patterns must be syntactically valid
- Text inputs must be valid UTF-8
- Flags must be valid combinations
- Cache keys must be collision-resistant

### Output Validation
- Match positions must be within text bounds
- Capture groups must be properly nested
- Performance metrics must be consistent
- Memory usage must stay within limits

### State Validation
- Matcher state must be consistent during execution
- Arena allocations must be properly tracked
- Thread pool usage must not exceed capacity
- Cache entries must maintain LRU ordering

This data model provides the foundation for implementing a high-performance, linear-time regex engine while maintaining full compatibility with existing Odin RE2 functionality.