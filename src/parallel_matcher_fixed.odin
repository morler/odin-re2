package regexp

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:time"

// ===========================================================================
// PARALLEL NFA MATCHER - Multi-threaded regex matching - FIXED VERSION
// ===========================================================================

// Forward declarations for circular dependencies
ErrorCode :: enum u8 { NoError, ParseError, MatchError }

// Match task for parallel processing
Match_Task :: struct {
    task_id:     int,
    start_pos:   int,
    end_pos:     int,     // Exclusive end position
    text:        string,
    program:     ^Program,
    result_chan: ^chan Match_Result,
    arena:       ^Arena,  // Per-task arena for memory allocations
}

// Match result from parallel workers
Match_Result :: struct {
    task_id:    int,
    found:      bool,
    start_pos:  int,
    end_pos:    int,
    success:    bool,     // Task completed successfully
    error:      ErrorCode,
}

// Thread worker configuration
Thread_Worker :: struct {
    worker_id:   int,
    thread:      thread.Handle,
    task_chan:   ^chan Match_Task,
    active:      bool,
    stats:       Worker_Stats,
    mutex:       sync.Mutex,
}

// Worker performance statistics
Worker_Stats :: struct {
    tasks_processed: u64,
    total_time:     time.Duration,
    avg_time:       f64,
    cache_hits:     u64,
    cache_misses:   u64,
}

// Text chunk for parallel processing
Text_Chunk :: struct {
    start_idx:  int,
    end_idx:    int,
    overlap:    int,  // Overlap with adjacent chunks for boundary matching
    text:       string,
}

// Result aggregator for combining parallel results
Result_Aggregator :: struct {
    best_match:    Match_Result,
    result_mutex:  sync.Mutex,
    all_results:   [dynamic]Match_Result,
    found_match:   bool,
}

// Parallel NFA matcher with configurable worker pool
Parallel_NFA_Matcher :: struct {
    num_workers:        int,
    chunk_size:         int,
    overlap_size:       int,
    workers:           []Thread_Worker,
    result_aggregator:  Result_Aggregator,
    global_arena:      ^Arena,
    task_dispatcher:    Task_Dispatcher,
    config:            Matcher_Config,
}

// Configuration for parallel matching
Matcher_Config :: struct {
    num_workers:         int,
    chunk_size:          int,
    overlap_size:        int,
    enable_load_balance: bool,
    enable_result_cache: bool,
    max_text_chunk:     int,
    min_chunk_size:     int,
}

// Task dispatcher for load balancing
Task_Dispatcher :: struct {
    task_queue:     ^chan Match_Task,
    pending_tasks:  [dynamic]Match_Task,
    load_balancer:  Load_Balancer,
}

// Load balancer for dynamic task distribution
Load_Balancer :: struct {
    worker_loads:       []f64,
    total_tasks:        u64,
    completed_tasks:    u64,
    rebalance_threshold: f64,
}

// ===========================================================================
// PARALLEL MATCHER INITIALIZATION
// ===========================================================================

// Create default matcher configuration
create_default_config :: proc() -> Matcher_Config {
    return Matcher_Config{
        num_workers = 4,
        chunk_size = 1024,
        overlap_size = 64,
        enable_load_balance = true,
        enable_result_cache = true,
        max_text_chunk = 10240,
        min_chunk_size = 128,
    }
}

// Create new parallel NFA matcher
new_parallel_matcher :: proc(config: Matcher_Config) -> ^Parallel_NFA_Matcher {
    matcher := new(Parallel_NFA_Matcher)
    matcher.num_workers = config.num_workers
    matcher.chunk_size = config.chunk_size
    matcher.overlap_size = config.overlap_size
    matcher.config = config

    // Initialize global arena
    matcher.global_arena = new_arena(1024 * 1024) // 1MB initial

    // Initialize workers
    matcher.workers = make([]Thread_Worker, config.num_workers)
    for i in 0..<config.num_workers {
        matcher.workers[i] = create_worker(i, config)
    }

    // Initialize result aggregator
    matcher.result_aggregator = Result_Aggregator{}
    matcher.result_aggregator.all_results = make([dynamic]Match_Result, 0, 32)

    // Initialize task dispatcher
    matcher.task_dispatcher = Task_Dispatcher{}
    task_queue := new(chan Match_Task)
    task_queue^ = make(chan Match_Task, config.num_workers * 2)
    matcher.task_dispatcher.task_queue = task_queue
    matcher.task_dispatcher.load_balancer.worker_loads = make([]f64, config.num_workers)
    matcher.task_dispatcher.load_balancer.rebalance_threshold = 0.3

    return matcher
}

// Create worker thread
create_worker :: proc(worker_id: int, config: Matcher_Config) -> Thread_Worker {
    worker := Thread_Worker{
        worker_id = worker_id,
        active = true,
        task_chan = new(chan Match_Task),
        stats = Worker_Stats{},
    }

    worker.task_chan^ = make(chan Match_Task, 16)

    // Start worker thread
    worker.thread = thread.create(worker_thread_proc, &worker)

    return worker
}

// Worker thread procedure
worker_thread_proc :: proc(arg: rawptr) -> rawptr {
    worker := (^Thread_Worker)(arg)

    fmt.printf("Worker %d started\n", worker.worker_id)

    for worker.active {
        // Wait for task
        task, ok := <-worker.task_chan^
        if !ok {
            break // Channel closed
        }

        // Process task
        start_time := time.now()
        result := process_match_task(task)
        end_time := time.now()

        // Update statistics
        sync.lock(&worker.mutex)
        worker.stats.tasks_processed += 1
        worker.stats.total_time += time.diff(end_time, start_time)
        worker.stats.avg_time = f64(worker.stats.total_time) / f64(worker.stats.tasks_processed)
        sync.unlock(&worker.mutex)

        // Send result
        task.result_chan^ <- result
    }

    fmt.printf("Worker %d stopped\n", worker.worker_id)
    return nil
}

// ===========================================================================
// PARALLEL MATCHING CORE
// ===========================================================================

// Parallel regex match with multiple starting positions
parallel_nfa_match :: proc(matcher: ^Parallel_NFA_Matcher, prog: ^Program, text: string) -> (bool, []int) {
    if prog == nil || len(text) == 0 {
        return false, nil
    }

    // Reset result aggregator
    reset_result_aggregator(&matcher.result_aggregator)

    // Create text chunks for parallel processing
    chunks := create_text_chunks(matcher, text)

    // Create result channel
    result_chan := new(chan Match_Result)
    result_chan^ = make(chan Match_Result, len(chunks))

    // Dispatch tasks to workers
    dispatch_tasks(matcher, prog, text, chunks, result_chan)

    // Collect results
    best_result := collect_parallel_results(matcher, result_chan, len(chunks))

    // Convert result to expected format
    if best_result.found {
        caps := make([]int, 2)
        caps[0] = best_result.start_pos
        caps[1] = best_result.end_pos
        return true, caps
    }

    return false, nil
}

// Create text chunks with overlap for boundary handling
create_text_chunks :: proc(matcher: ^Parallel_NFA_Matcher, text: string) -> []Text_Chunk {
    text_len := len(text)
    chunk_size := matcher.chunk_size
    overlap := matcher.overlap_size

    // Calculate number of chunks
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
        if i == num_chunks - 1 {
            overlap = 0
        }

        chunks[i] = Text_Chunk{
            start_idx = start,
            end_idx = end,
            overlap = overlap,
            text = text[start:end],
        }
    }

    return chunks
}

// Dispatch tasks to worker threads
dispatch_tasks :: proc(matcher: ^Parallel_NFA_Matcher, prog: ^Program, text: string,
                     chunks: []Text_Chunk, result_chan: ^chan Match_Result) {

    task_id := 0

    for i, chunk in chunks {
        // Create per-task arena
        task_arena := new_arena(4096) // 4KB per task

        // Create match task
        task := Match_Task{
            task_id = task_id,
            start_pos = chunk.start_idx,
            end_pos = chunk.end_idx,
            text = chunk.text,
            program = prog,
            result_chan = result_chan,
            arena = task_arena,
        }

        // Select worker (simple round-robin for now)
        worker_id := task_id % matcher.num_workers
        worker := &matcher.workers[worker_id]

        // Send task to worker
        worker.task_chan^ <- task

        task_id += 1
    }
}

// Process individual match task
process_match_task :: proc(task: Match_Task) -> Match_Result {
    result := Match_Result{
        task_id = task.task_id,
        success = false,
        error = .NoError,
    }

    // Simple NFA matching for this chunk
    for pos := 0; pos < len(task.text); pos += 1 {
        // Convert local position to global position
        global_pos := task.start_pos + pos

        // For now, use a simplified matching approach
        // This would call into the existing NFA matcher
        matched := false
        end_pos := pos

        // Simple character matching for demonstration
        if len(task.text) > 0 && task.text[pos] == 'a' {
            matched = true
            end_pos = pos + 1
        }

        if matched {
            // Convert local end position to global
            global_end_pos := task.start_pos + end_pos

            // Found a match - return it
            result.found = true
            result.start_pos = global_pos
            result.end_pos = global_end_pos
            result.success = true

            return result
        }
    }

    // No match found in this chunk
    result.success = true
    return result
}

// Collect results from all workers
collect_parallel_results :: proc(matcher: ^Parallel_NFA_Matcher, result_chan: ^chan Match_Result,
                               expected_results: int) -> Match_Result {

    best_result := Match_Result{found = false}
    results_received := 0

    for results_received < expected_results {
        result := <-result_chan^
        results_received += 1

        // Update aggregator
        update_result_aggregator(&matcher.result_aggregator, result)

        // Track best result (leftmost-longest match)
        if result.found && result.success {
            if !best_result.found ||
               result.start_pos < best_result.start_pos ||
               (result.start_pos == best_result.start_pos && result.end_pos > best_result.end_pos) {
                best_result = result
            }
        }
    }

    return best_result
}

// ===========================================================================
// RESULT AGGREGATION
// ===========================================================================

// Reset result aggregator for new match
reset_result_aggregator :: proc(aggregator: ^Result_Aggregator) {
    sync.lock(&aggregator.result_mutex)
    aggregator.best_match = Match_Result{found = false}
    aggregator.all_results = aggregator.all_results[:0] // Clear but keep capacity
    aggregator.found_match = false
    sync.unlock(&aggregator.result_mutex)
}

// Update result aggregator with new result
update_result_aggregator :: proc(aggregator: ^Result_Aggregator, result: Match_Result) {
    sync.lock(&aggregator.result_mutex)

    append(&aggregator.all_results, result)

    if result.found && result.success {
        if !aggregator.found_match ||
           result.start_pos < aggregator.best_match.start_pos ||
           (result.start_pos == aggregator.best_match.start_pos && result.end_pos > aggregator.best_match.end_pos) {
            aggregator.best_match = result
            aggregator.found_match = true
        }
    }

    sync.unlock(&aggregator.result_mutex)
}

// Get final match result
get_final_result :: proc(aggregator: ^Result_Aggregator) -> Match_Result {
    sync.lock(&aggregator.result_mutex)
    result := aggregator.best_match
    sync.unlock(&aggregator.result_mutex)
    return result
}

// ===========================================================================
// PARALLEL MATCHER CLEANUP
// ===========================================================================

// Stop all worker threads
stop_parallel_matcher :: proc(matcher: ^Parallel_NFA_Matcher) {
    // Signal workers to stop
    for i in 0..<matcher.num_workers {
        worker := &matcher.workers[i]
        worker.active = false
        close(worker.task_chan^) // Close channel to signal stop
    }

    // Wait for workers to finish
    for i in 0..<matcher.num_workers {
        worker := &matcher.workers[i]
        thread.join(worker.thread)
    }

    // Clean up arenas
    free_arena(matcher.global_arena)
}

// Get parallel matcher statistics
get_parallel_stats :: proc(matcher: ^Parallel_NFA_Matcher) -> Parallel_Stats {
    stats := Parallel_Stats{}

    for i in 0..<matcher.num_workers {
        worker := &matcher.workers[i]
        sync.lock(&worker.mutex)
        stats.total_tasks += worker.stats.tasks_processed
        stats.total_time += worker.stats.total_time
        sync.unlock(&worker.mutex)
    }

    if stats.total_tasks > 0 {
        stats.avg_task_time = f64(stats.total_time) / f64(stats.total_tasks)
    }
    stats.workers_used = matcher.num_workers

    return stats
}

// Parallel matcher statistics
Parallel_Stats :: struct {
    total_tasks:    u64,
    total_time:     time.Duration,
    avg_task_time:  f64,
    workers_used:   int,
    cache_hit_rate: f64,
}