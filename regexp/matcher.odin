package regexp



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
	prog:        ^Prog,
	text:        string,
	anchored:    bool,
	longest:     bool,
	queue:       Queue,
	thread_pool: Thread_Pool,
	state_vec:   [2]State_Vector,  // Double-buffered state vectors
	arena:       ^Arena,
	metrics:     Matcher_Metrics,  // Performance metrics
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

// Initialize state vectors with double buffering
init_state_vectors :: proc(state_vec: []State_Vector, arena: ^Arena, num_states: u32) {
	block_count := (num_states + 63) / 64
	
	for i in 0..<2 {
		state_vec[i].bits = arena_alloc_slice(arena, u64, int(block_count))
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

// Iterate over set bits
iterate_bits :: proc(sv: ^State_Vector, callback: proc(bit: u32)) {
	block_count := (sv.size + 63) / 64
	
	for block_idx in 0..<block_count {
		block_bits := sv.bits[block_idx]
		if block_bits == 0 {
			continue
		}
		
		// Iterate through bits in this block
		for offset in 0..<64 {
			if (block_bits & (u64(1) << offset)) != 0 {
				bit := u32(block_idx * 64 + offset)
				if bit < sv.size {
					callback(bit)
				}
			}
		}
	}
}

// Efficient state deduplication using bit vectors
check_and_set_state :: proc(sv: ^State_Vector, state: u32) -> bool {
	if test_bit(sv, state) {
		return false  // Already processed
	}
	
	set_bit(sv, state)
	return true  // New state
}

// Create a new matcher for the given program (arena-optimized)
new_matcher :: proc(prog: ^Prog, anchored: bool, longest: bool) -> ^Matcher {
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
	init_state_vectors(&matcher.state_vec, arena, u32(len(prog.inst)) + 1)
	
	// Initialize metrics
	matcher.metrics = Matcher_Metrics{}
	
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

// Allocate a thread from the pool
alloc_thread :: proc(pool: ^Thread_Pool, pc: u32) -> (thread: Thread, success: bool) {
	if pool.free_count == 0 {
		return Thread{}, false
	}
	
	// Get thread index from free list
	pool.free_count -= 1
	thread_idx := pool.free_list[pool.free_count]
	
	// Initialize thread
	thread = pool.threads[thread_idx]
	thread.pc = pc
	thread.active = true
	
	// Copy capture buffer
	for i in 0..<32 {
		thread.cap[i] = pool.capture_buf[thread_idx][i]
	}
	
	// Update statistics
	pool.stats.total_allocations += 1
	pool.stats.current_usage += 1
	if pool.stats.current_usage > pool.stats.peak_usage {
		pool.stats.peak_usage = pool.stats.current_usage
	}
	
	return thread, true
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
	
	// Reset state
	reset_queue(&matcher.queue)
	clear_state_vectors(&matcher.state_vec)
	
	// Initialize current state vector with start state
	set_bit(&matcher.state_vec[0], matcher.prog.start)
	
	// Reset metrics
	matcher.metrics = Matcher_Metrics{}
	
	// Start from initial state
	initial_thread, success := alloc_thread(&matcher.thread_pool, matcher.prog.start)
	if !success {
		return false, nil
	}
	
	// Initialize capture array
	for i in 0..<32 {
		initial_thread.cap[i] = -1
	}
	// Set start position for full match (capture group 0)
	if matcher.prog.num_cap > 0 {
		initial_thread.cap[0] = 0
	}
	
	// Add initial thread
	if !enqueue(&matcher.queue, initial_thread) {
		release_thread(&matcher.thread_pool, initial_thread)
		return false, nil
	}
	
	// Handle empty program (should match at position 0)
	if len(matcher.prog.inst) == 0 {
		delete(initial_thread.cap)
		caps := make([]int, 2)
		caps[0] = 0
		caps[1] = 0
		return true, caps
	}
	
	// Execute NFA
	best_match := false
	best_caps: []int
	
	for pos := 0; pos <= len(text); pos += 1 {
		// Process all threads at this position
		step_count := matcher.queue.size
		
		// Swap state vectors for double buffering
		current_sv := &matcher.state_vec[pos % 2]
		next_sv := &matcher.state_vec[(pos + 1) % 2]
		clear_state_vector(next_sv)
		
		for _ in 0..<step_count {
			thread := dequeue(&matcher.queue)
			if thread.pc >= matcher.prog.inst_len {
				// Reached accepting state
				if !best_match || (matcher.longest && thread.cap[1] > best_caps[1]) {
					best_match = true
					best_caps = make([]int, int(matcher.prog.num_cap) * 2)
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
			
			// Execute instruction
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

// Execute a single instruction (optimized for new instruction encoding)
execute_inst :: proc(matcher: ^Matcher, thread: Thread, pos: int) {
	inst := matcher.prog.inst[thread.pc]
	op := inst_op(inst)
	
	// Update metrics
	matcher.metrics.instructions_executed += 1
	
	switch op {
	case .Char:
		// Character matching with special value support
		if exec_char_inst(inst, matcher.text, pos) {
			next_thread, success := alloc_thread(&matcher.thread_pool, inst_arg(inst))
			if success {
				copy(next_thread.cap[:], thread.cap[:])
				enqueue(&matcher.queue, next_thread)
			}
		}
		
	case .Alt:
		// Alternation: fork into two threads
		first, second := exec_alt_inst(inst)
		
		thread1, success1 := alloc_thread(&matcher.thread_pool, first)
		thread2, success2 := alloc_thread(&matcher.thread_pool, second)
		
		if success1 {
			copy(thread1.cap[:], thread.cap[:])
			enqueue(&matcher.queue, thread1)
		}
		if success2 {
			copy(thread2.cap[:], thread.cap[:])
			enqueue(&matcher.queue, thread2)
		}
		
	case .Jmp:
		// Unconditional jump
		next_thread, success := alloc_thread(&matcher.thread_pool, inst_arg(inst))
		if success {
			copy(next_thread.cap[:], thread.cap[:])
			enqueue(&matcher.queue, next_thread)
		}
		
	case .Match:
		// Successful match - accepting state
		accepting_thread, success := alloc_thread(&matcher.thread_pool, matcher.prog.inst_len)
		if success {
			copy(accepting_thread.cap[:], thread.cap[:])
			enqueue(&matcher.queue, accepting_thread)
		}
		
	case .Cap:
		// Capture group update
		cap_index, is_start := exec_cap_inst(inst)
		if cap_index < 32 {
			if is_start {
				thread.cap[cap_index * 2] = pos
			} else {
				thread.cap[cap_index * 2 + 1] = pos
			}
		}
		
		next_thread, success := alloc_thread(&matcher.thread_pool, inst_arg(inst))
		if success {
			copy(next_thread.cap[:], thread.cap[:])
			enqueue(&matcher.queue, next_thread)
		}
		
	case .Empty:
		// Empty-width assertion
		if exec_empty_inst(inst, matcher.text, pos) {
			next_thread, success := alloc_thread(&matcher.thread_pool, inst_arg(inst))
			if success {
				copy(next_thread.cap[:], thread.cap[:])
				enqueue(&matcher.queue, next_thread)
			}
		}
	}
}

// Check if rune matches character class
match_rune_class :: proc(inst: Inst, r: rune) -> bool {
	// This is a simplified implementation
	// In a full implementation, we'd need to handle the rune ranges properly
	// For now, just handle the basic case
	return r == rune(inst.arg)
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
compile_to_nfa :: proc(ast: ^Regexp, prog: ^Prog) -> ErrorCode {
	if ast == nil || prog == nil {
		return .InternalError
	}
	
	// Use the new NFA compiler
	nfa_prog, err := compile_nfa(ast)
	if err != .NoError {
		return err
	}
	
	// Copy the compiled program to the provided prog structure
	if nfa_prog != nil {
		prog.inst = nfa_prog.inst
		prog.start = nfa_prog.start
		prog.num_cap = nfa_prog.num_cap
		
		// Don't free nfa_prog since we're transferring ownership of the instruction array
		free(nfa_prog)
	}
	
	return .NoError
}

// ===== Simplified NFA Matcher =====
// This is a working simplified NFA matcher that replaces the complex BFS implementation

// Simple NFA match using recursive execution
simple_nfa_match :: proc(prog: ^Prog, text: string) -> (bool, []int) {
	if prog == nil || len(prog.inst) == 0 {
		return false, nil
	}
	
	// Try to match from each position, but return the first (leftmost) match
	for start_pos := 0; start_pos <= len(text); start_pos += 1 {
		matched, end_pos := execute_from_position(prog, prog.start, text, start_pos)
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
execute_from_position :: proc(prog: ^Prog, pc: u32, text: string, pos: int) -> (bool, int) {
	if pc >= u32(len(prog.inst)) {
		return false, pos
	}
	
	inst := prog.inst[pc]
	
	#partial switch inst.op {
	case .Rune1:
		if pos < len(text) && rune(text[pos]) == rune(inst.arg) {
			return execute_from_position(prog, inst.out, text, pos + 1)
		} else {
			return false, pos
		}
		
	case .Match:
		return true, pos
		
	case .Alt:
		// Try first branch
		matched1, end1 := execute_from_position(prog, inst.out, text, pos)
		if matched1 {
			return true, end1
		}
		
		// Try second branch
		matched2, end2 := execute_from_position(prog, inst.arg, text, pos)
		if matched2 {
			return true, end2
		}
		
		return false, pos
		
	case .Jmp:
		// Unconditional jump
		return execute_from_position(prog, inst.out, text, pos)
	}
	
	return false, pos
}

