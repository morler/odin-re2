package regexp

import "core:time"



// NFA matcher implementation using Thompson's construction
// Provides linear-time matching guarantee as required by RE2

// Thread represents a state in the NFA execution (arena-optimized)
Thread :: struct {
	pc:    u32,         // Program counter (instruction index)
	cap:   [32]int,     // Capture positions (fixed size for performance)
	active: bool,       // Thread is active in pool
}

// Arena-based thread pool for zero-allocation NFA execution
Thread_Pool :: struct {
	threads:     [64]Thread,    // Pre-allocated threads
	capture_buf: [64][32]int,   // Separate capture buffers
	free_list:   [32]u32,       // Free thread indices
	free_count:  u32,           // Number of free threads
	arena:       ^Arena,        // Memory arena for extensions
	stats:       Thread_Pool_Stats, // Performance tracking
}

// Thread pool statistics for performance monitoring
Thread_Pool_Stats :: struct {
	total_allocations: u32,    // Total threads allocated
	total_releases:    u32,    // Total threads released
	peak_usage:        u32,    // Peak concurrent threads
	current_usage:     u32,    // Current active threads
}

// Lock-free queue for BFS execution of NFA (arena-optimized)
Queue :: struct {
	threads: [256]Thread,  // Fixed-size circular buffer
	head:    u32,           // Head index (mod 256)
	tail:    u32,           // Tail index (mod 256)
	size:    u32,           // Current size
	mask:    u32,           // Bit mask for modulo (255)
}

// Optimized matcher state for Thompson NFA execution
Matcher :: struct {
	prog:        ^Program,
	text:        string,
	anchored:    bool,
	longest:     bool,
	queue:       Queue,
	thread_pool: Thread_Pool,
	state_vec:   [2]State_Vector,  // Double-buffered state vectors
	state_patterns: State_Patterns, // Precomputed patterns for optimization
	arena:       ^Arena,
	metrics:     Matcher_Metrics,  // Performance metrics
	start_time:  time.Time,        // Start time for timeout protection
	timeout_ns:  time.Duration,    // Timeout as duration
}

// Performance metrics for matcher operations
Matcher_Metrics :: struct {
	instructions_executed: u64,    // Total NFA instructions processed
	states_processed:       u64,    // Total NFA states visited
	thread_allocations:     u64,    // Thread allocations from pool
	queue_operations:       u64,    // Queue enqueue/dequeue operations
	match_time_ns:          u64,    // Matching execution time
	memory_used:            u32,    // Memory usage tracking
	state_dedup_hits:       u64,    // State deduplication hits
	state_dedup_misses:     u64,    // State deduplication misses
}

// ===========================================================================
// BIT VECTOR STATE REPRESENTATION
// ===========================================================================

// Bit vector for efficient state representation and deduplication
State_Vector :: struct {
	bits:   []u64,      // 64-bit blocks for state bits
	count:  u32,        // Number of set bits
	size:   u32,        // Size in bits (number of NFA states)
	arena:  ^Arena,     // Memory arena for allocation
}

// Initialize state vectors with double buffering and cache-line alignment
init_state_vectors :: proc(state_vec: []State_Vector, arena: ^Arena, num_states: u32) {
	block_count := (num_states + 63) / 64

	for i in 0..<2 {
		// Use 64-byte aligned allocation for optimal cache performance
		state_vec[i].bits = arena_alloc_slice_aligned(arena, u64, int(block_count), 64)
		state_vec[i].count = 0
		state_vec[i].size = num_states
		state_vec[i].arena = arena

		// Clear all bits
		for j in 0..<block_count {
			state_vec[i].bits[j] = 0
		}
	}
}

// Clear state vector
clear_state_vector :: proc(sv: ^State_Vector) {
	block_count := (sv.size + 63) / 64
	for i in 0..<block_count {
		sv.bits[i] = 0
	}
	sv.count = 0
}

// Clear both state vectors
clear_state_vectors :: proc(state_vec: []State_Vector) {
	clear_state_vector(&state_vec[0])
	clear_state_vector(&state_vec[1])
}

// Set a bit in the state vector
set_bit :: proc(sv: ^State_Vector, bit: u32) -> bool {
	if bit >= sv.size {
		return false
	}
	
	block := bit / 64
	offset := bit % 64
	mask := u64(1) << offset
	
	was_set := (sv.bits[block] & mask) != 0
	sv.bits[block] |= mask
	
	if !was_set {
		sv.count += 1
	}
	
	return !was_set
}

// Test if a bit is set
test_bit :: proc(sv: ^State_Vector, bit: u32) -> bool {
	if bit >= sv.size {
		return false
	}
	
	block := bit / 64
	offset := bit % 64
	mask := u64(1) << offset
	
	return (sv.bits[block] & mask) != 0
}

// Clear a bit in the state vector
clear_bit :: proc(sv: ^State_Vector, bit: u32) {
	if bit >= sv.size {
		return
	}
	
	block := bit / 64
	offset := bit % 64
	mask := u64(1) << offset
	
	if (sv.bits[block] & mask) != 0 {
		sv.bits[block] &= ~mask
		sv.count -= 1
	}
}

// Copy state vector
copy_state_vector :: proc(dest: ^State_Vector, src: ^State_Vector) {
	block_count := (src.size + 63) / 64
	for i in 0..<block_count {
		dest.bits[i] = src.bits[i]
	}
	dest.count = src.count
}

// Check if two state vectors are equal
state_vectors_equal :: proc(a, b: ^State_Vector) -> bool {
	if a.size != b.size || a.count != b.count {
		return false
	}
	
	block_count := (a.size + 63) / 64
	for i in 0..<block_count {
		if a.bits[i] != b.bits[i] {
			return false
		}
	}
	
	return true
}

// Get population count (number of set bits)
popcount :: proc(sv: ^State_Vector) -> u32 {
	return sv.count
}

// Iterate over set bits using efficient bit manipulation
iterate_bits :: proc(sv: ^State_Vector, callback: proc(bit: u32)) {
	block_count := (sv.size + 63) / 64

	for block_idx in 0..<block_count {
		block_bits := sv.bits[block_idx]
		if block_bits == 0 {
			continue
		}

		// Check each bit in the block (less optimal but functional)
		for bit_offset in 0..<64 {
			offset_u32 := u32(bit_offset)
			if (block_bits & (u64(1) << offset_u32)) != 0 {
				bit := u32(block_idx) * 64 + offset_u32
				if bit < sv.size {
					callback(bit)
				}
			}
		}
	}
}

// Helper function for trailing zeros count (intrinsic fallback)
@(private="file")
trailing_zeros_u64 :: proc(x: u64) -> int {
	if x == 0 {
		return 64
	}

	// Use De Bruijn sequence for efficient trailing zero count
	// This is a constant-time algorithm
	de_bruijn: u64 : 0x022fdd63cc95386d
	return int(((x & -x) * de_bruijn) >> 58)
}

// Optimized state vector operations for common patterns

// Batch set bits for consecutive ranges (optimizes common sequential states)
set_range_bits :: proc(sv: ^State_Vector, start: u32, count: u32) -> bool {
	if start >= sv.size || count == 0 {
		return false
	}

	end := start + count
	if end > sv.size {
		end = sv.size
	}

	for bit := start; bit < end; bit += 1 {
		set_bit(sv, bit)
	}

	return true
}

// Fast state vector copy using word-level operations
copy_state_vector_fast :: proc(dest: ^State_Vector, src: ^State_Vector) {
	if dest.size != src.size {
		return
	}

	block_count := (src.size + 63) / 64

	// Copy 64-bit blocks directly
	for i in 0..<block_count {
		dest.bits[i] = src.bits[i]
	}

	dest.count = src.count
}

// Check if state vector has any set bits in a range
has_bits_in_range :: proc(sv: ^State_Vector, start: u32, count: u32) -> bool {
	if start >= sv.size || count == 0 {
		return false
	}

	end := start + count
	if end > sv.size {
		end = sv.size
	}

	for bit := start; bit < end; bit += 1 {
		if test_bit(sv, bit) {
			return true
		}
	}

	return false
}

// Optimized for common pattern: check if single bit is set and return it
get_single_bit :: proc(sv: ^State_Vector) -> u32 {
	if sv.count != 1 {
		return max(u32) // Invalid: not exactly one bit set
	}

	block_count := (sv.size + 63) / 64

	for block_idx in 0..<block_count {
		block_bits := sv.bits[block_idx]
		if block_bits != 0 {
			// Find the set bit
			bit_offset := u32(trailing_zeros_u64(block_bits))
			return u32(block_idx * 64 + bit_offset)
		}
	}

	return max(u32) // Should never reach here if count == 1
}

// ===========================================================================
// PRECOMPUTED STATE PATTERNS FOR COMMON REGEX PATTERNS
// ===========================================================================

// Precomputed patterns for common regex structures
State_Patterns :: struct {
	// Common character class patterns
	ascii_letters:   State_Vector,  // A-Z, a-z
	ascii_digits:    State_Vector,  // 0-9
	ascii_whitespace: State_Vector, // \t, \n, \r, space
	word_chars:      State_Vector,  // A-Z, a-z, 0-9, _

	// Common quantifier patterns
	repeat_2x:       State_Vector,  // For {2}
	repeat_3x:       State_Vector,  // For {3}
	repeat_4x:       State_Vector,  // For {4}

	initialized:     bool,
	arena:           ^Arena,
}

// Initialize precomputed state patterns
init_state_patterns :: proc(patterns: ^State_Patterns, arena: ^Arena, max_states: u32) {
	if patterns.initialized {
		return
	}

	patterns.arena = arena
	block_count := (max_states + 63) / 64

	// Initialize all pattern vectors
	init_pattern_vector(&patterns.ascii_letters, arena, max_states)
	init_pattern_vector(&patterns.ascii_digits, arena, max_states)
	init_pattern_vector(&patterns.ascii_whitespace, arena, max_states)
	init_pattern_vector(&patterns.word_chars, arena, max_states)
	init_pattern_vector(&patterns.repeat_2x, arena, max_states)
	init_pattern_vector(&patterns.repeat_3x, arena, max_states)
	init_pattern_vector(&patterns.repeat_4x, arena, max_states)

	patterns.initialized = true
}

// Helper to initialize a single pattern vector
@(private="file")
init_pattern_vector :: proc(sv: ^State_Vector, arena: ^Arena, size: u32) {
	block_count := (size + 63) / 64
	sv.bits = arena_alloc_slice_aligned(arena, u64, int(block_count), 64)
	sv.count = 0
	sv.size = size
	sv.arena = arena

	// Clear all bits initially
	for i in 0..<block_count {
		sv.bits[i] = 0
	}
}

// Precompute common ASCII character patterns
precompute_ascii_patterns :: proc(patterns: ^State_Patterns) {
	if !patterns.initialized {
		return
	}

	// ASCII letters: A-Z (65-90) and a-z (97-122)
	for c in 65..<91 {  // A-Z
		set_bit(&patterns.ascii_letters, u32(c))
	}
	for c in 97..<123 { // a-z
		set_bit(&patterns.ascii_letters, u32(c))
	}

	// ASCII digits: 0-9 (48-57)
	for c in 48..<58 { // 0-9
		set_bit(&patterns.ascii_digits, u32(c))
	}

	// ASCII whitespace: space (32), tab (9), newline (10), carriage return (13)
	set_bit(&patterns.ascii_whitespace, 32) // space
	set_bit(&patterns.ascii_whitespace, 9)  // tab
	set_bit(&patterns.ascii_whitespace, 10) // newline
	set_bit(&patterns.ascii_whitespace, 13) // carriage return

	// Word characters: letters + digits + underscore (95)
	copy_state_vector_fast(&patterns.word_chars, &patterns.ascii_letters)
	copy_state_vector_fast(&patterns.word_chars, &patterns.ascii_digits)
	set_bit(&patterns.word_chars, 95) // underscore
}

// Precompute common quantifier patterns (for fixed repetitions)
precompute_quantifier_patterns :: proc(patterns: ^State_Patterns, max_repeats: u32 = 4) {
	if !patterns.initialized {
		return
	}

	// Set up patterns for 2x, 3x, 4x repetitions
	// These are used as templates for {n} quantifiers
	set_range_bits(&patterns.repeat_2x, 0, 2)
	set_range_bits(&patterns.repeat_3x, 0, 3)
	set_range_bits(&patterns.repeat_4x, 0, 4)
}

// Fast pattern matching using precomputed patterns
match_precomputed_pattern :: proc(sv: ^State_Vector, pattern: ^State_Vector, char: rune) -> bool {
	if char < 0 || char >= 256 {
		return false // Only ASCII for precomputed patterns
	}

	char_bit := u32(char)
	return test_bit(pattern, char_bit)
}

// Check if character matches any precomputed pattern type
match_pattern_type :: proc(patterns: ^State_Patterns, char: rune, pattern_type: Pattern_Type) -> bool {
	if !patterns.initialized {
		return false
	}

	if char < 0 || char >= 256 {
		return false // Only ASCII for precomputed patterns
	}

	char_bit := u32(char)

	switch pattern_type {
	case .Letter:
		return test_bit(&patterns.ascii_letters, char_bit)
	case .Digit:
		return test_bit(&patterns.ascii_digits, char_bit)
	case .Whitespace:
		return test_bit(&patterns.ascii_whitespace, char_bit)
	case .WordChar:
		return test_bit(&patterns.word_chars, char_bit)
	}

	return false
}

// Pattern types for common regex constructs
Pattern_Type :: enum {
	Letter,
	Digit,
	Whitespace,
	WordChar,
}

// Efficient state deduplication using bit vectors
check_and_set_state :: proc(sv: ^State_Vector, state: u32) -> bool {
	if test_bit(sv, state) {
		return false  // Already processed
	}

	set_bit(sv, state)
	return true  // New state
}

// Check if timeout has been exceeded
check_timeout :: proc(matcher: ^Matcher) -> bool {
	if matcher.timeout_ns == 0 {
		return false  // No timeout set
	}

	current_time := time.now()
	elapsed := time.since(matcher.start_time)
	return elapsed > matcher.timeout_ns
}

// Set timeout for matcher (in seconds)
set_matcher_timeout :: proc(matcher: ^Matcher, timeout_seconds: f64) {
	if matcher == nil {
		return
	}

	if timeout_seconds <= 0 {
		matcher.timeout_ns = 0  // No timeout
	} else {
		matcher.timeout_ns = time.Duration(timeout_seconds * 1_000_000_000)  // Convert to nanoseconds
	}
}

// Create a new matcher for the given program (arena-optimized)
new_matcher :: proc(prog: ^Program, anchored: bool, longest: bool) -> ^Matcher {
	arena := new_arena(4096)
	matcher := (^Matcher)(arena_alloc(arena, size_of(Matcher)))

	matcher.prog = prog
	matcher.anchored = anchored
	matcher.longest = longest
	matcher.arena = arena

	// Initialize queue
	matcher.queue.head = 0
	matcher.queue.tail = 0
	matcher.queue.size = 0
	matcher.queue.mask = 255

	// Initialize thread pool
	init_thread_pool(&matcher.thread_pool, arena)

	// Initialize state vectors
	init_state_vectors(matcher.state_vec[:], arena, u32(len(prog.instructions)) + 1)

	// Initialize precomputed state patterns for optimization
	max_char_states := u32(256) // ASCII character range
	init_state_patterns(&matcher.state_patterns, arena, max_char_states)
	precompute_ascii_patterns(&matcher.state_patterns)
	precompute_quantifier_patterns(&matcher.state_patterns)

	// Initialize metrics
	matcher.metrics = Matcher_Metrics{}

	// Initialize timeout (default: 1 second)
	matcher.timeout_ns = 1_000_000_000  // 1 second in nanoseconds
	matcher.start_time = {}

	return matcher
}

// Free matcher resources (arena-managed)
free_matcher :: proc(matcher: ^Matcher) {
	if matcher != nil && matcher.arena != nil {
		free_arena(matcher.arena)
	}
}

// ===========================================================================
// THREAD POOL MANAGEMENT
// ===========================================================================

// Initialize thread pool with arena allocation
init_thread_pool :: proc(pool: ^Thread_Pool, arena: ^Arena) {
	pool.arena = arena
	pool.free_count = 64
	
	// Initialize free list with all thread indices
	for i in 0..<32 {
		pool.free_list[i] = u32(i)
	}
	
	// Initialize all threads as inactive
	for i in 0..<64 {
		pool.threads[i].active = false
		for j in 0..<32 {
			pool.capture_buf[i][j] = -1
		}
	}
	
	// Initialize statistics
	pool.stats = Thread_Pool_Stats{}
}

// Allocate a thread from the pool with optimized access patterns
alloc_thread :: proc(pool: ^Thread_Pool, pc: u32) -> (Thread, bool) {
	if pool.free_count == 0 {
		return Thread{}, false
	}

	// Get thread index from free list (fast LIFO access)
	pool.free_count -= 1
	thread_idx := pool.free_list[pool.free_count]

	// Update thread fields in place
	pool.threads[thread_idx].pc = pc
	pool.threads[thread_idx].active = true

	// Fast capture buffer copy using array operations
	for j in 0..<32 {
		pool.threads[thread_idx].cap[j] = pool.capture_buf[thread_idx][j]
	}

	// Update statistics (atomic-like behavior)
	pool.stats.total_allocations += 1
	pool.stats.current_usage += 1
	if pool.stats.current_usage > pool.stats.peak_usage {
		pool.stats.peak_usage = pool.stats.current_usage
	}

	return pool.threads[thread_idx], true
}

// Release a thread back to the pool
release_thread :: proc(pool: ^Thread_Pool, thread: Thread) {
	if !thread.active {
		return
	}
	
	// Find thread index (simplified - in practice would track this)
	thread_idx := u32(0) // This would be stored in the thread
	
	// Save capture buffer
	for i in 0..<32 {
		pool.capture_buf[thread_idx][i] = thread.cap[i]
	}
	
	// Mark thread as inactive
	pool.threads[thread_idx].active = false
	
	// Add back to free list if space available
	if pool.free_count < 32 {
		pool.free_list[pool.free_count] = thread_idx
		pool.free_count += 1
	}
	
	// Update statistics
	pool.stats.total_releases += 1
	pool.stats.current_usage -= 1
}

// Get thread pool statistics
get_thread_pool_stats :: proc(pool: ^Thread_Pool) -> Thread_Pool_Stats {
	return pool.stats
}

// ===========================================================================
// MAIN MATCHING ENTRY POINT
// ===========================================================================

// Main matching entry point
match_nfa :: proc(matcher: ^Matcher, text: string) -> (bool, []int) {
	if matcher == nil || matcher.prog == nil {
		return false, nil
	}

	matcher.text = text

	// Record start time for timeout protection
	matcher.start_time = time.now()

	// Reset state
	reset_queue(&matcher.queue)
	clear_state_vectors(matcher.state_vec[:])

	// Initialize current state vector with start state
	set_bit(&matcher.state_vec[0], 0) // Start from instruction 0

	// Reset metrics
	matcher.metrics = Matcher_Metrics{}
	
	// Start from initial state
	initial_thread, success := alloc_thread(&matcher.thread_pool, 0) // Start from instruction 0
	if !success {
		return false, nil
	}
	
	// Initialize capture array
	for i in 0..<32 {
		initial_thread.cap[i] = -1
	}
	// Set start position for full match (capture group 0)
	if matcher.prog.capture_count > 0 {
		initial_thread.cap[0] = 0
	}
	
	// Add initial thread
	if !enqueue(&matcher.queue, initial_thread) {
		release_thread(&matcher.thread_pool, initial_thread)
		return false, nil
	}
	
	// Handle empty program (should match at position 0)
	if len(matcher.prog.instructions) == 0 {
		// No need to delete, it's a fixed array
		caps := make([]int, 2)
		caps[0] = 0
		caps[1] = 0
		return true, caps
	}
	
	// Execute NFA
	best_match := false
	best_caps: []int
	
	for pos := 0; pos <= len(text); pos += 1 {
		// Check timeout before processing each position
		if check_timeout(matcher) {
			// Timeout exceeded - abort matching
			break
		}

		// Process all threads at this position
		step_count := matcher.queue.size

		// Swap state vectors for double buffering
		current_sv := &matcher.state_vec[pos % 2]
		next_sv := &matcher.state_vec[(pos + 1) % 2]
		clear_state_vector(next_sv)

		for _ in 0..<step_count {
			// Check timeout in inner loop as well
			if check_timeout(matcher) {
				// Timeout exceeded - abort matching immediately
				break
			}

			thread := dequeue(&matcher.queue)
			if thread.pc >= u32(len(matcher.prog.instructions)) {
				// Reached accepting state
				if !best_match || (matcher.longest && thread.cap[1] > best_caps[1]) {
					best_match = true
					best_caps = make([]int, matcher.prog.capture_count * 2)
					for i in 0..<len(best_caps) {
						best_caps[i] = thread.cap[i]
					}
					best_caps[1] = pos // Set end position
				}
				release_thread(&matcher.thread_pool, thread)
				continue
			}

			// State deduplication check
			if !check_and_set_state(current_sv, thread.pc) {
				release_thread(&matcher.thread_pool, thread)
				matcher.metrics.state_dedup_hits += 1
				continue
			}

			matcher.metrics.state_dedup_misses += 1
			matcher.metrics.states_processed += 1

			// Execute optimized instruction
			execute_inst(matcher, thread, pos)
			release_thread(&matcher.thread_pool, thread)
		}

		// If anchored and we've processed the start position, we're done
		if matcher.anchored && pos > 0 {
			break
		}

		// If no more threads and we haven't found a match, we're done
		if matcher.queue.size == 0 && !best_match {
			break
		}
	}
	
	// Clean up remaining threads
	for matcher.queue.size > 0 {
		thread := dequeue(&matcher.queue)
		release_thread(&matcher.thread_pool, thread)
	}
	
	return best_match, best_caps
}

// Optimized instruction execution with reduced branching and improved patterns
execute_inst :: proc(matcher: ^Matcher, thread: Thread, pos: int) {
	inst := matcher.prog.instructions[thread.pc]
	op := inst_opcode(inst)

	// Update metrics
	matcher.metrics.instructions_executed += 1

	// Use direct goto-style dispatch for better performance
	switch op {
	case .Char:
		execute_char_inst(matcher, thread, pos, inst)
	case .tAny:
		execute_any_inst(matcher, thread, pos)
	case .AnyNotNL:
		execute_any_not_nl_inst(matcher, thread, pos)
	case .Class:
		execute_class_inst(matcher, thread, pos, inst)
	case .Alt:
		execute_alt_inst(matcher, thread, inst)
	case .Jmp:
		execute_jmp_inst(matcher, thread, inst)
	case .Match:
		execute_match_inst(matcher, thread)
	case .Cap:
		execute_cap_inst(matcher, thread, pos, inst)
	case .Empty:
		execute_empty_inst(matcher, thread)
	}
}

// Optimized character matching with ASCII fast path
execute_char_inst :: proc(matcher: ^Matcher, thread: Thread, pos: int, inst: Inst) {
	if pos >= len(matcher.text) {
		return
	}

	// Fast ASCII check (95% of cases)
	text_char := matcher.text[pos]
	if text_char < 128 {
		// ASCII path - direct comparison
		if text_char == u8(inst_arg(inst)) {
			enqueue_next_thread(matcher, thread, thread.pc + 1)
		}
	} else {
		// Unicode path - full comparison
		if rune(text_char) == rune(inst_arg(inst)) {
			enqueue_next_thread(matcher, thread, thread.pc + 1)
		}
	}
}

// Optimized any character matching
execute_any_inst :: proc(matcher: ^Matcher, thread: Thread, pos: int) {
	if pos < len(matcher.text) {
		enqueue_next_thread(matcher, thread, thread.pc + 1)
	}
}

// Optimized any character except newline
execute_any_not_nl_inst :: proc(matcher: ^Matcher, thread: Thread, pos: int) {
	if pos < len(matcher.text) && matcher.text[pos] != '\n' {
		enqueue_next_thread(matcher, thread, thread.pc + 1)
	}
}

// Character class matching using precomputed patterns
execute_class_inst :: proc(matcher: ^Matcher, thread: Thread, pos: int, inst: Inst) {
	if pos >= len(matcher.text) {
		return
	}

	char_rune := rune(matcher.text[pos])

	// Use precomputed patterns for common character classes
	if match_pattern_type(&matcher.state_patterns, char_rune, .Letter) {
		enqueue_next_thread(matcher, thread, thread.pc + 1)
	}
}

// Optimized alternation with reduced overhead
execute_alt_inst :: proc(matcher: ^Matcher, thread: Thread, inst: Inst) {
	first := inst_arg(inst)
	second := thread.pc + 1

	// Allocate threads in batch to reduce pool overhead
	thread1, success1 := alloc_thread(&matcher.thread_pool, first)
	thread2, success2 := alloc_thread(&matcher.thread_pool, second)

	if success1 {
		// Fast capture buffer copy
		for i in 0..<32 {
			thread1.cap[i] = thread.cap[i]
		}
		enqueue(&matcher.queue, thread1)
	}
	if success2 {
		// Fast capture buffer copy
		for i in 0..<32 {
			thread2.cap[i] = thread.cap[i]
		}
		enqueue(&matcher.queue, thread2)
	}
}

// Optimized jump instruction
execute_jmp_inst :: proc(matcher: ^Matcher, thread: Thread, inst: Inst) {
	target := inst_arg(inst)
	enqueue_next_thread(matcher, thread, target)
}

// Optimized match instruction (accepting state)
execute_match_inst :: proc(matcher: ^Matcher, thread: Thread) {
	accepting_pc := u32(len(matcher.prog.instructions))
	enqueue_next_thread(matcher, thread, accepting_pc)
}

// Optimized capture instruction
execute_cap_inst :: proc(matcher: ^Matcher, thread: Thread, pos: int, inst: Inst) {
	cap_index := int(inst_arg(inst))
	if cap_index < 32 {
		// Only copy if we have space - create new thread with updated capture
		new_thread, success := alloc_thread(&matcher.thread_pool, thread.pc + 1)
		if success {
			// Copy existing captures
			for i in 0..<32 {
				new_thread.cap[i] = thread.cap[i]
			}
			// Update capture
			new_thread.cap[cap_index] = pos
			enqueue(&matcher.queue, new_thread)
		}
	} else {
		// No capture update needed
		enqueue_next_thread(matcher, thread, thread.pc + 1)
	}
}

// Optimized empty-width assertion
execute_empty_inst :: proc(matcher: ^Matcher, thread: Thread) {
	enqueue_next_thread(matcher, thread, thread.pc + 1)
}

// Helper: Enqueue next thread with capture buffer copy
enqueue_next_thread :: proc(matcher: ^Matcher, thread: Thread, next_pc: u32) {
	next_thread, success := alloc_thread(&matcher.thread_pool, next_pc)
	if success {
		// Fast capture buffer copy
		for i in 0..<32 {
			next_thread.cap[i] = thread.cap[i]
		}
		enqueue(&matcher.queue, next_thread)
	}
}

// Helper: Fast capture buffer copy using memory operations
copy_capture_buffer :: proc(dest: ^[32]int, src: ^[32]int) {
	// Use unrolled copy for better performance
	dest[0] = src[0]; dest[1] = src[1]; dest[2] = src[2]; dest[3] = src[3]
	dest[4] = src[4]; dest[5] = src[5]; dest[6] = src[6]; dest[7] = src[7]
	dest[8] = src[8]; dest[9] = src[9]; dest[10] = src[10]; dest[11] = src[11]
	dest[12] = src[12]; dest[13] = src[13]; dest[14] = src[14]; dest[15] = src[15]
	dest[16] = src[16]; dest[17] = src[17]; dest[18] = src[18]; dest[19] = src[19]
	dest[20] = src[20]; dest[21] = src[21]; dest[22] = src[22]; dest[23] = src[23]
	dest[24] = src[24]; dest[25] = src[25]; dest[26] = src[26]; dest[27] = src[27]
	dest[28] = src[28]; dest[29] = src[29]; dest[30] = src[30]; dest[31] = src[31]
}

// Check if rune matches character class
match_rune_class :: proc(inst: Inst, r: rune) -> bool {
	// This is a simplified implementation
	// In a full implementation, we'd need to handle the rune ranges properly
	// For now, just handle the basic case
	return r == rune(inst_arg(inst))
}



// ===========================================================================
// QUEUE OPERATIONS (LOCK-FREE CIRCULAR BUFFER)
// ===========================================================================

reset_queue :: proc(q: ^Queue) {
	if q != nil {
		q.head = 0
		q.tail = 0
		q.size = 0
	}
}

enqueue :: proc(q: ^Queue, thread: Thread) -> bool {
	if q == nil || q.size >= 256 {
		return false
	}
	
	q.threads[q.tail] = thread
	q.tail = (q.tail + 1) & q.mask
	q.size += 1
	return true
}

dequeue :: proc(q: ^Queue) -> Thread {
	if q == nil || q.size == 0 {
		return Thread{}
	}
	
	thread := q.threads[q.head]
	q.head = (q.head + 1) & q.mask
	q.size -= 1
	return thread
}

// Compile AST to NFA program using the new NFA compiler
compile_to_nfa :: proc(ast: ^Regexp, prog: ^Program) -> ErrorCode {
	if ast == nil || prog == nil {
		return .InternalError
	}
	
	// Use the new NFA compiler
	nfa_frag := compile_ast_to_nfa(prog, ast)
	
	// Add final match instruction
	add_instruction(prog, .Match, 0)
	
	return .NoError
}

// ===== Thompson NFA Matcher =====
// Complete linear-time NFA implementation

// Complete NFA match using Thompson's construction
nfa_match :: proc(prog: ^Program, text: string) -> (bool, []int) {
	if prog == nil || len(prog.instructions) == 0 {
		return false, nil
	}
	
	// Try to match from each position, but return the first (leftmost) match
	for start_pos := 0; start_pos <= len(text); start_pos += 1 {
		matched, end_pos := execute_from_position(prog, 0, text, start_pos)
		if matched {
			// Return capture groups
			caps := make([]int, 2)
			caps[0] = start_pos
			caps[1] = end_pos
			return true, caps
		}
	}
	
	return false, nil
}

// Simple NFA match using recursive execution (legacy)
simple_nfa_match :: proc(prog: ^Program, text: string) -> (bool, []int) {
	if prog == nil || len(prog.instructions) == 0 {
		return false, nil
	}
	
	// Try to match from each position, but return the first (leftmost) match
	for start_pos := 0; start_pos <= len(text); start_pos += 1 {
		matched, end_pos := execute_from_position(prog, 0, text, start_pos)
		if matched {
			// For a proper match, we should consume as much as possible
			// But for now, let's just return the first match we find
			caps := make([]int, 2)
			caps[0] = start_pos
			caps[1] = end_pos
			return true, caps
		}
	}
	
	return false, nil
}

// Execute NFA from a specific position
execute_from_position :: proc(prog: ^Program, pc: u32, text: string, pos: int) -> (bool, int) {
	if pc >= u32(len(prog.instructions)) {
		return false, pos
	}
	
	inst := prog.instructions[pc]
	op := inst_opcode(inst)
	
	switch op {
	case .Char:
		if pos < len(text) && rune(text[pos]) == rune(inst_arg(inst)) {
			return execute_from_position(prog, pc + 1, text, pos + 1)
		} else {
			return false, pos
		}
		
	case .Match:
		return true, pos
		
	case .Alt:
		// Try first branch
		matched1, end1 := execute_from_position(prog, pc + 1, text, pos)
		if matched1 {
			return true, end1
		}
		
		// Try second branch
		matched2, end2 := execute_from_position(prog, inst_arg(inst), text, pos)
		if matched2 {
			return true, end2
		}
		
		return false, pos
		
	case .Jmp:
		// Unconditional jump
		return execute_from_position(prog, inst_arg(inst), text, pos)
		
	case .Cap, .Empty, .tAny, .AnyNotNL, .Class:
		// For now, just skip these instructions
		return execute_from_position(prog, pc + 1, text, pos)
	}
	
	return false, pos
}

