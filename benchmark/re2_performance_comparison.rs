use std::time::Instant;
use std::collections::HashMap;
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io::Write;

// Google RE2 性能对比评测 - Rust 实现
// 用于与 Odin RE2 进行严格的性能对比

#[derive(Debug, Clone, Serialize, Deserialize)]
struct BenchmarkCase {
    name: String,
    pattern: String,
    input: String,
    description: String,
    category: String,
    expected_match: bool,
}

#[derive(Debug, Serialize, Deserialize)]
struct BenchmarkResult {
    case_name: String,
    category: String,
    compile_time_ns: u128,
    match_time_ns: u128,
    matched: bool,
    error: Option<String>,
    throughput_mbps: f64,
}

// 基础功能测试用例 - 必须与Odin版本完全一致
const BASIC_CASES: &[BenchmarkCase] = &[
    // 字面量匹配
    BenchmarkCase {
        name: "literal_simple".to_string(),
        pattern: "hello".to_string(),
        input: "hello world".to_string(),
        description: "Simple literal".to_string(),
        category: "literal".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "literal_not_found".to_string(),
        pattern: "xyz".to_string(),
        input: "hello world".to_string(),
        description: "Non-matching literal".to_string(),
        category: "literal".to_string(),
        expected_match: false,
    },
    BenchmarkCase {
        name: "literal_empty".to_string(),
        pattern: "".to_string(),
        input: "hello".to_string(),
        description: "Empty pattern".to_string(),
        category: "literal".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "literal_empty_input".to_string(),
        pattern: "hello".to_string(),
        input: "".to_string(),
        description: "Empty input".to_string(),
        category: "literal".to_string(),
        expected_match: false,
    },

    // 字符类
    BenchmarkCase {
        name: "char_class_basic".to_string(),
        pattern: "[abc]".to_string(),
        input: "b".to_string(),
        description: "Basic character class".to_string(),
        category: "char_class".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "char_class_range".to_string(),
        pattern: "[a-z]".to_string(),
        input: "m".to_string(),
        description: "Range character class".to_string(),
        category: "char_class".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "char_class_multiple".to_string(),
        pattern: "[a-zA-Z0-9]".to_string(),
        input: "X".to_string(),
        description: "Multiple ranges".to_string(),
        category: "char_class".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "char_class_negated".to_string(),
        pattern: "[^0-9]".to_string(),
        input: "a".to_string(),
        description: "Negated class".to_string(),
        category: "char_class".to_string(),
        expected_match: true,
    },

    // POSIX字符类
    BenchmarkCase {
        name: "posix_digit".to_string(),
        pattern: r"\d".to_string(),
        input: "5".to_string(),
        description: "Digit class".to_string(),
        category: "posix".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "posix_nondigit".to_string(),
        pattern: r"\D".to_string(),
        input: "a".to_string(),
        description: "Non-digit class".to_string(),
        category: "posix".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "posix_space".to_string(),
        pattern: r"\s".to_string(),
        input: " ".to_string(),
        description: "Space class".to_string(),
        category: "posix".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "posix_word".to_string(),
        pattern: r"\w".to_string(),
        input: "a".to_string(),
        description: "Word character".to_string(),
        category: "posix".to_string(),
        expected_match: true,
    },

    // 量词
    BenchmarkCase {
        name: "quantifier_star_zero".to_string(),
        pattern: "a*".to_string(),
        input: "bbb".to_string(),
        description: "Star zero occurrences".to_string(),
        category: "quantifier".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "quantifier_star_many".to_string(),
        pattern: "a*".to_string(),
        input: "aaaaa".to_string(),
        description: "Star many occurrences".to_string(),
        category: "quantifier".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "quantifier_plus_one".to_string(),
        pattern: "a+".to_string(),
        input: "a".to_string(),
        description: "Plus one occurrence".to_string(),
        category: "quantifier".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "quantifier_plus_many".to_string(),
        pattern: "a+".to_string(),
        input: "aaaaa".to_string(),
        description: "Plus many occurrences".to_string(),
        category: "quantifier".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "quantifier_quest_present".to_string(),
        pattern: "a?".to_string(),
        input: "a".to_string(),
        description: "Question mark present".to_string(),
        category: "quantifier".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "quantifier_quest_absent".to_string(),
        pattern: "a?".to_string(),
        input: "b".to_string(),
        description: "Question mark absent".to_string(),
        category: "quantifier".to_string(),
        expected_match: true,
    },

    // 精确量词
    BenchmarkCase {
        name: "quantifier_exact".to_string(),
        pattern: "a{3}".to_string(),
        input: "aaa".to_string(),
        description: "Exact count".to_string(),
        category: "quantifier".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "quantifier_min".to_string(),
        pattern: "a{2,}".to_string(),
        input: "aaaaa".to_string(),
        description: "Minimum count".to_string(),
        category: "quantifier".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "quantifier_range".to_string(),
        pattern: "a{2,4}".to_string(),
        input: "aaa".to_string(),
        description: "Range count".to_string(),
        category: "quantifier".to_string(),
        expected_match: true,
    },

    // 锚点
    BenchmarkCase {
        name: "anchor_begin".to_string(),
        pattern: "^hello".to_string(),
        input: "hello world".to_string(),
        description: "Begin anchor".to_string(),
        category: "anchor".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "anchor_end".to_string(),
        pattern: "world$".to_string(),
        input: "hello world".to_string(),
        description: "End anchor".to_string(),
        category: "anchor".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "anchor_both".to_string(),
        pattern: "^hello world$".to_string(),
        input: "hello world".to_string(),
        description: "Both anchors".to_string(),
        category: "anchor".to_string(),
        expected_match: true,
    },

    // 选择
    BenchmarkCase {
        name: "alternation_simple".to_string(),
        pattern: "cat|dog".to_string(),
        input: "dog".to_string(),
        description: "Simple alternation".to_string(),
        category: "alternation".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "alternation_multiple".to_string(),
        pattern: "cat|dog|bird".to_string(),
        input: "bird".to_string(),
        description: "Multiple alternation".to_string(),
        category: "alternation".to_string(),
        expected_match: true,
    },

    // 连接
    BenchmarkCase {
        name: "concatenation_simple".to_string(),
        pattern: "ab".to_string(),
        input: "ab".to_string(),
        description: "Simple concatenation".to_string(),
        category: "concatenation".to_string(),
        expected_match: true,
    },
    BenchmarkCase {
        name: "concatenation_long".to_string(),
        pattern: "abcdefghij".to_string(),
        input: "abcdefghij".to_string(),
        description: "Long concatenation".to_string(),
        category: "concatenation".to_string(),
        expected_match: true,
    },
];

// 性能关键测试用例
fn get_performance_cases() -> Vec<BenchmarkCase> {
    vec![
        // 长字符串匹配
        BenchmarkCase {
            name: "perf_long_literal".to_string(),
            pattern: "needle".to_string(),
            input: "a".repeat(1000) + "needle" + &"b".repeat(1000),
            description: "Long string literal".to_string(),
            category: "performance".to_string(),
            expected_match: true,
        },
        BenchmarkCase {
            name: "perf_long_class".to_string(),
            pattern: "[a-z]".to_string(),
            input: "x".repeat(10000),
            description: "Long char class match".to_string(),
            category: "performance".to_string(),
            expected_match: true,
        },
        BenchmarkCase {
            name: "perf_repeated_star".to_string(),
            pattern: "a*b".to_string(),
            input: "a".repeat(1000) + "b",
            description: "Repeated star pattern".to_string(),
            category: "performance".to_string(),
            expected_match: true,
        },
        BenchmarkCase {
            name: "perf_repeated_plus".to_string(),
            pattern: "a+b".to_string(),
            input: "a".repeat(1000) + "b",
            description: "Repeated plus pattern".to_string(),
            category: "performance".to_string(),
            expected_match: true,
        },
        BenchmarkCase {
            name: "perf_nested_groups".to_string(),
            pattern: "(a(b(c)*)*)".to_string(),
            input: "abc".repeat(100),
            description: "Nested groups".to_string(),
            category: "performance".to_string(),
            expected_match: true,
        },
    ]
}

// 实际应用模式
fn get_real_world_cases() -> Vec<BenchmarkCase> {
    vec![
        BenchmarkCase {
            name: "email_simple".to_string(),
            pattern: r"[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}".to_string(),
            input: "user@example.com".to_string(),
            description: "Simple email".to_string(),
            category: "realworld".to_string(),
            expected_match: true,
        },
        BenchmarkCase {
            name: "email_complex".to_string(),
            pattern: r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}".to_string(),
            input: "user.name+tag@example.co.uk".to_string(),
            description: "Complex email".to_string(),
            category: "realworld".to_string(),
            expected_match: true,
        },
        BenchmarkCase {
            name: "url_http".to_string(),
            pattern: r"https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?".to_string(),
            input: "https://example.com/path".to_string(),
            description: "HTTP URL".to_string(),
            category: "realworld".to_string(),
            expected_match: true,
        },
        BenchmarkCase {
            name: "ipv4_full".to_string(),
            pattern: r"(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9])".to_string(),
            input: "192.168.1.1".to_string(),
            description: "Full IPv4".to_string(),
            category: "realworld".to_string(),
            expected_match: true,
        },
        BenchmarkCase {
            name: "phone_us".to_string(),
            pattern: r"\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})".to_string(),
            input: "(555) 123-4567".to_string(),
            description: "US Phone".to_string(),
            category: "realworld".to_string(),
            expected_match: true,
        },
        BenchmarkCase {
            name: "date_iso".to_string(),
            pattern: r"[0-9]{4}-[0-9]{2}-[0-9]{2}".to_string(),
            input: "2023-12-25".to_string(),
            description: "ISO date".to_string(),
            category: "realworld".to_string(),
            expected_match: true,
        },
    ]
}

// 线性时间复杂度测试
fn get_linearity_cases() -> Vec<BenchmarkCase> {
    let sizes = vec![100, 1000, 10000, 100000];
    sizes.into_iter().map(|size| {
        BenchmarkCase {
            name: format!("linear_{}", size),
            pattern: "needle".to_string(),
            input: "x".repeat(size) + "needle",
            description: format!("Linear test {} chars", size),
            category: "linearity".to_string(),
            expected_match: true,
        }
    }).collect()
}

// 运行单个基准测试
fn run_benchmark(test_case: &BenchmarkCase) -> BenchmarkResult {
    let mut result = BenchmarkResult {
        case_name: test_case.name.clone(),
        category: test_case.category.clone(),
        compile_time_ns: 0,
        match_time_ns: 0,
        matched: false,
        error: None,
        throughput_mbps: 0.0,
    };

    // 测量编译时间
    let compile_start = Instant::now();
    let regex_result = Regex::new(&test_case.pattern);
    let compile_end = Instant::now();

    result.compile_time_ns = compile_start.elapsed().as_nanos();

    match regex_result {
        Ok(regex) => {
            // 预热
            for _ in 0..10 {
                let _ = regex.is_match(&test_case.input);
            }

            // 测量匹配时间（多次运行取平均）
            let iterations = if test_case.category == "performance" { 100 } else { 1000 };
            let match_start = Instant::now();
            let mut matched_count = 0;

            for _ in 0..iterations {
                if regex.is_match(&test_case.input) {
                    matched_count += 1;
                }
            }
            let match_end = Instant::now();

            let total_time = match_start.elapsed().as_nanos();
            result.match_time_ns = total_time / iterations as u128;
            result.matched = matched_count > 0;

            // 计算吞吐量
            if result.match_time_ns > 0 {
                let bytes_per_sec = (test_case.input.len() as f64) * 1_000_000_000.0 / (result.match_time_ns as f64);
                result.throughput_mbps = bytes_per_sec / (1024.0 * 1024.0);
            }
        }
        Err(e) => {
            result.error = Some(e.to_string());
        }
    }

    result
}

// 格式化时间
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

// 运行测试套件
fn run_test_suite(name: &str, cases: &[BenchmarkCase]) -> (Vec<BenchmarkResult>, HashMap<String, usize>) {
    println!("\n=== {} ===", name);
    println!("Running {} test cases...\n", cases.len());

    let mut results = Vec::new();
    let mut category_stats = HashMap::new();
    let mut successful = 0;
    let mut failed = 0;

    for test_case in cases {
        category_stats.entry(test_case.category.clone())
            .and_modify(|e| *e += 1)
            .or_insert(1);

        println!("Test: {}", test_case.name);
        println!("Pattern: {:?}", test_case.pattern);
        println!("Input: {:?} ({} chars)", test_case.input, test_case.input.len());
        println!("Category: {}", test_case.category);

        let result = run_benchmark(test_case);

        println!("Compile: {}", format_time(result.compile_time_ns));
        println!("Match:   {}", format_time(result.match_time_ns));
        println!("Result:  {}", result.matched);
        println!("Throughput: {:.2} MB/s", result.throughput_mbps);

        if let Some(error) = &result.error {
            println!("ERROR:   {}", error);
            failed += 1;
        } else {
            successful += 1;
            if result.matched != test_case.expected_match {
                println!("WARNING: Expected {}, got {}", test_case.expected_match, result.matched);
            }
        }

        println!("{}", "-".repeat(60));
        results.push(result);
    }

    println!("\n=== {} SUMMARY ===", name);
    println!("Total cases: {}", cases.len());
    println!("Successful:  {}", successful);
    println!("Failed:      {}", failed);

    println!("\nCategory breakdown:");
    for (category, count) in &category_stats {
        println!("  {}: {} cases", category, count);
    }

    (results, category_stats)
}

// 分析线性时间复杂度
fn analyze_linearity(results: &[BenchmarkResult]) {
    println!("\n=== LINEAR TIME COMPLEXITY ANALYSIS ===");

    let mut linear_results: Vec<_> = results.iter()
        .filter(|r| r.case_name.starts_with("linear_"))
        .collect();

    linear_results.sort_by_key(|r| r.case_name.parse::<usize>().unwrap_or(0));

    for (i, result) in linear_results.iter().enumerate() {
        let size: usize = result.case_name.split('_').nth(1).unwrap_or("0").parse().unwrap_or(0);
        println!("Input size: {}, Time: {}, Throughput: {:.2} MB/s",
            size, format_time(result.match_time_ns), result.throughput_mbps);

        if i > 0 {
            let prev_result = &linear_results[i-1];
            let prev_size: usize = prev_result.case_name.split('_').nth(1).unwrap_or("0").parse().unwrap_or(0);

            let growth_factor = result.match_time_ns as f64 / prev_result.match_time_ns as f64;
            let size_factor = size as f64 / prev_size as f64;

            println!("  Size {}→{}: Time grew by {:.2}x, Size grew by {:.2}x",
                prev_size, size, growth_factor, size_factor);

            if growth_factor > size_factor * 1.5 {
                println!("  ⚠️  Possible super-linear growth detected!");
            } else {
                println!("  ✅ Linear growth maintained");
            }
        }
    }
}

// 保存结果到文件
fn save_results(results: &[BenchmarkResult], filename: &str) -> Result<(), Box<dyn std::error::Error>> {
    let json = serde_json::to_string_pretty(results)?;
    let mut file = File::create(filename)?;
    file.write_all(json.as_bytes())?;
    println!("\nResults saved to: {}", filename);
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("=== Google RE2 Performance Comparison (Rust) ===");
    println!("Comprehensive benchmark suite for Odin RE2 comparison");
    println!("Date: {:?}", chrono::Utc::now());

    let mut all_results = Vec::new();

    // 运行基础功能测试
    let (basic_results, _) = run_test_suite("Basic Functionality", BASIC_CASES);
    all_results.extend(basic_results);

    // 运行性能测试
    let perf_cases = get_performance_cases();
    let (perf_results, _) = run_test_suite("Performance Critical", &perf_cases);
    all_results.extend(perf_results);

    // 运行实际应用测试
    let real_cases = get_real_world_cases();
    let (real_results, _) = run_test_suite("Real-World Patterns", &real_cases);
    all_results.extend(real_results);

    // 运行线性时间复杂度测试
    let linear_cases = get_linearity_cases();
    let (linear_results, _) = run_test_suite("Linearity Tests", &linear_cases);
    analyze_linearity(&linear_results);
    all_results.extend(linear_results);

    // 计算总体统计
    println!("\n=== OVERALL STATISTICS ===");
    let successful = all_results.iter().filter(|r| r.error.is_none()).count();
    let total = all_results.len();

    if successful > 0 {
        let total_compile: u128 = all_results.iter()
            .filter(|r| r.error.is_none())
            .map(|r| r.compile_time_ns)
            .sum();
        let total_match: u128 = all_results.iter()
            .filter(|r| r.error.is_none())
            .map(|r| r.match_time_ns)
            .sum();

        let avg_compile = total_compile / successful as u128;
        let avg_match = total_match / successful as u128;

        println!("Total cases: {}", total);
        println!("Successful:  {}", successful);
        println!("Failed:      {}", total - successful);
        println!("Avg compile: {}", format_time(avg_compile));
        println!("Avg match:   {}", format_time(avg_match));

        if total_match > 0 {
            let ratio = total_compile as f64 / total_match as f64;
            println!("Compile/Match ratio: {:.2}x", ratio);
        }
    }

    // 保存结果
    save_results(&all_results, "re2_rust_results.json")?;

    println!("\n=== COMPARISON READY ===");
    println!("Compare these results with Odin RE2 benchmark results");
    println!("to analyze performance differences and functionality gaps.");

    Ok(())
}