use regex::Regex;
use std::cmp::min;
use std::env;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::time::Instant;

const DEFAULT_FUNC_CASES: &str = "benchmark/data/functionality_cases.txt";
const DEFAULT_FUNC_OUTPUT: &str = "benchmark/results/functional_rust.tsv";
const DEFAULT_PERF_CASES: &str = "benchmark/data/performance_scenarios.txt";
const DEFAULT_PERF_OUTPUT: &str = "benchmark/results/performance_rust.tsv";

#[derive(Debug, Clone)]
struct TestCase {
    name: String,
    pattern: String,
    text: String,
    should_compile: bool,
    should_match: bool,
    verify_full_match: bool,
    expected_match: String,
    description: String,
}

impl Default for TestCase {
    fn default() -> Self {
        Self {
            name: String::new(),
            pattern: String::new(),
            text: String::new(),
            should_compile: true,
            should_match: false,
            verify_full_match: false,
            expected_match: String::new(),
            description: String::new(),
        }
    }
}

#[derive(Debug)]
struct CaseResult {
    test_case: TestCase,
    compile_ok: bool,
    actual_match: bool,
    match_verified: bool,
    compile_ns: i64,
    match_ns: i64,
    status: &'static str,
    notes: String,
}

#[derive(Debug, Clone)]
struct PerfScenario {
    name: String,
    pattern: String,
    text_strategy: String,
    text_base: String,
    text_size: usize,
    iterations: usize,
    should_match: bool,
    insert_interval: usize,
    anchor_prefix: String,
    anchor_suffix: String,
    description: String,
}

impl Default for PerfScenario {
    fn default() -> Self {
        Self {
            name: String::new(),
            pattern: String::new(),
            text_strategy: "repeat".to_string(),
            text_base: String::new(),
            text_size: 0,
            iterations: 1,
            should_match: true,
            insert_interval: 512,
            anchor_prefix: String::new(),
            anchor_suffix: String::new(),
            description: String::new(),
        }
    }
}

#[derive(Debug)]
struct PerfResult {
    scenario: PerfScenario,
    compile_ns: i64,
    match_total_ns: i64,
    match_avg_ns: i64,
    throughput_mb_s: f64,
    matched: bool,
    status: &'static str,
    notes: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Mode {
    Functionality,
    Performance,
}

#[derive(Debug)]
struct Config {
    mode: Mode,
    cases_path: PathBuf,
    output_path: PathBuf,
    verbose: bool,
}

fn main() {
    if let Err(err) = run() {
        eprintln!("{err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let config = parse_args()?;

    match config.mode {
        Mode::Functionality => run_functionality_mode(&config),
        Mode::Performance => run_performance_mode(&config),
    }
}

fn run_functionality_mode(config: &Config) -> Result<(), String> {
    let content = fs::read_to_string(&config.cases_path)
        .map_err(|e| format!("failed to read {:?}: {}", config.cases_path, e))?;

    let test_cases = parse_test_cases(&content)?;
    if test_cases.is_empty() {
        return Err("no test cases found".into());
    }

    let results = execute_cases(&test_cases, config.verbose);
    write_results(&config.output_path, &results)
        .map_err(|e| format!("failed to write results: {}", e))?;

    let passed = results.iter().filter(|r| r.status == "PASS").count();
    println!(
        "=== Rust regex functionality comparison ===\nCases: {}, Passed: {}, Failed: {}\nResults saved to {:?}",
        results.len(),
        passed,
        results.len() - passed,
        config.output_path
    );

    Ok(())
}

fn run_performance_mode(config: &Config) -> Result<(), String> {
    let content = fs::read_to_string(&config.cases_path)
        .map_err(|e| format!("failed to read {:?}: {}", config.cases_path, e))?;

    let scenarios = parse_performance_scenarios(&content)?;
    if scenarios.is_empty() {
        return Err("no performance scenarios found".into());
    }

    let results = execute_performance(&scenarios, config.verbose);
    write_performance_results(&config.output_path, &results)
        .map_err(|e| format!("failed to write results: {}", e))?;

    let passed = results.iter().filter(|r| r.status == "PASS").count();
    println!(
        "=== Rust regex performance comparison ===\nScenarios: {}, Passed: {}, Failed: {}\nResults saved to {:?}",
        results.len(),
        passed,
        results.len() - passed,
        config.output_path
    );

    Ok(())
}

fn parse_args() -> Result<Config, String> {
    let mut args = env::args().skip(1);

    let mut mode = Mode::Functionality;
    let mut cases_path = PathBuf::from(DEFAULT_FUNC_CASES);
    let mut output_path = PathBuf::from(DEFAULT_FUNC_OUTPUT);
    let mut cases_override = false;
    let mut output_override = false;
    let mut verbose = false;

    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--mode" => {
                let value = args
                    .next()
                    .ok_or_else(|| "--mode requires a value".to_string())?;
                mode = match value.as_str() {
                    "functionality" => Mode::Functionality,
                    "performance" => Mode::Performance,
                    other => {
                        return Err(format!("unsupported mode: {}", other));
                    }
                };
            }
            "--cases" => {
                let value = args
                    .next()
                    .ok_or_else(|| "--cases requires a value".to_string())?;
                cases_path = PathBuf::from(value);
                cases_override = true;
            }
            "--output" => {
                let value = args
                    .next()
                    .ok_or_else(|| "--output requires a value".to_string())?;
                output_path = PathBuf::from(value);
                output_override = true;
            }
            "--verbose" | "-v" => verbose = true,
            other => return Err(format!("unknown argument: {}", other)),
        }
    }

    if mode == Mode::Performance {
        if !cases_override {
            cases_path = PathBuf::from(DEFAULT_PERF_CASES);
        }
        if !output_override {
            output_path = PathBuf::from(DEFAULT_PERF_OUTPUT);
        }
    }

    Ok(Config {
        mode,
        cases_path,
        output_path,
        verbose,
    })
}

fn parse_test_cases(content: &str) -> Result<Vec<TestCase>, String> {
    let mut cases = Vec::new();
    let mut current = TestCase::default();
    let mut have_data = false;

    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }
        if trimmed == "---" {
            if have_data {
                cases.push(current);
                current = TestCase::default();
                have_data = false;
            }
            continue;
        }

        let (key, value) = line
            .split_once('=')
            .ok_or_else(|| format!("invalid line: {}", line))?;
        let key = key.trim();
        let value = unescape(value.trim());

        match key {
            "name" => {
                current.name = value;
                have_data = true;
            }
            "pattern" => current.pattern = value,
            "text" => current.text = value,
            "should_compile" => current.should_compile = parse_bool(&value, true),
            "should_match" => current.should_match = parse_bool(&value, false),
            "verify_full_match" => current.verify_full_match = parse_bool(&value, false),
            "expected" => current.expected_match = value,
            "description" => current.description = value,
            other => return Err(format!("unknown key: {}", other)),
        }
    }

    if have_data {
        cases.push(current);
    }

    Ok(cases)
}

fn parse_performance_scenarios(content: &str) -> Result<Vec<PerfScenario>, String> {
    let mut scenarios = Vec::new();
    let mut current = PerfScenario::default();
    let mut have_data = false;

    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() {
            continue;
        }
        if trimmed == "---" {
            if have_data {
                scenarios.push(current);
                current = PerfScenario::default();
                have_data = false;
            }
            continue;
        }

        let (key, value_raw) = line
            .split_once('=')
            .ok_or_else(|| format!("invalid line: {}", line))?;
        let key = key.trim();
        let value = unescape(value_raw.trim());

        match key {
            "name" => {
                current.name = value;
                have_data = true;
            }
            "pattern" => current.pattern = value,
            "text_strategy" => current.text_strategy = value,
            "text_base" => current.text_base = value,
            "text_size" => {
                let size = parse_usize(&value)?;
                current.text_size = size;
            }
            "iterations" => {
                let iters = parse_usize(&value)?;
                current.iterations = iters;
            }
            "should_match" => current.should_match = parse_bool(&value, true),
            "insert_interval" => {
                let interval = parse_usize(&value)?;
                current.insert_interval = interval;
            }
            "anchor_prefix" => current.anchor_prefix = value,
            "anchor_suffix" => current.anchor_suffix = value,
            "description" => current.description = value,
            other => return Err(format!("unknown key: {}", other)),
        }
    }

    if have_data {
        scenarios.push(current);
    }

    Ok(scenarios)
}

fn parse_usize(value: &str) -> Result<usize, String> {
    value
        .parse::<usize>()
        .map_err(|_| format!("invalid integer: {}", value))
}

fn parse_bool(value: &str, default: bool) -> bool {
    match value {
        "" => default,
        "true" | "TRUE" | "True" | "1" | "yes" | "YES" | "Yes" => true,
        "false" | "FALSE" | "False" | "0" | "no" | "NO" | "No" => false,
        _ => default,
    }
}

fn unescape(value: &str) -> String {
    let mut result = String::with_capacity(value.len());
    let mut chars = value.chars().peekable();
    while let Some(ch) = chars.next() {
        if ch == '\\' {
            if let Some(next) = chars.next() {
                match next {
                    'n' => result.push('\n'),
                    't' => result.push('\t'),
                    'r' => result.push('\r'),
                    '\\' => result.push('\\'),
                    other => result.push(other),
                }
            }
        } else {
            result.push(ch);
        }
    }
    result
}

fn execute_cases(cases: &[TestCase], verbose: bool) -> Vec<CaseResult> {
    let mut results = Vec::with_capacity(cases.len());

    for case in cases {
        let compile_start = Instant::now();
        let compiled = Regex::new(&case.pattern);
        let compile_ns = compile_start.elapsed().as_nanos() as i64;

        let mut result = CaseResult {
            test_case: case.clone(),
            compile_ok: false,
            actual_match: false,
            match_verified: false,
            compile_ns,
            match_ns: 0,
            status: "FAIL",
            notes: String::new(),
        };

        match compiled {
            Ok(regex) => {
                result.compile_ok = true;

                if !case.should_compile {
                    result.status = "FAIL";
                    result.notes = "expected compile failure but succeeded".into();
                    results.push(result);
                    continue;
                }

                let match_start = Instant::now();
                let found = regex.find(&case.text);
                let match_ns = match_start.elapsed().as_nanos() as i64;
                result.match_ns = match_ns;

                if let Some(mat) = found {
                    result.actual_match = true;
                    if case.verify_full_match {
                        let matched_str = mat.as_str().to_string();
                        if matched_str == case.expected_match {
                            result.match_verified = true;
                        } else {
                            result.notes = format!(
                                "expected_full_match:{}, got:{}",
                                case.expected_match, matched_str
                            );
                        }
                    }
                } else {
                    result.actual_match = false;
                    if case.verify_full_match && case.expected_match.is_empty() && case.should_match {
                        result.match_verified = true;
                    }
                }

                let expected_match = case.should_match;
                let actual_match = result.actual_match;

                if expected_match == actual_match {
                    if case.verify_full_match {
                        if result.match_verified {
                            result.status = "PASS";
                        } else if result.notes.is_empty() {
                            result.status = "FAIL";
                            result.notes = "full match verification failed".into();
                        } else {
                            result.status = "FAIL";
                        }
                    } else {
                        result.status = "PASS";
                    }
                } else {
                    result.status = "FAIL";
                    if actual_match {
                        result.notes = "unexpected match".into();
                    } else {
                        result.notes = "missing expected match".into();
                    }
                }
            }
            Err(err) => {
                result.compile_ok = false;
                result.notes = format!("compile_error:{}", err);
                if case.should_compile {
                    result.status = "FAIL";
                } else {
                    result.status = "PASS";
                }
            }
        }

        if verbose {
            println!("[{:5}] {} :: {}", result.status, case.name, result.notes);
        }

        results.push(result);
    }

    results
}

fn execute_performance(scenarios: &[PerfScenario], verbose: bool) -> Vec<PerfResult> {
    let mut results = Vec::with_capacity(scenarios.len());

    for scenario in scenarios {
        let mut result = PerfResult {
            scenario: scenario.clone(),
            compile_ns: 0,
            match_total_ns: 0,
            match_avg_ns: 0,
            throughput_mb_s: 0.0,
            matched: false,
            status: "FAIL",
            notes: String::new(),
        };

        if scenario.text_size == 0 {
            result.notes = "text_size must be > 0".into();
            results.push(result);
            continue;
        }
        if scenario.iterations == 0 {
            result.notes = "iterations must be > 0".into();
            results.push(result);
            continue;
        }

        let text = match generate_text_buffer(&scenario) {
            Ok(text) => text,
            Err(err) => {
                result.notes = err;
                results.push(result);
                continue;
            }
        };

        let compile_start = Instant::now();
        let compiled = Regex::new(&scenario.pattern);
        result.compile_ns = compile_start.elapsed().as_nanos() as i64;

        let regex = match compiled {
            Ok(regex) => regex,
            Err(err) => {
                result.notes = format!("compile_error:{}", err);
                results.push(result);
                continue;
            }
        };

        let mut total_match_ns: i64 = 0;
        let mut matched_any = false;

        for _ in 0..scenario.iterations {
            let match_start = Instant::now();
            let did_match = regex.is_match(&text);
            let match_ns = match_start.elapsed().as_nanos() as i64;
            total_match_ns += match_ns;
            if did_match {
                matched_any = true;
            }
        }

        result.match_total_ns = total_match_ns;
        if scenario.iterations > 0 {
            result.match_avg_ns = total_match_ns / scenario.iterations as i64;
        }

        if total_match_ns > 0 {
            let total_bytes =
                (scenario.text_size as f64) * (scenario.iterations as f64);
            let seconds = total_match_ns as f64 / 1_000_000_000.0;
            if seconds > 0.0 {
                result.throughput_mb_s = (total_bytes / 1_048_576.0) / seconds;
            }
        }

        result.matched = matched_any;

        if scenario.should_match {
            if matched_any {
                result.status = "PASS";
            } else {
                result.status = "FAIL";
                result.notes = "expected match missing".into();
            }
        } else if matched_any {
            result.status = "FAIL";
            result.notes = "unexpected match".into();
        } else {
            result.status = "PASS";
        }

        if verbose {
            println!(
                "[{:5}] {} :: compile={}ns match_avg={}ns throughput={:.2} MB/s {}",
                result.status,
                scenario.name,
                result.compile_ns,
                result.match_avg_ns,
                result.throughput_mb_s,
                result.notes
            );
        }

        results.push(result);
    }

    results
}

fn write_results(path: &Path, results: &[CaseResult]) -> Result<(), std::io::Error> {
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent)?;
        }
    }

    let mut file = fs::File::create(path)?;
    writeln!(
        file,
        "name\tshould_compile\tcompile_ok\tshould_match\tactual_match\tverify_full_match\tmatch_verified\tcompile_ns\tmatch_ns\tstatus\tnotes"
    )?;

    for res in results {
        writeln!(
            file,
            "{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
            res.test_case.name,
            res.test_case.should_compile,
            res.compile_ok,
            res.test_case.should_match,
            res.actual_match,
            res.test_case.verify_full_match,
            res.match_verified,
            res.compile_ns,
            res.match_ns,
            res.status,
            sanitize_notes(&res.notes)
        )?;
    }

    Ok(())
}

fn write_performance_results(path: &Path, results: &[PerfResult]) -> Result<(), std::io::Error> {
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent)?;
        }
    }

    let mut file = fs::File::create(path)?;
    writeln!(
        file,
        "name\tpattern\ttext_size\titerations\tcompile_ns\tmatch_total_ns\tmatch_avg_ns\tthroughput_mb_s\tmatched\tstatus\tnotes"
    )?;

    for res in results {
        writeln!(
            file,
            "{}\t{}\t{}\t{}\t{}\t{}\t{}\t{:.4}\t{}\t{}\t{}",
            res.scenario.name,
            res.scenario.pattern,
            res.scenario.text_size,
            res.scenario.iterations,
            res.compile_ns,
            res.match_total_ns,
            res.match_avg_ns,
            res.throughput_mb_s,
            res.matched,
            res.status,
            sanitize_notes(&res.notes)
        )?;
    }

    Ok(())
}

fn sanitize_notes(notes: &str) -> String {
    notes
        .chars()
        .map(|c| match c {
            '\t' | '\r' | '\n' => ' ',
            other => other,
        })
        .collect()
}

fn generate_text_buffer(scenario: &PerfScenario) -> Result<String, String> {
    let strategy = if scenario.text_strategy.is_empty() {
        "repeat".to_string()
    } else {
        scenario.text_strategy.to_ascii_lowercase()
    };

    match strategy.as_str() {
        "repeat" => generate_repeat_text(&scenario.text_base, scenario.text_size),
        "inject" => generate_inject_text(
            &scenario.text_base,
            scenario.text_size,
            &scenario.pattern,
            scenario.insert_interval,
        ),
        "anchor" => generate_anchor_text(scenario),
        other => Err(format!("unknown text_strategy: {}", other)),
    }
}

fn generate_repeat_text(base: &str, size: usize) -> Result<String, String> {
    if base.is_empty() {
        return Err("text_base cannot be empty for repeat strategy".into());
    }

    let mut result = String::with_capacity(size);
    while result.len() < size {
        let remaining = size - result.len();
        if remaining >= base.len() {
            result.push_str(base);
        } else {
            result.push_str(&base[..remaining]);
        }
    }
    if result.len() > size {
        result.truncate(size);
    }
    Ok(result)
}

fn generate_inject_text(
    base: &str,
    size: usize,
    pattern: &str,
    interval: usize,
) -> Result<String, String> {
    let text = generate_repeat_text(base, size)?;
    let interval = if interval == 0 { 256 } else { interval };

    let mut result = String::with_capacity(size + pattern.len() * (size / interval + 1));
    let mut position = 0;

    while position < text.len() {
        let end = min(position + interval, text.len());
        result.push_str(&text[position..end]);
        position = end;
        if position < text.len() {
            result.push_str(pattern);
        }
    }

    if result.len() > size {
        result.truncate(size);
    }
    Ok(result)
}

fn generate_anchor_text(scenario: &PerfScenario) -> Result<String, String> {
    if scenario.anchor_prefix.is_empty() || scenario.anchor_suffix.is_empty() {
        return Err("anchor strategy requires anchor_prefix and anchor_suffix".into());
    }
    let prefix_len = scenario.anchor_prefix.len();
    let suffix_len = scenario.anchor_suffix.len();
    if scenario.text_size < prefix_len + suffix_len {
        return Err("text_size too small for anchor strategy".into());
    }

    let filler_size = scenario.text_size - prefix_len - suffix_len;
    let filler = generate_repeat_text(&scenario.text_base, filler_size)?;

    let mut result = String::with_capacity(scenario.text_size);
    result.push_str(&scenario.anchor_prefix);
    result.push_str(&filler);
    result.push_str(&scenario.anchor_suffix);
    Ok(result)
}
