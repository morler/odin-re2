# Quickstart Guide - Odin RE2 Implementation

**Version**: 1.0.0  
**Date**: 2025-10-09  
**Purpose**: Getting started with RE2-compatible regex engine in Odin

## Installation

### Prerequisites
- Odin compiler (latest stable version)
- Compatible platform: Windows, Linux, or macOS

### Build Commands
```bash
# Build the regex library
odin build . -o:speed

# Run tests
odin test .

# Check code style and validate
odin check . -vet -vet-style
```

## Basic Usage

### Simple Pattern Matching
```odin
package main

import "core:fmt"
import "regexp"

main :: proc() {
    // Compile a pattern
    pattern, err := regexp("hello\\s+world")
    if err != .NoError {
        fmt.printf("Compilation error: %v\n", regexp.error_string(err))
        return
    }
    defer regexp.free_regexp(pattern)
    
    // Match against text
    result, err := regexp.match(pattern, "hello   world")
    if err != .NoError {
        fmt.printf("Match error: %v\n", regexp.error_string(err))
        return
    }
    
    if result.matched {
        fmt.printf("Found match at %d-%d\n", 
            result.full_match.start, 
            result.full_match.end)
    } else {
        fmt.println("No match found")
    }
}
```

### One-shot Matching
```odin
// For simple cases, use the convenience function
matched, err := regexp.match_string("test\\d+", "example test123")
if err == .NoError && matched {
    fmt.println("Pattern matched!")
}
```

## Working with Capture Groups

### Basic Captures
```odin
pattern, _ := regexp("(\\d+)-(\\d+)")
defer regexp.free_regexp(pattern)

result, _ := regexp.match(pattern, "123-456")
if result.matched && len(result.captures) >= 3 {
    // Full match
    full_match := result.text[result.full_match.start:result.full_match.end]
    fmt.printf("Full match: %s\n", full_match)
    
    // Capture groups
    group1 := result.text[result.captures[1].start:result.captures[1].end]
    group2 := result.text[result.captures[2].start:result.captures[2].end]
    fmt.printf("Group 1: %s\n", group1)
    fmt.printf("Group 2: %s\n", group2)
}
```

### Named Groups (Future Implementation)
```odin
// Planned feature for named capture groups
pattern, _ := regexp("(?P<year>\\d{4})-(?P<month>\\d{2})-(?P<day>\\d{2})")
// Implementation details to be added
```

## Common Patterns

### Email Validation
```odin
email_pattern := `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}`
pattern, _ := regexp(email_pattern)
defer regexp.free_regexp(pattern)

result, _ := regexp.match(pattern, "user@example.com")
if result.matched {
    fmt.println("Valid email address")
}
```

### Phone Number Extraction
```odin
phone_pattern := `(\(\d{3}\)\s*|\d{3}[-.\s]?)\d{3}[-.\s]?\d{4}`
pattern, _ := regexp(phone_pattern)
defer regexp.free_regexp(pattern)

text := "Call me at (555) 123-4567 or 555.123.4567"
result, _ := regexp.match(pattern, text)
if result.matched {
    phone := result.text[result.full_match.start:result.full_match.end]
    fmt.printf("Found phone number: %s\n", phone)
}
```

### URL Parsing
```odin
url_pattern := `(https?://)?([a-zA-Z0-9.-]+)(\.[a-zA-Z]{2,})(/[^\\s]*)?`
pattern, _ := regexp(url_pattern)
defer regexp.free_regexp(pattern)

result, _ := regexp.match(pattern, "https://example.com/path")
if result.matched {
    fmt.println("Valid URL format")
}
```

## Advanced Features

### Case Insensitive Matching
```odin
// Case insensitive flag support planned
pattern, _ := regexp("hello", .CaseInsensitive)
defer regexp.free_regexp(pattern)

result, _ := regexp.match(pattern, "HELLO World")
// Will match regardless of case
```

### Multi-line Mode
```odin
// Multi-line flag for ^ and $ behavior
pattern, _ := regexp("^start.*end$", .MultiLine)
defer regexp.free_regexp(pattern)

text := "start middle\nstart end"
result, _ := regexp.match(pattern, text)
// ^ and $ match at line boundaries in multi-line mode
```

### Unicode Support
```odin
// Full Unicode UTF-8 support
pattern, _ := regexp("\\p{L}+\\s*\\p{N}+")
defer regexp.free_regexp(pattern)

result, _ := regexp.match(pattern, "Привет 123")
// Handles Unicode letters and numbers correctly
```

## Error Handling

### Compilation Errors
```odin
pattern, err := regexp("[invalid")
if err != .NoError {
    switch err {
    case .ParseError:
        fmt.println("Invalid regex syntax")
    case .MemoryError:
        fmt.println("Out of memory")
    case .UTF8Error:
        fmt.println("Invalid UTF-8 in pattern")
    default:
        fmt.printf("Error: %v\n", regexp.error_string(err))
    }
    return
}
```

### Runtime Errors
```odin
result, err := regexp.match(pattern, input_text)
if err != .NoError {
    switch err {
    case .InternalError:
        fmt.println("Internal regex engine error")
    case .UTF8Error:
        fmt.println("Invalid UTF-8 in input text")
    default:
        fmt.printf("Match error: %v\n", regexp.error_string(err))
    }
}
```

## Performance Tips

### Compile Once, Use Many Times
```odin
// GOOD: Compile once, reuse
pattern, _ := regexp("fixed_pattern")
defer regexp.free_regexp(pattern)

for text in texts {
    result, _ := regexp.match(pattern, text)
    // process result
}

// AVOID: Recompiling in loop
for text in texts {
    pattern, _ := regexp("fixed_pattern")  // Inefficient!
    defer regexp.free_regexp(pattern)
    result, _ := regexp.match(pattern, text)
}
```

### Use Appropriate Patterns
```odin
// GOOD: Specific patterns
pattern, _ := regexp("\\d{4}-\\d{2}-\\d{2}")  // Date format

// AVOID: Overly general patterns
pattern, _ := regexp(".*")  // Matches everything, slow
```

### Memory Management
```odin
// Always free compiled patterns
pattern, _ := regexp("pattern")
defer regexp.free_regexp(pattern)  // Essential!

// For long-running applications, consider pattern caching
var cached_patterns: map[string]^regexp.Regexp_Pattern

get_cached_pattern :: proc(pattern_str: string) -> (^regexp.Regexp_Pattern, ErrorCode) {
    if cached, ok := cached_patterns[pattern_str] {
        return cached, .NoError
    }
    
    pattern, err := regexp.regexp(pattern_str)
    if err == .NoError {
        cached_patterns[pattern_str] = pattern
    }
    return pattern, err
}
```

## Testing

### Running Tests
```bash
# Run all tests
odin test .

# Run specific test file
odin test test_basic_matching.odin -file

# Run with verbose output
odin test . -v

# Check code style
odin check . -vet -vet-style
```

### Writing Tests
```odin
@(test)
test_my_pattern :: proc(t: ^testing.T) {
    pattern, err := regexp("test\\d+")
    testing.expect(t, err == .NoError, "Pattern should compile")
    defer regexp.free_regexp(pattern)
    
    result, err := regexp.match(pattern, "test123")
    testing.expect(t, err == .NoError, "Match should succeed")
    testing.expect(t, result.matched, "Should match test123")
    
    result, err = regexp.match(pattern, "nomatch")
    testing.expect(t, err == .NoError, "Match should succeed")
    testing.expect(t, !result.matched, "Should not match nomatch")
}
```

## Troubleshooting

### Common Issues

1. **Memory Leaks**: Always call `free_regexp()` for compiled patterns
2. **Performance**: Use compiled patterns repeatedly, don't recompile
3. **Unicode**: Ensure input text is valid UTF-8
4. **Complexity**: Very complex patterns may hit complexity limits

### Debug Mode
```bash
# Build with debug information
odin build . -debug

# Run with bounds checking (slower but safer)
odin test . -debug
```

### Getting Help
- Check the test files for usage examples
- Review the API contract documentation
- Examine the source code in the `regexp/` package
- Run `odin check . -vet -vet-style` for code quality issues

This quickstart guide provides the essential information for using the Odin RE2 implementation effectively while following best practices for performance and memory management.