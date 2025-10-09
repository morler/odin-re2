package regexp

import "core:fmt"

// SparseSet implementation for O(1) state management in NFA execution
// Based on RE2's SparseSet data structure

// SparseSet provides O(1) insert, delete, and membership test operations
// Used to track which NFA states are currently active
SparseSet :: struct {
	dense:  []u32,     // Dense array of active states
	sparse: []u32,     // Sparse array for O(1) lookup
	size:   u32,       // Current number of elements
	max_size: u32,     // Maximum capacity
}

// Create a new SparseSet with specified maximum size
new_sparse_set :: proc(max_size: u32) -> ^SparseSet {
	set := new(SparseSet)
	set.dense = make([]u32, max_size)
	set.sparse = make([]u32, max_size)
	set.size = 0
	set.max_size = max_size
	return set
}

// Free SparseSet memory
free_sparse_set :: proc(set: ^SparseSet) {
	if set != nil {
		delete(set.dense)
		delete(set.sparse)
		free(set)
	}
}

// Clear all elements from the set
clear :: proc(set: ^SparseSet) {
	if set != nil {
		set.size = 0
	}
}

// Check if the set contains the specified element
contains :: proc(set: ^SparseSet, value: u32) -> bool {
	if set == nil || value >= set.max_size {
		return false
	}
	
	index := set.sparse[value]
	return index < set.size && set.dense[index] == value
}

// Insert an element into the set
// Returns true if element was inserted, false if already present
insert :: proc(set: ^SparseSet, value: u32) -> bool {
	if set == nil || value >= set.max_size {
		return false
	}
	
	if contains(set, value) {
		return false // Already present
	}
	
	// Add to dense array and update sparse index
	index := set.size
	set.dense[index] = value
	set.sparse[value] = index
	set.size += 1
	
	return true
}

// Remove an element from the set
// Returns true if element was removed, false if not present
remove :: proc(set: ^SparseSet, value: u32) -> bool {
	if set == nil || value >= set.max_size {
		return false
	}
	
	if !contains(set, value) {
		return false // Not present
	}
	
	// Swap with last element to maintain O(1) deletion
	index := set.sparse[value]
	last_value := set.dense[set.size - 1]
	
	set.dense[index] = last_value
	set.sparse[last_value] = index
	
	set.size -= 1
	return true
}

// Get the current number of elements in the set
size :: proc(set: ^SparseSet) -> u32 {
	if set == nil {
		return 0
	}
	return set.size
}

// Check if the set is empty
is_empty :: proc(set: ^SparseSet) -> bool {
	return set == nil || set.size == 0
}

// Get all elements in the set as a slice
// Note: This returns a view into the dense array, do not modify
elements :: proc(set: ^SparseSet) -> []u32 {
	if set == nil || set.size == 0 {
		return nil
	}
	return set.dense[:set.size]
}

// Iterator for SparseSet elements
SparseSet_Iterator :: struct {
	set:   ^SparseSet,
	index: u32,
}

// Create a new iterator for the set
iterator :: proc(set: ^SparseSet) -> SparseSet_Iterator {
	return SparseSet_Iterator{set, 0}
}

// Get next element from iterator
// Returns (value, has_more)
next :: proc(it: ^SparseSet_Iterator) -> (u32, bool) {
	if it.set == nil || it.index >= it.set.size {
		return 0, false
	}
	
	value := it.set.dense[it.index]
	it.index += 1
	return value, true
}

// Reset iterator to beginning
reset_iterator :: proc(it: ^SparseSet_Iterator) {
	it.index = 0
}

// Debug function to print set contents (for testing)
debug_print :: proc(set: ^SparseSet) {
	if set == nil {
		fmt.printf("SparseSet(nil)\n")
		return
	}
	
	fmt.printf("SparseSet(size=%d, max=%d): [", set.size, set.max_size)
	for i in u32(0)..<set.size {
		if i > 0 {
			fmt.printf(", ")
		}
		fmt.printf("%d", set.dense[i])
	}
	fmt.printf("]\n")
}