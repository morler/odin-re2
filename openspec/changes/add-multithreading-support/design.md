# Design: Multithreading Support for Odin RE2

## Overview

This design document outlines the approach for adding practical multithreading support to Odin RE2's regex engine. The focus is on solving real performance bottlenecks without over-engineering.

## Architecture Decisions

### 1. Text Chunking Strategy

**Approach**: Split input text into overlapping chunks processed by different threads.

**Rationale**:
- Simple to implement and understand
- Preserves existing NFA matching logic with minimal changes
- Overlap ensures boundary matches aren't lost
- Works well with existing arena allocation system

**Trade-offs**:
- Pros: Minimal code changes, predictable behavior
- Cons: Some duplicate work on chunk boundaries

### 2. Worker Thread Model

**Approach**: Fixed-size thread pool with task queue.

**Rationale**:
- Avoids thread creation overhead for each match
- Limits resource usage (no thread explosion)
- Simple synchronization model
- Works well for typical regex matching workloads

**Thread Count**: Default to `min(4, CPU cores)` with user configuration option.

### 3. Memory Management

**Approach**: Per-thread arena allocation with shared result aggregation.

**Rationale**:
- Eliminates lock contention during matching
- Leverages existing optimized arena system
- Simple cleanup model (destroy arena when thread finishes)
- Minimal memory overhead (<5%)

### 4. Result Aggregation

**Approach**: Leftmost-longest match selection from worker results.

**Rationale**:
- Maintains compatibility with existing regex semantics
- Simple to implement and reason about
- No complex consensus mechanisms needed
- Deterministic results

## Performance Considerations

### When to Use Parallel Processing

**Automatic Thresholds**:
- Enable parallel for texts > 4KB
- Use single-threaded for smaller texts
- Consider pattern complexity in threshold calculation

**Expected Performance**:
- 2-3x speedup for texts > 64KB with 4 cores
- Linear scaling up to 4 threads
- Diminishing returns beyond 4 threads for most patterns

### Memory Overhead

**Per-Thread Allocation**:
- One arena per thread (4KB default)
- Task queue buffers
- Result storage structures
- **Total overhead**: <5% of single-threaded usage

## Implementation Strategy

### Phase 1: Core Parallel Framework
1. Worker thread pool implementation
2. Text chunking with overlap
3. Basic task distribution
4. Result collection and aggregation

### Phase 2: Integration
1. API extensions for parallel mode
2. Integration with existing matcher
3. Memory system integration
4. Threshold detection logic

### Phase 3: Validation
1. Performance benchmarking
2. Correctness testing
3. Stress testing
4. Documentation

## Risk Mitigation

### Thread Safety
- **Strategy**: Avoid shared mutable state during matching
- **Implementation**: Per-thread arenas, immutable program structures
- **Validation**: Stress testing with concurrent operations

### Performance Regression
- **Strategy**: Only enable parallel when beneficial
- **Implementation**: Automatic threshold detection, fallback to serial
- **Validation**: Comprehensive benchmarking across text sizes

### Correctness
- **Strategy**: Maintain exact same semantics as serial implementation
- **Implementation**: Leftmost-longest aggregation, boundary overlap
- **Validation**: Extensive correctness test suite

## API Design

### Backward Compatibility
Existing API remains unchanged:
```odin
// Existing API - unchanged
match_result := regex_match(pattern, text)
```

### New Parallel API
```odin
// New parallel API - opt-in
config := Parallel_Config{workers = 4}
matcher := new_parallel_matcher(config)
match_result := parallel_match(matcher, pattern, text)
```

### Automatic Mode
```odin
// Automatic mode - parallel when beneficial
matcher := new_auto_matcher() // Chooses parallel/serial automatically
match_result := auto_match(matcher, pattern, text)
```

## Testing Strategy

### Correctness Testing
- Compare parallel vs serial results for all existing test cases
- Edge case testing (empty strings, boundary conditions)
- Stress testing with concurrent operations

### Performance Testing
- Benchmark across text sizes (1KB to 1MB)
- Test scaling with worker count
- Memory usage validation
- Regression testing

### Integration Testing
- API compatibility verification
- Existing code validation
- Performance threshold validation

## Future Considerations

### Potential Optimizations (Out of Scope)
- Work-stealing algorithms for load balancing
- Parallel pattern compilation
- NUMA-aware memory allocation
- GPU acceleration

### Monitoring and Diagnostics
- Performance metrics collection
- Thread utilization monitoring
- Memory usage tracking
- Debug mode for parallel execution

## Conclusion

This design provides a practical path to adding multithreading support to Odin RE2 while maintaining the project's focus on simplicity and performance. The phased approach allows for incremental validation and reduces risk while delivering significant performance improvements for large text processing scenarios.