package regexp

import "core:c"
// Arena memory allocator for high-performance regex compilation and matching
// Provides deterministic memory usage and excellent performance

import "base:runtime"
import "core:fmt"

// Memory chunk for arena allocation
Memory_Chunk :: struct {
	data: []byte,
	size: int,
}

// Enhanced arena allocator for regex compilation and matching
Arena :: struct {
	data:           []byte,        // Raw memory buffer
	offset:         int,           // Current allocation position
	capacity:       int,           // Total buffer size
	chunks:         []Memory_Chunk, // Memory pool for efficiency
	peak_usage:     int,           // Peak memory usage tracking
	allocation_count: u32,         // Number of allocations
	debug_bounds:   bool,          // Bounds checking in debug builds
}

// String_View for zero-copy string operations
String_View :: struct {
	data: [^]u8,
	len:  int,
}

// Convert String_View to string
string_view_to_string :: proc(sv: String_View) -> string {
	return string(sv.data[:sv.len])
}

// Create a new arena with initial capacity and bounds checking
new_arena :: proc(initial_capacity: int = 4096) -> ^Arena {
	arena := new(Arena)
	arena.data = make([]byte, initial_capacity)
	arena.capacity = initial_capacity
	arena.offset = 0
	arena.chunks = []Memory_Chunk{}
	arena.peak_usage = 0
	arena.allocation_count = 0
	arena.debug_bounds = true  // Enable bounds checking in debug builds
	return arena
}

// Allocate memory from arena with bounds checking and tracking
arena_alloc :: proc(arena: ^Arena, size: int) -> rawptr {
	assert(arena != nil, "Arena cannot be nil")
	assert(size > 0, "Size must be positive")
	
	// Align to 8-byte boundary for performance
	aligned_size := (size + 7) & 0xFFFFFFF8
	
	// Bounds checking
	if arena.debug_bounds && arena.offset + aligned_size > arena.capacity {
		// Need to expand arena
		new_capacity := arena.capacity * 2
		if new_capacity < arena.offset + aligned_size {
			new_capacity = arena.offset + aligned_size + 4096  // Add extra space
		}
		
		new_data: []byte
		new_data, _ = runtime.make_slice([]byte, new_capacity)
		if len(new_data) == 0 {
			return nil
		}
		copy(new_data, arena.data)
		// arena.data will be garbage collected
		arena.data = new_data
		arena.capacity = new_capacity
	}
	
	ptr := &arena.data[arena.offset]
	arena.offset += aligned_size
	
	// Update tracking
	arena.allocation_count += 1
	if arena.offset > arena.peak_usage {
		arena.peak_usage = arena.offset
	}
	
	return ptr
}

// Allocate cache-line aligned memory (64-byte) for performance-critical structures
arena_alloc_aligned :: proc(arena: ^Arena, size: int, alignment: int = 64) -> rawptr {
	assert(arena != nil, "Arena cannot be nil")
	assert(size > 0, "Size must be positive")
	assert(alignment > 0 && (alignment & (alignment - 1)) == 0, "Alignment must be power of 2")

	// Calculate aligned size and offset
	aligned_size := (size + alignment - 1) & ~(alignment - 1)

	// Align current offset to cache line boundary
	data_ptr := raw_data(arena.data)
	current_addr := uintptr(uintptr(data_ptr) + uintptr(arena.offset))
	alignment_offset := (alignment - int(current_addr % uintptr(alignment))) % alignment
	total_needed := alignment_offset + aligned_size

	// Bounds checking
	if arena.debug_bounds && arena.offset + total_needed > arena.capacity {
		// Need to expand arena - ensure expansion starts at aligned boundary
		new_capacity := arena.capacity * 2
		if new_capacity < arena.offset + total_needed {
			new_capacity = arena.offset + total_needed + 4096
		}

		// Allocate new capacity with alignment in mind
		new_capacity = (new_capacity + alignment - 1) & ~(alignment - 1)

		new_data: []byte
		new_data, _ = runtime.make_slice([]byte, new_capacity)
		if len(new_data) == 0 {
			return nil
		}
		copy(new_data, arena.data)
		// arena.data will be garbage collected
		arena.data = new_data
		arena.capacity = new_capacity

		// Recalculate alignment for new buffer
		data_ptr = raw_data(arena.data)
		current_addr = uintptr(uintptr(data_ptr) + uintptr(arena.offset))
		alignment_offset = (alignment - int(current_addr % uintptr(alignment))) % alignment
		total_needed = alignment_offset + aligned_size
	}

	// Apply alignment offset
	arena.offset += alignment_offset

	ptr := &arena.data[arena.offset]
	arena.offset += aligned_size

	// Update tracking
	arena.allocation_count += 1
	if arena.offset > arena.peak_usage {
		arena.peak_usage = arena.offset
	}

	return ptr
}

// Allocate multiple items in batch for efficiency
arena_alloc_batch :: proc(arena: ^Arena, sizes: []int) -> []rawptr {
	assert(arena != nil, "Arena cannot be nil")
	
	result := make([]rawptr, len(sizes))
	total_size := 0
	
	// Calculate total aligned size
	for size in sizes {
		aligned_size := (size + 7) & 0xFFFFFFF8
		total_size += aligned_size
	}
	
	// Allocate contiguous block
	base_ptr := arena_alloc(arena, total_size)
	current_ptr := base_ptr
	
	for i, size in sizes {
		result[i] = current_ptr
		aligned_size := (size + 7) & 0xFFFFFFF8
		current_ptr = cast(rawptr) (uintptr(current_ptr) + uintptr(aligned_size))
	}
	
	return result
}

// Reset arena to reuse memory (keeps allocated buffers)
arena_reset :: proc(arena: ^Arena) {
	assert(arena != nil, "Arena cannot be nil")
	arena.offset = 0
}

// Free all memory associated with arena
free_arena :: proc(arena: ^Arena) {
	if arena == nil {
		return
	}
	
	delete(arena.data)
	delete(arena.chunks)
	free(arena)
}

// ===========================================================================
// MEMORY USAGE BOUNDS CHECKING
// ===========================================================================

// Memory usage constraints for regex operations
Memory_Constraints :: struct {
	max_per_operation: u32,    // Maximum memory per operation (1MB)
	max_growth_rate: f32,      // Maximum growth rate multiplier
	soft_limit: u32,           // Soft limit for warnings
	hard_limit: u32,           // Hard limit for errors
}

// Default memory constraints
DEFAULT_MEMORY_CONSTRAINTS :: Memory_Constraints {
	max_per_operation = 1024 * 1024,  // 1MB
	max_growth_rate = 2.0,             // 2x input size
	soft_limit = 512 * 1024,           // 512KB
	hard_limit = 1024 * 1024,          // 1MB
}

// Check memory usage against constraints
check_memory_constraints :: proc(arena: ^Arena, input_size: int, constraints: Memory_Constraints) -> (ok: bool, warning: bool) {
	used, capacity, utilization, peak, _ := arena_stats(arena)
	
	// Check per-operation limit
	if used > int(constraints.max_per_operation) {
		return false, false  // Exceeds hard limit
	}
	
	// Check growth rate
	expected_growth := f32(input_size) * constraints.max_growth_rate
	if f32(used) > expected_growth {
		return false, false  // Exceeds growth rate
	}
	
	// Check soft limit
	if used > int(constraints.soft_limit) {
		return true, true   // Warning threshold
	}
	
	return true, false  // Within limits
}

// Get memory usage report
memory_usage_report :: proc(arena: ^Arena) -> string {
	used, capacity, utilization, peak, alloc_count := arena_stats(arena)
	
	return fmt.tprintf(
		"Memory Usage Report:\n" +
		"  Used: %d bytes (%.2f MB)\n" +
		"  Capacity: %d bytes (%.2f MB)\n" +
		"  Utilization: %.1f%%\n" +
		"  Peak: %d bytes (%.2f MB)\n" +
		"  Allocations: %d\n" +
		"  Average allocation: %.1f bytes\n",
		used, f32(used) / (1024 * 1024),
		capacity, f32(capacity) / (1024 * 1024),
		utilization * 100,
		peak, f32(peak) / (1024 * 1024),
		alloc_count,
		f32(used) / f32(alloc_count)
	)
}

// Get current arena usage statistics
arena_stats :: proc(arena: ^Arena) -> (used: int, capacity: int, utilization: f32, peak: int, alloc_count: u32) {
	assert(arena != nil, "Arena cannot be nil")
	used = arena.offset
	capacity = arena.capacity
	utilization = f32(used) / f32(capacity)
	peak = arena.peak_usage
	alloc_count = arena.allocation_count
	return
}

// Create string view from slice (zero-copy)
make_string_view :: proc(s: string) -> String_View {
	return String_View{data = raw_data(s), len = len(s)}
}

// Create string view with copied data (for persistent storage)
make_string_view_copy :: proc(arena: ^Arena, s: string) -> String_View {
	if len(s) == 0 {
		return String_View{data = nil, len = 0}
	}
	
	data := arena_alloc(arena, len(s))
	data_bytes := ([^]u8)(data)
	
	// Copy bytes manually
	for i := 0; i < len(s); i += 1 {
		data_bytes[i] = s[i]
	}
	
	return String_View{data = data_bytes, len = len(s)}
}

// Create string view from pointer and length
make_string_view_ptr :: proc(data: [^]u8, len: int) -> String_View {
	return String_View{data = data, len = len}
}

// Convert string view to string
to_string :: proc(sv: String_View) -> string {
	return string(sv.data[:sv.len])
}

// Check if string view is empty
string_view_is_empty :: proc(sv: String_View) -> bool {
	return sv.len == 0
}

// Compare two string views
string_view_equal :: proc(a, b: String_View) -> bool {
	if a.len != b.len {
		return false
	}
	if a.len == 0 {
		return true
	}
	if a.len != b.len {
		return false
	}
	for i in 0..<a.len {
		if a.data[i] != b.data[i] {
			return false
		}
	}
	return true
}

// UTF-8 Iterator for efficient character processing
UTF8_Iterator :: struct {
	data:    [^]u8,    // UTF-8 byte sequence
	len:     int,      // Length of data
	pos:     int,      // Current position
	current: rune,     // Current Unicode character
	width:   int,      // Width of current character in bytes
}

// Create UTF-8 iterator from string view
make_utf8_iterator :: proc(sv: String_View) -> UTF8_Iterator {
	iter := UTF8_Iterator{
		data = sv.data,
		len = sv.len,
		pos = 0,
		current = 0,
		width = 0,
	}
	
	// Initialize first character
	if sv.len > 0 {
		utf8_next(&iter)
	}
	
	return iter
}

// Get next UTF-8 character
utf8_next :: proc(iter: ^UTF8_Iterator) -> bool {
	if iter.pos >= iter.len {
		iter.current = 0
		iter.width = 0
		return false
	}
	
	// Fast path for ASCII (95% of common text)
	first_byte := iter.data[iter.pos]
	if first_byte < 0x80 {
		iter.current = rune(first_byte)
		iter.width = 1
		iter.pos += 1
		return true
	}
	
	// Full UTF-8 decoding for Unicode characters
	if first_byte & 0xE0 == 0xC0 {
		// 2-byte sequence
		if iter.pos + 1 < iter.len {
			iter.current = rune((rune(first_byte & 0x1F) << 6) | rune(iter.data[iter.pos + 1] & 0x3F))
			iter.width = 2
			iter.pos += 2
			return true
		}
	} else if first_byte & 0xF0 == 0xE0 {
		// 3-byte sequence
		if iter.pos + 2 < iter.len {
			iter.current = rune((rune(first_byte & 0x0F) << 12) |
			                   (rune(iter.data[iter.pos + 1] & 0x3F) << 6) |
			                   rune(iter.data[iter.pos + 2] & 0x3F))
			iter.width = 3
			iter.pos += 3
			return true
		}
	} else if first_byte & 0xF8 == 0xF0 {
		// 4-byte sequence
		if iter.pos + 3 < iter.len {
			iter.current = rune((rune(first_byte & 0x07) << 18) |
			                   (rune(iter.data[iter.pos + 1] & 0x3F) << 12) |
			                   (rune(iter.data[iter.pos + 2] & 0x3F) << 6) |
			                   rune(iter.data[iter.pos + 3] & 0x3F))
			iter.width = 4
			iter.pos += 4
			return true
		}
	}
	
	// Invalid UTF-8 sequence
	iter.current = rune(0xFFFD) // Replacement character
	iter.width = 1
	iter.pos += 1
	return true
}

// Check if iterator has more characters
utf8_has_more :: proc(iter: ^UTF8_Iterator) -> bool {
	return iter.pos < iter.len
}

// Peek at current character without advancing
utf8_peek :: proc(iter: ^UTF8_Iterator) -> rune {
	return iter.current
}

// Get byte position of current character
utf8_position :: proc(iter: ^UTF8_Iterator) -> int {
	return iter.pos - iter.width
}

// ============================================================================
// ARENA SLICE ALLOCATION - Eliminates runtime.make_slice dependency
// ============================================================================

// Allocate a slice in arena memory
arena_alloc_slice :: proc(arena: ^Arena, $T: typeid, len: int) -> []T {
	if len == 0 {
		return []T{}
	}

	// Allocate contiguous memory for slice data and header
	total_size := size_of(T) * len
	data_ptr := arena_alloc(arena, total_size)

	// Create slice pointing to arena memory
	slice_data := ([^]T)(data_ptr)
	return slice_data[:len]
}

// Allocate a cache-line aligned slice in arena memory for performance-critical data
arena_alloc_slice_aligned :: proc(arena: ^Arena, $T: typeid, len: int, alignment: int = 64) -> []T {
	if len == 0 {
		return []T{}
	}

	// Allocate contiguous memory for slice data with cache-line alignment
	total_size := size_of(T) * len
	data_ptr := arena_alloc_aligned(arena, total_size, alignment)

	// Create slice pointing to arena memory
	slice_data := ([^]T)(data_ptr)
	return slice_data[:len]
}

// Allocate a slice and copy data from existing slice
arena_alloc_slice_copy :: proc(arena: ^Arena, $T: typeid, source: []T) -> []T {
	if len(source) == 0 {
		return []T{}
	}
	
	result := arena_alloc_slice(arena, T, len(source))
	copy(result, source)
	return result
}

// ===========================================================================
// MEMORY POOL FOR TEMPORARY ALLOCATIONS
// ===========================================================================

// Memory pool for frequently used temporary objects
Memory_Pool :: struct {
	freelist: []rawptr,    // Free list of available objects
	object_size: int,       // Size of each object
	capacity: int,          // Maximum pool size
	count: int,             // Current number of free objects
	arena: ^Arena,          // Arena for initial allocation
}

// Create a new memory pool
new_memory_pool :: proc(arena: ^Arena, object_size: int, initial_capacity: int = 16) -> ^Memory_Pool {
	pool := (^Memory_Pool)(arena_alloc(arena, size_of(Memory_Pool)))
	pool.object_size = object_size
	pool.capacity = initial_capacity * 4  // Allow growth
	pool.count = 0
	pool.arena = arena
	pool.freelist = arena_alloc_slice(arena, rawptr, pool.capacity)
	return pool
}

// Allocate from memory pool
pool_alloc :: proc(pool: ^Memory_Pool) -> rawptr {
	if pool.count > 0 {
		pool.count -= 1
		return pool.freelist[pool.count]
	}
	
	// Pool exhausted, allocate from arena
	return arena_alloc(pool.arena, pool.object_size)
}

// Return object to memory pool
pool_free :: proc(pool: ^Memory_Pool, ptr: rawptr) {
	if pool.count < pool.capacity {
		pool.freelist[pool.count] = ptr
		pool.count += 1
	}
	// Otherwise, let arena handle cleanup
}

// ===========================================================================
// MEMORY LEAK DETECTION (DEBUG BUILDS)
// ===========================================================================

// Memory allocation tracking for leak detection
Allocation_Tracker :: struct {
	allocations: []Allocation_Info,
	count: int,
	arena: ^Arena,
}

Allocation_Info :: struct {
	ptr: rawptr,
	size: int,
	file: string,
	line: int,
	active: bool,
}

// Create allocation tracker (debug builds only)
new_allocation_tracker :: proc(arena: ^Arena) -> ^Allocation_Tracker {
	tracker := (^Allocation_Tracker)(arena_alloc(arena, size_of(Allocation_Tracker)))
	tracker.allocations = arena_alloc_slice(arena, Allocation_Info, 1024)
	tracker.count = 0
	tracker.arena = arena
	return tracker
}

// Track allocation
track_allocation :: proc(tracker: ^Allocation_Tracker, ptr: rawptr, size: int, file: string, line: int) {
	if tracker.count < len(tracker.allocations) {
		tracker.allocations[tracker.count] = Allocation_Info{ptr, size, file, line, true}
		tracker.count += 1
	}
}

// Untrack allocation
untrack_allocation :: proc(tracker: ^Allocation_Tracker, ptr: rawptr) {
	for i in 0..<tracker.count {
		if tracker.allocations[i].ptr == ptr {
			// Remove by swapping with last element
			tracker.allocations[i] = tracker.allocations[tracker.count - 1]
			tracker.count -= 1
			break
		}
	}
}

// Report leaks
report_leaks :: proc(tracker: ^Allocation_Tracker) {
	if tracker.count > 0 {
		fmt.printf("Memory leaks detected: %d allocations\n", tracker.count)
		for i in 0..<tracker.count {
			info := &tracker.allocations[i]
			if info.active {
				fmt.printf("  Leak: %p (%d bytes) at %s:%d\n", info.ptr, info.size, info.file, info.line)
			}
		}
	}
}