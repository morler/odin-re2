package main

import "core:os"
import "core:fmt"

main :: proc() {
    file_path := "regexp/parser_fixed.odin"
    
    // Check if file exists
    if info, err := os.stat(file_path); err == nil {
        fmt.printf("File exists: %s (size: %d)\n", file_path, info.size)
        
        // Try to remove it
        if remove_err := os.remove(file_path); remove_err == nil {
            fmt.printf("Successfully removed %s\n", file_path)
        } else {
            fmt.printf("Failed to remove %s: %v\n", file_path, remove_err)
        }
    } else {
        fmt.printf("File does not exist: %s\n", file_path)
    }
}