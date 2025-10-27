package regexp

// Simplified version to test compilation
test_simplify :: proc(reg: ^Regexp) -> ^Regexp {
    if reg == nil do return nil

    // Test basic return statements
    return reg
}

test_bool :: proc() -> bool {
    return true
}

test_nil :: proc() -> ^Regexp {
    return nil
}