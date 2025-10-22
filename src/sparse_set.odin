package regexp

// SparseSet data structure for O(1) state management in NFA execution
// Critical for maintaining RE2's linear-time complexity guarantee



// SparseSet provides O(1) insertion, deletion, and membership testing
// Uses two arrays: dense (actual elements) and sparse (indices)
Sparse_Set :: struct {
	dense:  []u32, // Dense array of elements
	sparse: []u32, // Sparse index array
	size:   u32,   // Current number of elements
	max_size: u32, // Maximum capacity
}

// Create a new SparseSet with specified capacity
new_sparse_set :: proc(arena: ^Arena, capacity: u32) -> ^Sparse_Set {
	assert(capacity > 0, "Capacity must be positive")
	
	ss := (^Sparse_Set)(arena_alloc(arena, size_of(Sparse_Set)))
	ss^ = Sparse_Set{
		dense = make([]u32, capacity),
		sparse = make([]u32, capacity),
		size = 0,
		max_size = capacity,
	}
	
	// Initialize sparse array with sentinel values
	for i in 0..<capacity {
		ss.sparse[i] = 0xFFFFFFFF // Invalid index sentinel
	}
	
	return ss
}

// Check if element is in the set
contains :: proc(ss: ^Sparse_Set, elem: u32) -> bool {
	assert(ss != nil, "SparseSet cannot be nil")
	assert(elem < ss.max_size, "Element out of bounds")
	
	index := ss.sparse[elem]
	return index < ss.size && ss.dense[index] == elem
}

// Insert element into the set
// Returns true if element was inserted, false if already present
insert :: proc(ss: ^Sparse_Set, elem: u32) -> bool {
	assert(ss != nil, "SparseSet cannot be nil")
	assert(elem < ss.max_size, "Element out of bounds")
	
	if contains(ss, elem) {
		return false // Already present
	}
	
	assert(ss.size < ss.max_size, "SparseSet is full")
	
	// Add element to dense array and update sparse index
	ss.dense[ss.size] = elem
	ss.sparse[elem] = ss.size
	ss.size += 1
	
	return true
}

// Remove element from the set
// Returns true if element was removed, false if not present
remove :: proc(ss: ^Sparse_Set, elem: u32) -> bool {
	assert(ss != nil, "SparseSet cannot be nil")
	assert(elem < ss.max_size, "Element out of bounds")
	
	if !contains(ss, elem) {
		return false // Not present
	}
	
	// Get index of element in dense array
	index := ss.sparse[elem]
	
	// Move last element to fill the gap
	last_elem := ss.dense[ss.size - 1]
	ss.dense[index] = last_elem
	ss.sparse[last_elem] = index
	
	// Clear removed element's sparse index
	ss.sparse[elem] = 0xFFFFFFFF
	
	// Decrease size
	ss.size -= 1
	
	return true
}

// Clear all elements from the set
clear :: proc(ss: ^Sparse_Set) {
	assert(ss != nil, "SparseSet cannot be nil")
	
	// Reset sparse array
	for i in 0..<ss.size {
		elem := ss.dense[i]
		ss.sparse[elem] = 0xFFFFFFFF
	}
	
	ss.size = 0
}

// Get current number of elements
size :: proc(ss: ^Sparse_Set) -> u32 {
	assert(ss != nil, "SparseSet cannot be nil")
	return ss.size
}

// Check if set is empty
is_empty :: proc(ss: ^Sparse_Set) -> bool {
	assert(ss != nil, "SparseSet cannot be nil")
	return ss.size == 0
}

// Check if set is full
is_full :: proc(ss: ^Sparse_Set) -> bool {
	assert(ss != nil, "SparseSet cannot be nil")
	return ss.size == ss.max_size
}

// Get element at index in dense array
// Useful for iterating over elements
get :: proc(ss: ^Sparse_Set, index: u32) -> u32 {
	assert(ss != nil, "SparseSet cannot be nil")
	assert(index < ss.size, "Index out of bounds")
	return ss.dense[index]
}

// Iterator for SparseSet elements
Sparse_Set_Iterator :: struct {
	ss:     ^Sparse_Set,
	index:  u32,
}

// Create iterator for SparseSet
make_iterator :: proc(ss: ^Sparse_Set) -> Sparse_Set_Iterator {
	return Sparse_Set_Iterator{ss = ss, index = 0}
}

// Get next element from iterator
// Returns (element, has_more)
next :: proc(it: ^Sparse_Set_Iterator) -> (u32, bool) {
	if it.index >= it.ss.size {
		return 0, false
	}
	
	elem := it.ss.dense[it.index]
	it.index += 1
	return elem, true
}

// Reset iterator to beginning
reset_iterator :: proc(it: ^Sparse_Set_Iterator) {
	it.index = 0
}

// Copy elements from another SparseSet
// Returns true if copy was successful, false if destination is too small
copy_from :: proc(dest: ^Sparse_Set, src: ^Sparse_Set) -> bool {
	assert(dest != nil && src != nil, "SparseSet cannot be nil")
	
	if src.size > dest.max_size {
		return false // Destination too small
	}
	
	// Clear destination
	clear(dest)
	
	// Copy elements
	for i in 0..<src.size {
		elem := src.dense[i]
		dest.dense[i] = elem
		dest.sparse[elem] = i
	}
	
	dest.size = src.size
	return true
}

// Get memory usage statistics
memory_usage :: proc(ss: ^Sparse_Set) -> (dense_bytes: int, sparse_bytes: int, total_bytes: int) {
	assert(ss != nil, "SparseSet cannot be nil")
	
	dense_bytes = len(ss.dense) * size_of(u32)
	sparse_bytes = len(ss.sparse) * size_of(u32)
	total_bytes = dense_bytes + sparse_bytes
	return
}

// Validate SparseSet invariants (for debugging)
validate :: proc(ss: ^Sparse_Set) -> bool {
	assert(ss != nil, "SparseSet cannot be nil")
	
	// Check size bounds
	if ss.size > ss.max_size {
		return false
	}
	
	// Check dense-sparse consistency
	for i in 0..<ss.size {
		elem := ss.dense[i]
		if elem >= ss.max_size {
			return false
		}
		if ss.sparse[elem] != i {
			return false
		}
	}
	
	// Check that sparse entries for non-elements are invalid
	for i in 0..<ss.max_size {
		if ss.sparse[i] != 0xFFFFFFFF {
			// Should be a valid element
			if ss.sparse[i] >= ss.size || ss.dense[ss.sparse[i]] != i {
				return false
			}
		}
	}
	
	return true
}

// Convert SparseSet to slice (for debugging/debugging)
to_slice :: proc(ss: ^Sparse_Set, arena: ^Arena) -> []u32 {
	assert(ss != nil, "SparseSet cannot be nil")
	
	result := make([]u32, ss.size)
	copy(result, ss.dense[:ss.size])
	return result
}

// Find intersection with another SparseSet
// Stores result in destination SparseSet
// Returns true if successful, false if destination is too small
intersection :: proc(dest: ^Sparse_Set, a: ^Sparse_Set, b: ^Sparse_Set) -> bool {
	assert(dest != nil && a != nil && b != nil, "SparseSet cannot be nil")
	
	clear(dest)
	
	// Iterate through smaller set for efficiency
	if a.size < b.size {
		for i in 0..<a.size {
			elem := a.dense[i]
			if contains(b, elem) {
				if !insert(dest, elem) {
					return false // Destination full
				}
			}
		}
	} else {
		for i in 0..<b.size {
			elem := b.dense[i]
			if contains(a, elem) {
				if !insert(dest, elem) {
					return false // Destination full
				}
			}
		}
	}
	
	return true
}

// Find union with another SparseSet
// Stores result in destination SparseSet
// Returns true if successful, false if destination is too small
set_union :: proc(dest: ^Sparse_Set, a: ^Sparse_Set, b: ^Sparse_Set) -> bool {
	assert(dest != nil && a != nil && b != nil, "SparseSet cannot be nil")
	
	// Start with copy of a
	if !copy_from(dest, a) {
		return false
	}
	
	// Add elements from b
	for i in 0..<b.size {
		elem := b.dense[i]
		if !insert(dest, elem) {
			return false // Destination full
		}
	}
	
	return true
}

// Check if two SparseSets are equal
equal :: proc(a: ^Sparse_Set, b: ^Sparse_Set) -> bool {
	assert(a != nil && b != nil, "SparseSet cannot be nil")
	
	if a.size != b.size {
		return false
	}
	
	// Check if all elements of a are in b
	for i in 0..<a.size {
		elem := a.dense[i]
		if !contains(b, elem) {
			return false
		}
	}
	
	return true
}