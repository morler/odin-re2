package regexp

// Arena memory allocator for high-performance regex compilation and matching
// Provides deterministic memory usage and excellent performance

import "core:mem"

// Memory chunk for arena allocation
Memory_Chunk :: struct {
	data: []byte,
	size: int,
}

// Arena allocator for regex compilation and matching
Arena :: struct {
	data:     []byte,        // Raw memory buffer
	offset:   int,           // Current allocation position
	capacity: int,           // Total buffer size
	chunks:   []Memory_Chunk, // Memory pool for efficiency
}

// String_View for zero-copy string operations
String_View :: struct {
	data: [^]u8,
	len:  int,
}

// Create a new arena with initial capacity
new_arena :: proc(initial_capacity: int = 4096) -> ^Arena {
	arena := new(Arena)
	arena.data = make([]byte, initial_capacity)
	arena.capacity = initial_capacity
	arena.offset = 0
	arena.chunks = make([]Memory_Chunk, 0, 8)
	return arena
}

// Allocate memory from arena
arena_alloc :: proc(arena: ^Arena, size: int) -> rawptr {
	assert(arena != nil, "Arena cannot be nil")
	assert(size > 0, "Size must be positive")
	
	// Align to 8-byte boundary for performance
	aligned_size := (size + 7) & ~7
	
	if arena.offset + aligned_size > arena.capacity {
		// Need to expand arena
		new_capacity := arena.capacity * 2
		if new_capacity < arena.offset + aligned_size {
			new_capacity = arena.offset + aligned_size
		}
		
		new_data := make([]byte, new_capacity)
		mem.copy(new_data, arena.data, arena.offset)
		delete(arena.data)
		arena.data = new_data
		arena.capacity = new_capacity
	}
	
	ptr := &arena.data[arena.offset]
	arena.offset += aligned_size
	return ptr
}

// Allocate multiple items in batch for efficiency
arena_alloc_batch :: proc(arena: ^Arena, sizes: []int) -> []rawptr {
	assert(arena != nil, "Arena cannot be nil")
	
	result := make([]rawptr, len(sizes))
	total_size := 0
	
	// Calculate total aligned size
	for size in sizes {
		aligned_size := (size + 7) & ~7
		total_size += aligned_size
	}
	
	// Allocate contiguous block
	base_ptr := arena_alloc(arena, total_size)
	current_ptr := base_ptr
	
	for i, size in sizes {
		result[i] = current_ptr
		aligned_size := (size + 7) & ~7
		current_ptr = mem.ptr_offset(current_ptr, aligned_size)
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

// Get current arena usage statistics
arena_stats :: proc(arena: ^Arena) -> (used: int, capacity: int, utilization: f32) {
	assert(arena != nil, "Arena cannot be nil")
	used = arena.offset
	capacity = arena.capacity
	utilization = f32(used) / f32(capacity)
	return
}

// Create string view from slice (zero-copy)
make_string_view :: proc(s: string) -> String_View {
	return String_View{data = raw_data(s), len = len(s)}
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
is_empty :: proc(sv: String_View) -> bool {
	return sv.len == 0
}

// Compare two string views
equal :: proc(a, b: String_View) -> bool {
	if a.len != b.len {
		return false
	}
	if a.len == 0 {
		return true
	}
	return mem.compare(a.data, b.data, a.len) == 0
}

// UTF-8 Iterator for efficient character processing
UTF8_Iterator :: struct {
	data:    [^]u8,    // UTF-8 byte sequence
	pos:     int,      // Current position
	current: rune,     // Current Unicode character
	width:   int,      // Width of current character in bytes
}

// Create UTF-8 iterator from string view
make_utf8_iterator :: proc(sv: String_View) -> UTF8_Iterator {
	iter := UTF8_Iterator{
		data = sv.data,
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
	if iter.pos >= len(iter.data) {
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
		if iter.pos + 1 < len(iter.data) {
			iter.current = rune((rune(first_byte & 0x1F) << 6) | rune(iter.data[iter.pos + 1] & 0x3F))
			iter.width = 2
			iter.pos += 2
			return true
		}
	} else if first_byte & 0xF0 == 0xE0 {
		// 3-byte sequence
		if iter.pos + 2 < len(iter.data) {
			iter.current = rune((rune(first_byte & 0x0F) << 12) |
			                   (rune(iter.data[iter.pos + 1] & 0x3F) << 6) |
			                   rune(iter.data[iter.pos + 2] & 0x3F))
			iter.width = 3
			iter.pos += 3
			return true
		}
	} else if first_byte & 0xF8 == 0xF0 {
		// 4-byte sequence
		if iter.pos + 3 < len(iter.data) {
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
	return iter.pos < len(iter.data)
}

// Peek at current character without advancing
utf8_peek :: proc(iter: ^UTF8_Iterator) -> rune {
	return iter.current
}

// Get byte position of current character
utf8_position :: proc(iter: ^UTF8_Iterator) -> int {
	return iter.pos - iter.width
}