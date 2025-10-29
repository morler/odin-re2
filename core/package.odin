// =============================================================================
// Odin RE2 Package - High-performance RE2-compatible regular expression engine
// =============================================================================
//
// This package provides a complete RE2-compatible regular expression implementation
// with the following features:
//
// • Linear-time matching guarantee (O(n) complexity)
// • Memory-efficient arena allocation
// • Unicode support with UTF-8 optimization
// • ASCII fast path optimization
// • Thread-safe operations
//
// =============================================================================

package regexp

// Main API functions - re-exported for convenience
// These are the primary functions users will interact with

// Compile a regex pattern
// Returns: (pattern, error_code)
// Example: pattern, err := regexp.regexp("hello.*world")

// Free a compiled pattern
// Example: defer regexp.free_regexp(pattern)

// Match a pattern against text
// Returns: (match_result, error_code)
// Example: result, err := regexp.match(pattern, "hello beautiful world")

// Memory management
// new_arena :: proc(size: int) -> ^Arena
// free_arena :: proc(arena: ^Arena)

// Error handling
// ErrorCode :: enum { NoError, ParseError, ... }
// error_string :: proc(err: ErrorCode) -> string

// Data structures
// Regexp_Pattern :: struct { ... }
// Match_Result :: struct { matched, full_match, captures, text }
// Range :: struct { start, end: int }
// Arena :: struct { ... }

// Performance monitoring
// get_matcher_metrics :: proc(matcher: ^Matcher) -> Matcher_Metrics
// Matcher_Metrics :: struct { ... }

// =============================================================================
// Package initialization
// =============================================================================

// Initialize the regexp package - called automatically when needed
init_package :: proc() {
    init_ascii_classification()
    init_simd_support()
}

// Package-level initialization flag
package_initialized: bool = false

// Ensure package is initialized
ensure_initialized :: proc() {
    if !package_initialized {
        init_package()
        package_initialized = true
    }
}