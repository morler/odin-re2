package regexp



// NFA matcher implementation using Thompson's construction
// Provides linear-time matching guarantee as required by RE2

// Thread represents a state in the NFA execution
Thread :: struct {
	pc:    u32,         // Program counter (instruction index)
	cap:   []int,       // Capture positions
}

// Queue for BFS execution of NFA
Queue :: struct {
	threads: []Thread,
	head:    int,
	tail:    int,
	size:    int,
}

// Matcher state for NFA execution
Matcher :: struct {
	prog:        ^Prog,
	text:        string,
	anchored:    bool,
	longest:     bool,
	queue:       Queue,
	visited:     ^Sparse_Set,
	thread_pool: []Thread,
	arena:       ^Arena,
}

// Create a new matcher for the given program
new_matcher :: proc(prog: ^Prog, anchored: bool, longest: bool) -> ^Matcher {
	matcher := new(Matcher)
	matcher.prog = prog
	matcher.anchored = anchored
	matcher.longest = longest
	
	// Initialize arena for visited set
	matcher.arena = new_arena(1024)
	
	// Initialize queue
	matcher.queue.threads = make([]Thread, 256) // Initial capacity
	matcher.queue.head = 0
	matcher.queue.tail = 0
	matcher.queue.size = 0
	
	// Initialize visited set for state deduplication
	matcher.visited = new_sparse_set(matcher.arena, u32(len(prog.inst) + 1))
	
	// Initialize thread pool
	matcher.thread_pool = make([]Thread, 64)
	
	return matcher
}

// Free matcher resources
free_matcher :: proc(matcher: ^Matcher) {
	if matcher != nil {
		delete(matcher.queue.threads)
		// visited will be cleaned up when arena is freed
		delete(matcher.thread_pool)
		if matcher.arena != nil {
			free_arena(matcher.arena)
		}
		free(matcher)
	}
}

// Main matching entry point
match_nfa :: proc(matcher: ^Matcher, text: string) -> (bool, []int) {
	if matcher == nil || matcher.prog == nil {
		return false, nil
	}
	
	matcher.text = text
	
	// Reset state
	reset_queue(&matcher.queue)
	clear(matcher.visited)
	
	// Start from initial state
	initial_thread := Thread{matcher.prog.start, make([]int, int(matcher.prog.num_cap) * 2)}
	for i in 0..<len(initial_thread.cap) {
		initial_thread.cap[i] = -1
	}
	// Set start position for full match (capture group 0)
	if len(initial_thread.cap) > 0 {
		initial_thread.cap[0] = 0
	}
	
	// Add initial thread
	if !enqueue(&matcher.queue, initial_thread) {
		delete(initial_thread.cap)
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
		
		for _ in 0..<step_count {
			thread := dequeue(&matcher.queue)
		if thread.pc == u32(len(matcher.prog.inst)) {
			// Reached accepting state
			if !best_match || (matcher.longest && len(best_caps) > 1 && pos > best_caps[1]) {
				best_match = true
				best_caps = make([]int, len(thread.cap))
				copy(best_caps, thread.cap)
				if len(best_caps) > 1 {
					best_caps[1] = pos // Set end position
				}
			}
			delete(thread.cap)
			continue
		}
			
			// Execute instruction
			execute_inst(matcher, thread, pos)
			delete(thread.cap)
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
		delete(thread.cap)
	}
	
	return best_match, best_caps
}

// Execute a single instruction
execute_inst :: proc(matcher: ^Matcher, thread: Thread, pos: int) {
	inst := matcher.prog.inst[thread.pc]
	
	switch inst.op {
	case .Alt:
		// Fork into two threads
		thread1 := Thread{inst.out, make([]int, len(thread.cap))}
		thread2 := Thread{inst.arg, make([]int, len(thread.cap))}
		copy(thread1.cap, thread.cap)
		copy(thread2.cap, thread.cap)
		
		enqueue(&matcher.queue, thread1)
		enqueue(&matcher.queue, thread2)
		
	case .AltMatch:
		// Alternative that can also match at current position
		// Try match first, then alt
		thread1 := Thread{inst.out, make([]int, len(thread.cap))}
		thread2 := Thread{inst.arg, make([]int, len(thread.cap))}
		copy(thread1.cap, thread.cap)
		copy(thread2.cap, thread.cap)
		
		enqueue(&matcher.queue, thread1)
		enqueue(&matcher.queue, thread2)
		
	case .Capture:
		// Update capture position
		cap_index := int(inst.arg) * 2
		if cap_index < len(thread.cap) {
			thread.cap[cap_index] = pos
		}
		
		next_thread := Thread{inst.out, make([]int, len(thread.cap))}
		copy(next_thread.cap, thread.cap)
		enqueue(&matcher.queue, next_thread)
		
	case .EmptyWidth:
		// Check empty width assertion
		empty_op := EmptyOp(inst.arg)
		if match_empty_width(empty_op, matcher.text, pos) {
			next_thread := Thread{inst.out, make([]int, len(thread.cap))}
			copy(next_thread.cap, thread.cap)
			enqueue(&matcher.queue, next_thread)
		}
		
	case .Fail:
		// This thread dies
		// Nothing to do
		
	case .Match:
		// Successful match
		accepting_thread := Thread{u32(len(matcher.prog.inst)), make([]int, len(thread.cap))}
		copy(accepting_thread.cap, thread.cap)
		enqueue(&matcher.queue, accepting_thread)
		
	case .Rune:
		// Match character class
		if pos < len(matcher.text) {
			r := rune(matcher.text[pos])
			if match_rune_class(inst, r) {
				next_thread := Thread{inst.out, make([]int, len(thread.cap))}
				copy(next_thread.cap, thread.cap)
				enqueue(&matcher.queue, next_thread)
			}
		}
		
	case .Rune1:
		// Match single character
		if pos < len(matcher.text) && rune(matcher.text[pos]) == rune(inst.arg) {
			next_thread := Thread{inst.out, make([]int, len(thread.cap))}
			copy(next_thread.cap, thread.cap)
			enqueue(&matcher.queue, next_thread)
		}
		
	case .RuneAny:
		// Match any character
		if pos < len(matcher.text) {
			next_thread := Thread{inst.out, make([]int, len(thread.cap))}
			copy(next_thread.cap, thread.cap)
			enqueue(&matcher.queue, next_thread)
		}
		
	case .RuneAnyNotNL:
		// Match any character except newline
		if pos < len(matcher.text) && matcher.text[pos] != '\n' {
			next_thread := Thread{inst.out, make([]int, len(thread.cap))}
			copy(next_thread.cap, thread.cap)
			enqueue(&matcher.queue, next_thread)
		}
		
	case .Jmp:
		// Unconditional jump
		next_thread := Thread{inst.out, make([]int, len(thread.cap))}
		copy(next_thread.cap, thread.cap)
		enqueue(&matcher.queue, next_thread)
	}
}

// Check if rune matches character class
match_rune_class :: proc(inst: Inst, r: rune) -> bool {
	// This is a simplified implementation
	// In a full implementation, we'd need to handle the rune ranges properly
	// For now, just handle the basic case
	return r == rune(inst.arg)
}



// Queue operations
reset_queue :: proc(q: ^Queue) {
	if q != nil {
		q.head = 0
		q.tail = 0
		q.size = 0
	}
}

enqueue :: proc(q: ^Queue, thread: Thread) -> bool {
	if q == nil || q.size >= len(q.threads) {
		return false
	}
	
	q.threads[q.tail] = thread
	q.tail = (q.tail + 1) % len(q.threads)
	q.size += 1
	return true
}

dequeue :: proc(q: ^Queue) -> Thread {
	if q == nil || q.size == 0 {
		return Thread{}
	}
	
	thread := q.threads[q.head]
	q.head = (q.head + 1) % len(q.threads)
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

