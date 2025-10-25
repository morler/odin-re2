use std::time::Instant;
use regex::Regex;
use std::env;
use std::fs::File;
use std::io::{self, Write};
use std::path::Path;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 2 {
        eprintln!("Usage: {} --mode functionality|performance [--output <output_file>]", args[0]);
        std::process::exit(1);
    }
    
    let mode = &args[1];
    if mode != "--mode" || args.len() < 3 {
        eprintln!("Error: --mode argument required");
        std::process::exit(1);
    }
    
    let mode_value = &args[2];
    
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
            
            write_functionality_results(output_path);
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
            
            write_performance_results(output_path);
            println!("Performance benchmark completed. Results written to {}", output_path);
        }
        _ => {
            eprintln!("Error: Invalid mode '{}'. Use 'functionality' or 'performance'", mode_value);
            std::process::exit(1);
        }
    }
}

fn write_functionality_results(output_path: &str) {
    let mut file = File::create(output_path).expect("Unable to create file");
    
    // Write header
    writeln!(file, "name\tpattern\ttext\tshould_compile\tcompile_ok\tshould_match\tactual_match\tverify_full_match\tmatch_verified\tcompile_ns\tmatch_ns\tstatus\tnotes").expect("Unable to write header");
    
    // Simple test cases that match the Odin functionality tests
    let test_cases = vec![
        ("simple_literal", "hello", "hello world", true, true),
        ("literal_not_found", "xyz", "hello world", true, false),
        ("empty_pattern", "", "any text at all", true, true),
        ("empty_text", "hello", "", true, false),
        ("begin_anchor", "^begin", "begin here", true, true),
        ("begin_anchor_fail", "^begin", "we begin later", true, false),
        ("end_anchor", "end$", "reach the end", true, true),
        ("end_anchor_fail", "end$", "endings are tricky", true, false),
        ("char_class_simple", "[abc]", "b", true, true),
        ("char_class_range", "[a-f]", "m", true, false),
        ("char_class_negated", "[^0-9]", "a", true, true),
        ("dot_wildcard", "h.llo", "hallo", true, true),
        ("star_quantifier_zero", "ab*c", "ac", true, true),
        ("star_quantifier_many", "ab*c", "abbbbc", true, true),
        ("plus_quantifier_one", "ab+c", "abc", true, true),
        ("plus_quantifier_fail", "ab+c", "ac", true, false),
        ("alternation_first", "cat|dog|bird", "cat", true, true),
        ("alternation_fail", "cat|dog|bird", "ferret", true, false),
    ];
    
    for (name, pattern, text, should_compile, should_match) in test_cases {
        let (compile_ok, actual_match, compile_ns, match_ns, status, notes) = run_regex_test(pattern, text);
        
        writeln!(
            file,
            "{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
            name, pattern, text, should_compile, compile_ok, should_match, actual_match,
            false, false, compile_ns, match_ns, status, notes
        ).expect("Unable to write line");
    }
}

fn write_performance_results(output_path: &str) {
    let mut file = File::create(output_path).expect("Unable to create file");
    
    // Write header
    writeln!(file, "name\tpattern\ttext_size\titerations\tcompile_ns\tmatch_total_ns\tmatch_avg_ns\tthroughput_mb_s\tmatched\tstatus\tnotes").expect("Unable to write header");
    
    // Performance test cases
    let perf_cases = vec![
        ("simple_literal", "hello", "hello world"),
        ("long_literal", &"a".repeat(100), &"a".repeat(1000)),
        ("char_class_simple", "[abc]", "b"),
        ("star_quantifier", "a*", &"a".repeat(100)),
        ("plus_quantifier", "a+", &"a".repeat(100)),
        ("complex_pattern", "[a-z]+@[a-z]+\\.[a-z]+", "test@example.com"),
    ];
    
    for (name, pattern, text) in perf_cases {
        let (compile_ok, matched, compile_ns, match_ns, _status, _notes) = run_regex_test(pattern, text);
        let status = if compile_ok { "PASS" } else { "FAIL" };
        let notes = "";
        
        let text_size = text.len();
        let iterations = 1;
        let match_total_ns = match_ns;
        let match_avg_ns = match_ns;
        let throughput_mb_s = if match_ns > 0 {
            (text_size as f64) / (match_ns as f64 / 1_000_000_000.0) / 1_048_576.0
        } else {
            0.0
        };
        
        writeln!(
            file,
            "{}\t{}\t{}\t{}\t{}\t{}\t{}\t{:.6}\t{}\t{}\t{}",
            name, pattern, text_size, iterations, compile_ns, match_total_ns, match_avg_ns,
            throughput_mb_s, matched, status, notes
        ).expect("Unable to write line");
    }
}

fn run_regex_test(pattern: &str, text: &str) -> (bool, bool, u128, u128, String, String) {
    // Measure compilation time
    let compile_start = Instant::now();
    let regex_result = Regex::new(pattern);
    let compile_end = Instant::now();
    let compile_ns = compile_start.elapsed().as_nanos();
    
    match regex_result {
        Ok(regex) => {
            // Measure matching time
            let match_start = Instant::now();
            let matched = regex.is_match(text);
            let match_end = Instant::now();
            let match_ns = match_start.elapsed().as_nanos();
            
            let status = if matched { "PASS" } else { "FAIL" };
            (true, matched, compile_ns, match_ns, status.to_string(), String::new())
        }
        Err(e) => {
            (false, false, compile_ns, 0, "FAIL".to_string(), e.to_string())
        }
    }
}