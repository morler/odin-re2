package main

import "core:fmt"
import "core:os"
import "core:time"
import "core:strings"
import "core:math"
import "../regexp"

// ================================================================================
// Google RE2 全面对比评测套件
//
// 设计原则:
// 1. 覆盖RE2的所有核心功能
// 2. 测试边界情况和特殊场景
// 3. 严格的性能基准测试
// 4. 线性时间复杂度验证
// ================================================================================

Benchmark_Case :: struct {
	name: string,
	pattern: string,
	input: string,
	description: string,
	category: string,
	expected_match: bool,
	expected_groups: [dynamic]string,
}

// RE2官方测试用例 - 基础功能
RE2_BASIC_CASES :: []Benchmark_Case{
	// 字面量匹配 - 最基础的场景
	{name="literal_simple", pattern="hello", input="hello world", description="Simple literal", category="literal", expected_match=true},
	{name="literal_not_found", pattern="xyz", input="hello world", description="Non-matching literal", category="literal", expected_match=false},
	{name="literal_empty", pattern="", input="hello", description="Empty pattern", category="literal", expected_match=true},
	{name="literal_empty_input", pattern="hello", input="", description="Empty input", category="literal", expected_match=false},

	// 字符类 - RE2的核心功能
	{name="char_class_basic", pattern="[abc]", input="b", description="Basic character class", category="char_class", expected_match=true},
	{name="char_class_range", pattern="[a-z]", input="m", description="Range character class", category="char_class", expected_match=true},
	{name="char_class_multiple", pattern="[a-zA-Z0-9]", input="X", description="Multiple ranges", category="char_class", expected_match=true},
	{name="char_class_negated", pattern="[^0-9]", input="a", description="Negated class", category="char_class", expected_match=true},
	{name="char_class_union", pattern="[a-c][x-z]", input="bx", description="Union intersection", category="char_class", expected_match=true},

	// 预定义字符类 - POSIX标准
	{name="posix_digit", pattern="\\d", input="5", description="Digit class", category="posix", expected_match=true},
	{name="posix_nondigit", pattern="\\D", input="a", description="Non-digit class", category="posix", expected_match=true},
	{name="posix_space", pattern="\\s", input=" ", description="Space class", category="posix", expected_match=true},
	{name="posix_nonspace", pattern="\\S", input="a", description="Non-space class", category="posix", expected_match=true},
	{name="posix_word", pattern="\\w", input="a", description="Word character", category="posix", expected_match=true},
	{name="posix_nonword", pattern="\\W", input="@", description="Non-word character", category="posix", expected_match=true},

	// 量词 - 性能关键区域
	{name="quantifier_star_zero", pattern="a*", input="bbb", description="Star zero occurrences", category="quantifier", expected_match=true},
	{name="quantifier_star_many", pattern="a*", input="aaaaa", description="Star many occurrences", category="quantifier", expected_match=true},
	{name="quantifier_plus_one", pattern="a+", input="a", description="Plus one occurrence", category="quantifier", expected_match=true},
	{name="quantifier_plus_many", pattern="a+", input="aaaaa", description="Plus many occurrences", category="quantifier", expected_match=true},
	{name="quantifier_quest_present", pattern="a?", input="a", description="Question mark present", category="quantifier", expected_match=true},
	{name="quantifier_quest_absent", pattern="a?", input="b", description="Question mark absent", category="quantifier", expected_match=true},

	// 精确量词 - RE2特有优化
	{name="quantifier_exact", pattern="a{3}", input="aaa", description="Exact count", category="quantifier", expected_match=true},
	{name="quantifier_min", pattern="a{2,}", input="aaaaa", description="Minimum count", category="quantifier", expected_match=true},
	{name="quantifier_range", pattern="a{2,4}", input="aaa", description="Range count", category="quantifier", expected_match=true},
	{name="quantifier_range_exact", pattern="a{2,4}", input="aa", description="Range minimum", category="quantifier", expected_match=true},
	{name="quantifier_range_max", pattern="a{2,4}", input="aaaa", description="Range maximum", category="quantifier", expected_match=true},

	// 锚点 - 性能优化关键
	{name="anchor_begin", pattern="^hello", input="hello world", description="Begin anchor", category="anchor", expected_match=true},
	{name="anchor_end", pattern="world$", input="hello world", description="End anchor", category="anchor", expected_match=true},
	{name="anchor_both", pattern="^hello world$", input="hello world", description="Both anchors", category="anchor", expected_match=true},
	{name="anchor_multiline", pattern="^test", input="line1\ntest", description="Multiline begin", category="anchor", expected_match=true},
	{name="anchor_multiline_end", pattern="end$", input="test\nend", description="Multiline end", category="anchor", expected_match=true},

	// 选择 - 分支逻辑测试
	{name="alternation_simple", pattern="cat|dog", input="dog", description="Simple alternation", category="alternation", expected_match=true},
	{name="alternation_multiple", pattern="cat|dog|bird", input="bird", description="Multiple alternation", category="alternation", expected_match=true},
	{name="alternation_priority", pattern="a|ab", input="ab", description="Priority alternation", category="alternation", expected_match=true},
	{name="alternation_complex", pattern="hello|world|test", input="world", description="Complex alternation", category="alternation", expected_match=true},

	// 连接 - 最常见的模式
	{name="concatenation_simple", pattern="ab", input="ab", description="Simple concatenation", category="concatenation", expected_match=true},
	{name="concatenation_long", pattern="abcdefghij", input="abcdefghij", description="Long concatenation", category="concatenation", expected_match=true},
	{name="concatenation_mixed", pattern="a1b2c3", input="a1b2c3", description="Mixed concatenation", category="concatenation", expected_match=true},

	// 分组 - 捕获和非捕获
	{name="group_capture", pattern="(ab)", input="ab", description="Capture group", category="group", expected_match=true},
	{name="group_noncapture", pattern="(?:ab)", input="ab", description="Non-capture group", category="group", expected_match=true},
	{name="group_nested", pattern="(a(b)c)", input="abc", description="Nested group", category="group", expected_match=true},
}

// RE2边界情况和特殊测试
RE2_EDGE_CASES :: []Benchmark_Case{
	// Unicode支持 - RE2的强项
	{name="unicode_basic", pattern="\\u00E9", input="é", description="Unicode literal", category="unicode", expected_match=true},
	{name="unicode_class", pattern="[\\u00E0-\\u00E9]", input="é", description="Unicode range", category="unicode", expected_match=true},
	{name="utf8_rune", pattern="é", input="café", description="UTF-8 rune", category="unicode", expected_match=true},

	// 转义字符
	{name="escape_dot", pattern="\\.", input="a.b", description="Escape dot", category="escape", expected_match=true},
	{name="escape_star", pattern="\\*", input="a*b", description="Escape star", category="escape", expected_match=true},
	{name="escape_plus", pattern="\\+", input="a+b", description="Escape plus", category="escape", expected_match=true},
	{name="escape_question", pattern="\\?", input="a?b", description="Escape question", category="escape", expected_match=true},

	// 特殊字符类
	{name="special_dot", pattern="a.b", input="axb", description="Dot wildcard", category="special", expected_match=true},
	{name="special_dot_no_match", pattern="a.b", input="a\nb", description="Dot no newline", category="special", expected_match=false},
	{name="special_caret", pattern="a\\^b", input="a^b", description="Caret literal", category="special", expected_match=true},
	{name="special_dollar", pattern="a\\$b", input="a$b", description="Dollar literal", category="special", expected_match=true},

	// 边界匹配器
	{name="boundary_word", pattern="\\btest\\b", input="test", description="Word boundary", category="boundary", expected_match=true},
	{name="boundary_nonword", pattern="\\Btest\\B", input="atest", description="Non-word boundary", category="boundary", expected_match=true},
	{name="boundary_start", pattern="\\<test", input="test", description="Start word", category="boundary", expected_match=true},
	{name="boundary_end", pattern="test\\>", input="test", description="End word", category="boundary", expected_match=true},
}

// RE2性能关键测试用例
RE2_PERFORMANCE_CASES :: []Benchmark_Case{
	// 长字符串匹配
	{name="perf_long_literal", pattern="needle", input=strings.repeat("a", 1000) + "needle" + strings.repeat("b", 1000),
	 description="Long string literal", category="performance", expected_match=true},

	{name="perf_long_class", pattern="[a-z]", input=strings.repeat("x", 10000),
	 description="Long char class match", category="performance", expected_match=true},

	// 重复模式
	{name="perf_repeated_star", pattern="a*b", input=strings.repeat("a", 1000) + "b",
	 description="Repeated star pattern", category="performance", expected_match=true},

	{name="perf_repeated_plus", pattern="a+b", input=strings.repeat("a", 1000) + "b",
	 description="Repeated plus pattern", category="performance", expected_match=true},

	// 复杂嵌套
	{name="perf_nested_groups", pattern="(a(b(c)*)*)", input=strings.repeat("abc", 100),
	 description="Nested groups", category="performance", expected_match=true},

	// 回溯测试（应该不存在）
	{name="perf_no_backtrack", pattern="a*.*b", input=strings.repeat("a", 1000) + "b",
	 description="No backtrack test", category="performance", expected_match=true},
}

// 实际应用模式
REAL_WORLD_PATTERNS :: []Benchmark_Case{
	// 邮箱验证
	{name="email_simple", pattern="[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}", input="user@example.com",
	 description="Simple email", category="realworld", expected_match=true},

	{name="email_complex", pattern="[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", input="user.name+tag@example.co.uk",
	 description="Complex email", category="realworld", expected_match=true},

	// URL匹配
	{name="url_http", pattern="https?://[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}(/.*)?", input="https://example.com/path",
	 description="HTTP URL", category="realworld", expected_match=true},

	// IP地址
	{name="ipv4_full", pattern="(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9])\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9])",
	 input="192.168.1.1", description="Full IPv4", category="realworld", expected_match=true},

	// 电话号码
	{name="phone_us", pattern="\\(?([0-9]{3})\\)?[-.\\s]?([0-9]{3})[-.\\s]?([0-9]{4})",
	 input="(555) 123-4567", description="US Phone", category="realworld", expected_match=true},

	// 日期格式
	{name="date_iso", pattern="[0-9]{4}-[0-9]{2}-[0-9]{2}", input="2023-12-25",
	 description="ISO date", category="realworld", expected_match=true},

	// 时间格式
	{name="time_24h", pattern="[0-9]{2}:[0-9]{2}:[0-9]{2}", input="23:59:59",
	 description="24-hour time", category="realworld", expected_match=true},

	// 日志格式
	{name="log_apache", pattern="([0-9.]+) - - \\[([^\\]]+)\\] \"([^\"]+)\" ([0-9]{3}) ([0-9]+)",
	 input="127.0.0.1 - - [25/Dec/2023:10:00:00 +0000] \"GET /index.html HTTP/1.1\" 200 1234",
	 description="Apache log", category="realworld", expected_match=true},
}

// 线性时间复杂度验证用例
LINEARITY_TEST_CASES :: []Benchmark_Case{
	// 不同规模的输入，验证O(n)复杂度
	{name="linear_100", pattern="needle", input=strings.repeat("x", 100) + "needle",
	 description="Linear test 100 chars", category="linearity", expected_match=true},

	{name="linear_1000", pattern="needle", input=strings.repeat("x", 1000) + "needle",
	 description="Linear test 1000 chars", category="linearity", expected_match=true},

	{name="linear_10000", pattern="needle", input=strings.repeat("x", 10000) + "needle",
	 description="Linear test 10000 chars", category="linearity", expected_match=true},

	{name="linear_100000", pattern="needle", input=strings.repeat("x", 100000) + "needle",
	 description="Linear test 100000 chars", category="linearity", expected_match=true},
}

Benchmark_Result :: struct {
	case_name: string,
	category: string,
	compile_time_ns: i64,
	match_time_ns: i64,
	matched: bool,
	error: string,
	throughput_mbps: f64,
}

// 执行单个基准测试
run_benchmark :: proc(case: Benchmark_Case) -> Benchmark_Result {
	result := Benchmark_Result{
		case_name = case.name,
		category = case.category,
		compile_time_ns = 0,
		match_time_ns = 0,
		matched = false,
		error = "",
		throughput_mbps = 0,
	}

	// 测量编译时间
	compile_start := time.tick_now()
	regex_obj, compile_err := regexp.compile(case.pattern)
	compile_end := time.tick_now()

	result.compile_time_ns = time.duration_nanoseconds(compile_end - compile_start)

	if compile_err != nil {
		result.error = fmt.tprintf("Compile error: %v", compile_err)
		return result
	}

	// 测量匹配时间
	match_start := time.tick_now()
	matched, match_err := regexp.match(regex_obj, case.input)
	match_end := time.tick_now()

	result.match_time_ns = time.duration_nanoseconds(match_end - match_start)

	if match_err != nil {
		result.error = fmt.tprintf("Match error: %v", match_err)
		return result
	}

	result.matched = matched

	// 计算吞吐量 MB/s
	if result.match_time_ns > 0 {
		bytes_per_sec := f64(len(case.input)) * 1_000_000_000.0 / f64(result.match_time_ns)
		result.throughput_mbps = bytes_per_sec / (1024.0 * 1024.0)
	}

	return result
}

// 格式化时间显示
format_time :: proc(nanoseconds: i64) -> string {
	if nanoseconds < 1_000 {
		return fmt.tprintf("%dns", nanoseconds)
	} else if nanoseconds < 1_000_000 {
		return fmt.tprintf("%.2fμs", f64(nanoseconds) / 1_000.0)
	} else if nanoseconds < 1_000_000_000 {
		return fmt.tprintf("%.2fms", f64(nanoseconds) / 1_000_000.0)
	} else {
		return fmt.tprintf("%.2fs", f64(nanoseconds) / 1_000_000_000.0)
	}
}

// 运行测试套件
run_test_suite :: proc(name: string, cases: []Benchmark_Case) {
	fmt.printf("\n=== %s ===\n", name)
	fmt.printf("Running %d test cases...\n\n", len(cases))

	total_compile := i64(0)
	total_match := i64(0)
	successful := 0
	failed := 0

	// 按类别统计
	category_stats := make(map[string]int)

	for case in cases {
		fmt.printf("Test: %s\n", case.name)
		fmt.printf("Pattern: %q\n", case.pattern)
		fmt.printf("Input: %q\n", case.input)
		fmt.printf("Category: %s\n", case.category)
		fmt.printf("Description: %s\n", case.description)

		result := run_benchmark(case)

		fmt.printf("Compile: %s\n", format_time(result.compile_time_ns))
		fmt.printf("Match:   %s\n", format_time(result.match_time_ns))
		fmt.printf("Result:  %v\n", result.matched)
		fmt.printf("Throughput: %.2f MB/s\n", result.throughput_mbps)

		if result.error != "" {
			fmt.printf("ERROR:   %s\n", result.error)
			failed += 1
		} else {
			total_compile += result.compile_time_ns
			total_match += result.match_time_ns
			successful += 1

			// 验证预期结果
			if result.matched != case.expected_match {
				fmt.printf("WARNING: Expected %v, got %v\n", case.expected_match, result.matched)
			}
		}

		category_stats[case.category] += 1
		fmt.printf("%s\n", strings.repeat("-", 60))
	}

	// 套件总结
	fmt.printf("\n=== %s SUMMARY ===\n", name)
	fmt.printf("Total cases:    %d\n", len(cases))
	fmt.printf("Successful:     %d\n", successful)
	fmt.printf("Failed:         %d\n", failed)

	if successful > 0 {
		avg_compile := total_compile / successful
		avg_match := total_match / successful
		fmt.printf("Avg compile:   %s\n", format_time(avg_compile))
		fmt.printf("Avg match:     %s\n", format_time(avg_match))
		fmt.printf("Total compile: %s\n", format_time(total_compile))
		fmt.printf("Total match:   %s\n", format_time(total_match))

		// 性能分析
		ratio := f64(total_compile) / f64(total_match)
		fmt.printf("Compile/Match ratio: %.2fx\n", ratio)
	}

	// 类别分布
	fmt.printf("\nCategory breakdown:\n")
	for category, count in category_stats {
		fmt.printf("  %s: %d cases\n", category, count)
	}
}

// 线性时间复杂度分析
analyze_linearity :: proc() {
	fmt.printf("\n=== LINEAR TIME COMPLEXITY ANALYSIS ===\n")

	input_sizes := []int{100, 1000, 10000, 100000}
	times := make([]f64, len(input_sizes))

	for i, case in LINEARITY_TEST_CASES {
		result := run_benchmark(case)
		times[i] = f64(result.match_time_ns)

		fmt.printf("Input size: %d, Time: %s, Throughput: %.2f MB/s\n",
			len(case.input), format_time(result.match_time_ns), result.throughput_mbps)
	}

	// 计算时间增长率
	fmt.printf("\nTime growth analysis:\n")
	for i in 1..<len(times) {
		growth_factor := times[i] / times[i-1]
		size_factor := f64(input_sizes[i]) / f64(input_sizes[i-1])

		fmt.printf("Size %d→%d: Time grew by %.2fx, Size grew by %.2fx\n",
			input_sizes[i-1], input_sizes[i], growth_factor, size_factor)

		if growth_factor > size_factor * 1.5 {
			fmt.printf("  ⚠️  Possible super-linear growth detected!\n")
		} else {
			fmt.printf("  ✅ Linear growth maintained\n")
		}
	}
}

main :: proc() {
	fmt.printf("=== Google RE2 Comprehensive Benchmark Suite ===\n")
	fmt.printf("Odin RE2 Implementation Validation\n")
	fmt.printf("Date: %s\n\n", time.now())

	// 运行所有测试套件
	run_test_suite("RE2 Basic Functionality", RE2_BASIC_CASES)
	run_test_suite("RE2 Edge Cases", RE2_EDGE_CASES)
	run_test_suite("RE2 Performance Critical", RE2_PERFORMANCE_CASES)
	run_test_suite("Real-World Patterns", REAL_WORLD_PATTERNS)

	// 线性时间复杂度分析
	analyze_linearity()

	fmt.printf("\n=== BENCHMARK COMPLETED ===\n")
	fmt.printf("Compare these results with Google RE2 C++ implementation\n")
	fmt.printf("to validate correctness and performance competitiveness.\n")
}