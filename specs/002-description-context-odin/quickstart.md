# Quickstart Guide: Odin RE2 Performance Optimization

**Date**: 2025-10-12  
**Branch**: 002-description-context-odin  
**Purpose**: Developer guide for using the optimized Odin RE2 engine

## Getting Started

### Prerequisites

- Odin compiler (latest stable version)
- Windows/Linux/macOS development environment
- Basic understanding of regular expressions

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/odin-re2.git
cd odin-re2

# Build the optimized version
odin build . -o:speed

# Run tests to verify installation
odin test .
odin test run_tests.odin
```

## Basic Usage

### Simple Pattern Matching

```odin
package main

import "regexp"

main :: proc() {
    // Compile a simple pattern
    pattern, err := compile("hello\\s+world", {})
    if err != nil {
        printf("Compilation error: %v\n", err)
        return
    }
    defer free_pattern(pattern)
    
    // Test matching
    text := "hello   world"
    result := match_pattern(pattern, text)
    
    if result.success {
        printf("Match found: %d-%d\n", result.start_pos, result.end_pos)
    } else {
        printf("No match found\n")
    }
}
```

### Boolean Matching (Optimized)

```odin
// Fast boolean check - 50% faster than full match
if match_string(pattern, "hello world") {
    printf("Pattern matches!\n")
}
```

### Capture Groups

```odin
pattern, err := compile("(\\w+)\\s+(\\w+)", {})
if err != nil { return }

result := match_pattern(pattern, "John Doe")
if result.success && len(result.captures) >= 3 {
    printf("Full match: %s\n", text[result.start_pos:result.end_pos])
    printf("First name: %s\n", text[result.captures[1].start:result.captures[1].end])
    printf("Last name: %s\n", text[result.captures[2].start:result.captures[2].end])
}
```

## Advanced Usage

### Finding All Matches

```odin
// Iterator for all non-overlapping matches
iter := find_all(pattern, "one two three four")
for {
    match, has_more := next(&iter)
    if !has_more { break }
    
    printf("Found: %s\n", text[match.start_pos:match.end_pos])
}
```

### Performance Monitoring

```odin
// Get performance metrics
metrics := get_performance_metrics()
printf("Total matches: %v\n", metrics.states_processed)
printf("Average time: %v ns\n", metrics.match_time_ns)
printf("Cache hit rate: %.2f%%\n", 
    f32(metrics.cache_hits) / f32(metrics.cache_hits + metrics.cache_misses) * 100.0)
```

### Concurrent Matching

```odin
import "core:thread"

// Patterns are thread-safe after compilation
worker :: proc(pattern: ^Regex_Pattern, texts: []string) {
    for text in texts {
        if match_string(pattern, text) {
            // Process match
        }
    }
}

// Launch multiple workers
pattern, _ := compile("\\d+", {})
defer free_pattern(pattern)

threads: [4]thread.Thread
for i in 0..<4 {
    threads[i] = thread.create(worker, pattern, text_batch[i])
}

for i in 0..<4 {
    thread.join(threads[i])
}
```

## Performance Optimization Tips

### 1. Use Pattern Caching

```odin
// Patterns are automatically cached, but you can manage cache manually
pattern, _ := compile("expensive_pattern", {})

// Clear cache if memory pressure
clear_cache()

// Check cache performance
metrics := get_performance_metrics()
printf("Cache efficiency: %.2f%%\n", 
    f32(metrics.cache_hits) / f32(metrics.cache_hits + metrics.cache_misses) * 100.0)
```

### 2. Choose the Right API

```odin
// For simple existence checks - use match_string()
if match_string(pattern, text) {
    // Fast path - no capture group overhead
}

// For capture information - use match_pattern()
result := match_pattern(pattern, text)
if result.success {
    // Full match information available
}

// For multiple matches - use iterator
iter := find_all(pattern, text)
// Process all matches efficiently
```

### 3. Optimize Pattern Design

```odin
// Good: Specific character classes
pattern1, _ := compile("[0-9]+", {})  // Digits only

// Better: Use built-in shortcuts when available
pattern2, _ := compile("\\d+", {})   // More optimized

// Avoid: Catastrophic backtracking patterns
// bad_pattern := "(a+)+b"  // Can cause exponential behavior
```

### 4. Memory Management

```odin
// Patterns use arena allocation - free when done
pattern, _ := compile("temporary_pattern", {})
defer free_pattern(pattern)  // Releases arena memory

// For long-running applications, monitor memory usage
metrics := get_performance_metrics()
if metrics.peak_memory_bytes > 1024*1024 {  // 1MB
    clear_cache()  // Release cached patterns
}
```

## Migration from Previous Version

### API Compatibility

The optimized version maintains 100% API compatibility:

```odin
// Existing code continues to work unchanged
pattern, err := regexp.compile("old_pattern", regexp.Flags{})
result := regexp.match_string(pattern, "test text")

// New performance features are opt-in
metrics := regexp.get_performance_metrics()
```

### Performance Improvements

Expected improvements with the optimized version:

| Pattern Type | Previous | Optimized | Improvement |
|--------------|----------|-----------|-------------|
| Simple literals | 1-5ms | <2.5ms | 50%+ |
| Complex quantifiers | 10-100ms | 1-10ms | 90%+ |
| Pathological cases | Exponential | Linear | ∞ |
| Memory usage | Unbounded | <1MB | Bounded |

### New Features

#### Performance Metrics

```odin
// New: Detailed performance tracking
metrics := get_performance_metrics()
printf("Match time: %v ns\n", metrics.match_time_ns)
printf("Memory used: %v bytes\n", metrics.memory_used)
printf("States processed: %v\n", metrics.states_processed)
```

#### Enhanced Error Information

```odin
// Enhanced error details
pattern, err := compile("invalid[regex", {})
if err != nil {
    printf("Error at position %d: %v\n", err.position, err.message)
    // Output: Error at position 7: Unclosed character class
}
```

## Troubleshooting

### Common Issues

#### Performance Problems

```odin
// If matching is slow, check:
metrics := get_performance_metrics()

// 1. High cache miss rate?
if metrics.cache_misses > metrics.cache_hits {
    // Consider reusing compiled patterns
}

// 2. High memory usage?
if metrics.peak_memory_bytes > 512*1024 {  // 512KB
    clear_cache()  // Release memory
}

// 3. Many states processed?
if metrics.states_processed > uint(len(text)) * 10 {
    // Pattern might be too complex - consider simplification
}
```

#### Memory Issues

```odin
// Monitor memory usage
pattern, _ := compile("complex_pattern", {})
result := match_pattern(pattern, large_text)

if result.memory_used > 1024*1024 {  // 1MB limit exceeded
    // Pattern is too complex for the input
    // Consider breaking into smaller chunks
}
```

#### Compilation Errors

```odin
// Handle compilation errors gracefully
pattern, err := compile("invalid(pattern", {})
if err != nil {
    switch err.code {
    case .Invalid_Syntax:
        printf("Syntax error: %v\n", err.message)
    case .Unsupported_Feature:
        printf("Feature not yet implemented\n")
    case .Pattern_Too_Large:
        printf("Pattern exceeds complexity limits\n")
    }
}
```

### Debug Mode

```odin
// Enable debug information during development
when ODIN_DEBUG {
    // Debug builds include additional validation
    pattern, err := compile("debug_pattern", {})
    
    // Debug builds check arena bounds
    result := match_pattern(pattern, text)
    
    // Debug builds track detailed metrics
    metrics := get_performance_metrics()
    printf("Debug: %v instructions executed\n", metrics.instructions_executed)
}
```

## Benchmarks

### Running Benchmarks

```bash
# Run performance benchmarks
odin run benchmark/performance_benchmark.odin

# Compare with Rust reference implementation
cd benchmark
cargo run --release
```

### Benchmark Results

Expected results on typical hardware:

```
Simple Pattern Matching:
- Odin RE2: 0.8ms (60-char text)
- Rust RE2: 1.2ms
- Improvement: 33% faster

Complex Quantifiers:
- Odin RE2: 5ms (complex pattern)
- Rust RE2: 8ms  
- Improvement: 37% faster

Pathological Patterns:
- Odin RE2: 2ms (linear time)
- Previous: >1000ms (exponential)
- Improvement: 500x faster
```

## Best Practices

### 1. Pattern Compilation

- Compile patterns once, reuse many times
- Use pattern caching for frequently used patterns
- Free patterns when no longer needed

### 2. Memory Management

- Monitor memory usage in long-running applications
- Clear cache periodically if memory pressure occurs
- Use arena allocation patterns for temporary data

### 3. Performance Optimization

- Choose the right API for your use case
- Profile performance bottlenecks
- Optimize pattern design for linear-time behavior

### 4. Error Handling

- Always check compilation errors
- Handle memory allocation failures
- Provide meaningful error messages to users

### 5. Testing

- Test with both typical and pathological inputs
- Verify performance requirements are met
- Include memory usage testing in test suites

This quickstart guide provides everything needed to effectively use the optimized Odin RE2 engine while taking advantage of the new performance features and maintaining compatibility with existing code.