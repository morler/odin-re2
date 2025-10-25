package main

import "core:fmt"
import "core:strings"
import "./regexp"

main :: proc() {
    fmt.println("=== 重复量词测试 ===")
    
    // 测试用例：a{2,4} 应该匹配 2-4 个 'a'
    test_cases := [?]struct {
        pattern: string,
        text:    string,
        should_match: bool,
        expected_match: string,
    }{
        {"a{2,4}", "", false, ""},
        {"a{2,4}", "a", false, ""},
        {"a{2,4}", "aa", true, "aa"},
        {"a{2,4}", "aaa", true, "aaa"},
        {"a{2,4}", "aaaa", true, "aaaa"},
        {"a{2,4}", "aaaaa", true, "aaaa"},  // 应该只匹配前4个
        {"a{2,4}", "baaa", true, "aaa"},
        {"a{2,4}", "baaaab", true, "aaaa"},
    }
    
    for test in test_cases {
        fmt.printf("测试: 模式='%s', 文本='%s'\n", test.pattern, test.text)
        
        // 编译正则表达式
        pattern, err := regexp.regexp(test.pattern)
        if err != .NoError {
            fmt.printf("  编译错误: %v\n", err)
            continue
        }
        defer regexp.free_regexp(pattern)
        
        // 执行匹配
        result, match_err := regexp.match(pattern, test.text)
        if match_err != .NoError {
            fmt.printf("  匹配错误: %v\n", match_err)
            continue
        }
        
        if result.matched {
            match_str := test.text[result.full_match.start:result.full_match.end]
            fmt.printf("  匹配成功: '%s' (位置 %d-%d)\n", match_str, result.full_match.start, result.full_match.end)
            
            if test.should_match {
                if match_str == test.expected_match {
                    fmt.printf("  ✅ 正确匹配\n")
                } else {
                    fmt.printf("  ❌ 错误匹配: 期望 '%s', 实际 '%s'\n", test.expected_match, match_str)
                }
            } else {
                fmt.printf("  ❌ 不应该匹配\n")
            }
        } else {
            fmt.printf("  匹配失败\n")
            if !test.should_match {
                fmt.printf("  ✅ 正确拒绝\n")
            } else {
                fmt.printf("  ❌ 应该匹配 '%s'\n", test.expected_match)
            }
        }
        
        fmt.println()
    }
    
    // 测试其他重复量词
    fmt.println("=== 其他重复量词测试 ===")
    
    other_tests := [?]struct {
        pattern: string,
        text:    string,
        should_match: bool,
    }{
        {"a{0,2}", "", true},      // 0-2个a
        {"a{0,2}", "a", true},
        {"a{0,2}", "aa", true},
        {"a{0,2}", "aaa", true},   // 应该匹配前2个
        {"a{3}", "", false},       // 恰好3个a
        {"a{3}", "a", false},
        {"a{3}", "aa", false},
        {"a{3}", "aaa", true},
        {"a{3}", "aaaa", true},    // 应该匹配前3个
    }
    
    for test in other_tests {
        fmt.printf("测试: 模式='%s', 文本='%s'\n", test.pattern, test.text)
        
        pattern, err := regexp.regexp(test.pattern)
        if err != .NoError {
            fmt.printf("  编译错误: %v\n", err)
            continue
        }
        defer regexp.free_regexp(pattern)
        
        result, match_err := regexp.match(pattern, test.text)
        if match_err != .NoError {
            fmt.printf("  匹配错误: %v\n", match_err)
            continue
        }
        
        if result.matched == test.should_match {
            fmt.printf("  ✅ 正确\n")
        } else {
            fmt.printf("  ❌ 错误: 期望 %v, 实际 %v\n", test.should_match, result.matched)
        }
        
        fmt.println()
    }
}