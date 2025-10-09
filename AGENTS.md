# Odin RE2 Project - Agent Guidelines

## Build Commands
```bash
odin build filename.odin -file          # Build single file
odin build . -o:speed                   # Build with optimizations
odin test .                             # Run all tests
odin test filename.odin -file           # Test single file
odin check . -vet -vet-style            # Lint and validate
```

## Code Style Guidelines

### Naming Conventions
- **Types**: `Pascal_Case` (e.g., `Regexp_Op`, `Char_Class`)
- **Procedures**: `snake_case` (e.g., `parse_regexp`, `to_string`)
- **Variables**: `snake_case` (e.g., `error_code`, `cap_num`)
- **Constants**: `ALL_CAPS` (e.g., `NoError`, `PerlX`)

### Formatting & Imports
- Use tabs for indentation, 1TBS brace style
- Group imports: core libs first, then local packages
- Use explicit imports: `import "core:fmt"`, `import "regexp"`
- Trailing commas required for multi-line arrays/structs

### Error Handling & Memory
- Use `ErrorCode` enum, return `(result, ErrorCode)` tuples
- Use `new()`/`free()` for explicit allocation
- Clean up memory with `free_regexp()` in all test procedures
- Use `panic()` only for unrecoverable programmer errors

### RE2-Specific Rules
- AST structures must match RE2 exactly
- Preserve RE2's linear-time complexity guarantee
- No backreferences (RE2 design choice)
- Unicode UTF-8 support throughout

### Testing
- Use `@(test)` attribute, name files `test_*.odin` or `*_test.odin`
- Test both success and error paths
- Always run `odin check . -vet -vet-style` before committing
