package main

import "core:fmt"
import "../regexp"

main :: proc() {
	fmt.println("=== Unicode 支持测试 ===")
	fmt.println("测试 Latin, Greek, Cyrillic 脚本支持")
	fmt.println()

	// 测试 Latin 脚本
	fmt.println("1. Latin 脚本测试:")
	test_unicode_script("hello", "hello world", "Latin basic")
	test_unicode_script("café", "café résumé", "Latin extended")
	test_unicode_script("naïve", "naïve façade", "Latin diacritics")

	// 测试 Greek 脚本
	fmt.println("\n2. Greek 脚本测试:")
	test_unicode_script("καλημέρα", "καλημέρα κόσμε", "Greek basic")
	test_unicode_script("Αθήνα", "Αθήνα είναι η πρωτεύουσα", "Greek with capital")

	// 测试 Cyrillic 脚本
	fmt.println("\n3. Cyrillic 脚本测试:")
	test_unicode_script("привет", "привет мир", "Cyrillic basic")
	test_unicode_script("Москва", "Москва - столица России", "Cyrillic with capital")

	// 测试混合脚本
	fmt.println("\n4. 混合脚本测试:")
	test_unicode_script("[a-z]+", "Hello World 123", "ASCII letters")
	test_unicode_script("[Α-Ωα-ω]+", "Καλημέρα κόσμε", "Greek letters")
	test_unicode_script("[А-Яа-я]+", "Привет мир", "Cyrillic letters")

	fmt.println("\n=== Unicode 支持验证完成 ===")
}

test_unicode_script :: proc(pattern: string, text: string, description: string) {
	pat, err := regexp.regexp(pattern)
	if err != .NoError {
		fmt.printf("  ❌ %s: 编译失败 %v\n", description, err)
		return
	}
	defer regexp.free_regexp(pat)

	result, match_err := regexp.match(pat, text)
	if match_err != .NoError {
		fmt.printf("  ❌ %s: 匹配错误 %v\n", description, match_err)
		return
	}

	if result.matched {
		fmt.printf("  ✅ %s: 匹配成功\n", description)
		matched_text := string(text[result.full_match.start:result.full_match.end])
		fmt.printf("     匹配文本: '%s'\n", matched_text)
	} else {
		fmt.printf("  ❌ %s: 匹配失败\n", description)
	}
}