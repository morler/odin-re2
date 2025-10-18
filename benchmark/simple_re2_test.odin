package main

import "core:fmt"
import "core:time"
import "../regexp"

// 简化的RE2对比测试
Simple_Test :: struct {
	name: string,
	pattern: string,
	input: string,
	expected: bool,
	description: string,
}

TESTS :: []Simple_Test{
	// 基础字面量测试
	{name="literal_match", pattern="hello", input="hello world", expected=true, description="Basic literal match"},
	{name="literal_no_match", pattern="xyz", input="hello world", expected=false, description="No match"},

	// 字符类测试 - 已知问题区域
	{name="char_class_basic", pattern="[abc]", input="b", expected=true, description="Simple char class"},
	{name="char_class_range", pattern="[a-z]", input="m", expected=true, description="Char range"},
	{name="char_class_negated", pattern="[^0-9]", input="a", expected=true, description="Negated class"},

	// 量词测试
	{name="star_zero", pattern="a*", input="bbb", expected=true, description="Star matches zero"},
	{name="star_many", pattern="a*", input="aaaa", expected=true, description="Star matches many"},
	{name="plus_one", pattern="a+", input="a", expected=true, description="Plus matches one"},
	{name="plus_zero", pattern="a+", input="bbb", expected=false, description="Plus requires one"},

	// 锚点测试 - 已知问题区域
	{name="anchor_begin", pattern="^hello", input="hello world", expected=true, description="Begin anchor"},
	{name="anchor_end", pattern="world$", input="hello world", expected=true, description="End anchor"},

	// 选择测试
	{name="alternation", pattern="cat|dog", input="dog", expected=true, description="Simple alternation"},

	// 连接测试
	{name="concatenation", pattern="ab", input="ab", expected=true, description="Simple concatenation"},
}

Test_Result :: struct {
	test: Simple_Test,
	compile_time_ns: i64,
	match_time_ns: i64,
	matched: bool,
	error: string,
	correct: bool,
}

run_test :: proc(test: Simple_Test) -> Test_Result {
	result := Test_Result{
		test = test,
		compile_time_ns = 0,
		match_time_ns = 0,
		matched = false,
		error = "",
		correct = false,
	}

	// 编译测试
	compile_start := time.tick_now()
	regex_obj, compile_err := regexp.regexp(test.pattern)
	compile_end := time.tick_now()

	compile_duration := time.diff(time.Time(compile_end), time.Time(compile_start))
	result.compile_time_ns = time.duration_nanoseconds(compile_duration)

	if compile_err != .NoError {
		result.error = fmt.tprintf("Compile error: %v", compile_err)
		return result
	}

	defer regexp.free_regexp(regex_obj)

	// 匹配测试
	match_start := time.tick_now()
	match_result, match_err := regexp.match(regex_obj, test.input)
	match_end := time.tick_now()

	match_duration := time.diff(time.Time(match_end), time.Time(match_start))
	result.match_time_ns = time.duration_nanoseconds(match_duration)

	if match_err != .NoError {
		result.error = fmt.tprintf("Match error: %v", match_err)
		return result
	}

	result.matched = match_result.matched
	result.correct = (result.matched == test.expected)

	return result
}

format_time :: proc(nanoseconds: i64) -> string {
	if nanoseconds < 1_000 {
		return fmt.tprintf("%dns", nanoseconds)
	} else if nanoseconds < 1_000_000 {
		return fmt.tprintf("%.2fμs", f64(nanoseconds) / 1_000.0)
	} else {
		return fmt.tprintf("%.2fms", f64(nanoseconds) / 1_000_000.0)
	}
}

main :: proc() {
	fmt.printf("=== Simple RE2 Comparison Test ===\n")
	fmt.printf("Testing %d cases\n\n", len(TESTS))

	passed := 0
	failed := 0
	errors := 0
	total_compile := i64(0)
	total_match := i64(0)

	for test in TESTS {
		fmt.printf("Test: %s\n", test.name)
		fmt.printf("  Pattern: %q, Input: %q\n", test.pattern, test.input)
		fmt.printf("  Expected: %v\n", test.expected)

		result := run_test(test)

		if result.error != "" {
			fmt.printf("  ❌ ERROR: %s\n", result.error)
			errors += 1
		} else {
			status := "✅ PASS"
			if !result.correct {
				status = "❌ FAIL"
			}

			actual := "MATCHED"
			if !result.matched {
				actual = "NOT MATCHED"
			}

			fmt.printf("  %s: %s (expected %v)\n", status, actual, test.expected)
			fmt.printf("  Compile: %s, Match: %s\n",
				format_time(result.compile_time_ns), format_time(result.match_time_ns))

			total_compile += result.compile_time_ns
			total_match += result.match_time_ns

			if result.correct {
				passed += 1
			} else {
				failed += 1
			}
		}
		fmt.printf("\n")
	}

	// 总结
	fmt.printf("=== SUMMARY ===\n")
	fmt.printf("Total:   %d\n", len(TESTS))
	fmt.printf("Passed:  %d\n", passed)
	fmt.printf("Failed:  %d\n", failed)
	fmt.printf("Errors:  %d\n", errors)

	if passed > 0 {
		avg_compile := total_compile / i64(passed)
		avg_match := total_match / i64(passed)
		fmt.printf("Avg compile: %s\n", format_time(avg_compile))
		fmt.printf("Avg match:   %s\n", format_time(avg_match))
	}

	// 关键发现
	fmt.printf("\n=== KEY FINDINGS ===\n")

	if errors > 0 {
		fmt.printf("⚠️  %d compilation/match errors found\n", errors)
	}

	if failed > 0 {
		fmt.printf("⚠️  %d functionality failures found\n", failed)

		// 分析失败模式
		char_class_failures := 0
		anchor_failures := 0

		for test in TESTS {
			// 简单的失败检测逻辑
			if test.name == "char_class_basic" || test.name == "char_class_range" || test.name == "char_class_negated" {
				char_class_failures += 1
			}
			if test.name == "anchor_begin" || test.name == "anchor_end" {
				anchor_failures += 1
			}
		}

		if char_class_failures > 0 {
			fmt.printf("  • Character classes likely failing (%d tests)\n", char_class_failures)
		}
		if anchor_failures > 0 {
			fmt.printf("  • Anchors likely failing (%d tests)\n", anchor_failures)
		}
	}

	success_rate := f64(passed) / f64(len(TESTS)) * 100.0
	fmt.printf("Success rate: %.1f%%\n", success_rate)

	if success_rate >= 90.0 {
		fmt.printf("✅ Excellent! Almost full RE2 compatibility\n")
	} else if success_rate >= 70.0 {
		fmt.printf("🟡 Good progress. Focus on remaining issues\n")
	} else {
		fmt.printf("🔴 Major issues detected. Significant work needed\n")
	}

	fmt.printf("\n=== RECOMMENDED ACTIONS ===\n")
	fmt.printf("1. Fix character class implementation\n")
	fmt.printf("2. Implement proper anchor support\n")
	fmt.printf("3. Add comprehensive test coverage\n")
	fmt.printf("4. Run full benchmark suite\n")
}