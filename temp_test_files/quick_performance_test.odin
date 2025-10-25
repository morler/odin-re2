package main

import "core:fmt"
import "core:time"
import "core:strings"

// 简单的性能测试，不依赖复杂的regexp模块
main :: proc() {
	fmt.println("=== 简单性能对比测试 ===")
	fmt.println("测试基础字符串操作性能")
	fmt.println()
	
	// 测试数据
	text := "The quick brown fox jumps over the lazy dog. " 
	text_large := strings.repeat(text, 1000) // 约44KB
	pattern := "lazy"
	
	fmt.printf("文本大小: %d 字节\n", len(text_large))
	fmt.printf("查找模式: %q\n", pattern)
	fmt.println()
	
	// 测试1: 内置字符串查找
	fmt.println("--- 内置字符串查找 ---")
	start := time.now()
	found := strings.contains(text_large, pattern)
	end := time.now()
	
	duration := time.diff(end, start)
	fmt.printf("结果: %v\n", found)
	fmt.printf("时间: %v\n", duration)
	
	// 计算吞吐量
	if duration > 0 {
		seconds := f64(duration) / f64(time.Second)
		throughput := f64(len(text_large)) / seconds / (1024.0 * 1024.0)
		fmt.printf("吞吐量: %.2f MB/s\n", throughput)
	}
	
	fmt.println()
	
	// 测试2: 简单字符遍历
	fmt.println("--- 字符遍历匹配 ---")
	start = time.now()
	found_manual := false
	for i := 0; i <= len(text_large) - len(pattern); i += 1 {
		match := true
		for j := 0; j < len(pattern); j += 1 {
			if text_large[i + j] != pattern[j] {
				match = false
				break
			}
		}
		if match {
			found_manual = true
			break
		}
	}
	end = time.now()
	
	duration = time.diff(end, start)
	fmt.printf("结果: %v\n", found_manual)
	fmt.printf("时间: %v\n", duration)
	
	if duration > 0 {
		seconds := f64(duration) / f64(time.Second)
		throughput := f64(len(text_large)) / seconds / (1024.0 * 1024.0)
		fmt.printf("吞吐量: %.2f MB/s\n", throughput)
	}
	
	fmt.println()
	
	// 测试3: 多次重复测试
	fmt.println("--- 重复测试 (1000次) ---")
	iterations := 1000
	
	start = time.now()
	for i := 0; i < iterations; i += 1 {
		_ = strings.contains(text_large, pattern)
	}
	end = time.now()
	
	duration = time.diff(end, start)
	avg_duration := duration / time.Duration(iterations)
	fmt.printf("总时间: %v\n", duration)
	fmt.printf("平均时间: %v\n", avg_duration)
	
	if avg_duration > 0 {
		seconds := f64(avg_duration) / f64(time.Second)
		throughput := f64(len(text_large)) / seconds / (1024.0 * 1024.0)
		fmt.printf("平均吞吐量: %.2f MB/s\n", throughput)
	}
	
	fmt.println()
	fmt.println("=== 测试完成 ===")
	fmt.println("注意: 这是基础字符串操作性能")
	fmt.println("实际正则表达式引擎会有额外开销")
}