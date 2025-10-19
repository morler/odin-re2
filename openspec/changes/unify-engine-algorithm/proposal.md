# Unify Engine Algorithm

## Why
Current codebase mixes recursive backtracking (`match_pattern` functions) with Thompson NFA (`match_nfa`), violating RE2's linear-time guarantee principle and creating architectural inconsistency. This violates the core RE2 design principle and can lead to exponential time complexity on certain patterns.

## Summary
Remove recursive backtracking implementation and standardize on Thompson NFA algorithm to ensure linear-time performance guarantee and eliminate architectural inconsistency.

## What
**Minimal approach**: Remove recursive backtracking code while keeping all existing functionality intact through the NFA path.

## Scope
- **Files affected**: `src/regexp.odin` (lines 400-800)
- **Functions removed**: `match_pattern`, `match_pattern_anchored`, and related backtrack functions
- **Functions preserved**: `match_nfa_pattern` and all NFA infrastructure
- **Tests**: Ensure all existing tests pass without modification
- **API**: No breaking changes to public API

## Success Criteria
1. All recursive backtracking code removed
2. All existing tests continue to pass
3. Performance remains O(n) for all patterns
4. No API changes required

## Implementation Notes
- This is a **code removal** task only
- No new features or APIs needed
- Leverage existing NFA implementation
- Memory management patterns remain unchanged