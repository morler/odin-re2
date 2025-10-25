package main

import "core:fmt"
import "core:time"
import "../regexp"

main :: proc() {
	fmt.println("=== Odin RE2 简化性能验证测试 ===")

	// 创建内存 arena
	arena := regexp.new_arena()

	// 测试基础匹配功能
	test_basic_matching(arena)

	// 测试性能
	test_performance(arena)

	fmt.println("\n简化性能验证测试完成!")
}

test_basic_matching :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- 基础匹配测试 ---")

	// 测试简单模式匹配
	pattern := "hello"
	ast, parse_err := regexp.parse_regexp_internal(pattern, {})
	if parse_err != .NoError {
		fmt.printf("解析错误: %v\n", parse_err)
		return
	}

	program, compile_err := regexp.compile_nfa(ast, arena)
	if compile_err != .NoError {
		fmt.printf("编译错误: %v\n", compile_err)
		return
	}

	matcher := regexp.new_matcher(program, false, true)

	// 测试匹配
	text := "hello world"
	matched, caps := regexp.match_nfa(matcher, text)
	fmt.printf("模式 '%s' 在文本 '%s' 中的匹配结果: %v\n", pattern, text, matched)
	if matched && len(caps) >= 2 {
		fmt.printf("匹配位置: %d-%d\n", caps[0], caps[1])
	}

	fmt.println("[PASS] 基础匹配测试")
}

test_performance :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- 性能测试 ---")

	// 简单的性能测试
	pattern := "[a-zA-Z0-9]+"
	ast, parse_err := regexp.parse_regexp_internal(pattern, {})
	if parse_err != .NoError {
		fmt.printf("解析错误: %v\n", parse_err)
		return
	}

	program, compile_err := regexp.compile_nfa(ast, arena)
	if compile_err != .NoError {
		fmt.printf("编译错误: %v\n", compile_err)
		return
	}

	matcher := regexp.new_matcher(program, false, true)

	test_texts := []string{
		"hello123world456",
		"The quick brown fox jumps over the lazy dog",
		"1234567890",
	}

	iterations := 10000

	for text in test_texts {
		start := time.now()
		match_count := 0
		for i in 0..<iterations {
			matched, _ := regexp.match_nfa(matcher, text)
			if matched {
				match_count += 1
			}
		}
		elapsed := time.since(start)

		matches_per_second := f64(match_count) / (f64(elapsed) / 1_000_000_000)
		fmt.printf("文本长度 %d: %v (%.2f ns/op, %.0f matches/s)\n",
			len(text), elapsed, f64(elapsed) / f64(iterations), matches_per_second)
	}

	fmt.println("[PASS] 性能测试")
}

assert :: proc(condition: bool, message: string) {
	if !condition {
		fmt.printf("断言失败: %s\n", message)
		panic("测试失败")
	}
}