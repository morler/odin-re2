package main

import "core:os"
import "core:fmt"

main :: proc() {
    content, err := os.read_entire_file("regexp/parser.odin")
    if err != nil {
        fmt.printf("Error reading file: %v\n", err)
        return
    }
    
    // Replace var nodes with nodes
    fixed := string_replace(content, "\tvar nodes: [32]^Regexp", "\tnodes: [32]^Regexp")
    
    err = os.write_entire_file("regexp/parser.odin", fixed)
    if err != nil {
        fmt.printf("Error writing file: %v\n", err)
        return
    }
    
    fmt.println("Fixed parser.odin")
}

string_replace :: proc(s: string, old: string, new: string) -> string {
    // Simple string replacement
    result := make([]byte, len(s) * 2) // Overallocate
    result_len := 0
    
    i := 0
    for i < len(s) {
        if i <= len(s) - len(old) && s[i:i+len(old)] == old {
            for j in 0..<len(new) {
                result[result_len] = new[j]
                result_len += 1
            }
            i += len(old)
        } else {
            result[result_len] = s[i]
            result_len += 1
            i += 1
        }
    }
    
    return string(result[:result_len])
}