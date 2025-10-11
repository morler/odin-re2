package main

import "core:os"
import "core:fmt"

main :: proc() {
    // Remove duplicate parser files
    files_to_remove := []string{
        "regexp/parser_fixed.odin",
    }
    
    for file in files_to_remove {
        err := os.remove_file(file)
        if err == nil {
            fmt.printf("Removed %s\n", file)
        } else {
            fmt.printf("Failed to remove %s: %v\n", file, err)
        }
    }
}