use std::time::Instant;

fn main() {
    println!("=== Rust Regex 基础性能测试 ===");
    
    // 测试数据
    let base_text = "The quick brown fox jumps over the lazy dog. ";
    let text_large = base_text.repeat(1000); // 约44KB
    let pattern = "lazy";
    
    println!("文本大小: {} 字节", text_large.len());
    println!("查找模式: \"{}\"", pattern);
    println!();
    
    // 测试1: 内置字符串查找
    println!("--- 内置字符串查找 ---");
    let start = Instant::now();
    let found = text_large.contains(pattern);
    let duration = start.elapsed();
    
    println!("结果: {}", found);
    println!("时间: {:?}", duration);
    
    if duration.as_nanos() > 0 {
        let throughput = text_large.len() as f64 / duration.as_secs_f64() / (1024.0 * 1024.0);
        println!("吞吐量: {:.2} MB/s", throughput);
    }
    
    println!();
    
    // 测试2: 正则表达式匹配
    println!("--- 正则表达式匹配 ---");
    let regex_start = Instant::now();
    let re = regex::Regex::new(pattern).unwrap();
    let regex_compile_time = regex_start.elapsed();
    
    let match_start = Instant::now();
    let found_regex = re.is_match(&text_large);
    let match_time = match_start.elapsed();
    
    println!("编译时间: {:?}", regex_compile_time);
    println!("匹配结果: {}", found_regex);
    println!("匹配时间: {:?}", match_time);
    
    if match_time.as_nanos() > 0 {
        let throughput = text_large.len() as f64 / match_time.as_secs_f64() / (1024.0 * 1024.0);
        println!("匹配吞吐量: {:.2} MB/s", throughput);
    }
    
    println!();
    
    // 测试3: 重复测试
    println!("--- 重复测试 (1000次) ---");
    let iterations = 1000;
    
    let start = Instant::now();
    for _ in 0..iterations {
        text_large.contains(pattern);
    }
    let duration = start.elapsed();
    
    println!("总时间: {:?}", duration);
    println!("平均时间: {:?}", duration / iterations);
    
    let avg_duration = duration / iterations;
    if avg_duration.as_nanos() > 0 {
        let throughput = text_large.len() as f64 / avg_duration.as_secs_f64() / (1024.0 * 1024.0);
        println!("平均吞吐量: {:.2} MB/s", throughput);
    }
    
    println!();
    println!("=== 测试完成 ===");
}