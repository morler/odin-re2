# Tasks: Unify Engine Algorithm

## Implementation Tasks

1. **Identify backtrack functions to remove**
   - Audit `src/regexp.odin` for recursive backtracking functions
   - List all functions that call `match_pattern` recursively
   - Verify no external dependencies on these functions

2. **Remove recursive backtrack implementation**
   - Delete `match_pattern` function (lines ~600-800)
   - Delete `match_pattern_anchored` function
   - Delete helper functions: `try_match_sequence`, `try_quantifier_backtrack`
   - Delete quantifier backtrack functions: `match_star`, `match_plus`, `match_quest`, `match_repeat`

3. **Update main API to use NFA path**
   - Ensure `match` function in `regexp.odin` calls `match_nfa_pattern`
   - Verify `match_string` function uses NFA path
   - Test that API behavior remains identical

4. **Validate functionality**
   - Run existing test suite: `odin test .`
   - Run manual tests with key patterns: literals, quantifiers, character classes
   - Verify no regressions in matching behavior

5. **Performance verification**
   - Test linear-time guarantee with pathological patterns
   - Confirm memory usage remains bounded
   - Validate no performance regressions

## Validation Criteria

- All tests pass without modification
- No recursive function calls in matching logic
- Linear-time complexity maintained for all patterns
- Memory usage remains bounded and predictable