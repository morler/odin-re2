package main

import "core:fmt"
import "core:os"
import "core:time"

// Example usage of parallel regex matching
// This demonstrates the key features and best practices

import regexp "../src"

// Example 1: Basic parallel matching
example_basic_parallel :: proc() {
    fmt.println("=== Example 1: Basic Parallel Matching ===")

    // Create parallel matcher with 4 workers
    matcher := regexp.new_parallel_matcher(4)
    defer regexp.free_parallel_matcher(matcher)

    // Compile a pattern
    pattern := `[a-z]+@[a-z]+\.[a-z]+`
    prog, err := regexp.compile(pattern)
    if err != nil {
        fmt.printf("Error compiling pattern: %v\n", err)
        return
    }
    defer regexp.free_program(prog)

    // Test text with email addresses
    text := "Contact us at support@example.com or sales@company.org for assistance."

    // Perform parallel matching
    start := time.now()
    matched, captures := regexp.regex_match_parallel(matcher, prog, text)
    elapsed := time.duration_seconds(time.now() - start)

    if matched {
        fmt.printf("Found email: '%s' at position [%d,%d]\n",
                  text[captures[0]:captures[1]], captures[0], captures[1])
    } else {
        fmt.println("No email found")
    }

    fmt.printf("Time taken: %.3f ms\n\n", elapsed * 1000.0)
}

// Example 2: Processing large text
example_large_text :: proc() {
    fmt.println("=== Example 2: Large Text Processing ===")

    // Create large text for demonstration
    large_text := create_large_sample_text(100_000)  // 100KB
    defer delete(large_text)

    // Create parallel matcher
    matcher := regexp.new_parallel_matcher(0)  // Auto-detect cores
    defer regexp.free_parallel_matcher(matcher)

    // Pattern to find words with numbers
    pattern := `[a-z]+[0-9]+[a-z]*`
    prog, err := regexp.compile(pattern)
    if err != nil {
        fmt.printf("Error compiling pattern: %v\n", err)
        return
    }
    defer regexp.free_program(prog)

    // Time the parallel matching
    start := time.now()
    matched, captures := regexp.regex_match_parallel(matcher, prog, large_text)
    elapsed := time.duration_seconds(time.now() - start)

    if matched {
        fmt.printf("Found match: '%s' at position [%d,%d]\n",
                  large_text[captures[0]:captures[1]], captures[0], captures[1])
    }

    fmt.printf("Processed %d bytes in %.3f ms\n", len(large_text), elapsed * 1000.0)
    fmt.printf("Throughput: %.1f MB/s\n\n", f64(len(large_text)) / (elapsed * 1_000_000.0))
}

// Example 3: Custom configuration
example_custom_config :: proc() {
    fmt.println("=== Example 3: Custom Configuration ===")

    // Create custom configuration
    config := regexp.Parallel_Config{
        num_workers = 8,      // 8 workers
        chunk_size = 32768,   // 32KB chunks
        overlap_size = 256,   // 256 byte overlap
        enable_threshold = 16384,  // Enable for texts >16KB
    }

    matcher := regexp.new_parallel_matcher_with_config(config)
    defer regexp.free_parallel_matcher(matcher)

    // Pattern for URLs
    pattern := `https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`
    prog, err := regexp.compile(pattern)
    if err != nil {
        fmt.printf("Error compiling pattern: %v\n", err)
        return
    }
    defer regexp.free_program(prog)

    // Test text with URLs
    text := "Visit https://example.com or http://test.org for more information."

    matched, captures := regexp.regex_match_parallel(matcher, prog, text)
    if matched {
        fmt.printf("Found URL: '%s'\n", text[captures[0]:captures[1]])
    }

    fmt.println("Custom configuration applied successfully\n")
}

// Example 4: Multiple pattern matching
example_multiple_patterns :: proc() {
    fmt.println("=== Example 4: Multiple Pattern Matching ===")

    matcher := regexp.new_parallel_matcher(4)
    defer regexp.free_parallel_matcher(matcher)

    // Compile multiple patterns
    email_prog, _ := regexp.compile(`[a-z]+@[a-z]+\.[a-z]+`)
    defer regexp.free_program(email_prog)

    phone_prog, _ := regexp.compile(`\d{3}-\d{3}-\d{4}`)
    defer regexp.free_program(phone_prog)

    url_prog, _ := regexp.compile(`https?://[a-z]+\.[a-z]+`)
    defer regexp.free_program(url_prog)

    // Test text with multiple types of data
    text := `
        Contact John at john@example.com or call 555-123-4567.
        Visit our website at https://company.com for more details.
        You can also reach support at support@help.org.
        Emergency contact: 911-000-1234
    `

    // Find all emails
    fmt.println("Email addresses found:")
    start := 0
    for start < len(text) {
        matched, captures := regexp.regex_match_parallel(matcher, email_prog, text[start:])
        if !matched {
            break
        }
        fmt.printf("  - %s\n", text[start + captures[0]:start + captures[1]])
        start += captures[1]
    }

    // Find all phone numbers
    fmt.println("\nPhone numbers found:")
    start = 0
    for start < len(text) {
        matched, captures := regexp.regex_match_parallel(matcher, phone_prog, text[start:])
        if !matched {
            break
        }
        fmt.printf("  - %s\n", text[start + captures[0]:start + captures[1]])
        start += captures[1]
    }

    // Find all URLs
    fmt.println("\nURLs found:")
    start = 0
    for start < len(text) {
        matched, captures := regexp.regex_match_parallel(matcher, url_prog, text[start:])
        if !matched {
            break
        }
        fmt.printf("  - %s\n", text[start + captures[0]:start + captures[1]])
        start += captures[1]
    }

    fmt.println()
}

// Example 5: Performance comparison
example_performance_comparison :: proc() {
    fmt.println("=== Example 5: Performance Comparison ===")

    // Create test texts of different sizes
    sizes := []int{1000, 10000, 100000}
    pattern := `[a-z]+[0-9]+`

    prog, err := regexp.compile(pattern)
    if err != nil {
        fmt.printf("Error compiling pattern: %v\n", err)
        return
    }
    defer regexp.free_program(prog)

    // Create parallel matcher
    parallel_matcher := regexp.new_parallel_matcher(0)
    defer regexp.free_parallel_matcher(parallel_matcher)

    fmt.Println("Text Size | Sequential | Parallel | Speedup")
    fmt.Println("----------|------------|----------|--------")

    for size in sizes {
        // Create test text
        text := create_pattern_text(size, pattern)
        defer delete(text)

        // Sequential timing
        seq_start := time.now()
        seq_matched, _ := regexp.simple_nfa_match(prog, text)
        seq_time := time.duration_seconds(time.now() - seq_start)

        // Parallel timing
        par_start := time.now()
        par_matched, _ := regexp.regex_match_parallel(parallel_matcher, prog, text)
        par_time := time.duration_seconds(time.now() - par_start)

        speedup := seq_time / par_time

        fmt.printf("%9d | %10.3f | %8.3f | %7.2fx\n",
                  size, seq_time * 1000.0, par_time * 1000.0, speedup)
    }

    fmt.Println()
}

// Helper: Create large sample text
create_large_sample_text :: proc(size: int) -> string {
    text := make([dynamic]u8)

    // Create repeating pattern with some matches
    words := []string{"hello", "world", "test", "data", "regex", "parallel"}

    for len(text) < size {
        word := words[len(text) % len(words)]
        number := fmt.tprintf("%d", len(text) % 1000)

        // Add word + number combination (creates matches for our pattern)
        for char in word {
            append(&text, u8(char))
        }
        for char in number {
            append(&text, u8(char))
        }
        append(&text, ' ')
    }

    return string(text[:size])
}

// Helper: Create text with specific pattern
create_pattern_text :: proc(size: int, pattern: string) -> string {
    text := make([dynamic]u8)

    // Fill with random characters
    for len(text) < size {
        append(&text, 'a' + u8(len(text) % 26))
    }

    // Insert pattern at regular intervals
    interval := size / 10
    if interval < len(pattern) {
        interval = len(pattern) * 2
    }

    for pos := interval; pos < size - len(pattern); pos += interval {
        for j := 0; j < len(pattern) && pos + j < size; j += 1 {
            text[pos + j] = pattern[j]
        }
    }

    return string(text[:])
}

// Main function
main :: proc() {
    fmt.println("Parallel Regex Matching Examples")
    fmt.println("=================================")
    fmt.println()

    // Run all examples
    example_basic_parallel()
    example_large_text()
    example_custom_config()
    example_multiple_patterns()
    example_performance_comparison()

    fmt.Println("All examples completed successfully!")
    fmt.Println("\nKey takeaways:")
    fmt.Println("- Parallel matching is automatic for large texts")
    fmt.Println("- Performance improves significantly with text size")
    fmt.Println("- Configuration is flexible and tunable")
    fmt.Println("- API is simple and backward compatible")
}

// Helper for string building
strings :: struct {}

// Simple string repeat function
repeat :: proc(s: string, count: int) -> string {
    if count <= 0 {
        return ""
    }
    result := make([dynamic]u8)
    for i := 0; i < count; i += 1 {
        for char in s {
            append(&result, u8(char))
        }
    }
    return string(result[:])
}

// Simple string split function
split :: proc(text: string, delimiter: string) -> []string {
    result := make([dynamic]string)
    start := 0

    for i := 0; i <= len(text) - len(delimiter); i += 1 {
        match := true
        for j := 0; j < len(delimiter); j += 1 {
            if text[i + j] != delimiter[j] {
                match = false
                break
            }
        }
        if match {
            append(&result, text[start:i])
            start = i + len(delimiter)
        }
    }

    if start < len(text) {
        append(&result, text[start:])
    }

    return result[:]
}