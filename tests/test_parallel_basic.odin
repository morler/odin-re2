package main

import "core:fmt"
import "core:time"
import "core:thread"

// Simple parallel text search test to validate concepts

// Simple match result
Match_Result :: struct {
    found:      bool,
    start_pos:  int,
    end_pos:    int,
    worker_id:  int,
}

// Worker task
Worker_Task :: struct {
    task_id:     int,
    pattern:     string,
    text:        string,
    start_pos:   int,
    worker_id:   int,
}

// Simple worker thread data
Worker_Data :: struct {
    worker_id:   int,
    task:        Worker_Task,
    completed:    bool,
    result:      Match_Result,
}

// Worker thread procedure - Odin compatible version
worker_proc :: proc(arg: ^thread.Thread) -> rawptr {
    data := (^Worker_Data)(arg.data)

    fmt.printf("Worker %d started\n", data.worker_id)

    // Simple string search in assigned text
    pattern_len := len(data.task.pattern)
    text_len := len(data.task.text)

    data.result = Match_Result{
        found = false,
        start_pos = -1,
        end_pos = -1,
        worker_id = data.worker_id,
    }

    if pattern_len > 0 && text_len > 0 {
        // Search for pattern
        for i := 0; i <= text_len - pattern_len; i += 1 {
            match := true
            for j := 0; j < pattern_len; j += 1 {
                if data.task.text[i + j] != data.task.pattern[j] {
                    match = false
                    break
                }
            }

            if match {
                data.result.found = true
                data.result.start_pos = data.task.start_pos + i
                data.result.end_pos = data.task.start_pos + i + pattern_len
                break
            }
        }
    }

    data.completed = true
    fmt.printf("Worker %d completed, found: %v, pos: %d-%d\n",
              data.worker_id, data.result.found,
              data.result.start_pos, data.result.end_pos)

    return nil
}

// Simple parallel search function
parallel_search :: proc(pattern: string, text: string, num_workers: int) -> (bool, int, int) {
    fmt.printf("Starting parallel search for '%s' in %d bytes with %d workers\n",
              pattern, len(text), num_workers)

    if pattern == "" || text == "" || num_workers <= 0 {
        return false, -1, -1
    }

    // Divide text into chunks
    chunk_size := len(text) / num_workers
    if chunk_size == 0 {
        chunk_size = 1
    }

    // Create worker data
    workers := make([]Worker_Data, num_workers)
    threads := make([]thread.Thread, num_workers)

    // Start workers
    for i in 0..<num_workers {
        start_pos := i * chunk_size
        end_pos := start_pos + chunk_size
        if i == num_workers - 1 {
            end_pos = len(text) // Last worker gets remaining text
        }

        workers[i] = Worker_Data{
            worker_id = i,
            completed = false,
            task = Worker_Task{
                task_id = i,
                pattern = pattern,
                text = text[start_pos:end_pos],
                start_pos = start_pos,
                worker_id = i,
            },
        }

        // Start thread
        threads[i] = thread.create_with_data(worker_proc, &workers[i])
    }

    // Wait for all workers to complete
    best_result := Match_Result{found = false}
    all_completed := false

    for !all_completed {
        all_completed = true
        for i in 0..<num_workers {
            if !workers[i].completed {
                all_completed = false
                break
            }

            // Check if this worker found a match
            if workers[i].result.found {
                if !best_result.found ||
                   workers[i].result.start_pos < best_result.start_pos {
                    best_result = workers[i].result
                }
            }
        }

        if !all_completed {
            time.sleep(time.Millisecond * 10)
        }
    }

    // Wait for threads to finish
    for i in 0..<num_workers {
        thread.join(&threads[i])
    }

    if best_result.found {
        fmt.printf("Best match found at position %d-%d by worker %d\n",
                  best_result.start_pos, best_result.end_pos, best_result.worker_id)
        return true, best_result.start_pos, best_result.end_pos
    }

    fmt.printf("No match found\n")
    return false, -1, -1
}

main :: proc() {
    fmt.printf("=== Parallel Text Search Test ===\n")

    // Test case 1: Simple pattern
    text := "The quick brown fox jumps over the lazy dog. The fox is quick."
    pattern := "fox"

    fmt.printf("\nTest 1: Simple pattern '%s'\n", pattern)
    fmt.printf("Text: %s\n", text)

    // Sequential search for comparison
    seq_start := time.now()
    seq_pos := -1
    for i := 0; i <= len(text) - len(pattern); i += 1 {
        match := true
        for j := 0; j < len(pattern); j += 1 {
            if text[i + j] != pattern[j] {
                match = false
                break
            }
        }
        if match {
            seq_pos = i
            break
        }
    }
    seq_end := time.now()
    seq_time := time.diff(seq_end, seq_start)

    fmt.printf("Sequential: found at %d, time: %v\n", seq_pos, seq_time)

    // Parallel search
    par_start := time.now()
    found, start_pos, end_pos := parallel_search(pattern, text, 4)
    par_end := time.now()
    par_time := time.diff(par_end, par_start)

    fmt.printf("Parallel: found at %d-%d, time: %v\n", start_pos, end_pos, par_time)

    if found && seq_pos >= 0 && start_pos == seq_pos {
        fmt.printf("✅ Test 1 PASSED: Results match!\n")
    } else {
        fmt.printf("❌ Test 1 FAILED: Results don't match!\n")
    }

    // Test case 2: Pattern at different positions
    fmt.printf("\nTest 2: Multiple occurrences\n")
    text2 := "abc abc abc abc"
    pattern2 := "abc"

    found2, start2, end2 := parallel_search(pattern2, text2, 2)
    fmt.printf("Parallel search for '%s' in '%s'\n", pattern2, text2)
    fmt.printf("Result: found=%v, pos=%d-%d\n", found2, start2, end2)

    if found2 && start2 == 0 {
        fmt.printf("✅ Test 2 PASSED: Found first occurrence\n")
    } else {
        fmt.printf("❌ Test 2 FAILED\n")
    }

    // Test case 3: No match
    fmt.printf("\nTest 3: No match\n")
    text3 := "Hello World"
    pattern3 := "xyz"

    found3, start3, end3 := parallel_search(pattern3, text3, 2)
    fmt.printf("Parallel search for '%s' in '%s'\n", pattern3, text3)
    fmt.printf("Result: found=%v, pos=%d-%d\n", found3, start3, end3)

    if !found3 {
        fmt.printf("✅ Test 3 PASSED: Correctly no match\n")
    } else {
        fmt.printf("❌ Test 3 FAILED: Should not match\n")
    }

    fmt.printf("\n=== Test Complete ===\n")
}