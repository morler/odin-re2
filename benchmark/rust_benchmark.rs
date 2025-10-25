use std::time::Instant;
use regex::Regex;
use std::env;
use std::fs::File;
use std::io::{self, Write};
use std::path::Path;

#[derive(Debug, Clone)]
struct BenchmarkCase {
    name: &'static str,
    pattern: String,
    input: String,
    description: &'static str,
}

// Core test cases that exercise different regex features
// These must match the Odin benchmark cases exactly
fn get_benchmark_cases() -> Vec<BenchmarkCase> {
    vec![
        // Basic literals - the foundation
        BenchmarkCase {
            name: "simple_literal",
            pattern: "hello".to_string(),
            input: "hello world".to_string(),
            description: "Simple literal matching",
        },
        BenchmarkCase {
            name: "literal_not_found",
            pattern: "xyz".to_string(),
            input: "hello world".to_string(),
            description: "Literal that doesn't match",
        },
        BenchmarkCase {
            name: "long_literal",
            pattern: "a".repeat(100),
            input: "a".repeat(1000),
            description: "Long literal pattern",
        },
        
        // Character classes - essential for real-world patterns
        BenchmarkCase {
            name: "char_class_simple",
            pattern: "[abc]".to_string(),
            input: "b".to_string(),
            description: "Simple character class",
        },
        BenchmarkCase {
            name: "char_class_range",
            pattern: "[a-z]".to_string(),
            input: "m".to_string(),
            description: "Character class range",
        },
        BenchmarkCase {
            name: "char_class_negated",
            pattern: "[^0-9]".to_string(),
            input: "a".to_string(),
            description: "Negated character class",
        },
        BenchmarkCase {
            name: "char_class_complex",
            pattern: "[a-zA-Z0-9_]".to_string(),
            input: "X".to_string(),
            description: "Complex character class",
        },
        
        // Quantifiers - the heart of regex power
        BenchmarkCase {
            name: "star_zero",
            pattern: "a*".to_string(),
            input: "bbb".to_string(),
            description: "Star matching zero occurrences",
        },
        BenchmarkCase {
            name: "star_many",
            pattern: "a*".to_string(),
            input: "aaaaab".to_string(),
            description: "Star matching many occurrences",
        },
        BenchmarkCase {
            name: "plus_one",
            pattern: "a+".to_string(),
            input: "a".to_string(),
            description: "Plus matching one occurrence",
        },
        BenchmarkCase {
            name: "plus_many",
            pattern: "a+".to_string(),
            input: "aaaaa".to_string(),
            description: "Plus matching many occurrences",
        },
        BenchmarkCase {
            name: "quest_present",
            pattern: "a?".to_string(),
            input: "a".to_string(),
            description: "Question mark matching",
        },
        BenchmarkCase {
            name: "quest_absent",
            pattern: "a?".to_string(),
            input: "b".to_string(),
            description: "Question mark not matching",
        },
        
        // Anchors - positioning control
        BenchmarkCase {
            name: "begin_anchor",
            pattern: "^hello".to_string(),
            input: "hello world".to_string(),
            description: "Begin anchor",
        },
        BenchmarkCase {
            name: "end_anchor",
            pattern: "world$".to_string(),
            input: "hello world".to_string(),
            description: "End anchor",
        },
        BenchmarkCase {
            name: "both_anchors",
            pattern: "^hello world$".to_string(),
            input: "hello world".to_string(),
            description: "Both anchors",
        },
        
        // Alternation - choice patterns
        BenchmarkCase {
            name: "alt_simple",
            pattern: "cat|dog".to_string(),
            input: "dog".to_string(),
            description: "Simple alternation",
        },
        BenchmarkCase {
            name: "alt_multiple",
            pattern: "cat|dog|bird".to_string(),
            input: "bird".to_string(),
            description: "Multiple alternation",
        },
        BenchmarkCase {
            name: "alt_complex",
            pattern: "hello|world|test".to_string(),
            input: "world".to_string(),
            description: "Complex alternation",
        },
        
        // Concatenation - sequence patterns
        BenchmarkCase {
            name: "concat_simple",
            pattern: "ab".to_string(),
            input: "ab".to_string(),
            description: "Simple concatenation",
        },
        BenchmarkCase {
            name: "concat_long",
            pattern: "abcdefghij".to_string(),
            input: "abcdefghij".to_string(),
            description: "Long concatenation",
        },
        BenchmarkCase {
            name: "concat_mixed",
            pattern: "a1b2c3".to_string(),
            input: "a1b2c3".to_string(),
            description: "Mixed concatenation",
        },
        
        // Real-world patterns
        BenchmarkCase {
            name: "email_simple",
            pattern: "[a-z]+@[a-z]+\\.[a-z]+".to_string(),
            input: "test@example.com".to_string(),
            description: "Simple email pattern",
        },
        BenchmarkCase {
            name: "phone_simple",
            pattern: "[0-9]{3}-[0-9]{3}-[0-9]{4}".to_string(),
            input: "555-123-4567".to_string(),
            description: "Simple phone pattern",
        },
        BenchmarkCase {
            name: "ipv4_simple",
            pattern: "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}".to_string(),
            input: "192.168.1.1".to_string(),
            description: "Simple IPv4 pattern",
        },
    ]
}

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
        case_name: test_case.name.to_string(),
        compile_time_ns: 0,
        match_time_ns: 0,
        matched: false,
        error: None,
    };
    
    // Measure compilation time
    let compile_start = Instant::now();
    let regex_result = Regex::new(&test_case.pattern);
    let _compile_end = Instant::now();
    
    result.compile_time_ns = compile_start.elapsed().as_nanos();
    
    match regex_result {
        Ok(regex) => {
            // Measure matching time
            let match_start = Instant::now();
            let matched = regex.is_match(&test_case.input);
            let _match_end = Instant::now();
            
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

fn write_functionality_tsv(output_path: &str, cases: &[BenchmarkCase]) -> io::Result<()> {
    let mut file = File::create(output_path)?;
    
    // Write header
    writeln!(file, "name\tpattern\ttext\tshould_compile\tcompile_ok\tshould_match\tactual_match\tverify_full_match\tmatch_verified\tcompile_ns\tmatch_ns\tstatus\tnotes")?;
    
    for case in cases {
        let result = run_benchmark(case);
        
        let should_compile = true;
        let compile_ok = result.error.is_none();
        let should_match = true; // For benchmark cases, we assume they should match
        let actual_match = result.matched;
        let verify_full_match = false; // Not verifying full match for benchmarks
        let match_verified = false;
        let status = if result.error.is_none() && result.matched { "PASS" } else { "FAIL" };
        let notes = result.error.unwrap_or_default();
        
        writeln!(
            file,
            "{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
            case.name,
            case.pattern,
            case.input,
            should_compile,
            compile_ok,
            should_match,
            actual_match,
            verify_full_match,
            match_verified,
            result.compile_time_ns,
            result.match_time_ns,
            status,
            notes
        )?;
    }
    
    Ok(())
}

fn write_performance_tsv(output_path: &str, cases: &[BenchmarkCase]) -> io::Result<()> {
    let mut file = File::create(output_path)?;
    
    // Write header
    writeln!(file, "name\tpattern\ttext_size\titerations\tcompile_ns\tmatch_total_ns\tmatch_avg_ns\tthroughput_mb_s\tmatched\tstatus\tnotes")?;
    
    for case in cases {
        let result = run_benchmark(case);
        
        let text_size = case.input.len();
        let iterations = 1; // Single match for benchmark
        let match_total_ns = result.match_time_ns;
        let match_avg_ns = result.match_time_ns;
        let throughput_mb_s = if result.match_time_ns > 0 {
            (text_size as f64) / (result.match_time_ns as f64 / 1_000_000_000.0) / 1_048_576.0
        } else {
            0.0
        };
        let matched = result.matched;
        let status = if result.error.is_none() { "PASS" } else { "FAIL" };
        let notes = result.error.unwrap_or_default();
        
        writeln!(
            file,
            "{}\t{}\t{}\t{}\t{}\t{}\t{}\t{:.6}\t{}\t{}\t{}",
            case.name,
            case.pattern,
            text_size,
            iterations,
            result.compile_time_ns,
            match_total_ns,
            match_avg_ns,
            throughput_mb_s,
            matched,
            status,
            notes
        )?;
    }
    
    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 2 {
        eprintln!("Usage: {} --mode functionality|performance [--cases <cases_file>] [--output <output_file>]", args[0]);
        std::process::exit(1);
    }
    
    let mode = &args[1];
    if mode != "--mode" || args.len() < 3 {
        eprintln!("Error: --mode argument required");
        std::process::exit(1);
    }
    
    let mode_value = &args[2];
    let cases = get_benchmark_cases();
    
    match mode_value.as_str() {
        "functionality" => {
            let output_path = if args.len() > 4 && args[3] == "--output" {
                &args[4]
            } else {
                "benchmark/results/functional_rust.tsv"
            };
            
            // Ensure output directory exists
            if let Some(parent) = Path::new(output_path).parent() {
                std::fs::create_dir_all(parent).ok();
            }
            
            if let Err(e) = write_functionality_tsv(output_path, &cases) {
                eprintln!("Error writing functionality results: {}", e);
                std::process::exit(1);
            }
            
            println!("Functionality benchmark completed. Results written to {}", output_path);
        }
        "performance" => {
            let output_path = if args.len() > 4 && args[3] == "--output" {
                &args[4]
            } else {
                "benchmark/results/performance_rust.tsv"
            };
            
            // Ensure output directory exists
            if let Some(parent) = Path::new(output_path).parent() {
                std::fs::create_dir_all(parent).ok();
            }
            
            if let Err(e) = write_performance_tsv(output_path, &cases) {
                eprintln!("Error writing performance results: {}", e);
                std::process::exit(1);
            }
            
            println!("Performance benchmark completed. Results written to {}", output_path);
        }
        _ => {
            eprintln!("Error: Invalid mode '{}'. Use 'functionality' or 'performance'", mode_value);
            std::process::exit(1);
        }
    }
}