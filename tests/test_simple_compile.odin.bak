package main

import "regexp"
import "core:fmt"

main :: proc() {
	pattern := "hello"
	compiled, err := regexp.regexp(pattern)
	if err != .NoError {
		fmt.printf("Failed to compile pattern: %v\n", err)
		return
	}
	
	fmt.printf("Successfully compiled pattern: %s\n", pattern)
	fmt.printf("AST op: %v\n", compiled.ast.op)
	
	if compiled.ast != nil {
		regexp.free_regexp(compiled)
	}
}