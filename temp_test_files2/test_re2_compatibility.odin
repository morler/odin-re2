package main

import "core:fmt"
import "core:time"
import "../regexp"

main :: proc() {
	fmt.println("=== Odin RE2 兼容性验证测试 ===")

	// 创建内存 arena
	arena := regexp.new_arena()

	// 测试基础RE2功能兼容性
	test_basic_patterns(arena)

	// 测试字符类兼容性
	test_character_classes(arena)

	// 测试量词兼容性
	test_quantifiers(arena)

	// 测试锚点兼容性
	test_anchors(arena)

	// 测试Unicode兼容性
	test_unicode_compatibility(arena)

	// 测试边界情况
	test_edge_cases(arena)

	// 总结结果
	print_summary()

	fmt.println("\nRE2兼容性验证完成!")
}

// Test case structure
Test_Case :: struct {
	name:     string,
	pattern:  string,
	text:     string,
	expected: bool,
	should_match: string, // expected match text if any
}

test_results := [dynamic]string{}
pass_count := 0
total_count := 0

// 基础模式兼容性测试
test_basic_patterns :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- 基础模式兼容性测试 ---")

	test_cases := []Test_Case{
		// Literal matching
		{"literal_simple", "hello", "hello world", true, "hello"},
		{"literal_not_found", "xyz", "hello world", false, ""},
		{"literal_empty", "", "hello", true, ""},

		// Escape sequences
		{"escape_digit", "\\d", "123", true, "1"},
		{"escape_space", "\\s", "hello world", true, " "},
		{"escape_word", "\\w", "hello", true, "h"},
		{"escape_not_digit", "\\D", "abc", true, "a"},
		{"escape_not_space", "\\S", "hello", true, "h"},
		{"escape_not_word", "\\W", " ", true, " "},
	}

	run_test_suite(test_cases, arena)
}

// 字符类兼容性测试
test_character_classes :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- 字符类兼容性测试 ---")

	test_cases := []Test_Case{
		// Simple character classes
		{"class_simple", "[abc]", "b", true, "b"},
		{"class_range", "[a-z]", "m", true, "m"},
		{"class_range_outside", "[a-z]", "A", false, ""},
		{"class_negated", "[^0-9]", "a", true, "a"},
		{"class_multiple", "[a-zA-Z0-9]", "Z5", true, "Z"},

		// Predefined classes
		{"class_digit", "\\d+", "123", true, "123"},
		{"class_alpha", "[a-zA-Z]+", "Hello", true, "Hello"},
		{"class_alnum", "[a-zA-Z0-9]+", "test123", true, "test123"},
		{"class_word_boundary", "\\bword\\b", "word", true, "word"},
	}

	run_test_suite(test_cases, arena)
}

// 量词兼容性测试
test_quantifiers :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- 量词兼容性测试 ---")

	test_cases := []Test_Case{
		// Note: Quantifiers currently have issues, but we test what works
		{"quant_star_zero", "a*b", "b", true, "b"},
		{"quant_star_many", "a*b", "aaaab", true, "aaaab"},
		{"quant_plus_one", "a+b", "ab", true, "ab"},
		{"quant_plus_many", "a+b", "aaab", true, "aaab"},
		{"quant_question_zero", "a?b", "b", true, "b"},
		{"quant_question_one", "a?b", "ab", true, "ab"},
		{"quant_exact", "a{3}", "aaa", true, "aaa"},
		{"quant_exact_min", "a{2,}", "aaa", true, "aaa"},
		{"quant_exact_range", "a{1,3}", "aa", true, "aa"},
	}

	run_test_suite(test_cases, arena)
}

// 锚点兼容性测试
test_anchors :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- 锚点兼容性测试 ---")

	test_cases := []Test_Case{
		{"anchor_start", "^hello", "hello world", true, "hello"},
		{"anchor_start_fail", "^hello", "say hello", false, ""},
		{"anchor_end", "world$", "hello world", true, "world"},
		{"anchor_end_fail", "world$", "world peace", false, ""},
		{"anchor_both", "^hello world$", "hello world", true, "hello world"},
		{"anchor_both_fail", "^hello world$", "say hello world", false, ""},
	}

	run_test_suite(test_cases, arena)
}

// Unicode兼容性测试
test_unicode_compatibility :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- Unicode兼容性测试 ---")

	test_cases := []Test_Case{
		// Unicode letters
		{"unicode_latin", "[\\u0041-\\u005A]+", "HELLO", true, "HELLO"},
		{"unicode_accent", "[\\u00C0-\\u00FF]+", "ÀÁÂÃ", true, "ÀÁÂÃ"},
		{"unicode_greek", "[\\u0391-\\u03A9]+", "ΑΒΓ", true, "ΑΒΓ"},
		{"unicode_cyrillic", "[\\u0410-\\u044F]+", "АБВ", true, "АБВ"},

		// Mixed scripts
		{"unicode_mixed", "[a-zA-Z\\u00C0-\\u00FF]+", "Café", true, "Café"},
		{"unicode_chinese", "[\\u4e00-\\u9fff]+", "你好", true, "你好"},

		// UTF-8 sequences
		{"utf8_emoji", "[\\u1F600-\\u1F64F]", "😀", true, "😀"},
	}

	run_test_suite(test_cases, arena)
}

// 边界情况测试
test_edge_cases :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- 边界情况测试 ---")

	test_cases := []Test_Case{
		// Empty cases
		{"empty_pattern", "", "anything", true, ""},
		{"empty_text", "hello", "", false, ""},
		{"both_empty", "", "", true, ""},

		// Large inputs
		{"large_text", "hello", string([]byte{0} * 1000) + "hello", true, "hello"},

		// Special characters
		{"special_chars", "[.*+?^${}()|\\[\\]]", "*", true, "*"},
		{"dot_matches_all", ".", "any char", true, "a"},

		// Line boundaries
		{"line_boundary", "hello", "hello\nworld", true, "hello"},
	}

	run_test_suite(test_cases, arena)
}

// 运行测试套件
run_test_suite :: proc(test_cases: []Test_Case, arena: ^regexp.Arena) {
	for case in test_cases {
		total_count += 1

		// 解析模式
		ast, parse_err := regexp.parse_regexp_internal(case.pattern, {})
		if parse_err != .NoError {
			fmt.printf("  ❌ %s: 解析失败 %v\n", case.name, parse_err)
			append(&test_results, fmt.tprintf("❌ %s: 解析失败", case.name))
			continue
		}

		// 编译NFA
		program, compile_err := regexp.compile_nfa(ast, arena)
		if compile_err != .NoError {
			fmt.printf("  ❌ %s: 编译失败 %v\n", case.name, compile_err)
			append(&test_results, fmt.tprintf("❌ %s: 编译失败", case.name))
			continue
		}

		// 创建匹配器
		matcher := regexp.new_matcher(program, false, true)

		// 执行匹配
		matched, caps := regexp.match_nfa(matcher, case.text)

		// 检查结果
		success := matched == case.expected
		if success && case.should_match != "" && len(caps) >= 2 {
			actual_match := case.text[caps[0]:caps[1]]
			success = actual_match == case.should_match
		}

		if success {
			fmt.printf("  ✅ %s: 通过\n", case.name)
			append(&test_results, fmt.tprintf("✅ %s", case.name))
			pass_count += 1
		} else {
			fmt.printf("  ❌ %s: 失败 (期望: %v, 实际: %v",
				case.name, case.expected, matched)
			if len(caps) >= 2 {
				actual_match := case.text[caps[0]:caps[1]]
				fmt.printf(", 匹配: '%s'", actual_match)
			}
			fmt.println(")")
			append(&test_results, fmt.tprintf("❌ %s: 失败", case.name))
		}
	}
}

// 打印总结
print_summary :: proc() {
	fmt.println("\n" + "="*50)
	fmt.println("RE2兼容性验证总结")
	fmt.println("="*50)
	fmt.printf("总测试数: %d\n", total_count)
	fmt.printf("通过测试: %d\n", pass_count)
	fmt.printf("失败测试: %d\n", total_count - pass_count)
	fmt.printf("通过率: %.1f%%\n", f64(pass_count) / f64(total_count) * 100)

	fmt.println("\n详细结果:")
	for result in test_results {
		fmt.println("  " + result)
	}

	fmt.println("\n兼容性评估:")
	if pass_count == total_count {
		fmt.println("🎉 完全兼容 - 所有测试通过!")
	} else if f64(pass_count) / f64(total_count) >= 0.9 {
		fmt.println("✅ 高度兼容 - 90%+ 测试通过")
	} else if f64(pass_count) / f64(total_count) >= 0.7 {
		fmt.println("⚠️  部分兼容 - 70-90% 测试通过")
	} else {
		fmt.println("❌ 兼容性不足 - 需要改进")
	}

	fmt.Println("\n建议改进:")
	fmt.Println("• 修复量词处理问题 (*, +, ? 量词)")
	fmt.println("• 增强复杂模式支持")
	fmt.Println("• 完善错误处理机制")
	fmt.Println("• 扩展Unicode支持范围")
}