use std::time::Instant;
use regex::Regex;

// Standard benchmark test suite for comparing Rust regex vs Odin RE2
// This mirrors the Odin benchmark exactly for fair comparison

#[derive(Debug, Clone)]
struct BenchmarkCase {
    name: String,
    pattern: String,
    input: String,
    description: String,
}

// Core test cases that exercise different regex features
// These must match the Odin benchmark cases exactly
const BENCHMARK_CASES: &[BenchmarkCase] = &[
    // Basic literals - the foundation
    BenchmarkCase {
        name: "simple_literal".to_string(),
        pattern: "hello".to_string(),
        input: "hello world".to_string(),
        description: "Simple literal matching".to_string(),
    },
    BenchmarkCase {
        name: "literal_not_found".to_string(),
        pattern: "xyz".to_string(),
        input: "hello world".to_string(),
        description: "Literal that doesn't match".to_string(),
    },
    BenchmarkCase {
        name: "long_literal".to_string(),
        pattern: "a".repeat(100),
        input: "a".repeat(1000),
        description: "Long literal pattern".to_string(),
    },
    
    // Character classes - essential for real-world patterns
    BenchmarkCase {
        name: "char_class_simple".to_string(),
        pattern: "[abc]".to_string(),
        input: "b".to_string(),
        description: "Simple character class".to_string(),
    },
    BenchmarkCase {
        name: "char_class_range".to_string(),
        pattern: "[a-z]".to_string(),
        input: "m".to_string(),
        description: "Character class range".to_string(),
    },
    BenchmarkCase {
        name: "char_class_negated".to_string(),
        pattern: "[^0-9]".to_string(),
        input: "a".to_string(),
        description: "Negated character class".to_string(),
    },
    BenchmarkCase {
        name: "char_class_complex".to_string(),
        pattern: "[a-zA-Z0-9_]".to_string(),
        input: "X".to_string(),
        description: "Complex character class".to_string(),
    },
    
    // Quantifiers - where performance matters most
    BenchmarkCase {
        name: "star_zero".to_string(),
        pattern: "a*".to_string(),
        input: "bbb".to_string(),
        description: "Star matching zero occurrences".to_string(),
    },
    BenchmarkCase {
        name: "star_many".to_string(),
        pattern: "a*".to_string(),
        input: "aaaaab".to_string(),
        description: "Star matching many occurrences".to_string(),
    },
    BenchmarkCase {
        name: "plus_one".to_string(),
        pattern: "a+".to_string(),
        input: "a".to_string(),
        description: "Plus matching one occurrence".to_string(),
    },
    BenchmarkCase {
        name: "plus_many".to_string(),
        pattern: "a+".to_string(),
        input: "aaaaa".to_string(),
        description: "Plus matching many occurrences".to_string(),
    },
    BenchmarkCase {
        name: "quest_present".to_string(),
        pattern: "a?".to_string(),
        input: "a".to_string(),
        description: "Question mark matching".to_string(),
    },
    BenchmarkCase {
        name: "quest_absent".to_string(),
        pattern: "a?".to_string(),
        input: "b".to_string(),
        description: "Question mark not matching".to_string(),
    },
    
    // Anchors - important for performance optimization
    BenchmarkCase {
        name: "begin_anchor".to_string(),
        pattern: "^hello".to_string(),
        input: "hello world".to_string(),
        description: "Begin anchor".to_string(),
    },
    BenchmarkCase {
        name: "end_anchor".to_string(),
        pattern: "world$".to_string(),
        input: "hello world".to_string(),
        description: "End anchor".to_string(),
    },
    BenchmarkCase {
        name: "both_anchors".to_string(),
        pattern: "^hello world$".to_string(),
        input: "hello world".to_string(),
        description: "Both anchors".to_string(),
    },
    
    // Alternation - tests branching logic
    BenchmarkCase {
        name: "alt_simple".to_string(),
        pattern: "cat|dog".to_string(),
        input: "dog".to_string(),
        description: "Simple alternation".to_string(),
    },
    BenchmarkCase {
        name: "alt_multiple".to_string(),
        pattern: "cat|dog|bird".to_string(),
        input: "bird".to_string(),
        description: "Multiple alternation".to_string(),
    },
    BenchmarkCase {
        name: "alt_complex".to_string(),
        pattern: "hello|world|test".to_string(),
        input: "world".to_string(),
        description: "Complex alternation".to_string(),
    },
    
    // Concatenation - most common pattern
    BenchmarkCase {
        name: "concat_simple".to_string(),
        pattern: "ab".to_string(),
        input: "ab".to_string(),
        description: "Simple concatenation".to_string(),
    },
    BenchmarkCase {
        name: "concat_long".to_string(),
        pattern: "abcdefghij".to_string(),
        input: "abcdefghij".to_string(),
        description: "Long concatenation".to_string(),
    },
    BenchmarkCase {
        name: "concat_mixed".to_string(),
        pattern: "a1b2c3".to_string(),
        input: "a1b2c3".to_string(),
        description: "Mixed concatenation".to_string(),
    },
    
    // Real-world patterns
    BenchmarkCase {
        name: "email_simple".to_string(),
        pattern: "[a-z]+@[a-z]+\\.[a-z]+".to_string(),
        input: "test@example.com".to_string(),
        description: "Simple email pattern".to_string(),
    },
    BenchmarkCase {
        name: "phone_simple".to_string(),
        pattern: "[0-9]{3}-[0-9]{3}-[0-9]{4}".to_string(),
        input: "555-123-4567".to_string(),
        description: "Simple phone pattern".to_string(),
    },
    BenchmarkCase {
        name: "ipv4_simple".to_string(),
        pattern: "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}".to_string(),
        input: "192.168.1.1".to_string(),
        description: "Simple IPv4 pattern".to_string(),
    },
];

#[derive(Debug)]
struct BenchmarkResult {
    case_name: String,
    compile_time_ns: u128,
    match_time_ns: u128,
    matched: bool,
    error: Option<String>,
}

// Run single benchmark case
fn run_benchmark(test_case: &BenchmarkCase) -> BenchmarkResult {
    let mut result = BenchmarkResult {
        case_name: test_case.name.clone(),
        compile_time_ns: 0,
        match_time_ns: 0,
        matched: false,
        error: None,
    };
    
    // Measure compilation time
    let compile_start = Instant::now();
    let regex_result = Regex::new(&test_case.pattern);
    let compile_end = Instant::now();
    
    result.compile_time_ns = compile_start.elapsed().as_nanos();
    
    match regex_result {
        Ok(regex) => {
            // Measure matching time
            let match_start = Instant::now();
            let matched = regex.is_match(&test_case.input);
            let match_end = Instant::now();
            
            result.match_time_ns = match_start.elapsed().as_nanos();
            result.matched = matched;
        }
        Err(e) => {
            result.error = Some(e.to_string());
        }
    }
    
    result
}

// Format time duration for human reading
fn format_time(nanoseconds: u128) -> String {
    if nanoseconds < 1_000 {
        format!("{}ns", nanoseconds)
    } else if nanoseconds < 1_000_000 {
        format!("{:.2}μs", nanoseconds as f64 / 1_000.0)
    } else if nanoseconds < 1_000_000_000 {
        format!("{:.2}ms", nanoseconds as f64 / 1_000_000.0)
    } else {
        format!("{:.2}s", nanoseconds as f64 / 1_000_000_000.0)
    }
}

fn main() {
    println!("=== Rust Regex Benchmark Suite ===");
    println!("Running {} benchmark cases...\n", BENCHMARK_CASES.len());
    
    let mut total_compile_time: u128 = 0;
    let mut total_match_time: u128 = 0;
    let mut successful_cases = 0;
    
    for test_case in BENCHMARK_CASES {
        println!("Running: {}", test_case.name);
        println!("Pattern: {:?}", test_case.pattern);
        println!("Input:   {:?}", test_case.input);
        println!("Desc:    {}", test_case.description);
        
        let result = run_benchmark(test_case);
        
        println!("Compile: {}", format_time(result.compile_time_ns));
        println!("Match:   {}", format_time(result.match_time_ns));
        println!("Result:  {}", result.matched);
        
        if let Some(error) = &result.error {
            println!("Error:   {}", error);
        } else {
            total_compile_time += result.compile_time_ns;
            total_match_time += result.match_time_ns;
            successful_cases += 1;
        }
        
        println!("{}", "-".repeat(50));
    }
    
    // Summary statistics
    println!("\n=== BENCHMARK SUMMARY ===");
    println!("Total cases:        {}", BENCHMARK_CASES.len());
    println!("Successful cases:   {}", successful_cases);
    println!("Failed cases:       {}", BENCHMARK_CASES.len() - successful_cases);
    println!("Total compile time: {}", format_time(total_compile_time));
    println!("Total match time:   {}", format_time(total_match_time));
    
    if successful_cases > 0 {
        let avg_compile = total_compile_time / successful_cases as u128;
        let avg_match = total_match_time / successful_cases as u128;
        println!("Avg compile time:   {}", format_time(avg_compile));
        println!("Avg match time:     {}", format_time(avg_match));
    }
    
    println!("\n=== PERFORMANCE ANALYSIS ===");
    
    // Performance analysis
    if total_compile_time > 0 {
        let compile_ratio = total_compile_time as f64 / total_match_time as f64;
        println!("Compile/Match ratio: {:.2}x", compile_ratio);
        
        if compile_ratio > 10.0 {
            println!("⚠️  Compilation is significantly slower than matching");
            println!("   Consider pattern caching for repeated use");
        } else if compile_ratio > 2.0 {
            println!("ℹ️  Compilation is slower than matching");
            println!("   Pattern reuse is beneficial");
        } else {
            println!("✅ Compilation overhead is reasonable");
        }
    }
    
    // Check for linear time behavior indicators
    if successful_cases >= 10 {
        let avg_total_time = (total_compile_time + total_match_time) as f64 / successful_cases as f64;
        if avg_total_time < 100_000.0 { // Less than 100μs average
            println!("✅ Performance is excellent - suitable for high-throughput use");
        } else if avg_total_time < 1_000_000.0 { // Less than 1ms average
            println!("✅ Performance is good - suitable for most applications");
        } else {
            println!("⚠️  Performance may be a concern for high-throughput applications");
        }
    }
    
    println!("\n=== COMPARISON READY ===");
    println!("Compare these results with the Odin RE2 benchmark");
    println!("to analyze performance differences and functionality gaps.");
}