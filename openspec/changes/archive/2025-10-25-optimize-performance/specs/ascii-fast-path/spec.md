# ascii-fast-path Specification

## ADDED Requirements

### Requirement: ASCII Character Classification
The regex engine SHALL provide O(1) character classification for ASCII characters using a pre-computed lookup table.

#### Scenario: ASCII letter classification
- **WHEN** engine processes character 'a' (ASCII 97)
- **THEN** classification table SHALL return `LETTER` in O(1) time
- **AND** performance SHALL be >10x faster than Unicode path

#### Scenario: ASCII number classification
- **WHEN** engine processes character '5' (ASCII 53)
- **THEN** classification table SHALL return `NUMBER` in O(1) time
- **AND** engine SHALL avoid Unicode property lookup

#### Scenario: Non-ASCII fallback
- **WHEN** engine processes character '世' (Unicode 19990)
- **THEN** engine SHALL fall back to Unicode path
- **AND** classification SHALL be accurate for Unicode characters

### Requirement: ASCII Fast Path Integration
The regex engine SHALL use fast path for ASCII-heavy text processing without breaking Unicode support.

#### Scenario: ASCII-only pattern matching
- **WHEN** pattern `[a-z]+` matches ASCII text `"hello world"`
- **THEN** engine SHALL use ASCII fast path for all characters
- **AND** performance SHALL be 3-5x faster than Unicode path

#### Scenario: Mixed text pattern matching
- **WHEN** pattern `\w+` matches mixed text `"hello 世界"`
- **THEN** engine SHALL use fast path for ASCII characters
- **AND** engine SHALL use Unicode path for non-ASCII characters
- **AND** overall performance SHALL be >2x faster

#### Scenario: Character class optimization
- **WHEN** pattern `[abc123]` processes ASCII text
- **THEN** engine SHALL use pre-computed ASCII classification
- **AND** SHALL bypass Unicode property checks
- **AND** maintain 100% compatibility with existing semantics

### Requirement: ASCII Performance Benchmarks
The engine SHALL provide performance benchmarks to validate ASCII fast path improvements.

#### Scenario: Throughput benchmark
- **WHEN** benchmark runs 1MB ASCII text through `[a-z]+` pattern
- **THEN** throughput SHALL exceed 2,000 MB/s
- **AND** SHALL be 3-5x faster than baseline Unicode implementation

#### Scenario: Latency benchmark
- **WHEN** measuring single character classification time
- **THEN** ASCII classification SHALL complete in <50ns
- **AND** Unicode fallback SHALL complete in <200ns

#### Scenario: Memory usage benchmark
- **WHEN** measuring memory overhead of optimization
- **THEN** classification table SHALL use <1KB additional memory
- **AND** SHALL not increase per-match memory allocation

## MODIFIED Requirements

### Requirement: Unicode Property Matching (from regex-engine spec)
The Unicode property matching SHALL be optimized to first check for ASCII characters before performing full Unicode property lookup.

#### Scenario: Unicode property with ASCII input
- **WHEN** pattern `\p{L}` processes ASCII character 'a'
- **THEN** engine SHALL use ASCII classification first
- **AND** SHALL fall back to Unicode property check only if needed
- **AND** performance SHALL be >5x faster than pure Unicode path

#### Scenario: Unicode property with mixed input
- **WHEN** pattern `\p{N}` processes mixed text "a5b世"
- **THEN** engine SHALL use fast path for 'a', '5', 'b'
- **AND** SHALL use Unicode path for '世'
- **AND** SHALL maintain correct Unicode property semantics

## Cross-References

- Related to vector-operations capability for SIMD character class optimization
- Depends on performance-validation capability for benchmarking infrastructure
- Extends regex-engine specification requirements