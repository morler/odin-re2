## Why
The regex engine has critical syntax support gaps that prevent it from being RE2-compatible and useful for real-world applications. Testing revealed that core features like alternation (|), wildcards (.*), complex quantifiers ({m,n}), and escape sequences are completely non-functional, making the engine unsuitable for production use despite having good performance characteristics.

## What Changes
- Fix alternation operator `|` to support single character and pattern choices
- Implement wildcard `.` and Kleene star `.*` combination matching  
- Fix complex quantifier syntax `{m,n}` to work with all pattern types
- Implement proper escape sequence handling for `\s`, `\.` etc.
- Fix anchor behavior `^` `$` in complex patterns
- Ensure all fixed syntax maintains linear time complexity guarantees

## Impact
- **Affected specs**: regex-engine (new capability)
- **Affected code**: 
  - `regexp/parser.odin` - AST construction for syntax elements
  - `regexp/matcher.odin` - NFA matching logic  
  - `regexp/inst.odin` - NFA instruction generation
  - `tests/` - Comprehensive test coverage for fixed syntax
- **BREAKING**: None - this fixes broken functionality, doesn't change working APIs