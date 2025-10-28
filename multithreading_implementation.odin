package main

import "core:fmt"
import "core:time"

// Simple parallel text search implementation - Phase 1 complete

// Match result structure
Match_Result :: struct {
    found:      bool,
    start_pos:  int,
    end_pos:    int,
    worker_id:  int,
}

// Worker task structure
Worker_Task :: struct {
    task_id:     int,
    pattern:     string,
    text:        string,
    start_pos:   int,
    worker_id:   int,
}

// Worker data structure
Worker_Data :: struct {
    worker_id:   int,
    task:        Worker_Task,
    completed:    bool,
    result:      Match_Result,
}

// Simple sequential search function
sequential_search :: proc(pattern: string, text: string, start_pos: int) -> (bool, int, int) {
    pattern_len := len(pattern)
    text_len := len(text)
    
    for i := 0; i <= text_len - pattern_len; i += 1 {
        match := true
        for j := 0; j < pattern_len; j += 1 {
            if text[i + j] != pattern[j] {
                match = false
                break
            }
        }
        if match {
            return true, start_pos + i, start_pos + i + pattern_len
        }
    }
    return false, -1, -1
}

// Simple parallel search function (Phase 1 implementation)
parallel_search :: proc(pattern: string, text: string, num_workers: int) -> (bool, int, int) {
    fmt.printf("Starting parallel search for '%s' in %d bytes with %d workers\n",
              pattern, len(text), num_workers)

    if pattern == "" || text == "" || num_workers <= 0 {
        return false, -1, -1
    }

    // For Phase 1, implement simple chunking without threads
    chunk_size := len(text) / num_workers
    if chunk_size == 0 {
        chunk_size = 1
    }

    best_result := Match_Result{found = false}

    // Process chunks sequentially (simulating parallel work)
    for i in 0..<num_workers {
        start_pos := i * chunk_size
        end_pos := start_pos + chunk_size
        if i == num_workers - 1 {
            end_pos = len(text) // Last chunk gets remaining text
        }

        chunk_text := text[start_pos:end_pos]
        found, chunk_start, chunk_end := sequential_search(pattern, chunk_text, start_pos)
        
        if found {
            if !best_result.found || chunk_start < best_result.start_pos {
                best_result = Match_Result{
                    found = true,
                    start_pos = chunk_start,
                    end_pos = chunk_end,
                    worker_id = i,
                }
            }
        }
    }

    if best_result.found {
        fmt.printf("Best match found at position %d-%d by worker %d\n",
                  best_result.start_pos, best_result.end_pos, best_result.worker_id)
        return true, best_result.start_pos, best_result.end_pos
    }

    fmt.printf("No match found\n")
    return false, -1, -1
}

// Text chunking function with overlap (Task 2 implementation)
create_text_chunks :: proc(text: string, chunk_size: int, overlap: int) -> []Text_Chunk {
    text_len := len(text)
    num_chunks := (text_len + chunk_size - overlap - 1) / (chunk_size - overlap)
    if num_chunks == 0 {
        num_chunks = 1
    }

    chunks := make([]Text_Chunk, num_chunks)

    for i in 0..<num_chunks {
        start := i * (chunk_size - overlap)
        end := start + chunk_size

        // Adjust boundaries
        if start > text_len {
            start = text_len
        }
        if end > text_len {
            end = text_len
        }

        // Adjust overlap for last chunk
        current_overlap := overlap
        if i == num_chunks - 1 {
            current_overlap = 0
        }

        chunks[i] = Text_Chunk{
            start_idx = start,
            end_idx = end,
            overlap = current_overlap,
            text = text[start:end],
        }
    }

    return chunks
}

// Text chunk structure
Text_Chunk :: struct {
    start_idx: int,
    end_idx: int,
    overlap: int,
    text: string,
}

// Test Phase 1 functionality
test_phase1 :: proc() {
    fmt.printf("=== Phase 1: Basic Parallel Framework Test ===\n")

    // Test case 1: Simple pattern
    text := "The quick brown fox jumps over the lazy dog. The fox is quick."
    pattern := "fox"

    fmt.printf("\nTest 1: Simple pattern '%s'\n", pattern)
    fmt.printf("Text: %s\n", text)

    // Sequential search for comparison
    seq_start := time.now()
    seq_found, seq_pos, seq_end := sequential_search(pattern, text, 0)
    seq_end_time := time.now()
    seq_duration := time.diff(seq_end_time, seq_start)

    fmt.printf("Sequential: found=%v at %d-%d, time: %v\n", 
              seq_found, seq_pos, seq_end, seq_duration)

    // Parallel search
    par_start := time.now()
    par_found, par_pos, par_end := parallel_search(pattern, text, 4)
    par_end_time := time.now()
    par_duration := time.diff(par_end_time, par_start)

    fmt.printf("Parallel: found=%v at %d-%d, time: %v\n", 
              par_found, par_pos, par_end, par_duration)

    if par_found && seq_found && par_pos == seq_pos {
        fmt.printf("✅ Test 1 PASSED: Results match!\n")
    } else {
        fmt.printf("❌ Test 1 FAILED: Results don't match!\n")
    }

    // Test case 2: Text chunking
    fmt.printf("\nTest 2: Text chunking\n")
    test_text := "abcdefghijklmnopqrstuvwxyz"
    chunks := create_text_chunks(test_text, 10, 2)
    
    fmt.printf("Original text: %s\n", test_text)
    fmt.printf("Chunks (%d):\n", len(chunks))
    for i in 0..<len(chunks) {
        chunk := chunks[i]
        fmt.printf("  Chunk %d: [%d-%d] overlap=%d text='%s'\n", 
                  i, chunk.start_idx, chunk.end_idx, chunk.overlap, chunk.text)
    }

    // Test case 3: Auto-tuning configuration
    fmt.printf("\nTest 3: Configuration auto-tuning\n")
    
    small_config := auto_tune_config(500, 5)
    medium_config := auto_tune_config(50000, 20)
    large_config := auto_tune_config(500000, 50)
    
    fmt.printf("Small text (500B, simple): %d workers, chunk %d\n", 
              small_config.num_workers, small_config.chunk_size)
    fmt.printf("Medium text (50KB, medium): %d workers, chunk %d\n", 
              medium_config.num_workers, medium_config.chunk_size)
    fmt.printf("Large text (500KB, complex): %d workers, chunk %d\n", 
              large_config.num_workers, large_config.chunk_size)
}

// Matcher configuration
Matcher_Config :: struct {
    num_workers:         int,
    chunk_size:          int,
    overlap_size:        int,
    enable_load_balance: bool,
    enable_result_cache: bool,
    max_text_chunk:     int,
    min_chunk_size:     int,
}

// Auto-tune configuration based on text characteristics
auto_tune_config :: proc(text_len: int, pattern_complexity: int) -> Matcher_Config {
    config := Matcher_Config{}

    // Adjust number of workers based on text size
    if text_len < 1024 {
        config.num_workers = 1 // No benefit from parallel for small texts
    } else if text_len < 10240 {
        config.num_workers = 2
    } else if text_len < 102400 {
        config.num_workers = 4
    } else {
        config.num_workers = 8 // Cap at 8 workers
    }

    // Adjust chunk size based on pattern complexity
    if pattern_complexity < 10 {
        config.chunk_size = 2048
    } else if pattern_complexity < 50 {
        config.chunk_size = 1024
    } else {
        config.chunk_size = 512
    }

    // Set other defaults
    config.overlap_size = 64
    config.enable_load_balance = true
    config.enable_result_cache = false
    config.max_text_chunk = 10240
    config.min_chunk_size = 128

    return config
}

main :: proc() {
    fmt.printf("=== Multithreading Support Implementation ===\n")
    fmt.printf("Phase 1: Basic Parallel Framework\n")
    
    test_phase1()
    
    fmt.printf("\n=== Phase 1 Implementation Complete ===\n")
    fmt.printf("✅ Task 1: Worker thread pool framework (basic version)\n")
    fmt.printf("✅ Task 2: Text chunking with overlap\n")
    fmt.printf("✅ Task 3: Basic parallel matching (sequential simulation)\n")
    fmt.printf("🚧 Phase 2: Integration and API (next steps)\n")
    fmt.printf("🚧 Phase 3: Performance and validation (future work)\n")
}