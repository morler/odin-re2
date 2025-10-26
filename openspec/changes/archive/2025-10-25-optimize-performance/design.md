# Performance Optimization Design

## Overview

This design document explains the technical approach for optimizing Odin RE2 performance through three key optimizations: ASCII fast path, SIMD vector operations, and cache-optimized state management.

## Current Architecture Analysis

### Performance Bottlenecks

1. **Unicode Path Overhead**: All characters go through Unicode processing even when 95% are ASCII
2. **Character Class Matching**: Linear search through character sets instead of vectorized operations
3. **State Management**: Non-aligned state vectors causing cache misses
4. **Memory Access**: Scattered allocation patterns reducing cache efficiency

### Current Data Flow

```
Input Text -> UTF-8 Decode -> Unicode Property Check -> NFA State Processing -> Result
```

**Issues**:
- UTF-8 decode even for ASCII characters
- Unicode property lookup for every character
- State vectors not cache-aligned
- No SIMD utilization

## Optimized Architecture

### ASCII Fast Path

**Pre-computed Classification Table**:
```odin
ASCII_CHAR_CLASS :: enum u8 {
    OTHER = 0,
    LETTER = 1, 
    NUMBER = 2,
    WHITESPACE = 3,
    PUNCTUATION = 4,
}

// 128-entry table for O(1) classification
ASCII_CLASS_TABLE :: [128]ASCII_CHAR_CLASS {
    // Pre-computed at compile time
}
```

**Optimized Flow**:
```
Input Text -> ASCII Check? -> [ASCII: Fast Path] / [Unicode: Regular Path] -> Result
```

**Performance Impact**: 3-5x speedup for ASCII text (95% of real-world usage)

### SIMD Character Class Matching

**Current Implementation**:
```odin
// Linear search through character set
match_char_class :: proc(text: string, pos: int, char_set: []rune) -> bool {
    for ch in char_set {
        if text[pos] == ch {
            return true
        }
    }
    return false
}
```

**Optimized Implementation**:
```odin
match_char_class_simd :: proc(text: string, pos: int, char_set: []rune) -> bool {
    when ODIN_ARCH == .amd64 {
        // Process 16 characters at once with SSE2
        // Bitmask operations for character class matching
        // Early exit on first match
    } else {
        return match_char_class_regular(text, pos, char_set)
    }
}
```

**Performance Impact**: 2-4x speedup for [a-z] style patterns

### Cache-Optimized State Vectors

**Current State Vector**:
```odin
State_Vector :: struct {
    states: []bool,        // Byte-per-state, cache inefficient
    count:  int,          // Number of active states
}
```

**Optimized State Vector**:
```odin
State_Vector :: struct {
    bits:   []u64,        // 64-bit blocks, cache-aligned
    count:  u32,          // Number of set bits
    size:   u32,          // Size in bits
    arena:  ^Arena,       // Memory arena for allocation
}

// Fast bit operations
set_state_bit :: proc(sv: ^State_Vector, index: int) {
    block := index / 64
    bit := u64(1) << (index % 64)
    sv.bits[block] |= bit
}

check_state_bit :: proc(sv: ^State_Vector, index: int) -> bool {
    block := index / 64
    bit := u64(1) << (index % 64)
    return sv.bits[block] & bit != 0
}
```

**Benefits**:
- 64x less memory for state representation
- Cache-line aligned for optimal performance
- Bit-level operations for bulk state operations
- 50% reduction in state processing time

## Implementation Details

### ASCII Fast Path Integration

**File Changes**: `src/utf8_optimized.odin`, `src/matcher.odin`

**Integration Points**:
1. Character class matching: Check ASCII first
2. Unicode property matching: Fast ASCII property lookup
3. String literal matching: Direct byte comparison
4. Quantifier processing: ASCII-optimized loops

```odin
match_char_class :: proc(matcher: ^Matcher, text: string, pos: int) -> bool {
    ch := text[pos]
    
    // ASCII fast path (95% of cases)
    if ch < 128 {
        class := ASCII_CLASS_TABLE[ch]
        return should_match_class(matcher.current_class, class)
    }
    
    // Fallback to Unicode path
    return match_char_class_unicode(matcher, text, pos)
}
```

### SIMD Implementation Strategy

**Feature Flags**: Enable/disable SIMD at compile time
```odin
ENABLE_SIMD :: #config(ODIN_SIMD, true) when ODIN_ARCH == .amd64 else false
```

**Fallback Strategy**: Always provide non-SIMD implementation
```odin
match_char_class_optimized :: proc(...) -> bool {
    when ENABLE_SIMD {
        return match_char_class_simd(...)
    } else {
        return match_char_class_regular(...)
    }
}
```

### Memory Layout Optimization

**Arena Allocation Pattern**:
```odin
// Allocate state vectors with proper alignment
alloc_state_vector :: proc(arena: ^Arena, size: int) -> ^State_Vector {
    // Ensure 64-byte alignment
    sv := arena_alloc_aligned(arena, size_of(State_Vector), 64)
    sv.bits = arena_alloc_aligned(arena, (size + 63) / 64 * size_of(u64), 64)
    sv.size = u32(size)
    return sv
}
```

**Cache-Friendly Access**:
- Sequential state vector processing
- Prefetch next cache line
- Batch state updates
- Minimize random memory access

## Performance Validation Strategy

### Benchmark Suite Design

**Micro-benchmarks**:
- ASCII vs Unicode character classification
- SIMD vs regular character class matching
- Optimized vs regular state vector operations
- Memory allocation patterns

**Macro-benchmarks**:
- Real-world regex patterns
- Large text processing
- Repeated pattern compilation
- Concurrent matching operations

**Success Metrics**:
- Throughput (MB/s) for different pattern types
- Latency (ns) for individual operations
- Memory usage patterns
- Cache miss rates

### Profiling Infrastructure

**Built-in Profiling**:
```odin
Performance_Metrics :: struct {
    ascii_fast_path_hits: u64,
    unicode_path_hits: u64,
    simd_operations: u64,
    cache_misses: u64,
}

get_performance_metrics :: proc() -> Performance_Metrics
```

**External Validation**:
- Odin's built-in profiling tools
- Platform-specific performance counters
- Memory usage analysis
- CPU cache profiling

## Trade-offs and Decisions

### Design Trade-offs

1. **Code Complexity vs Performance**
   - Decision: Moderate complexity increase for 3-5x performance gain
   - Mitigation: Clear separation of optimized and regular paths

2. **Memory Usage vs Speed**
   - Decision: Slightly more memory for classification tables
   - Mitigation: Tables are small (128 entries) and shared

3. **Portability vs Optimization**
   - Decision: SIMD optimization for x86-64 only
   - Mitigation: Fallback implementations for other architectures

### Risk Mitigation

1. **SIMD Availability**
   - Risk: Target platforms may not support required SIMD
   - Mitigation: Feature flags and runtime detection

2. **Correctness**
   - Risk: Optimizations may introduce bugs
   - Mitigation: Extensive testing and gradual rollout

3. **Maintenance**
   - Risk: Complex optimizations hard to maintain
   - Mitigation: Clear documentation and modular design

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- ASCII classification table
- Fast path integration
- Basic performance testing

### Phase 2: Vector Operations (Week 3-4)
- SIMD character class matching
- State vector optimization
- Memory layout improvements

### Phase 3: Integration (Week 5-6)
- Full system integration
- Performance validation
- Documentation and cleanup

This design provides a clear path to 3-5x performance improvement while maintaining code quality and architectural integrity.