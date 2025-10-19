# Algorithm Consistency Specification

## REMOVED Requirements

### Recursive Backtracking Functions
**Requirement**: Remove `match_pattern` function and its recursive implementation
**Reason**: Violates linear-time guarantee principle of RE2
**Scenario**: Pattern `a*b` should match in O(n) time, not exponential time

### Quantifier Backtracking Implementation
**Requirement**: Remove `match_star`, `match_plus`, `match_quest`, `match_repeat` backtrack versions
**Reason**: These implementations use recursive backtracking which can cause exponential behavior
**Scenario**: Pattern `a*` on long input should never trigger exponential backtracking

### Helper Backtrack Functions
**Requirement**: Remove `try_match_sequence` and `try_quantifier_backtrack` functions
**Reason**: These are infrastructure for recursive backtracking algorithm
**Scenario**: Complex concatenation patterns should use NFA state machine, not backtracking

## MODIFIED Requirements

### Main Matching API
**Requirement**: Update `match` function to exclusively use NFA implementation
**Implementation**: Call `match_nfa_pattern` instead of removed backtrack functions
**Scenario**: User calls `regexp.match(pattern, text)` should work identically but use NFA path
**Validation**: All existing tests must pass without modification

### Pattern Matching Behavior
**Requirement**: Ensure all pattern matching behavior remains identical after algorithm unification
**Implementation**: Preserve exact match results, capture groups, and error handling
**Scenario**: Pattern `hello\s+world` should match exactly the same way before and after changes
**Validation**: Character classes, quantifiers, anchors, and capture groups work identically

## ADDED Requirements

### Linear-Time Guarantee Validation
**Requirement**: Ensure all pattern matching operations maintain O(n) complexity
**Implementation**: Use only Thompson NFA algorithm for all matching operations
**Scenario**: Pattern `(a+)+b` on input `"aaaaaaaaaaaaaaaaaaaaaa"` should complete in linear time
**Validation**: No exponential time complexity for any pattern type

### Algorithm Consistency Verification
**Requirement**: Verify unified NFA algorithm handles all regex constructs correctly
**Implementation**: Test literals, character classes, quantifiers, alternation, and captures
**Scenario**: Complex pattern `[a-z]+(\d+|[A-Z]+)*` should match correctly using NFA only
**Validation**: Full RE2 feature compatibility maintained through NFA implementation