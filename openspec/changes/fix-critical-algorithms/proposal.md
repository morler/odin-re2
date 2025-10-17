## Why
Critical algorithm defects in quantifier matching (O(n³) complexity) and anchor handling (complete failure) make Odin RE2 unsuitable for production use and pose exponential performance risks.

## What Changes
- Fix quantifier matching algorithms (*, +, ?, {m,n}) to use O(n) greedy matching
- Implement proper anchor handling (^ and $) with position awareness
- Add recursion depth limits to prevent stack overflow
- **BREAKING**: Changes internal algorithm behavior but maintains public API compatibility

## Impact
- Affected specs: regex-matching
- Affected code: regexp/regexp.odin (match_star, match_plus, match_quest, match_repeat, match_begin_line, match_end_line)
- Performance improvement: 100-1000x faster for complex patterns
- Functionality improvement: Quantifiers and anchors will work correctly
