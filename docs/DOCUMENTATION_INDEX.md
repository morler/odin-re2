# Odin RE2 Documentation

📚 **Complete documentation for the Odin RE2 regular expression engine**

## 📋 Documentation Status

| Document | Status | Last Updated | Description |
|----------|--------|--------------|-------------|
| [README.md](../README.md) | ✅ Current | 2025-01-28 | Main project overview and quick start |
| [API.md](API.md) | ✅ Current | 2025-01-28 | Complete API reference and examples |
| [PERFORMANCE.md](PERFORMANCE.md) | ✅ Current | 2025-01-28 | Performance characteristics and optimizations |
| [EXAMPLES.md](EXAMPLES.md) | ✅ Current | 2025-01-28 | Comprehensive usage examples |
| [ARCHITECTURE.md](ARCHITECTURE.md) | ⚠️ Legacy | 2025-01-20 | Internal architecture (needs update) |
| [DESIGN.md](DESIGN.md) | ⚠️ Legacy | 2025-01-20 | Design decisions (needs update) |

## 🚀 Quick Start

### Installation & Build
```bash
# Clone the repository
git clone https://github.com/your-repo/odin-re2.git
cd odin-re2

# Build the core library
odin build core/ -o:speed -ignore-unknown-attributes

# Run basic example
odin run examples/basic_usage_final.odin -file -ignore-unknown-attributes
```

### Basic Usage
```odin
import "core:fmt"
import regexp "../core"

main :: proc() {
    // Compile a pattern
    pattern, err := regexp.regexp("hello")
    if err != .NoError {
        fmt.printf("Error: %v\n", err)
        return
    }
    defer regexp.free_regexp(pattern)

    // Match against text
    result, _ := regexp.match(pattern, "hello world")
    if result.matched {
        fmt.println("Found match!")
    }
}
```

## 📊 Current Feature Status

### ✅ Working Features
- **Literal matching**: `hello`, `world`
- **Dot pattern**: `h.llo` (any character)
- **Star quantifier**: `l*` (zero or more)
- **Character classes**: `[aeiou]`, `[a-z]`
- **Anchors**: `^start`, `end$`
- **Unicode ranges**: `[\u0400-\u04FF]`
- **Empty pattern**: `""` (always matches at position 0)

### ⚠️ Limited Support
- **Plus quantifier**: `l+` (one or more) - basic support
- **Question mark**: `l?` (zero or one) - basic support
- **Complex star**: `.*` - known matching issues
- **Unicode properties**: `\p{Letter}` - framework only
- **Capture groups**: `(pattern)` - basic framework

### ❌ Known Issues
- Complex quantifier patterns (`.*`) have matching problems
- Limited Unicode property support
- No case-insensitive matching
- No advanced regex features (lookaround, etc.)

## 📖 Learning Path

### For New Users
1. Start with [EXAMPLES.md](EXAMPLES.md) - practical examples
2. Read [API.md](API.md) - understand the API
3. Check [PERFORMANCE.md](PERFORMANCE.md) - optimization tips

### For Advanced Users
1. Review [PERFORMANCE.md](PERFORMANCE.md) - performance characteristics
2. Study [API.md](API.md) - advanced features and memory management
3. Examine source code in `core/` - implementation details

### For Contributors
1. Read [ARCHITECTURE.md](ARCHITECTURE.md) - internal design
2. Study [DESIGN.md](DESIGN.md) - design decisions
3. Review test cases in `tests/` - expected behavior

## 🔧 API Quick Reference

### Core Functions
```odin
// Pattern compilation
pattern, err := regexp.regexp("pattern_string")

// Pattern matching
result, err := regexp.match(pattern, "text_to_match")

// Memory management
defer regexp.free_regexp(pattern)
arena := regexp.new_arena(4096)
defer regexp.free_arena(arena)
```

### Supported Pattern Syntax
- **Literals**: `hello`, `world`
- **Dot**: `.` (any character)
- **Star**: `*` (zero or more)
- **Plus**: `+` (one or more) ⚠️
- **Question**: `?` (zero or one) ⚠️
- **Character class**: `[abc]`, `[a-z]`
- **Negation**: `[^abc]`
- **Anchors**: `^` (start), `$` (end)
- **Unicode**: `[\u0000-\uFFFF]`

## ⚡ Performance Characteristics

### Verified Performance
- **Literal matching**: 2253+ MB/s
- **Dot pattern**: 1500+ MB/s
- **Star quantifier**: 1200+ MB/s
- **Compilation speed**: 1800-5000ns
- **Memory efficiency**: 50%+ reduction with arena allocation

### Optimization Tips
1. **Use literal patterns** when possible
2. **Leverage ASCII fast path** for ASCII text
3. **Reuse compiled patterns** - compile once, match many times
4. **Use arena allocation** for multiple operations
5. **Avoid complex quantifiers** like `.*` (known issues)

## 🛠️ Troubleshooting

### Common Issues

**Build Errors**
```bash
# Error: import "regexp" not found
# Fix: Use correct import path
import regexp "../core"

# Error: architecture detection syntax
# Fix: Use proper enum syntax
when ODIN_ARCH == .amd64 {
    // amd64 specific code
}
```

**Runtime Issues**
```odin
// Pattern compilation fails
pattern, err := regexp.regexp("[invalid")
if err != .NoError {
    fmt.printf("Error: %s\n", regexp.error_string(err))
    return
}

// No match found
result, _ := regexp.match(pattern, text)
if !result.matched {
    fmt.println("No match found - check pattern logic")
}
```

**Performance Issues**
```odin
// Use arena for better memory efficiency
arena := regexp.new_arena(4096)
defer regexp.free_arena(arena)

// Avoid recompiling patterns
pattern, _ := regexp.regexp("test")  // Compile once
for text in texts {
    result, _ := regexp.match(pattern, text)  // Use many times
}
```

## 📚 Related Resources

- [Project Repository](https://github.com/your-repo/odin-re2)
- [Odin Language Documentation](https://odin-lang.org/docs/)
- [Google RE2 Documentation](https://github.com/google/re2/wiki/Syntax)
- [Unicode Regular Expressions](https://unicode.org/reports/tr18/)

## 📝 Contributing

1. **Report Issues**: Use GitHub issues for bug reports
2. **Submit PRs**: Follow existing code style and add tests
3. **Update Docs**: Keep documentation current with changes
4. **Test Thoroughly**: Run all tests before submitting changes

```bash
# Run all tests
odin run tests/unit/test_basic_simple.odin -file -ignore-unknown-attributes
odin run examples/basic_usage_final.odin -file -ignore-unknown-attributes
```

---

**Next Steps**: Choose your path based on your needs:
- **User**: Start with [EXAMPLES.md](EXAMPLES.md)
- **Developer**: Read [API.md](API.md)
- **Performance**: Check [PERFORMANCE.md](PERFORMANCE.md)
- **Troubleshooting**: See sections above