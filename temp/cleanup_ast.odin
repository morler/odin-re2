package main

import "core:os"
import "core:fmt"

main :: proc() {
    // Remove duplicate AST files
    files_to_remove := []string{
        "regexp/ast_fixed.odin",
        "regexp/ast_new.odin",
    }
    
    for file in files_to_remove {
        if remove_err := os.remove(file); remove_err == nil {
            fmt.printf("Successfully removed %s\n", file)
        } else {
            fmt.printf("Failed to remove %s: %v\n", file, remove_err)
        }
    }
}