package main

import "core:fmt"

main :: proc() {
    fmt.println("Hello World")
    return
}

test_func :: proc(x: int) -> (bool, int) {
    if x > 0 {
        return true, x
    } else {
        return false, 0
    }
}