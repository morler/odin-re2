## ADDED Requirements

### Requirement: Linear-Time Quantifier Matching
The regex engine SHALL match quantifiers (*, +, ?, {m,n}) in O(n) time complexity.

#### Scenario: Star quantifier with zero matches
- **WHEN** pattern "ab*c" matches text "ac"
- **THEN** return successful match with correct boundaries

#### Scenario: Star quantifier with multiple matches  
- **WHEN** pattern "ab*c" matches text "abbbbc"
- **THEN** return successful match with correct boundaries

#### Scenario: Plus quantifier minimum requirement
- **WHEN** pattern "ab+c" matches text "ac"
- **THEN** return no match (minimum one 'b' required)

#### Scenario: Plus quantifier with matches
- **WHEN** pattern "ab+c" matches text "abbbc"
- **THEN** return successful match with correct boundaries

### Requirement: Position-Aware Anchor Matching
The regex engine SHALL handle start (^) and end ($) anchors based on actual text position.

#### Scenario: Begin anchor at start
- **WHEN** pattern "^hello" matches text "hello world"
- **THEN** return successful match

#### Scenario: Begin anchor not at start
- **WHEN** pattern "^hello" matches text "world hello"
- **THEN** return no match

#### Scenario: End anchor at end
- **WHEN** pattern "world$" matches text "hello world"
- **THEN** return successful match

#### Scenario: End anchor not at end
- **WHEN** pattern "world$" matches text "world hello"
- **THEN** return no match

## MODIFIED Requirements

### Requirement: Recursive Depth Safety
The regex engine SHALL prevent stack overflow from excessive recursion.

#### Scenario: Deeply nested patterns
- **WHEN** processing extremely nested quantifier patterns
- **THEN** limit recursion depth and return error instead of crashing

#### Scenario: Performance timeout protection
- **WHEN** matching takes longer than reasonable threshold
- **THEN** abort with timeout error rather than infinite loop

### Requirement: Quantifier Error Handling
The regex engine SHALL handle quantifier edge cases correctly.

#### Scenario: Empty pattern with quantifier
- **WHEN** pattern ""* matches any text
- **THEN** return match at each valid position

#### Scenario: Invalid repeat ranges
- **WHEN** pattern "a{5,3}" has invalid range
- **THEN** return compilation error
