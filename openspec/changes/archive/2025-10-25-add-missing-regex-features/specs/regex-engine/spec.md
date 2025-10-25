## ADDED Requirements
### Requirement: Unicode Property Support
The regex engine SHALL support Unicode property matching using `\p{...}` and `\P{...}` syntax for basic categories.

#### Scenario: Unicode letter property
- **WHEN** pattern `\p{L}` is compiled and matched against input `"a"`
- **THEN** the engine SHALL return a successful match

#### Scenario: Unicode number property
- **WHEN** pattern `\p{N}` is compiled and matched against input `"5"`
- **THEN** the engine SHALL return a successful match

#### Scenario: Negated Unicode property
- **WHEN** pattern `\P{L}` is compiled and matched against input `"5"`
- **THEN** the engine SHALL return a successful match

### Requirement: Lookbehind Assertions
The regex engine SHALL support positive and negative lookbehind assertions using `(?<=...)` and `(?<!...)` syntax.

#### Scenario: Positive lookbehind success
- **WHEN** pattern `(?<=abc)def` is compiled and matched against input `"abcdef"`
- **THEN** the engine SHALL match `"def"` with a successful lookbehind assertion

#### Scenario: Negative lookbehind success
- **WHEN** pattern `(?<!abc)def` is compiled and matched against input `"xyzdef"`
- **THEN** the engine SHALL match `"def"` with a successful negative lookbehind assertion

#### Scenario: Lookbehind failure
- **WHEN** pattern `(?<=abc)def` is compiled and matched against input `"xyzdef"`
- **THEN** the engine SHALL return no match

### Requirement: Basic Mode Modifiers
The regex engine SHALL support inline case-insensitive, multiline, and dotall mode modifiers.

#### Scenario: Case-insensitive modifier
- **WHEN** pattern `(?i)abc` is compiled and matched against input `"ABC"`
- **THEN** the engine SHALL return a successful match

#### Scenario: Multiline modifier
- **WHEN** pattern `(?m)^abc` is compiled and matched against input `"xyz\nabc"`
- **THEN** the engine SHALL match `"abc"` at the start of the line

#### Scenario: Dotall modifier
- **WHEN** pattern `(?s)abc.*def` is compiled and matched against input `"abc\ndef"`
- **THEN** the engine SHALL return a successful match across the newline

## MODIFIED Requirements
### Requirement: Basic Quantifier Support
The regex engine SHALL support simple quantifier syntax including both greedy and lazy variants.

#### Scenario: Exact repetition
- **WHEN** pattern `a{3}` is compiled and matched against input `aaa`
- **THEN** the engine SHALL return a successful match

#### Scenario: Greedy quantifier
- **WHEN** pattern `a+` is compiled and matched against input `"aaa"`
- **THEN** the engine SHALL match all three `a` characters greedily

#### Scenario: Lazy quantifier
- **WHEN** pattern `a+?` is compiled and matched against input `"aaa"`
- **THEN** the engine SHALL match only one `a` character lazily