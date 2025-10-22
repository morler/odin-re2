use std::time::Instant;

struct Scenario {
    name: String,
    pattern: String,
    text: String,
    iterations: usize,
}

fn main() {
    println!("=== Simple Rust Performance Test ===");
    
    let scenarios = vec![
        Scenario {
            name: "literal".to_string(),
            pattern: "hello".to_string(),
            text: "The quick brown fox jumps over the lazy dog. hello world.".to_string(),
            iterations: 1000,
        },
        Scenario {
            name: "char_class".to_string(),
            pattern: "[a-z]+".to_string(),
            text: "abcdefghijklmnopqrstuvwxyz".to_string(),
            iterations: 1000,
        },
        Scenario {
            name: "quantifier_star".to_string(),
            pattern: "a*".to_string(),
            text: "aaaaaaaaaa".to_string(),
            iterations: 100,
        },
        Scenario {
            name: "quantifier_plus".to_string(),
            pattern: "a+".to_string(),
            text: "aaaaaaaaaa".to_string(),
            iterations: 100,
        },
        Scenario {
            name: "complex".to_string(),
            pattern: "([A-Z][a-z]+)".to_string(),
            text: "HelloWorld TestCase".to_string(),
            iterations: 100,
        },
    ];
    
    println!("Scenario\tPattern\tText Size\tIterations\tAvg Time (ns)\tThroughput (MB/s)");
    println!("--------\t-------\t---------\t----------\t-------------\t----------------");
    
    for scenario in scenarios {
        let regex = match regex::Regex::new(&scenario.pattern) {
            Ok(re) => re,
            Err(e) => {
                println!("{}\t{}\tCOMPILE_ERROR: {}", scenario.name, scenario.pattern, e);
                continue;
            }
        };
        
        let mut total_ns: u128 = 0;
        let mut matched_any = false;
        
        for _ in 0..scenario.iterations {
            let start = Instant::now();
            let matched = regex.is_match(&scenario.text);
            let end = Instant::now();
            
            if matched {
                matched_any = true;
            }
            
            total_ns += end.duration_since(start).as_nanos();
        }
        
        let avg_ns = total_ns / scenario.iterations as u128;
        let text_size = scenario.text.len();
        let total_bytes = text_size * scenario.iterations;
        
        let throughput = if total_ns > 0 {
            let seconds = total_ns as f64 / 1_000_000_000.0;
            (total_bytes as f64 / 1_048_576.0) / seconds
        } else {
            0.0
        };
        
        println!("{}\t{}\t{}\t{}\t{}\t{:.2}", 
            scenario.name, 
            scenario.pattern, 
            text_size, 
            scenario.iterations, 
            avg_ns, 
            throughput);
    }
}