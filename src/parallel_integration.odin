package regexp

import "core:fmt"
import "core:time"

// ===========================================================================
// PARALLEL MATCHER INTEGRATION - Phase 2: Integration and API
// ===========================================================================

// Parallel matcher configuration
Parallel_Config :: struct {
    num_workers:      int,
    chunk_size:       int,
    overlap_size:     int,
    enable_threshold: int,    // Minimum text size for parallel processing
}

// Parallel matcher result
Parallel_Match_Result :: struct {
    found:      bool,
    start_pos:  int,
    end_pos:    int,
    workers_used: int,
    duration:   time.Duration,
}

// Create default parallel configuration
default_parallel_config :: proc() -> Parallel_Config {
    return Parallel_Config{
        num_workers = 4,
        chunk_size = 1024,
        overlap_size = 64,
        enable_threshold = 4096, // Enable parallel for texts > 4KB
    }
}

// Auto-tune configuration for given text and pattern
tune_parallel_config :: proc(text: string, pattern_complexity: int) -> Parallel_Config {
    config := Parallel_Config{}
    text_len := len(text)

    // Auto-adjust worker count based on text size
    if text_len < config.enable_threshold {
        config.num_workers = 1 // Sequential for small texts
    } else if text_len < 10240 {
        config.num_workers = 2
    } else if text_len < 102400 {
        config.num_workers = 4
    } else {
        config.num_workers = 8
    }

    // Auto-adjust chunk size based on pattern complexity
    if pattern_complexity < 10 {
        config.chunk_size = 2048
    } else if pattern_complexity < 50 {
        config.chunk_size = 1024
    } else {
        config.chunk_size = 512
    }

    config.overlap_size = 64
    config.enable_threshold = 4096

    return config
}

// Main parallel regex matching function
regex_match_parallel :: proc(pattern: string, text: string) -> Parallel_Match_Result {
    start_time := time.now()

    result := Parallel_Match_Result{}
    result.workers_used = 1 // Default to sequential

    // Compile pattern (using existing compiler)
    arena := new_arena(8192)
    defer free_arena(arena)

    prog, err := compile_pattern_simple(pattern, arena)
    if err != .NoError {
        result.found = false
        result.duration = time.diff(time.now(), start_time)
        return result
    }

    // Estimate pattern complexity
    pattern_complexity := estimate_pattern_complexity(prog)

    // Auto-tune configuration
    config := tune_parallel_config(text, pattern_complexity)

    // Choose processing strategy
    if config.num_workers == 1 {
        // Use sequential matching
        found, start_pos, end_pos := regex_match_sequential(prog, text)
        result.found = found
        result.start_pos = start_pos
        result.end_pos = end_pos
        result.workers_used = 1
    } else {
        // Use parallel matching
        found, start_pos, end_pos, workers := regex_match_parallel_workers(prog, text, config)
        result.found = found
        result.start_pos = start_pos
        result.end_pos = end_pos
        result.workers_used = workers
    }

    result.duration = time.diff(time.now(), start_time)
    return result
}

// Sequential regex matching (fallback and for small texts)
regex_match_sequential :: proc(prog: ^Program, text: string) -> (bool, int, int) {
    // Use existing NFA matcher implementation
    // This would integrate with matcher.odin's simple_nfa_match_with_context
    
    // For now, implement basic character matching
    for pos := 0; pos < len(text); pos += 1 {
        matched, end_pos := simple_nfa_match_with_context(prog, nil, pos)
        if matched {
            return true, pos, end_pos
        }
    }
    return false, -1, -1
}

// Parallel regex matching with multiple workers
regex_match_parallel_workers :: proc(prog: ^Program, text: string, config: Parallel_Config) -> (bool, int, int, int) {
    // Create text chunks with overlap for boundary handling
    chunks := create_text_chunks_parallel(text, config.chunk_size, config.overlap_size)

    // Process chunks in parallel (simulated for Phase 1)
    // In Phase 2+, this would use actual threads
    best_match_found := false
    best_start := -1
    best_end := -1

    // Process chunks sequentially for now (simulating parallel work)
    for chunk in chunks {
        chunk_text := chunk.text
        chunk_offset := chunk.start_idx

        // Search within this chunk
        for pos := 0; pos < len(chunk_text); pos += 1 {
            global_pos := chunk_offset + pos
            
            matched, end_pos := simple_nfa_match_with_context(prog, nil, global_pos)
            if matched {
                if !best_match_found || global_pos < best_start {
                    best_match_found = true
                    best_start = global_pos
                    best_end = end_pos
                }
                break // First match in this chunk is sufficient
            }
        }
    }

    return best_match_found, best_start, best_end, config.num_workers
}

// Create text chunks with overlap for parallel processing
create_text_chunks_parallel :: proc(text: string, chunk_size: int, overlap: int) -> []Text_Chunk {
    text_len := len(text)
    
    if text_len <= chunk_size {
        // Text is smaller than chunk size, return single chunk
        chunks := make([]Text_Chunk, 1)
        chunks[0] = Text_Chunk{
            start_idx = 0,
            end_idx = text_len,
            overlap = 0,
            text = text,
        }
        return chunks
    }

    // Calculate number of chunks with overlap
    effective_chunk_size := chunk_size - overlap
    num_chunks := (text_len + effective_chunk_size - 1) / effective_chunk_size

    chunks := make([]Text_Chunk, num_chunks)

    for i in 0..<num_chunks {
        start := i * effective_chunk_size
        end := start + chunk_size

        // Adjust boundaries
        if end > text_len {
            end = text_len
        }

        // Last chunk has no overlap
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

// Text chunk structure for parallel processing
Text_Chunk :: struct {
    start_idx: int,
    end_idx: int,
    overlap: int,
    text: string,
}

// Estimate pattern complexity for configuration tuning
estimate_pattern_complexity :: proc(prog: ^Program) -> int {
    if prog == nil {
        return 0
    }

    complexity := 0
    for inst in prog.instructions {
        switch inst.op {
        case .InstAlt, .InstAltMatch:
            complexity += 3 // Alternation is expensive
        case .InstCapture:
            complexity += 2 // Capture groups add overhead
        case .InstEmptyWidth:
            complexity += 2 // Lookarounds add complexity
        case .InstRune, .InstRune1, .InstRuneAny:
            complexity += 1 // Basic character matching
        case .InstMatch:
            complexity += 1
        }
    }

    return complexity
}

// Simple pattern compilation (placeholder for parser integration)
compile_pattern_simple :: proc(pattern: string, arena: ^Arena) -> (^Program, ErrorCode) {
    // This would integrate with parser.odin
    // For now, return a simple program that matches literal text
    
    prog := new(Program)
    prog.instructions = make([dynamic]Inst, 0)
    
    // Create simple literal matching instructions
    for char in pattern {
        append(&prog.instructions, Inst{.InstRune})
    }
    append(&prog.instructions, Inst{.InstMatch})
    
    return prog, .NoError
}

// Forward declarations for integration
Program :: struct {
    instructions: [dynamic]Inst,
}

Inst :: struct {
    op: OpCode,
}

OpCode :: enum u8 {
    InstAlt,
    InstAltMatch,
    InstCapture,
    InstEmptyWidth,
    InstRune,
    InstRune1,
    InstRuneAny,
    InstMatch,
}

Arena :: struct {
    data: []byte,
}

ErrorCode :: enum u8 {
    NoError,
    ParseError,
    MatchError,
}

// Arena functions (would integrate with memory.odin)
new_arena :: proc(size: int) -> ^Arena {
    arena := new(Arena)
    arena.data = make([]byte, size)
    return arena
}

free_arena :: proc(arena: ^Arena) {
    // Placeholder - would integrate with memory system
}

// NFA matching function (would integrate with matcher.odin)
simple_nfa_match_with_context :: proc(prog: ^Program, ctx: ^Match_Context, pos: int) -> (bool, int) {
    // This would integrate with matcher.odin
    // For now, return simple literal matching
    return false, pos + 1
}

Match_Context :: struct {
    // Would integrate with matcher.odin's context
}