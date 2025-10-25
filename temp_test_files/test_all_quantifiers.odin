package main

import "core:fmt"
import "core:os"
import "./regexp"

main :: proc() {
	fmt.println("=== 综合量词测试 ===")
	
	test_cases := []string{
		"a*",     // 0或多个
		"a+",     // 1或多个  
		"a?",     // 0或1个
		"a{2}",   // 精确2个
		"a{2,4}", // 2到4个
		"a{0,2}", // 0到2个
		"a{3,}",  // 至少3个
	}
	
	texts := []string{
		"", "a", "aa", "aaa", "aaaa", "aaaaa",
	}
	
	for pattern in test_cases {
		fmt.printf("\n模式: %s\n", pattern)
		
		// 编译正则表达式
		re, err_code := regexp.regexp(pattern)
		if err_code != .NoError {
			fmt.printf("  编译失败: %v\n", err_code)
			continue
		}
		
		for text in texts {
			result, err_code := regexp.match(re, text)
			if err_code != .NoError {
				fmt.printf("  ❌ 匹配错误: %v\n", err_code)
				continue
			}
			
			if result.matched {
				fmt.printf("  ✅ 匹配 '%s' -> '%s' (位置 %d-%d)\n", 
					text, text[result.full_match.start:result.full_match.end], 
					result.full_match.start, result.full_match.end)
			} else {
				fmt.printf("  ❌ 不匹配 '%s'\n", text)
			}
		}
		
		regexp.free_regexp(re)
	}
	
	fmt.println("\n=== 测试完成 ===")
}