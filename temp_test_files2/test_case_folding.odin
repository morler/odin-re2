package main

import "core:fmt"
import "core:time"
import "../regexp"

main :: proc() {
	fmt.println("=== 大小写处理测试 ===")

	// 测试 ASCII 大小写折叠
	test_ascii_case_folding()

	// 测试 Unicode 大小写折叠
	test_unicode_case_folding()

	// 测试大小写不敏感匹配
	test_case_insensitive_matching()

	// 测试性能
	test_case_folding_performance()

	fmt.println("\n所有大小写处理测试完成!")
}

test_ascii_case_folding :: proc() {
	fmt.println("\n--- ASCII 大小写折叠测试 ---")

	// 测试大写到小写转换
	assert(regexp.unicode_fold_case('A') == 'a', "A should fold to a")
	assert(regexp.unicode_fold_case('Z') == 'z', "Z should fold to z")
	assert(regexp.unicode_fold_case('H') == 'h', "H should fold to h")

	// 测试小写保持不变
	assert(regexp.unicode_fold_case('a') == 'a', "a should remain a")
	assert(regexp.unicode_fold_case('z') == 'z', "z should remain z")

	// 测试非字母字符保持不变
	assert(regexp.unicode_fold_case('1') == '1', "1 should remain 1")
	assert(regexp.unicode_fold_case('@') == '@', "@ should remain @")
	assert(regexp.unicode_fold_case(' ') == ' ', "space should remain space")

	fmt.println("[PASS] ASCII 大小写折叠测试")
}

test_unicode_case_folding :: proc() {
	fmt.println("\n--- Unicode 大小写折叠测试 ---")

	// 测试 Latin-1 Supplement 字符
	assert(regexp.unicode_fold_case('É') == 'é', "É should fold to é")
	assert(regexp.unicode_fold_case('À') == 'à', "À should fold to à")
	assert(regexp.unicode_fold_case('Ø') == 'ø', "Ø should fold to ø")
	assert(regexp.unicode_fold_case('Þ') == 'þ', "Þ should fold to þ")

	// 测试小写保持不变
	assert(regexp.unicode_fold_case('é') == 'é', "é should remain é")
	assert(regexp.unicode_fold_case('à') == 'à', "à should remain à")

	// 测试希腊字母
	assert(regexp.unicode_fold_case('Α') == 'α', "Alpha should fold to alpha")
	assert(regexp.unicode_fold_case('Ω') == 'ω', "Omega should fold to omega")
	assert(regexp.unicode_fold_case('Σ') == 'σ', "Sigma should fold to sigma")

	// 测试西里尔字母
	assert(regexp.unicode_fold_case('А') == 'а', "Cyrillic А should fold to а")
	assert(regexp.unicode_fold_case('Я') == 'я', "Cyrillic Я should fold to я")

	fmt.println("[PASS] Unicode 大小写折叠测试")
}

test_case_insensitive_matching :: proc() {
	fmt.println("\n--- 大小写不敏感匹配测试 ---")

	// 测试 ASCII 大小写不敏感匹配
	assert(case_insensitive_match('a', 'A'), "a should match A case-insensitively")
	assert(case_insensitive_match('Z', 'z'), "Z should match z case-insensitively")
	assert(case_insensitive_match('H', 'h'), "H should match h case-insensitively")

	// 测试 ASCII 不匹配情况
	assert(!case_insensitive_match('a', 'b'), "a should not match b")
	assert(!case_insensitive_match('A', '1'), "A should not match 1")

	// 测试 Unicode 大小写不敏感匹配
	assert(case_insensitive_match('é', 'É'), "é should match É case-insensitively")
	assert(case_insensitive_match('α', 'Α'), "alpha should match Alpha case-insensitively")
	assert(case_insensitive_match('а', 'А'), "Cyrillic а should match А case-insensitively")

	fmt.println("[PASS] 大小写不敏感匹配测试")
}

test_case_folding_performance :: proc() {
	fmt.println("\n--- 大小写折叠性能测试 ---")

	test_chars := []rune{'A', 'a', 'É', 'é', 'Α', 'α', 'А', 'а'}
	char_names := []string{"A", "a", "É", "é", "Alpha", "alpha", "Cyrillic А", "Cyrillic а"}

	iterations := 100000

	for i in 0..<len(test_chars) {
		char := test_chars[i]
		start := time.now()
		for j in 0..<iterations {
			_ = regexp.unicode_fold_case(char)
		}
		elapsed := time.since(start)

		fmt.printf("字符 '%s' (%c): %v (%.2f ns/op)\n",
			char_names[i], char, elapsed, f64(elapsed) / f64(iterations))
	}

	fmt.println("[PASS] 大小写折叠性能测试")
}

// 辅助函数：大小写不敏感比较
case_insensitive_match :: proc(a: rune, b: rune) -> bool {
	return regexp.unicode_fold_case(a) == regexp.unicode_fold_case(b)
}

assert :: proc(condition: bool, message: string) {
	if !condition {
		fmt.printf("断言失败: %s\n", message)
		panic("测试失败")
	}
}