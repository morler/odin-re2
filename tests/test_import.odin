package main

import "core:fmt"
import "core:testing"

// Try different import paths
@(test)
test_import_paths :: proc(t: ^testing.T) {
	fmt.println("Testing import paths...")
	
	// Try path 1: ../src/regexp
	// import "../src/regexp"
	
	// Try path 2: ./regexp
	// import "./regexp"
	
	// Try path 3: regexp
	// import "regexp"
	
	fmt.println("Import test completed")
}