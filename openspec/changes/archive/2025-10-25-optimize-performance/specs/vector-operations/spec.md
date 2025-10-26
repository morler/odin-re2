# vector-operations Specification

## ADDED Requirements

### Requirement: SIMD Character Class Matching
The regex engine SHALL use SIMD intrinsics for character class matching on supported architectures.

#### Scenario: SIMD character class optimization
- **WHEN** pattern `[a-z]` matches text on x86-64 with SSE2
- **THEN** engine SHALL process 16 characters simultaneously
- **AND** performance SHALL be 2-4x faster than regular matching
- **AND** SHALL maintain identical matching semantics

#### Scenario: SIMD fallback for unsupported architectures
- **WHEN** SIMD not available on target architecture
- **THEN** engine SHALL fall back to regular character class matching
- **AND** SHALL not break functionality
- **AND** performance SHALL be equivalent to baseline

#### Scenario: SIMD feature flag control
- **WHEN** SIMD disabled at compile time
- **THEN** engine SHALL use regular implementations
- **AND** SHALL compile without SIMD intrinsics
- **AND** SHALL maintain full compatibility

### Requirement: Cache-Optimized State Vectors
The regex engine SHALL use 64-byte aligned bit vectors for NFA state management.

#### Scenario: State vector bit operations
- **WHEN** managing NFA states during matching
- **THEN** engine SHALL use 64-bit blocks for state representation
- **AND** state operations SHALL be O(1) per bit
- **AND** memory usage SHALL be 64x lower than boolean arrays

#### Scenario: Cache-aligned state vectors
- **WHEN** allocating state vectors
- **THEN** engine SHALL align to 64-byte cache line boundaries
- **AND** SHALL minimize cache misses during state operations
- **AND** SHALL improve matching performance by 50%+

#### Scenario: State vector bulk operations
- **WHEN** processing multiple NFA transitions
- **THEN** engine SHALL support bulk bit operations (AND, OR, XOR)
- **AND** SHALL process 64 states in single operation
- **AND** SHALL reduce transition processing time by 60%

### Requirement: Optimized Memory Access Patterns
The regex engine SHALL organize data structures for optimal cache performance.

#### Scenario: Sequential state processing
- **WHEN** processing NFA states
- **THEN** engine SHALL access state vectors sequentially
- **AND** SHALL prefetch next cache line when beneficial
- **AND** SHALL minimize random memory access patterns

#### Scenario: Arena allocation optimization
- **WHEN** allocating temporary matching data
- **THEN** engine SHALL use arena allocation for better locality
- **AND** SHALL reduce memory fragmentation
- **AND** SHALL improve cache performance

#### Scenario: Data structure layout
- **WHEN** defining core data structures
- **THEN** engine SHALL arrange frequently accessed fields together
- **AND** SHALL align hot data structures to cache boundaries
- **AND** SHALL minimize padding and wasted space

## MODIFIED Requirements

### Requirement: Character Class Support (from regex-engine spec)
Character class matching SHALL be optimized with SIMD and bit vector operations where available.

#### Scenario: Optimized simple character class
- **WHEN** matching pattern `[abc]` against long text
- **THEN** engine SHALL use SIMD operations when available
- **AND** SHALL fall back to optimized bit operations
- **AND** performance SHALL be 2-4x faster than baseline

#### Scenario: Optimized character range
- **WHEN** matching pattern `[a-z]` against ASCII text
- **THEN** engine SHALL use SIMD range checking
- **AND** SHALL use ASCII fast path for range validation
- **AND** SHALL maintain exact matching semantics

#### Scenario: Optimized negated character class
- **WHEN** matching pattern `[^abc]` against text
- **THEN** engine SHALL use SIMD for exclusion checking
- **AND** SHALL combine with ASCII fast path
- **AND** SHALL maintain correct negation semantics

### Requirement: NFA Engine Operations (from regex-engine spec)
NFA state management SHALL use optimized bit vectors and cache-friendly algorithms.

#### Scenario: State transition processing
- **WHEN** processing NFA state transitions
- **THEN** engine SHALL use bit vector operations for state sets
- **AND** SHALL perform bulk state updates efficiently
- **AND** SHALL maintain O(n) matching complexity

#### Scenario: State vector garbage collection
- **WHEN** cleaning up unused NFA states
- **THEN** engine SHALL use efficient bit vector clearing
- **AND** SHALL reuse allocated state vectors
- **AND** SHALL minimize memory allocation overhead

## Cross-References

- Depends on ascii-fast-path capability for character classification
- Related to performance-validation capability for benchmarking SIMD improvements
- Extends regex-engine specification NFA requirements