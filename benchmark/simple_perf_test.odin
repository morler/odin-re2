package main

import "core:fmt"
import "core:time"
import "../regexp"

// Simple performance test for Odin RE2
Test_Case :: struct {
    name: string,
    pattern: string,
    text: string,
    iterations: int,
}

main :: proc() {
    fmt.println("=== Odin RE2 Simple Performance Test ===")

    test_cases := []Test_Case{
        {"Literal", "hello", "hello world hello universe", 10000},
        {"Char Class", "[a-z]+", "abc123def456ghi", 10000},
        {"Quantifier Plus", "a+", "aaaaabbbccc", 10000},
        {"Quantifier Star", "a*b", "aaaaab", 10000},
        {"Unicode", "你好", "你好世界测试", 5000},
        {"Complex", "a+b+c+", "aaabbbccc", 5000},
    }

    for test_case in test_cases {
        run_test(test_case)
    }
}

run_test :: proc(test: Test_Case) {
    fmt.printf("\nTest: %s\n", test.name)
    fmt.printf("Pattern: %s\n", test.pattern)

    // Compile
    start_compile := time.now()
    pattern, compile_err := regexp.regexp(test.pattern)
    end_compile := time.now()

    if compile_err != regexp.ErrorCode.NoError {
        fmt.printf("  COMPILE ERROR: %v\n", compile_err)
        return
    }

    compile_duration := time.diff(end_compile, start_compile)
    compile_ns := time.duration_nanoseconds(compile_duration)
    if compile_ns < 0 { compile_ns = -compile_ns }
    fmt.printf("  Compile time: %dns\n", compile_ns)

    // Warmup
    for i in 0..<100 {
        _, match_err := regexp.match(pattern, test.text)
        if match_err != regexp.ErrorCode.NoError {
            fmt.printf("  WARMUP ERROR: %v\n", match_err)
            regexp.free_regexp(pattern)
            return
        }
    }

    // Benchmark
    start_match := time.now()
    successful_matches := 0

    for i in 0..<test.iterations {
        result, match_err := regexp.match(pattern, test.text)
        if match_err == regexp.ErrorCode.NoError && result.matched {
            successful_matches += 1
        }
    }

    end_match := time.now()
    match_duration := time.diff(end_match, start_match)
    total_time_ns := time.duration_nanoseconds(match_duration)
    if total_time_ns < 0 { total_time_ns = -total_time_ns }
    avg_time_ns := total_time_ns / i64(test.iterations)
    ops_per_sec := 1_000_000_000 / u64(avg_time_ns) if avg_time_ns > 0 else 0
    success_rate := f32(successful_matches) / f32(test.iterations) * 100.0

    fmt.printf("  Iterations: %d\n", test.iterations)
    fmt.printf("  Total time: %dns\n", total_time_ns)
    fmt.printf("  Avg time: %dns\n", avg_time_ns)
    fmt.printf("  Throughput: %v ops/sec\n", ops_per_sec)
    fmt.printf("  Success rate: %.1f%%\n", success_rate)

    if ops_per_sec > 1_000_000 {
        fmt.printf("  Rating: 🟢 EXCELLENT (>1M ops/sec)\n")
    } else if ops_per_sec > 100_000 {
        fmt.printf("  Rating: 🟡 GOOD (>100K ops/sec)\n")
    } else if ops_per_sec > 10_000 {
        fmt.printf("  Rating: 🟠 ACCEPTABLE (>10K ops/sec)\n")
    } else {
        fmt.printf("  Rating: 🔴 POOR (<10K ops/sec)\n")
    }

    regexp.free_regexp(pattern)
}