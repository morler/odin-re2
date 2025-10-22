package main

import "core:fmt"
import "core:time"
import "../regexp"

main :: proc() {
	fmt.println("=== UTF-8 优化测试 ===")

	// 测试基础 UTF-8 解码
	test_utf8_decoding()

	// 测试 ASCII 快速路径
	test_ascii_fast_path()

	// 测试 Unicode 字符处理
	test_unicode_processing()

	// 测试性能
	test_utf8_performance()

	// 测试错误处理
	test_error_handling()

	fmt.println("\n所有 UTF-8 优化测试完成!")
}

test_utf8_decoding :: proc() {
	fmt.println("\n--- UTF-8 解码测试 ---")

	// 测试 ASCII 字符
	ascii_data := []u8{'H', 'e', 'l', 'l', 'o'}
	char, bytes, valid := regexp.decode_utf8_char_fast(ascii_data, 0)
	assert(char == 'H' && bytes == 1 && valid, "ASCII 'H' should decode correctly")

	// 测试 2字节 UTF-8 (é)
	utf8_2byte := []u8{0xC3, 0xA9}  // é
	char, bytes, valid = regexp.decode_utf8_char_fast(utf8_2byte, 0)
	assert(char == 'é' && bytes == 2 && valid, "UTF-8 'é' should decode correctly")

	// 测试 3字节 UTF-8 (中)
	utf8_3byte := []u8{0xE4, 0xB8, 0xAD}  // 中
	char, bytes, valid = regexp.decode_utf8_char_fast(utf8_3byte, 0)
	assert(char == '中' && bytes == 3 && valid, "UTF-8 '中' should decode correctly")

	// 测试 4字节 UTF-8 (😊)
	utf8_4byte := []u8{0xF0, 0x9F, 0x98, 0x8A}  // 😊
	char, bytes, valid = regexp.decode_utf8_char_fast(utf8_4byte, 0)
	assert(char == '😊' && bytes == 4 && valid, "UTF-8 '😊' should decode correctly")

	fmt.println("[PASS] UTF-8 解码测试")
}

test_ascii_fast_path :: proc() {
	fmt.println("\n--- ASCII 快速路径测试 ---")

	// 创建混合 ASCII/Unicode 字符串
	mixed_text := "Hello, 世界! This is a test with ASCII and 漢字."
	text_bytes := transmute([]u8)mixed_text

	// 测试快速路径
	ascii_count := 0
	unicode_count := 0

	pos := 0
	for pos < len(text_bytes) {
		char, bytes, _ := regexp.decode_utf8_char_fast(text_bytes, pos)
		if char < 128 {
			ascii_count += 1
		} else {
			unicode_count += 1
		}
		pos += bytes
	}

	fmt.printf("ASCII 字符: %d\n", ascii_count)
	fmt.printf("Unicode 字符: %d\n", unicode_count)
	fmt.printf("ASCII 比例: %.1f%%\n", f64(ascii_count) / f64(ascii_count + unicode_count) * 100)

	assert(ascii_count > 0, "Should have ASCII characters")
	assert(unicode_count > 0, "Should have Unicode characters")

	fmt.println("[PASS] ASCII 快速路径测试")
}

test_unicode_processing :: proc() {
	fmt.println("\n--- Unicode 处理测试 ---")

	// 测试 UTF-8 迭代器
	text := "Hello 世界! 😊"
	text_bytes := transmute([]u8)text

	iter := regexp.make_utf8_iterator_fast(text_bytes)
	char_count := 0

	for regexp.utf8_has_more_fast(&iter) {
		char := regexp.utf8_peek_fast(&iter)
		char_count += 1
		regexp.utf8_advance_fast(&iter)
	}

	// 手动计算期望的字符数
	// "Hello" = 5 字符, " " = 1 字符, "世界" = 2 字符, "!" = 1 字符, " " = 1 字符, "😊" = 1 字符
	expected_count := 11  // 5 + 1 + 2 + 1 + 1 + 1
	assert(char_count == expected_count, fmt.tprintf("Should have %d characters, got %d", expected_count, char_count))

	// 测试字符计数
	count := regexp.count_utf8_chars_fast(text_bytes)
	assert(count == expected_count, fmt.tprintf("Character count should be %d, got %d", expected_count, count))

	fmt.printf("字符计数: %d\n", count)
	fmt.println("[PASS] Unicode 处理测试")
}

test_utf8_performance :: proc() {
	fmt.println("\n--- UTF-8 性能测试 ---")

	// 创建测试数据 (混合 ASCII/Unicode)
	// 由于 Odin 不支持非常量字符串连接，我们使用单个字符串
	test_text := "The quick brown fox jumps over the lazy dog. Hello 世界! 这是一个测试。Bonjour le monde!"
	text_bytes := transmute([]u8)test_text

	iterations := 100000

	// 测试解码性能
	start := time.now()
	decoded_chars := 0
	for i in 0..<iterations {
		pos := 0
		for pos < len(text_bytes) {
			char, bytes, _ := regexp.decode_utf8_char_fast(text_bytes, pos)
			if char != 0 {
				decoded_chars += 1
			}
			pos += bytes
		}
	}
	decode_time := time.since(start)

	// 测试迭代器性能
	start = time.now()
	iterated_chars := 0
	for i in 0..<iterations {
		iter := regexp.make_utf8_iterator_fast(text_bytes)
		for regexp.utf8_has_more_fast(&iter) {
			regexp.utf8_peek_fast(&iter)
			iterated_chars += 1
			regexp.utf8_advance_fast(&iter)
		}
	}
	iterator_time := time.since(start)

	fmt.printf("解码性能: %v (%.2f ns/op)\n", decode_time, f64(decode_time) / f64(iterations * len(text_bytes)))
	fmt.printf("迭代器性能: %v (%.2f ns/op)\n", iterator_time, f64(iterator_time) / f64(iterations * len(text_bytes)))

	assert(decoded_chars == iterated_chars, "Both methods should decode same number of characters")

	fmt.println("[PASS] UTF-8 性能测试")
}

test_error_handling :: proc() {
	fmt.println("\n--- 错误处理测试 ---")

	// 测试无效的 UTF-8 序列
	invalid_utf8 := []u8{0x80, 0xC0, 0xE0, 0x80}  // Various invalid sequences

	error_count := 0
	pos := 0
	for pos < len(invalid_utf8) {
		_, _, valid := regexp.decode_utf8_char_fast(invalid_utf8, pos)
		if !valid {
			error_count += 1
		}
		pos += 1  // Move one byte at a time to test error recovery
	}

	assert(error_count > 0, "Should detect invalid UTF-8 sequences")

	// 测试不完整序列
	incomplete := []u8{0xC3}  // Incomplete 2-byte sequence
	char, bytes, valid := regexp.decode_utf8_char_fast(incomplete, 0)
	assert(!valid, "Incomplete sequence should be invalid")
	assert(bytes == 1, "Should consume one byte for incomplete sequence")

	fmt.printf("检测到 %d 个无效 UTF-8 序列\n", error_count)
	fmt.println("[PASS] 错误处理测试")
}

assert :: proc(condition: bool, message: string) {
	if !condition {
		fmt.printf("断言失败: %s\n", message)
		panic("测试失败")
	}
}