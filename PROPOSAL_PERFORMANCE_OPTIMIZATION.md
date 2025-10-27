# Odin RE2 Performance Optimization Proposal

**Proposal ID**: 2025-10-25-001  
**Target**: Core Performance Optimization  
**Duration**: 6-8 weeks  
**Priority**: High  

## Problem Statement

Current Odin RE2 implementation has solid functionality but lacks critical performance optimizations needed to reach production viability. Key performance gaps:

- String search: 434 MB/s vs 2,000+ MB/s target
- Character iteration: 46 MB/s vs 1,500+ MB/s target  
- Missing ASCII fast path (95% of text processing)
- No SIMD optimization for character classes
- Module import issues prevent proper testing

## Solution Overview

**Phase 1: Critical Path Optimization (3 weeks)**
- Implement ASCII fast path for 95% of text processing
- Fix module system for proper benchmarking
- Add basic SIMD character class matching

**Phase 2: Vector Operations & Memory (3 weeks)** 
- State vector optimization with 64-byte alignment
- Improve memory access patterns
- Add comprehensive performance tests

## Specific Changes

### 1. ASCII Fast Path Implementation

**Files to modify**: `src/utf8_optimized.odin`, `src/matcher.odin`

**Change**: Add O(1) ASCII character classification table

```odin
// New addition to utf8_optimized.odin
ASCII_CHAR_CLASS :: enum u8 {
    OTHER = 0,
    LETTER = 1, 
    NUMBER = 2,
    WHITESPACE = 3,
    PUNCTUATION = 4,
}

ASCII_CLASS_TABLE :: [128]ASCII_CHAR_CLASS {
    // Pre-computed classification for all ASCII chars
}

is_ascii_char_class :: proc(ch: rune, class: ASCII_CHAR_CLASS) -> bool {
    return ch < 128 && ASCII_CLASS_TABLE[ch] == class
}
```

**Expected Impact**: 3-5x performance improvement for ASCII text

### 2. Module System Fix

**Files to modify**: `src/regexp.odin`, Test files

**Change**: Export public API properly

```odin
// In regexp.odin - ensure public exports
@(public)
parse_regexp_internal :: proc(pattern: string, flags: Parse_Flags) -> (^AST_Node, ErrorCode)

@(public) 
compile_nfa :: proc(ast: ^AST_Node, arena: ^Arena) -> (^NFA_Program, ErrorCode)

@(public)
match_nfa :: proc(matcher: ^Matcher, text: string) -> (bool, []Capture)
```

**Expected Impact**: Enable proper performance testing

### 3. Basic SIMD Character Classes

**Files to modify**: `src/matcher.odin`

**Change**: Use Odin's SIMD intrinsics for character classes

```odin
// New SIMD-optimized character class matching
match_char_class_simd :: proc(text: string, pos: int, char_set: []rune) -> bool {
    when ODIN_ARCH == .amd64 {
        // Use SSE2 for character class matching
        // 16-character blocks at once
    } else {
        // Fallback to regular implementation
        return match_char_class_regular(text, pos, char_set)
    }
}
```

**Expected Impact**: 2-4x improvement for [a-z] style patterns

### 4. State Vector Optimization

**Files to modify**: `src/matcher.odin`, `src/memory.odin`

**Change**: 64-byte aligned state vectors with bit operations

```odin
State_Vector :: struct {
    bits:   []u64,      // 64-bit blocks
    count:  u32,        // Number of set bits
    size:   u32,        // Size in bits
    // 64-byte aligned for cache efficiency
}

// Fast bit operations for state management
set_state_bit :: proc(sv: ^State_Vector, index: int) {
    block := index / 64
    bit := u64(1) << (index % 64)
    sv.bits[block] |= bit
}
```

**Expected Impact**: 50% reduction in state processing time

### 5. Performance Test Suite

**Files to create**: `tests/performance_test.odin`

**Change**: Comprehensive benchmark suite

```odin
Benchmark_Result :: struct {
    name:         string,
    pattern:      string,
    text_size:    int,
    iterations:   int,
    time_ns:      i64,
    throughput_mb_per_s: f64,
}

run_benchmark :: proc(pattern: string, text: string, iterations: int) -> Benchmark_Result {
    // Proper timing and measurement
}
```

## Implementation Plan

### Week 1-2: ASCII Fast Path
- [ ] Implement ASCII classification table
- [ ] Add fast path to matcher
- [ ] Test with ASCII-heavy workloads
- [ ] Measure performance improvement

### Week 3: Module System & Testing  
- [ ] Fix public API exports
- [ ] Create working performance tests
- [ ] Establish baseline metrics
- [ ] Set up continuous benchmarking

### Week 4-5: SIMD & Vector Ops
- [ ] Implement SIMD character class matching
- [ ] Add state vector optimization
- [ ] Optimize memory access patterns
- [ ] Test with complex patterns

### Week 6: Integration & Validation
- [ ] Full integration testing
- [ ] Performance validation
- [ ] Documentation updates
- [ ] Final performance report

## Success Metrics

**Performance Targets**:
- String search: >2,000 MB/s (current: 434 MB/s)
- Character iteration: >1,500 MB/s (current: 46 MB/s)
- Pattern matching: >1,200 MB/s (current: TBD)
- Compilation: <500 ns/pattern

**Functional Targets**:
- All existing tests pass
- New performance tests pass
- No regressions in functionality
- Proper module import working

## Risk Assessment

**Low Risk**:
- ASCII fast path addition (isolated change)
- Module system fixes (API cleanup)
- Performance test creation (new code)

**Medium Risk**:
- SIMD implementation (architecture-specific)
- State vector changes (core algorithm)

**Mitigation**:
- Feature flags for SIMD
- Fallback implementations
- Extensive testing before integration
- Rollback plan for each change

## Resource Requirements

**Developer**: 1 senior developer (6-8 weeks)
**Testing**: Performance validation infrastructure
**Hardware**: x86-64 test machine with SSE2 support
**External Dependencies**: None (pure Odin implementation)

## Timeline

| Week | Focus | Deliverables |
|------|-------|--------------|
| 1-2 | ASCII Fast Path | O(1) character classification, 3x+ speedup |
| 3 | Module System | Working imports, baseline benchmarks |
| 4-5 | SIMD & Vectors | SIMD matching, state optimization |
| 6 | Integration | Full test suite, performance report |

**Total Duration**: 6 weeks  
**Go/No-Go Decision**: End of Week 3 (after module fixes)

## Conclusion

This proposal focuses on the most critical performance bottlenecks with minimal architectural changes. By implementing ASCII fast path, basic SIMD, and state vector optimization, we can achieve 3-5x performance improvement while maintaining the current architecture and avoiding over-engineering.

The changes are incremental, testable, and have clear rollback points. Success will make Odin RE2 viable for production use while preserving the existing clean architecture.