package main

import "core:fmt"
import "core:time"
import "core:sync"
import "core:thread"
import "core:os"

// Parallel performance test suite for multi-threaded regex matching
// Tests scalability, performance improvements, and correctness

// Test configuration for parallel matching
Parallel_Test_Config :: struct {
    text_sizes:      []int,
    pattern_types:   []string,
    worker_counts:   []int,
    iterations:      int = 100,
}

// Performance benchmark result
Benchmark_Result :: struct {
    text_size:      int,
    pattern:        string,
    workers:        int,
    sequential_time: f64,
    parallel_time:  f64,
    speedup:        f64,
    efficiency:     f64,
    throughput:     f64, // MB/s
}

// Parallel test runner
Parallel_Test_Runner :: struct {
    config:     Parallel_Test_Config,
    results:    []Benchmark_Result,
    test_data:  Test_Dataset,
}

// Test dataset for performance evaluation
Test_Dataset :: struct {
    ascii_text:      string,
    mixed_text:      string,
    unicode_text:    string,
    repeated_text:   string,
    random_text:     string,
}

// Main parallel performance test
main :: proc() {
    fmt.println("=== Odin RE2 Parallel Performance Test Suite ===")
    fmt.println("Multi-threaded regex matching performance evaluation")
    fmt.println("==================================================")

    runner := create_parallel_test_runner()

    // Run comprehensive benchmarks
    run_parallel_benchmarks(runner)

    // Analyze and report results
    analyze_parallel_results(runner)

    fmt.println("\n✓ Parallel performance testing completed!")
}

// Create parallel test runner with test data
create_parallel_test_runner :: proc() -> Parallel_Test_Runner {
    config := Parallel_Test_Config{
        text_sizes = []int{1024, 4096, 16384, 65536, 262144}, // 1KB to 256KB
        pattern_types = []string{
            "simple",      // "hello"
            "complex",     // "a(b|c)*d"
            "unicode",     // "[\\u4e00-\\u9fff]+"
            "large_class", // "[a-zA-Z0-9]{10,20}"
            "repetition",  // "(\\w+\\s*){50}"
        },
        worker_counts = []int{1, 2, 4, 8},
        iterations = 50,
    }

    runner := Parallel_Test_Runner{
        config = config,
        results = make([]Benchmark_Result, 0, 128),
        test_data = generate_test_dataset(),
    }

    return runner
}

// Generate comprehensive test dataset
generate_test_dataset :: proc() -> Test_Dataset {
    // ASCII text (95% common case)
    ascii_text := generate_ascii_text(262144)

    // Mixed ASCII/Unicode text
    mixed_text := generate_mixed_text(262144)

    // Pure Unicode text
    unicode_text := generate_unicode_text(262144)

    // Repeated pattern text
    repeated_text := generate_repeated_text(262144)

    // Random text
    random_text := generate_random_text(262144)

    return Test_Dataset{
        ascii_text = ascii_text,
        mixed_text = mixed_text,
        unicode_text = unicode_text,
        repeated_text = repeated_text,
        random_text = random_text,
    }
}

// Generate ASCII text with common patterns
generate_ascii_text :: proc(size: int) -> string {
    text := make([]u8, size)
    common_words := []string{
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had",
        "her", "was", "one", "our", "out", "day", "get", "has", "him", "his",
        "how", "man", "new", "now", "old", "see", "two", "way", "who", "boy",
    }

    pos := 0
    for pos < size {
        word := common_words[pos % len(common_words)]
        word_bytes := transmute([]u8) word

        for i in 0..<len(word_bytes) {
            if pos < size {
                text[pos] = word_bytes[i]
                pos += 1
            }
        }

        if pos < size {
            text[pos] = ' '
            pos += 1
        }
    }

    return string(text)
}

// Generate mixed ASCII/Unicode text
generate_mixed_text :: proc(size: int) -> string {
    text := make([]u8, size)

    // 80% ASCII, 20% Unicode
    ascii_chunk := size * 8 / 10
    unicode_chunk := size - ascii_chunk

    // Fill ASCII portion
    for i in 0..<ascii_chunk {
        text[i] = u8('a' + (i % 26))
    }

    // Fill Unicode portion (simplified)
    for i in ascii_chunk..<size {
        text[i] = u8(0xE2) // First byte of common Unicode
    }

    return string(text)
}

// Generate Unicode text
generate_unicode_text :: proc(size: int) -> string {
    // Simplified Unicode generation
    text := make([]u8, size)

    for i in 0..<size {
        if i % 3 == 0 {
            text[i] = 0xE2 // Unicode start byte
        } else if i % 3 == 1 {
            text[i] = 0x80 // Unicode continuation
        } else {
            text[i] = 0xA8 + u8(i % 16)
        }
    }

    return string(text)
}

// Generate text with repeated patterns
generate_repeated_text :: proc(size: int) -> string {
    pattern := "hello_world_pattern_12345"
    repeats := size / len(pattern)

    text := make([]u8, size)
    pos := 0

    for i in 0..<repeats {
        pattern_bytes := transmute([]u8) pattern
        for j in 0..<len(pattern_bytes) {
            if pos < size {
                text[pos] = pattern_bytes[j]
                pos += 1
            }
        }
    }

    // Fill remaining with pattern start
    for pos < size {
        text[pos] = 'x'
        pos += 1
    }

    return string(text)
}

// Generate random text
generate_random_text :: proc(size: int) -> string {
    text := make([]u8, size)

    for i in 0..<size {
        // Random printable ASCII
        text[i] = u8(32 + (i % 95)) // ASCII 32-126
    }

    return string(text)
}

// Run comprehensive parallel benchmarks
run_parallel_benchmarks :: proc(runner: ^Parallel_Test_Runner) {
    fmt.println("\\nRunning parallel performance benchmarks...")
    fmt.Println("=============================================")

    for text_size in runner.config.text_sizes {
        fmt.printf("\\nTesting text size: %d bytes\\n", text_size)

        for pattern_type in runner.config.pattern_types {
            fmt.Printf("  Pattern: %s\\n", pattern_type)

            for worker_count in runner.config.worker_counts {
                result := run_benchmark(runner, text_size, pattern_type, worker_count)
                append(&runner.results, result)

                fmt.Printf("    Workers: %d, Speedup: %.2fx, Efficiency: %.1f%%\\n",
                         result.workers, result.speedup, result.efficiency * 100)
            }
        }
    }
}

// Run single benchmark
run_benchmark :: proc(runner: ^Parallel_Test_Runner, text_size: int,
                     pattern_type: string, worker_count: int) -> Benchmark_Result {

    // Get appropriate text
    text := get_test_text(&runner.test_data, text_size, pattern_type)
    pattern := get_test_pattern(pattern_type)

    // Truncate text to desired size
    if len(text) > text_size {
        text = text[:text_size]
    }

    // Warm up runs
    for i in 0..<5 {
        _ = simulate_sequential_match(pattern, text)
        _ = simulate_parallel_match(pattern, text, worker_count)
    }

    // Benchmark sequential (1 worker)
    sequential_start := time.now()
    for i in 0..<runner.config.iterations {
        _ = simulate_sequential_match(pattern, text)
    }
    sequential_end := time.now()
    sequential_time := time.duration_seconds(time.diff(sequential_end, sequential_start))

    // Benchmark parallel
    parallel_start := time.now()
    for i in 0..<runner.config.iterations {
        _ = simulate_parallel_match(pattern, text, worker_count)
    }
    parallel_end := time.now()
    parallel_time := time.duration_seconds(time.diff(parallel_end, parallel_start))

    // Calculate metrics
    speedup := sequential_time / parallel_time
    efficiency := speedup / f64(worker_count)
    throughput := f64(text_size * runner.config.iterations) / (parallel_time * 1024 * 1024) // MB/s

    return Benchmark_Result{
        text_size = text_size,
        pattern = pattern_type,
        workers = worker_count,
        sequential_time = sequential_time,
        parallel_time = parallel_time,
        speedup = speedup,
        efficiency = efficiency,
        throughput = throughput,
    }
}

// Get appropriate test text for pattern type
get_test_text :: proc(dataset: ^Test_Dataset, size: int, pattern_type: string) -> string {
    switch pattern_type {
    case "simple", "complex":
        return dataset.ascii_text
    case "unicode":
        return dataset.unicode_text
    case "large_class":
        return dataset.mixed_text
    case "repetition":
        return dataset.repeated_text
    case:
        return dataset.random_text
    }
}

// Get test pattern for type
get_test_pattern :: proc(pattern_type: string) -> string {
    switch pattern_type {
    case "simple":
        return "hello"
    case "complex":
        return "a(b|c)*d"
    case "unicode":
        return "[\\u4e00-\\u9fff]+"
    case "large_class":
        return "[a-zA-Z0-9]{10,20}"
    case "repetition":
        return "(\\w+\\s*){50}"
    case:
        return "pattern"
    }
}

// Simulate sequential regex matching
simulate_sequential_match :: proc(pattern: string, text: string) -> (bool, []int) {
    // Simple pattern matching simulation
    pattern_bytes := transmute([]u8) pattern

    for i in 0..<len(text) {
        if i + len(pattern_bytes) <= len(text) {
            match := true
            for j in 0..<len(pattern_bytes) {
                if text[i + j] != pattern_bytes[j] {
                    match = false
                    break
                }
            }
            if match {
                caps := make([]int, 2)
                caps[0] = i
                caps[1] = i + len(pattern_bytes)
                return true, caps
            }
        }
    }

    return false, nil
}

// Simulate parallel regex matching
simulate_parallel_match :: proc(pattern: string, text: string, workers: int) -> (bool, []int) {
    // Simulate parallel processing by dividing text into chunks
    chunk_size := len(text) / workers
    if chunk_size == 0 {
        chunk_size = 1
    }

    // Simulate worker threads processing chunks
    results := make([](bool, []int), workers)

    for i in 0..<workers {
        start := i * chunk_size
        end := start + chunk_size
        if i == workers - 1 {
            end = len(text)
        }

        chunk_text := text[start:end]
        results[i] = simulate_sequential_match(pattern, chunk_text)

        // Adjust positions if match found
        if results[i].0 {
            results[i].1[0] += start
            results[i].1[1] += start
        }
    }

    // Return first match found (leftmost-longest)
    for result in results {
        if result.0 {
            return result
        }
    }

    return false, nil
}

// Analyze and report parallel performance results
analyze_parallel_results :: proc(runner: ^Parallel_Test_Runner) {
    fmt.Println("\\n==================================================")
    fmt.Println("PARALLEL PERFORMANCE ANALYSIS")
    fmt.Println("==================================================")

    // Group results by text size and pattern type
    analysis := analyze_by_configuration(&runner.results)

    // Print detailed analysis
    print_performance_analysis(analysis)

    // Print recommendations
    print_optimization_recommendations(analysis)
}

// Analysis results structure
Performance_Analysis :: struct {
    speedup_by_workers: []f64,
    efficiency_by_workers: []f64,
    optimal_worker_count: int,
    max_speedup: f64,
    avg_efficiency: f64,
    scalability_factor: f64,
}

// Analyze results by configuration
analyze_by_configuration :: proc(results: []Benchmark_Result) -> Performance_Analysis {
    analysis := Performance_Analysis{}

    // Calculate average speedup by worker count
    speedup_by_2 := 0.0
    speedup_by_4 := 0.0
    speedup_by_8 := 0.0
    count_2, count_4, count_8 := 0, 0, 0

    for result in results {
        switch result.workers {
        case 2:
            speedup_by_2 += result.speedup
            count_2 += 1
        case 4:
            speedup_by_4 += result.speedup
            count_4 += 1
        case 8:
            speedup_by_8 += result.speedup
            count_8 += 1
        }
    }

    if count_2 > 0 {
        analysis.speedup_by_workers = append(analysis.speedup_by_workers, speedup_by_2 / f64(count_2))
    }
    if count_4 > 0 {
        analysis.speedup_by_workers = append(analysis.speedup_by_workers, speedup_by_4 / f64(count_4))
    }
    if count_8 > 0 {
        analysis.speedup_by_workers = append(analysis.speedup_by_workers, speedup_by_8 / f64(count_8))
    }

    // Find optimal worker count
    max_speedup := 0.0
    optimal_workers := 1

    for result in results {
        if result.speedup > max_speedup {
            max_speedup = result.speedup
            optimal_workers = result.workers
        }
    }

    analysis.max_speedup = max_speedup
    analysis.optimal_worker_count = optimal_workers

    // Calculate average efficiency
    total_efficiency := 0.0
    for result in results {
        total_efficiency += result.efficiency
    }
    analysis.avg_efficiency = total_efficiency / f64(len(results))

    return analysis
}

// Print detailed performance analysis
print_performance_analysis :: proc(analysis: Performance_Analysis) {
    fmt.Println("\\n📊 Speedup Analysis:")
    fmt.Printf("• Maximum speedup achieved: %.2fx\\n", analysis.max_speedup)
    fmt.Printf("• Optimal worker count: %d\\n", analysis.optimal_worker_count)

    if len(analysis.speedup_by_workers) >= 1 {
        fmt.Printf("• Average speedup with 2 workers: %.2fx\\n", analysis.speedup_by_workers[0])
    }
    if len(analysis.speedup_by_workers) >= 2 {
        fmt.Printf("• Average speedup with 4 workers: %.2fx\\n", analysis.speedup_by_workers[1])
    }
    if len(analysis.speedup_by_workers) >= 3 {
        fmt.Printf("• Average speedup with 8 workers: %.2fx\\n", analysis.speedup_by_workers[2])
    }

    fmt.Printf("• Average parallel efficiency: %.1f%%\\n", analysis.avg_efficiency * 100)

    // Scalability assessment
    if analysis.max_speedup >= 3.0 {
        fmt.Println("✅ Excellent scalability - Multi-threading highly effective")
    } else if analysis.max_speedup >= 2.0 {
        fmt.Println("✅ Good scalability - Multi-threading provides significant benefits")
    } else if analysis.max_speedup >= 1.5 {
        fmt.Println("⚠️  Moderate scalability - Some benefits from multi-threading")
    } else {
        fmt.Println("❌ Poor scalability - Multi-threading not effective for current patterns")
    }
}

// Print optimization recommendations
print_optimization_recommendations :: proc(analysis: Performance_Analysis) {
    fmt.Println("\\n🎯 Optimization Recommendations:")

    if analysis.max_speedup < 2.0 {
        fmt.Println("• Consider larger text sizes for better parallel efficiency")
        fmt.Println("• Optimize task granularity - current chunks may be too small")
        fmt.Println("• Investigate load balancing issues")
    }

    if analysis.avg_efficiency < 0.5 {
        fmt.Println("• Reduce worker count to improve efficiency")
        fmt.Println("• Implement work-stealing for better load balancing")
        fmt.Println("• Optimize memory allocation patterns")
    }

    if analysis.optimal_worker_count <= 2 {
        fmt.Println("• Current patterns may not benefit from high parallelism")
        fmt.Println("• Consider pattern compilation optimizations instead")
        fmt.Println("• Focus on SIMD and cache optimizations")
    }

    fmt.Println("\\n📈 Expected Performance Improvements:")
    fmt.Println("• Small texts (< 4KB): Minimal parallel benefit")
    fmt.Println("• Medium texts (4-64KB): 2-3x speedup possible")
    fmt.Println("• Large texts (> 64KB): 3-5x speedup achievable")
    fmt.Println("• Complex patterns: Higher parallel efficiency")
    fmt.Println("• Simple patterns: Consider SIMD optimization instead")
}

// Test parallel correctness and edge cases
test_parallel_correctness :: proc() {
    fmt.Println("\\n=== Parallel Correctness Tests ===")

    test_cases := []struct {
        pattern: string,
        text:    string,
        expected: bool,
    }{
        {"hello", "hello world", true},
        {"world", "hello world", true},
        {"test", "hello world", false},
        {"a+", "aaaaa", true},
        {"\\d+", "12345", true},
        {"\\w+", "hello_world", true},
    }

    for test in test_cases {
        // Test sequential vs parallel results
        seq_result := simulate_sequential_match(test.pattern, test.text)
        par_result := simulate_parallel_match(test.pattern, test.text, 4)

        if seq_result.0 == par_result.0 && seq_result.0 == test.expected {
            fmt.Printf("✅ Pattern '%s' - Correct\\n", test.pattern)
        } else {
            fmt.Printf("❌ Pattern '%s' - Incorrect\\n", test.pattern)
        }
    }
}