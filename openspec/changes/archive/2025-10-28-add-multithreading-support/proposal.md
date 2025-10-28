# Change Proposal: Add Multithreading Support

**Change ID**: `add-multithreading-support`
**Date**: 2025-10-27
**Status**: Draft

## Why

Modern systems typically have 4+ CPU cores, but Odin RE2 can only use one core for regex matching. This creates a significant performance bottleneck when processing large text files, where single-threaded execution cannot keep up with the available computational resources. Users processing log files, parsing large documents, or performing batch text analysis experience unnecessarily slow performance.

## Problem Statement

The current Odin RE2 implementation uses a single-threaded NFA matcher that cannot leverage multi-core CPUs for performance. While existing optimizations (ASCII fast path, SIMD infrastructure) provide 3-5x speedup, large text processing remains bottlenecked by serial execution.

**Key Issues Identified**:
- Serial NFA execution limits performance on multi-core systems
- Large text files (>64KB) show limited scalability
- Current implementation underutilizes available CPU resources

## Proposed Solution

Add practical multithreading support focused on solving real performance bottlenecks without over-engineering:

1. **Text chunking with worker threads** - Split large texts into chunks processed in parallel
2. **Simple task distribution** - Basic round-robin or queue-based task assignment
3. **Result aggregation** - Leftmost-longest match selection from parallel results
4. **Configurable worker count** - Allow users to optimize for their hardware

## Scope

**In Scope**:
- Parallel NFA matching for large texts (>4KB)
- Simple worker thread pool implementation
- Backward-compatible API (opt-in parallel mode)
- Basic performance validation

**Out of Scope** (future work):
- Complex work-stealing algorithms
- Parallel pattern compilation
- Advanced load balancing
- NUMA optimization

## Success Criteria

- 2-3x performance improvement on texts >64KB with 4 cores
- 100% backward compatibility with existing API
- Zero correctness regressions
- <5% memory overhead for parallel processing

## Implementation Approach

**Phase 1**: Basic parallel matching with text chunking
**Phase 2**: Performance tuning and validation
**Phase 3**: Integration and documentation

## Risks and Mitigations

- **Risk**: Thread safety issues with shared data structures
  **Mitigation**: Use per-thread arenas, avoid shared mutable state
- **Risk**: Performance overhead for small texts
  **Mitigation**: Only enable parallel processing for texts above threshold
- **Risk**: Correctness issues with boundary conditions
  **Mitigation**: Overlap chunks to ensure boundary matches aren't missed