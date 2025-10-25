## Why
Basic RE2 features are working but users commonly request missing Unicode support, lookbehinds, and case-insensitive matching that are essential for real-world regex usage.

## What Changes
- Add Unicode property support (`\p{L}`, `\p{Number}`, etc.)
- Implement lookbehind assertions (`(?<=...)`, `(?<!...)`)
- Add case-insensitive flag (`(?i)`)
- Add multiline flag (`(?m)`) for proper `^`/`$` behavior
- Add dotall flag (`(?s)`) for `.` to match newlines

## Impact
- Affected specs: regex-engine  
- Affected code: regexp/parser.odin, regexp/matcher.odin, regexp/ast.odin
- **BREAKING**: Parser changes may affect some edge cases in pattern compilation