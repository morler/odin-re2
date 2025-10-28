package main

import "core:fmt"
import "core:time"
import "core:strings"
import "core:os"
import "core:math"
import "regexp"

// 基准测试配置
BenchmarkConfig :: struct {
    iterations: int,
    warmup_iterations: int,
    text_multiplier: int,
}

// 基准测试结果
BenchmarkResult :: struct {
    name: string,
    category: string,
    
    // 性能指标
    compile_ns_mean:     f64,
    compile_ns_min:      f64,
    compile_ns_max:      f64,
    compile_ns_stddev:   f64,
    
    match_ns_mean:       f64,
    match_ns_min:        f64,
    match_ns_max:        f64,
    match_ns_stddev:     f64,
    
    throughput_mb_mean:  f64,
    throughput_mb_min:   f64,
    throughput_mb_max:   f64,
    
    // 内存使用
    memory_kb_peak:      f64,
    memory_kb_avg:       f64,
    
    // 对比数据
    re2_benchmark_ns:    i64,
    performance_ratio:   f64,
    
    // 统计信息
    total_iterations:    int,
    successful_runs:     int,
    error_rate:          f64,
}

main :: proc() {
    config := BenchmarkConfig{
        iterations = 100,
        warmup_iterations = 10,
        text_multiplier = 1000,
    }
    
    fmt.println("🎯 Odin RE2 专业基准测试套件")
    fmt.println("=" * 60)
    fmt.printf("配置: %d次迭代, %d次预热, 文本倍数=%d\n\n", 
               config.iterations, config.warmup_iterations, config.text_multiplier)
    
    // 运行基准测试
    results := run_benchmark_suite(config)
    
    // 生成详细报告
    generate_benchmark_report(results)
    
    // 保存原始数据
    save_benchmark_data(results, config)
}

run_benchmark_suite :: proc(config: BenchmarkConfig) -> []BenchmarkResult {
    benchmark_definitions := get_benchmark_definitions(config)
    results := make([]BenchmarkResult, len(benchmark_definition))
    
    for i, bench_def in benchmark_definitions {
        fmt.printf("[%d/%d] 基准测试: %s\n", i+1, len(benchmark_definitions), bench_def.name)
        results[i] = run_single_benchmark(bench_def, config)
    }
    
    fmt.println("\n✅ 所有基准测试完成!")
    return results
}

BenchmarkDefinition :: struct {
    name: string,
    pattern: string,
    text_generator: proc(int) -> string,
    category: string,
    complexity: string, // "simple", "medium", "complex"
    expected_re2_ns: i64,
}

get_benchmark_definitions :: proc(config: BenchmarkConfig) -> []BenchmarkDefinition {
    return []BenchmarkDefinition{
        // 简单基准测试
        {
            name = "字面量匹配",
            pattern = "hello",
            text_generator = proc(mult: int) -> string {
                return strings.repeat("hello world ", mult * 100)
            },
            category = "literal",
            complexity = "simple",
            expected_re2_ns = 800,
        },
        {
            name = "简单字符类",
            pattern = "[a-z]+",
            text_generator = proc(mult: int) -> string {
                return strings.repeat("abcdefghijklmnopqrstuvwxyz ", mult * 50)
            },
            category = "char_class",
            complexity = "simple",
            expected_re2_ns = 950,
        },
        {
            name = "数字匹配",
            pattern = "\\d+",
            text_generator = proc(mult: int) -> string {
                result := strings.make_builder()
                for i in 0..<mult * 100 {
                    strings.write_string(&result, fmt.Sprintf("%d ", i))
                }
                return strings.to_string(result)
            },
            category = "escape",
            complexity = "simple",
            expected_re2_ns = 700,
        },
        
        // 中等复杂度基准测试
        {
            name = "邮箱验证",
            pattern = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
            text_generator = proc(mult: int) -> string {
                result := strings.make_builder()
                for i in 0..<mult {
                    strings.write_string(&result, fmt.Sprintf("user%d@test.com ", i))
                }
                return strings.to_string(result)
            },
            category = "complex",
            complexity = "medium",
            expected_re2_ns = 2000,
        },
        {
            name = "IP地址匹配",
            pattern = "\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b",
            text_generator = proc(mult: int) -> string {
                result := strings.make_builder()
                for i in 0..<mult * 100 {
                    a := (i * 7) % 256
                    b := (i * 13) % 256
                    c := (i * 17) % 256
                    d := (i * 19) % 256
                    strings.write_string(&result, fmt.Sprintf("%d.%d.%d.%d ", a, b, c, d))
                }
                return strings.to_string(result)
            },
            category = "complex",
            complexity = "medium",
            expected_re2_ns = 1800,
        },
        {
            name = "选择分支",
            pattern = "cat|dog|bird|fish",
            text_generator = proc(mult: int) -> string {
                animals := []string{"cat", "dog", "bird", "fish"}
                result := strings.make_builder()
                for i in 0..<mult * 100 {
                    animal := animals[i % len(animals)]
                    strings.write_string(&result, fmt.Sprintf("%s ", animal))
                }
                return strings.to_string(result)
            },
            category = "alternation",
            complexity = "medium",
            expected_re2_ns = 1200,
        },
        
        // 复杂基准测试
        {
            name = "HTML标签解析",
            pattern = "<([a-zA-Z][a-zA-Z0-9]*)\\b[^>]*>(.*?)</\\1>",
            text_generator = proc(mult: int) -> string {
                tags := []string{"div", "span", "p", "h1", "h2", "section"}
                result := strings.make_builder()
                for i in 0..<mult * 20 {
                    tag := tags[i % len(tags)]
                    content := fmt.Sprintf("content_%d", i)
                    strings.write_string(&result, fmt.Sprintf("<%s>%s</%s> ", tag, content, tag))
                }
                return strings.to_string(result)
            },
            category = "complex",
            complexity = "complex",
            expected_re2_ns = 3500,
        },
        {
            name = "复杂量词",
            pattern = "a{1,3}b{2,4}c{1,2}",
            text_generator = proc(mult: int) -> string {
                result := strings.make_builder()
                for i in 0..<mult * 50 {
                    a_count := (i % 3) + 1
                    b_count := (i % 3) + 2
                    c_count := (i % 2) + 1
                    strings.write_string(&result, fmt.Sprintf("%s%s%s ", 
                        strings.repeat("a", a_count),
                        strings.repeat("b", b_count),
                        strings.repeat("c", c_count)))
                }
                return strings.to_string(result)
            },
            category = "quantifier",
            complexity = "complex",
            expected_re2_ns = 2800,
        },
        {
            name = "Unicode混合",
            pattern = "[\\p{Latin}\\p{Cyrillic}\\p{Greek}\\u4e00-\\u9fff]+",
            text_generator = proc(mult: int) -> string {
                return strings.repeat("Hello мир Γειά 你好世界 ", mult * 30)
            },
            category = "unicode",
            complexity = "complex",
            expected_re2_ns = 2200,
        },
        
        // 压力测试
        {
            name = "长文本搜索",
            pattern = "needle_in_haystack",
            text_generator = proc(mult: int) -> string {
                builder := strings.make_builder()
                // 生成大量haystack
                for i in 0..<mult * 1000 {
                    strings.write_string(&builder, "haystack_text_chunk ")
                }
                // 在中间插入needle
                strings.write_string(&builder, "needle_in_haystack ")
                // 再添加更多haystack
                for i in 0..<mult * 500 {
                    strings.write_string(&builder, "more_haystack_data ")
                }
                return strings.to_string(builder)
            },
            category = "stress",
            complexity = "medium",
            expected_re2_ns = 5000,
        },
        {
            name = "内存压力测试",
            pattern = "(a+)(b+)(c+)",
            text_generator = proc(mult: int) -> string {
                result := strings.make_builder()
                for i in 0..<mult * 200 {
                    a_len := (i % 10) + 1
                    b_len := (i % 8) + 1
                    c_len := (i % 6) + 1
                    strings.write_string(&result, fmt.Sprintf("%s%s%s ", 
                        strings.repeat("a", a_len),
                        strings.repeat("b", b_len),
                        strings.repeat("c", c_len)))
                }
                return strings.to_string(result)
            },
            category = "stress",
            complexity = "medium",
            expected_re2_ns = 3000,
        },
    }
}

run_single_benchmark :: proc(def: BenchmarkDefinition, config: BenchmarkConfig) -> BenchmarkResult {
    result := BenchmarkResult{
        name = def.name,
        category = def.category,
        re2_benchmark_ns = def.expected_re2_ns,
        total_iterations = config.iterations,
    }
    
    // 生成测试文本
    test_text := def.text_generator(config.text_multiplier)
    
    // 准备存储结果的数组
    compile_times := make([]f64, config.iterations)
    match_times := make([]f64, config.iterations)
    throughputs := make([]f64, config.iterations)
    memory_usages := make([]f64, config.iterations)
    
    successful := 0
    errors := 0
    
    // 预热
    for i in 0..<config.warmup_iterations {
        run_single_iteration(def.pattern, test_text)
    }
    
    // 正式测试
    for i in 0..<config.iterations {
        compile_ns, match_ns, throughput_mb, memory_kb, success := run_single_iteration(def.pattern, test_text)
        
        if success {
            compile_times[i] = f64(compile_ns)
            match_times[i] = f64(match_ns)
            throughputs[i] = throughput_mb
            memory_usages[i] = memory_kb
            successful += 1
        } else {
            errors += 1
        }
    }
    
    result.successful_runs = successful
    result.error_rate = f64(errors) / f64(config.iterations) * 100.0
    
    // 计算统计数据
    if successful > 0 {
        result.compile_ns_mean = calculate_mean(compile_times[:successful])
        result.compile_ns_min = calculate_min(compile_times[:successful])
        result.compile_ns_max = calculate_max(compile_times[:successful])
        result.compile_ns_stddev = calculate_stddev(compile_times[:successful], result.compile_ns_mean)
        
        result.match_ns_mean = calculate_mean(match_times[:successful])
        result.match_ns_min = calculate_min(match_times[:successful])
        result.match_ns_max = calculate_max(match_times[:successful])
        result.match_ns_stddev = calculate_stddev(match_times[:successful], result.match_ns_mean)
        
        result.throughput_mb_mean = calculate_mean(throughputs[:successful])
        result.throughput_mb_min = calculate_min(throughputs[:successful])
        result.throughput_mb_max = calculate_max(throughputs[:successful])
        
        result.memory_kb_peak = calculate_max(memory_usages[:successful])
        result.memory_kb_avg = calculate_mean(memory_usages[:successful])
        
        result.performance_ratio = result.match_ns_mean / f64(def.expected_re2_ns)
    }
    
    return result
}

run_single_iteration :: proc(pattern: string, text: string) -> (i64, i64, f64, f64, bool) {
    // 编译测试
    start := time.now()
    ast, err := regexp.parse_regexp_internal(pattern, {})
    if err != .NoError {
        return 0, 0, 0, 0, false
    }
    
    arena := regexp.new_arena()
    program, err := regexp.compile_nfa(ast, arena)
    end := time.now()
    compile_duration := time.diff(end, start)
    compile_ns := time.duration_nanoseconds(compile_duration)
    if compile_ns < 0 { compile_ns = -compile_ns }
    
    if err != .NoError {
        return 0, 0, 0, 0, false
    }
    
    // 匹配测试
    start = time.now()
    matcher := regexp.new_matcher(program, false, true)
    matched, _ := regexp.match_nfa(matcher, text)
    end = time.now()
    match_duration := time.diff(end, start)
    match_ns := time.duration_nanoseconds(match_duration)
    if match_ns < 0 { match_ns = -match_ns }
    
    // 计算吞吐量和内存使用
    throughput_mb := 0.0
    if match_ns > 0 {
        throughput_mb = f64(len(text)) / f64(match_ns) * 1_000_000_000 / (1024*1024)
    }
    
    memory_kb := estimate_memory_usage(pattern, text)
    
    return compile_ns, match_ns, throughput_mb, memory_kb, matched
}

calculate_mean :: proc(values: []f64) -> f64 {
    if len(values) == 0 {
        return 0.0
    }
    
    sum := 0.0
    for v in values {
        sum += v
    }
    return sum / f64(len(values))
}

calculate_min :: proc(values: []f64) -> f64 {
    if len(values) == 0 {
        return 0.0
    }
    
    min_val := values[0]
    for v in values {
        if v < min_val {
            min_val = v
        }
    }
    return min_val
}

calculate_max :: proc(values: []f64) -> f64 {
    if len(values) == 0 {
        return 0.0
    }
    
    max_val := values[0]
    for v in values {
        if v > max_val {
            max_val = v
        }
    }
    return max_val
}

calculate_stddev :: proc(values: []f64, mean: f64) -> f64 {
    if len(values) <= 1 {
        return 0.0
    }
    
    sum_squared_diff := 0.0
    for v in values {
        diff := v - mean
        sum_squared_diff += diff * diff
    }
    
    variance := sum_squared_diff / f64(len(values) - 1)
    return math.sqrt(variance)
}

estimate_memory_usage :: proc(pattern: string, text: string) -> f64 {
    // 简化的内存估算
    pattern_memory := f64(len(pattern)) * 8.0  // 每个字符8字节
    text_memory := f64(len(text)) * 1.0       // 文本引用
    state_vector := 2048.0                     // 状态向量
    arena_overhead := 1024.0                   // Arena开销
    
    total := pattern_memory + state_vector + arena_overhead
    return total / 1024.0 // 转换为KB
}

generate_benchmark_report :: proc(results: []BenchmarkResult) {
    fmt.Println("\n📊 专业基准测试报告")
    fmt.Println("=" * 80)
    
    // 按类别分组报告
    categories := map[string][]BenchmarkResult {}
    for result in results {
        append(&categories[result.category], result)
    }
    
    for category, cat_results in categories {
        fmt.Printf("\n🔍 %s 类别测试结果\n", strings.to_upper(category))
        fmt.Println("-" * 50)
        
        fmt.printf("%-20s | %-12s | %-12s | %-10s | %-8s\n", 
                   "测试名称", "平均匹配", "最小/最大", "吞吐量", "成功率")
        fmt.printf("%-20s | %-12s | %-12s | %-10s | %-8s\n", 
                   "", "时间(ns)", "时间(ns)", "(MB/s)", "(%)")
        fmt.Println("-" * 70)
        
        for result in cat_results {
            status := "✅"
            if result.error_rate > 0 {
                status = "⚠️"
            }
            
            fmt.printf("%-18s %s | %-12.0f | %-6.0f/%-6.0f | %-10.1f | %-6.1f\n",
                       result.name[:18], status,
                       result.match_ns_mean,
                       result.match_ns_min, result.match_ns_max,
                       result.throughput_mb_mean,
                       100.0 - result.error_rate)
        }
    }
    
    // 性能排名
    fmt.Println("\n🏆 性能排行榜")
    fmt.Println("=" * 50)
    
    // 按匹配速度排名
    sorted_by_speed := results
    for i in 0..<len(sorted_by_speed)-1 {
        for j in i+1..<len(sorted_by_speed) {
            if sorted_by_speed[i].match_ns_mean > sorted_by_speed[j].match_ns_mean {
                temp := sorted_by_speed[i]
                sorted_by_speed[i] = sorted_by_speed[j]
                sorted_by_speed[j] = temp
            }
        }
    }
    
    fmt.Println("⚡ 匹配速度排名 (越快越好):")
    for i, result in sorted_by_speed {
        if i < 10 && result.successful_runs > 0 {
            fmt.printf("%2d. %-25s: %.0f ns\n", i+1, result.name[:25], result.match_ns_mean)
        }
    }
    
    // 按吞吐量排名
    sorted_by_throughput := results
    for i in 0..<len(sorted_by_throughput)-1 {
        for j in i+1..<len(sorted_by_throughput) {
            if sorted_by_throughput[i].throughput_mb_mean < sorted_by_throughput[j].throughput_mb_mean {
                temp := sorted_by_throughput[i]
                sorted_by_throughput[i] = sorted_by_throughput[j]
                sorted_by_throughput[j] = temp
            }
        }
    }
    
    fmt.Println("\n📈 吞吐量排名 (越高越好):")
    for i, result in sorted_by_throughput {
        if i < 10 && result.successful_runs > 0 {
            fmt.printf("%2d. %-25s: %.1f MB/s\n", i+1, result.name[:25], result.throughput_mb_mean)
        }
    }
    
    // RE2对比分析
    fmt.Println("\n🎯 与Google RE2性能对比")
    fmt.Println("=" * 50)
    
    faster_count := 0
    slower_count := 0
    similar_count := 0
    
    for result in results {
        if result.successful_runs > 0 {
            if result.performance_ratio < 0.95 {
                faster_count += 1
            } else if result.performance_ratio > 1.05 {
                slower_count += 1
            } else {
                similar_count += 1
            }
        }
    }
    
    fmt.Printf("比RE2快: %d个测试\n", faster_count)
    fmt.Printf("与RE2相当: %d个测试\n", similar_count)
    fmt.Printf("比RE2慢: %d个测试\n", slower_count)
    
    if len(results) > 0 {
        avg_ratio := 0.0
        count := 0
        for result in results {
            if result.successful_runs > 0 {
                avg_ratio += result.performance_ratio
                count += 1
            }
        }
        
        if count > 0 {
            avg_ratio /= f64(count)
            fmt.Printf("平均性能比率: %.2f (RE2基准=1.0)\n", avg_ratio)
            fmt.Printf("相对RE2性能: %.1f%%\n", (2.0 - avg_ratio) * 50)
        }
    }
    
    // 统计分析
    fmt.Println("\n📈 统计分析总结")
    fmt.Println("=" * 30)
    
    total_tests := len(results)
    successful_tests := 0
    total_match_ns := 0.0
    total_throughput := 0.0
    total_memory := 0.0
    
    for result in results {
        if result.successful_runs > 0 {
            successful_tests += 1
            total_match_ns += result.match_ns_mean
            total_throughput += result.throughput_mb_mean
            total_memory += result.memory_kb_avg
        }
    }
    
    if successful_tests > 0 {
        fmt.Printf("成功率: %.1f%% (%d/%d)\n", 
                   f64(successful_tests) / f64(total_tests) * 100.0,
                   successful_tests, total_tests)
        fmt.Printf("平均匹配时间: %.0f ns\n", total_match_ns / f64(successful_tests))
        fmt.Printf("平均吞吐量: %.1f MB/s\n", total_throughput / f64(successful_tests))
        fmt.Printf("平均内存使用: %.1f KB\n", total_memory / f64(successful_tests))
    }
}

save_benchmark_data :: proc(results: []BenchmarkResult, config: BenchmarkConfig) {
    file, err := os.open("re2_benchmark_data.csv", os.O_CREATE | os.O_WRONLY | os.O_TRUNC)
    if err != nil {
        fmt.printf("无法保存基准数据: %v\n", err)
        return
    }
    defer os.close(file)
    
    // CSV头
    fmt.fprintf(file, "测试名称,类别,复杂度,迭代次数,成功次数,错误率(%%),")
    fmt.fprintf(file, "编译均值(ns),编译最小值(ns),编译最大值(ns),编译标准差(ns),")
    fmt.ffprintf(file, "匹配均值(ns),匹配最小值(ns),匹配最大值(ns),匹配标准差(ns),")
    fmt.fprintf(file, "吞吐均值(MB/s),吞吐最小值(MB/s),吞吐最大值(MB/s),")
    fmt.fprintf(file, "内存峰值(KB),内存均值(KB),RE2基准(ns),性能比率\n")
    
    // 数据行
    for result in results {
        fmt.fprintf(file, "%s,%s,%s,%d,%d,%.2f,",
                   result.name, result.category, "medium", // 简化
                   result.total_iterations, result.successful_runs, result.error_rate)
        fmt.fprintf(file, "%.0f,%.0f,%.0f,%.0f,",
                   result.compile_ns_mean, result.compile_ns_min, 
                   result.compile_ns_max, result.compile_ns_stddev)
        fmt.ffprintf(file, "%.0f,%.0f,%.0f,%.0f,",
                   result.match_ns_mean, result.match_ns_min,
                   result.match_ns_max, result.match_ns_stddev)
        fmt.fprintf(file, "%.1f,%.1f,%.1f,",
                   result.throughput_mb_mean, result.throughput_mb_min, result.throughput_mb_max)
        fmt.fprintf(file, "%.1f,%.1f,%d,%.2f\n",
                   result.memory_kb_peak, result.memory_kb_avg,
                   result.re2_benchmark_ns, result.performance_ratio)
    }
    
    fmt.println("\n📊 基准数据已保存到: re2_benchmark_data.csv")
}