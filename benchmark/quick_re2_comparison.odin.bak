package main

import "core:fmt"
import "core:os"
import "core:time"
import "../regexp"

// ================================================================================
// Google RE2 快速对比评测
//
// 目标: 快速验证当前Odin RE2实现与RE2预期行为的差异
// 重点: 功能正确性验证，性能初步评估
// ================================================================================

Quick_Test :: struct {
	name: string,
	pattern: string,
	input: string,
	expected: bool,
	description: string,
}

// 核心功能测试用例 - 基于RE2官方测试集
CORE_TESTS :: []Quick_Test{
	// 基础字面量 - 应该100%通过
	{name="literal_basic", pattern="hello", input="hello world", expected=true, description="Basic literal match"},
	{name="literal_not_found", pattern="xyz", input="hello world", expected=false, description="Literal not found"},
	{name="literal_empty_pattern", pattern="", input="hello", expected=true, description="Empty pattern"},
	{name="literal_empty_input", pattern="hello", input="", expected=false, description="Empty input"},

	// 字符类 - 当前问题区域
	{name="char_class_simple", pattern="[abc]", input="b", expected=true, description="Simple char class"},
	{name="char_class_not_found", pattern="[abc]", input="x", expected=false, description="Char class not found"},
	{name="char_class_range", pattern="[a-z]", input="m", expected=true, description="Char class range"},
	{name="char_class_range_outside", pattern="[a-z]", input="1", expected=false, description="Outside char range"},
	{name="char_class_negated", pattern="[^0-9]", input="a", expected=true, description="Negated char class"},
	{name="char_class_negated_match", pattern="[^0-9]", input="5", expected=false, description="Negated should not match"},
	{name="char_class_complex", pattern="[a-zA-Z0-9_]", input="X", expected=true, description="Complex char class"},
	{name="char_class_union", pattern="[a-c][x-z]", input="bx", expected=true, description="Union of classes"},

	// 量词 - 应该基本正常
	{name="star_zero", pattern="a*", input="bbb", expected=true, description="Star matches zero"},
	{name="star_many", pattern="a*", input="aaaa", expected=true, description="Star matches many"},
	{name="plus_one", pattern="a+", input="a", expected=true, description="Plus matches one"},
	{name="plus_many", pattern="a+", input="aaaa", expected=true, description="Plus matches many"},
	{name="plus_zero", pattern="a+", input="bbb", expected=false, description="Plus requires at least one"},
	{name="quest_present", pattern="a?", input="a", expected=true, description="Question mark present"},
	{name="quest_absent", pattern="a?", input="b", expected=true, description="Question mark absent (matches zero)"},

	// 锚点 - 当前问题区域
	{name="anchor_begin", pattern="^hello", input="hello world", expected=true, description="Begin anchor"},
	{name="anchor_begin_fail", pattern="^hello", input="say hello", expected=false, description="Begin anchor should fail"},
	{name="anchor_end", pattern="world$", input="hello world", expected=true, description="End anchor"},
	{name="anchor_end_fail", pattern="world$", input="world peace", expected=false, description="End anchor should fail"},
	{name="anchor_both", pattern="^hello world$", input="hello world", expected=true, description="Both anchors"},
	{name="anchor_both_fail", pattern="^hello world$", input="say hello world", expected=false, description="Both anchors should fail"},

	// 选择 - 应该正常工作
	{name="alt_first", pattern="cat|dog", input="cat", expected=true, description="Alternation first option"},
	{name="alt_second", pattern="cat|dog", input="dog", expected=true, description="Alternation second option"},
	{name="alt_none", pattern="cat|dog", input="bird", expected=false, description="Alternation no match"},
	{name="alt_multiple", pattern="cat|dog|bird", input="bird", expected=true, description="Multiple alternation"},

	// 连接 - 应该正常工作
	{name="concat_simple", pattern="ab", input="ab", expected=true, description="Simple concatenation"},
	{name="concat_fail", pattern="ab", input="ac", expected=false, description="Concatenation fail"},
	{name="concat_long", pattern="abcdef", input="abcdef", expected=true, description="Long concatenation"},

	// 点号通配符
	{name="dot_match", pattern="a.b", input="axb", expected=true, description="Dot matches any char"},
	{name="dot_no_match", pattern="a.b", input="ab", expected=false, description="Dot requires a char"},
	{name="dot_multiple", pattern="a.c", input="axcxd", expected=false, description="Dot not greedy by default"},

	// POSIX字符类 - 可能有问题
	{name="posix_digit", pattern="\\d", input="5", expected=true, description="POSIX digit"},
	{name="posix_nondigit", pattern="\\D", input="a", expected=true, description="POSIX non-digit"},
	{name="posix_space", pattern="\\s", input=" ", expected=true, description="POSIX space"},
	{name="posix_word", pattern="\\w", input="a", expected=true, description="POSIX word"},
}

Test_Result :: struct {
	test: Quick_Test,
	compile_time_ns: i64,
	match_time_ns: i64,
	matched: bool,
	compile_error: bool,
	match_error: bool,
	error_message: string,
	correct: bool,
}

run_single_test :: proc(test: Quick_Test) -> Test_Result {
	result := Test_Result{
		test = test,
		compile_time_ns = 0,
		match_time_ns = 0,
		matched = false,
		compile_error = false,
		match_error = false,
		error_message = "",
		correct = false,
	}

	// 编译测试
	compile_start := time.tick_now()
	regex_obj, compile_err := regexp.compile(test.pattern)
	compile_end := time.tick_now()

	result.compile_time_ns = time.duration_nanoseconds(compile_end - compile_start)

	if compile_err != nil {
		result.compile_error = true
		result.error_message = fmt.tprintf("Compile error: %v", compile_err)
		return result
	}

	// 匹配测试
	match_start := time.tick_now()
	matched, match_err := regexp.match(regex_obj, test.input)
	match_end := time.tick_now()

	result.match_time_ns = time.duration_nanoseconds(match_end - match_start)

	if match_err != nil {
		result.match_error = true
		result.error_message = fmt.tprintf("Match error: %v", match_err)
		return result
	}

	result.matched = matched
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

analyze_category :: proc(results: []Test_Result, category: string) {
	fmt.printf("\n--- %s Analysis ---\n", category)

	category_results := make([dynamic]Test_Result)
	for result in results {
		// 简单的分类逻辑
		if category == "Character Classes" &&
		   (strings.contains(result.test.pattern, "[") ||
		    strings.contains(result.test.pattern, "\\d") ||
		    strings.contains(result.test.pattern, "\\w")) {
			append(&category_results, result)
		} else if category == "Anchors" &&
		          (strings.contains(result.test.pattern, "^") ||
		           strings.contains(result.test.pattern, "$")) {
			append(&category_results, result)
		} else if category == "Quantifiers" &&
		          (strings.contains(result.test.pattern, "*") ||
		           strings.contains(result.test.pattern, "+") ||
		           strings.contains(result.test.pattern, "?")) {
			append(&category_results, result)
		}
	}

	if len(category_results) == 0 {
		fmt.printf("No tests found for category: %s\n", category)
		return
	}

	passed := 0
	total := len(category_results)
	total_compile := i64(0)
	total_match := i64(0)

	for result in category_results {
		if result.correct {
			passed += 1
		}
		total_compile += result.compile_time_ns
		total_match += result.match_time_ns
	}

	fmt.printf("Tests: %d/%d passed (%.1f%%)\n", passed, total, f64(passed)/f64(total)*100.0)

	if passed > 0 {
		avg_compile := total_compile / passed
		avg_match := total_match / passed
		fmt.printf("Avg compile: %s, Avg match: %s\n", format_time(avg_compile), format_time(avg_match))
	}

	// 显示失败的具体测试
	if passed < total {
		fmt.printf("Failed tests:\n")
		for result in category_results {
			if !result.correct {
				status: string
				if result.matched {
					status = "MATCHED"
				} else {
					status = "NOT MATCHED"
				}

				expected: string
				if result.test.expected {
					expected = "MATCH"
				} else {
					expected = "NO MATCH"
				}

				fmt.printf("  %s: got %s, expected %s (%s)\n",
					result.test.name, status, expected, result.test.description)
			}
		}
	}
}

main :: proc() {
	fmt.printf("=== Google RE2 Quick Comparison ===\n")
	fmt.printf("Odin RE2 Implementation Status Check\n")
	fmt.printf("Tests: %d\n\n", len(CORE_TESTS))

	results := make([dynamic]Test_Result)

	// 运行所有测试
	for test in CORE_TESTS {
		fmt.printf("Test: %s - %s\n", test.name, test.description)
		fmt.printf("  Pattern: %q, Input: %q, Expected: %v\n", test.pattern, test.input, test.expected)

		result := run_single_test(test)
		append(&results, result)

		if result.compile_error || result.match_error {
			fmt.printf("  ❌ ERROR: %s\n", result.error_message)
		} else {
			status: string
			if result.correct {
				status = "✅ PASS"
			} else {
				status = "❌ FAIL"
			}

			actual: string
			if result.matched {
				actual = "MATCHED"
			} else {
				actual = "NOT MATCHED"
			}

			expected: string
			if result.test.expected {
				expected = "MATCH"
			} else {
				expected = "NO MATCH"
			}

			fmt.printf("  %s: %s (got %s, expected %s)\n",
				status, actual, actual, expected)
			fmt.printf("  Compile: %s, Match: %s\n",
				format_time(result.compile_time_ns), format_time(result.match_time_ns))
		}
		fmt.printf("\n")
	}

	// 总体统计
	fmt.printf("=== OVERALL STATISTICS ===\n")

	total_tests := len(results)
	passed_tests := 0
	failed_tests := 0
	compile_errors := 0
	match_errors := 0
	total_compile_time := i64(0)
	total_match_time := i64(0)

	for result in results {
		if result.compile_error {
			compile_errors += 1
		} else if result.match_error {
			match_errors += 1
		} else if result.correct {
			passed_tests += 1
			total_compile_time += result.compile_time_ns
			total_match_time += result.match_time_ns
		} else {
			failed_tests += 1
			total_compile_time += result.compile_time_ns
			total_match_time += result.match_time_ns
		}
	}

	fmt.printf("Total tests:     %d\n", total_tests)
	fmt.printf("Passed:          %d (%.1f%%)\n", passed_tests, f64(passed_tests)/f64(total_tests)*100.0)
	fmt.printf("Failed:          %d (%.1f%%)\n", failed_tests, f64(failed_tests)/f64(total_tests)*100.0)
	fmt.printf("Compile errors:  %d\n", compile_errors)
	fmt.printf("Match errors:    %d\n", match_errors)

	if passed_tests > 0 {
		avg_compile := total_compile_time / passed_tests
		avg_match := total_match_time / passed_tests
		fmt.printf("Avg compile:    %s\n", format_time(avg_compile))
		fmt.printf("Avg match:      %s\n", format_time(avg_match))

		compile_match_ratio := f64(total_compile_time) / f64(total_match_time)
		fmt.printf("Compile/Match:  %.2fx\n", compile_match_ratio)
	}

	// 分类分析
	analyze_category(results[:], "Character Classes")
	analyze_category(results[:], "Anchors")
	analyze_category(results[:], "Quantifiers")

	// 关键发现
	fmt.printf("\n=== KEY FINDINGS ===\n")

	if failed_tests > 0 {
		fmt.printf("⚠️  %d critical issues found:\n", failed_tests)

		// 分析失败模式
		char_class_failures := 0
		anchor_failures := 0

		for result in results {
			if !result.correct && !result.compile_error && !result.match_error {
				if strings.contains(result.test.pattern, "[") {
					char_class_failures += 1
				}
				if strings.contains(result.test.pattern, "^") || strings.contains(result.test.pattern, "$") {
					anchor_failures += 1
				}
			}
		}

		if char_class_failures > 0 {
			fmt.printf("  • Character classes: %d failures (HIGH PRIORITY)\n", char_class_failures)
		}
		if anchor_failures > 0 {
			fmt.printf("  • Anchors: %d failures (HIGH PRIORITY)\n", anchor_failures)
		}
	}

	if compile_errors > 0 {
		fmt.Printf("  • Compilation errors: %d (CRITICAL)\n", compile_errors)
	}

	if passed_tests == total_tests {
		fmt.Printf("✅ All tests passed! Odin RE2 is RE2 compatible.\n")
	} else if f64(passed_tests)/f64(total_tests) > 0.8 {
		fmt.Printf("🟡 Good progress (%.1f%% pass rate). Focus on remaining issues.\n",
			f64(passed_tests)/f64(total_tests)*100.0)
	} else {
		fmt.Printf("🔴 Major issues detected (%.1f%% pass rate). Significant work needed.\n",
			f64(passed_tests)/f64(total_tests)*100.0)
	}

	// 建议的修复优先级
	fmt.Printf("\n=== RECOMMENDED FIXES ===\n")
	fmt.Printf("1. CRITICAL: Fix character class matching ([abc], [a-z], etc.)\n")
	fmt.Printf("2. CRITICAL: Implement proper anchor support (^, $)\n")
	fmt.Printf("3. IMPORTANT: Add POSIX character classes (\\d, \\w, \\s)\n")
	fmt.Printf("4. NICE TO HAVE: Performance optimizations\n")
	fmt.Printf("5. NICE TO HAVE: Enhanced error messages\n")

	fmt.Printf("\n=== NEXT STEPS ===\n")
	fmt.Printf("1. Run: odin run re2_comprehensive_benchmark.odin\n")
	fmt.Printf("2. Run: python run_re2_comparison.py\n")
	fmt.Printf("3. Review detailed comparison report\n")
	fmt.Printf("4. Implement critical fixes\n")
	fmt.Printf("5. Re-run validation tests\n")
}