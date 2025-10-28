package regexp

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:time"

// ===========================================================================
// PARALLEL NFA MATCHER - Odin compatible version
// ===========================================================================

// Forward declarations
ErrorCode :: enum u8 { NoError, ParseError, MatchError }

// Simple match result
Match_Result :: struct {
    found:      bool,
    start_pos:  int,
    end_pos:    int,
    task_id:    int,
}

// Text chunk for parallel processing
Text_Chunk :: struct {
    start_idx:  int,
    end_idx:    int,
    text:       string,
}

// Thread worker state
Thread_Worker :: struct {
    worker_id:   int,
    thread:      thread.Handle,
    active:      bool,
    pending:     bool,
    current_task: Match_Task,
    result:      Match_Result,
    mutex:       sync.Mutex,
}

// Match task for parallel processing
Match_Task :: struct {
    task_id:    int,
    start_pos:  int,
    end_pos:    int,
    text:       string,
    pattern:    string,  // Simplified - just use string pattern
}

// Parallel NFA matcher
Parallel_NFA_Matcher :: struct {
    num_workers:   int,
    chunk_size:    int,
    overlap_size:  int,
    workers:      []Thread_Worker,
    ready:        bool,
}

// ===========================================================================
// PARALLEL MATCHER INITIALIZATION
// ===========================================================================

// Create new parallel NFA matcher
new_parallel_matcher :: proc(num_workers: int, chunk_size: int = 1024) -> ^Parallel_NFA_Matcher {
    matcher := new(Parallel_NFA_Matcher)
    matcher.num_workers = num_workers
    matcher.chunk_size = chunk_size
    matcher.overlap_size = 64
    matcher.ready = false

    // Initialize workers
    matcher.workers = make([]Thread_Worker, num_workers)
    for i in 0..<num_workers {
        worker := Thread_Worker{
            worker_id = i,
            active = true,
            pending = false,
        }

        // Start worker thread
        worker.thread = thread.create(simple_worker_proc, &worker)
        matcher.workers[i] = worker
    }

    matcher.ready = true
    return matcher
}

// Simple worker procedure
simple_worker_proc :: proc(arg: rawptr) -> rawptr {
    worker := (^Thread_Worker)(arg)

    fmt.printf("Worker %d started\n", worker.worker_id)

    for worker.active {
        sync.lock(&worker.mutex)

        if worker.pending {
            // Process the task
            result := process_simple_task(worker.current_task)
            worker.result = result
            worker.pending = false

            fmt.printf("Worker %d completed task %d\n", worker.worker_id, result.task_id)
        }

        sync.unlock(&worker.mutex)

        // Small sleep to prevent busy waiting
        time.sleep(time.Millisecond * 1)
    }

    fmt.printf("Worker %d stopped\n", worker.worker_id)
    return nil
}

// Process a simple matching task
process_simple_task :: proc(task: Match_Task) -> Match_Result {
    result := Match_Result{
        task_id = task.task_id,
        found = false,
        start_pos = -1,
        end_pos = -1,
    }

    // Simple string search (demonstration)
    pattern_len := len(task.pattern)
    text_len := len(task.text)

    if pattern_len == 0 || text_len == 0 {
        return result
    }

    // Search for pattern in text chunk
    for i := 0; i <= text_len - pattern_len; i += 1 {
        match := true
        for j := 0; j < pattern_len; j += 1 {
            if i + j >= text_len || task.text[i + j] != task.pattern[j] {
                match = false
                break
            }
        }

        if match {
            result.found = true
            result.start_pos = task.start_pos + i
            result.end_pos = task.start_pos + i + pattern_len
            return result
        }
    }

    return result
}

// ===========================================================================
// PARALLEL MATCHING CORE
// ===========================================================================

// Parallel string search
parallel_string_search :: proc(matcher: ^Parallel_NFA_Matcher, pattern: string, text: string) -> (bool, int, int) {
    if !matcher.ready {
        fmt.printf("Error: Matcher not ready\n")
        return false, -1, -1
    }

    if pattern == "" || text == "" {
        return false, -1, -1
    }

    // Create text chunks for parallel processing
    chunks := create_text_chunks_simple(matcher, text)

    // Dispatch tasks to workers
    for i, chunk in chunks {
        task := Match_Task{
            task_id = i,
            start_pos = chunk.start_idx,
            end_pos = chunk.end_idx,
            text = chunk.text,
            pattern = pattern,
        }

        // Assign to worker (round-robin)
        worker_id := i % matcher.num_workers
        worker := &matcher.workers[worker_id]

        sync.lock(&worker.mutex)
        worker.current_task = task
        worker.pending = true
        sync.unlock(&worker.mutex)
    }

    // Wait for all tasks to complete
    best_result := Match_Result{found = false}

    for i, chunk in chunks {
        worker_id := i % matcher.num_workers
        worker := &matcher.workers[worker_id]

        // Wait for this specific task to complete
        task_completed := false
        for !task_completed {
            sync.lock(&worker.mutex)
            task_completed = !worker.pending && worker.result.task_id == i
            if task_completed {
                // Update best result (leftmost-longest)
                if worker.result.found {
                    if !best_result.found ||
                       worker.result.start_pos < best_result.start_pos ||
                       (worker.result.start_pos == best_result.start_pos &&
                        worker.result.end_pos > best_result.end_pos) {
                        best_result = worker.result
                    }
                }
            }
            sync.unlock(&worker.mutex)

            if !task_completed {
                time.sleep(time.Millisecond * 10)
            }
        }
    }

    if best_result.found {
        return true, best_result.start_pos, best_result.end_pos
    }

    return false, -1, -1
}

// Create simple text chunks
create_text_chunks_simple :: proc(matcher: ^Parallel_NFA_Matcher, text: string) -> []Text_Chunk {
    text_len := len(text)
    chunk_size := matcher.chunk_size

    if text_len <= chunk_size {
        return []Text_Chunk{
            Text_Chunk{0, text_len, text}
        }
    }

    // Calculate number of chunks
    num_chunks := (text_len + chunk_size - 1) / chunk_size
    chunks := make([]Text_Chunk, num_chunks)

    for i in 0..<num_chunks {
        start := i * chunk_size
        end := start + chunk_size
        if end > text_len {
            end = text_len
        }

        chunks[i] = Text_Chunk{
            start_idx = start,
            end_idx = end,
            text = text[start:end],
        }
    }

    return chunks
}

// ===========================================================================
// PARALLEL MATCHER CLEANUP
// ===========================================================================

// Stop all worker threads
stop_parallel_matcher :: proc(matcher: ^Parallel_NFA_Matcher) {
    fmt.printf("Stopping parallel matcher...\n")

    // Signal workers to stop
    for i in 0..<matcher.num_workers {
        worker := &matcher.workers[i]
        sync.lock(&worker.mutex)
        worker.active = false
        sync.unlock(&worker.mutex)
    }

    // Wait for workers to finish
    for i in 0..<matcher.num_workers {
        worker := &matcher.workers[i]
        thread.join(worker.thread)
    }

    matcher.ready = false
    fmt.printf("All workers stopped\n")
}

// Get matcher status
get_matcher_status :: proc(matcher: ^Parallel_NFA_Matcher) -> string {
    active_workers := 0
    for i in 0..<matcher.num_workers {
        worker := &matcher.workers[i]
        sync.lock(&worker.mutex)
        if worker.active {
            active_workers += 1
        }
        sync.unlock(&worker.mutex)
    }

    return fmt.tprintf("Parallel Matcher: %d/%d workers active", active_workers, matcher.num_workers)
}