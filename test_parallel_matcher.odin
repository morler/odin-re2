package main

import "core:fmt"
import "regexp"

main :: proc() {
    fmt.println("Parallel matcher module compiled successfully!")
    
    // Test configuration
    config := default_matcher_config()
    fmt.printf("Default config: %d workers, chunk size %d\n", config.num_workers, config.chunk_size)
    
    // Test auto-tuning
    auto_config := auto_tune_config(50000, 20)
    fmt.printf("Auto config for 50KB text: %d workers, chunk size %d\n", auto_config.num_workers, auto_config.chunk_size)
    
    fmt.println("Basic parallel matcher functionality test complete.")
}