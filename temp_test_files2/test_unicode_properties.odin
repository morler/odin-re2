package main

import "core:fmt"
import "core:time"
import "../regexp"

main :: proc() {
	fmt.println("=== Unicode 属性匹配测试 ===")

	// 测试基础 Unicode 类别匹配
	test_basic_unicode_categories()

	// 测试 Unicode 脚本匹配
	test_unicode_scripts()

	// 测试 ASCII 快速路径
	test_ascii_fast_path()

	// 测试性能
	test_unicode_performance()

	fmt.println("\n所有 Unicode 属性匹配测试完成!")
}

test_basic_unicode_categories :: proc() {
	fmt.println("\n--- 基础 Unicode 类别测试 ---")

	// 测试 ASCII 字符
	assert(regexp.is_ascii_letter_fast('a'), "ASCII 'a' should be letter")
	assert(regexp.is_ascii_letter_fast('Z'), "ASCII 'Z' should be letter")
	assert(regexp.is_ascii_digit_fast('5'), "ASCII '5' should be digit")
	assert(regexp.is_ascii_punctuation_fast('.'), "ASCII '.' should be punctuation")
	assert(regexp.is_ascii_whitespace_fast(' '), "ASCII space should be whitespace")

	// 测试 Unicode 类别
	assert(regexp.match_unicode_property('a', .Lowercase_Letter), "'a' should be lowercase letter")
	assert(regexp.match_unicode_property('Z', .Uppercase_Letter), "'Z' should be uppercase letter")
	assert(regexp.match_unicode_property('5', .Decimal_Number), "'5' should be decimal number")

	// 测试西里尔字母
	assert(regexp.match_unicode_property('а', .Lowercase_Letter), "Cyrillic 'а' should be lowercase letter")
	assert(regexp.match_unicode_property('Я', .Uppercase_Letter), "Cyrillic 'Я' should be uppercase letter")

	// 测试希腊字母
	assert(regexp.match_unicode_property('α', .Lowercase_Letter), "Greek 'α' should be lowercase letter")
	assert(regexp.match_unicode_property('Ω', .Uppercase_Letter), "Greek 'Ω' should be uppercase letter")

	fmt.println("[PASS] 基础 Unicode 类别测试")
}

test_unicode_scripts :: proc() {
	fmt.println("\n--- Unicode 脚本测试 ---")

	// 测试拉丁脚本
	assert(regexp.is_script('a', .Latin), "ASCII 'a' should be Latin script")
	assert(regexp.is_script('Z', .Latin), "ASCII 'Z' should be Latin script")
	assert(regexp.is_script('é', .Latin), "Latin 'é' should be Latin script")

	// 测试西里尔脚本
	assert(regexp.is_script('а', .Cyrillic), "Cyrillic 'а' should be Cyrillic script")
	assert(regexp.is_script('Ж', .Cyrillic), "Cyrillic 'Ж' should be Cyrillic script")

	// 测试希腊脚本
	assert(regexp.is_script('α', .Greek), "Greek 'α' should be Greek script")
	assert(regexp.is_script('Δ', .Greek), "Greek 'Δ' should be Greek script")

	fmt.println("[PASS] Unicode 脚本测试")
}

test_ascii_fast_path :: proc() {
	fmt.println("\n--- ASCII 快速路径测试 ---")

	// 性能测试 - 比较 ASCII 快速路径 vs Unicode 路径
	test_char := 'e'
	iterations := 10000000  // 增加迭代次数以获得更准确的测量

	// 测试快速路径
	start := time.now()
	for i in 0..<iterations {
		_ = regexp.is_ascii_letter_fast(test_char)
	}
	fast_time := time.since(start)

	// 测试标准路径
	start = time.now()
	for i in 0..<iterations {
		_ = regexp.match_unicode_property(test_char, .Lowercase_Letter)
	}
	standard_time := time.since(start)

	fmt.printf("ASCII 快速路径: %v\n", fast_time)
	fmt.printf("Unicode 标准路径: %v\n", standard_time)

	if fast_time > 0 && standard_time > 0 {
		fmt.printf("性能提升: %.2fx\n", f64(standard_time) / f64(fast_time))
	}

	// 验证两者结果相同
	fast_result := regexp.is_ascii_letter_fast(test_char)
	standard_result := regexp.match_unicode_property(test_char, .Lowercase_Letter)
	assert(fast_result == standard_result, "Both methods should return same result")

	fmt.println("[PASS] ASCII 快速路径测试")
}

test_unicode_performance :: proc() {
	fmt.println("\n--- Unicode 性能测试 ---")

	// 测试不同字符集的性能
	test_chars := []rune{'a', 'Z', '5', 'α', 'А', 'é', '字'}
	property_names := []string{"小写字母", "大写字母", "数字", "小写字母", "大写字母", "小写字母", "其他"}
	properties := []regexp.Unicode_Category{
		.Lowercase_Letter, .Uppercase_Letter, .Decimal_Number,
		.Lowercase_Letter, .Uppercase_Letter, .Lowercase_Letter, .Other
	}

	iterations := 100000

	for i in 0..<len(test_chars) {
		char := test_chars[i]
		start := time.now()
		for j in 0..<iterations {
			_ = regexp.match_unicode_property(char, properties[i])
		}
		elapsed := time.since(start)

		fmt.printf("字符 '%c' (%s): %v (%.2f ns/op)\n",
			char, property_names[i], elapsed, f64(elapsed) / f64(iterations))
	}

	fmt.println("[PASS] Unicode 性能测试")
}

assert :: proc(condition: bool, message: string) {
	if !condition {
		fmt.printf("断言失败: %s\n", message)
		panic("测试失败")
	}
}