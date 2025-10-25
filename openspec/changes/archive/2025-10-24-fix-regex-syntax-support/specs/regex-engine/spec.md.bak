## ADDED Requirements

### Requirement: Basic Alternation Support
The regex engine SHALL support simple alternation operator `|`.

#### Scenario: Simple alternation
- **WHEN** pattern `a|b` is compiled and matched against input `a`
- **THEN** the engine SHALL return a successful match

#### Scenario: Alternation no match
- **WHEN** pattern `a|b` is compiled and matched against input `c`
- **THEN** the engine SHALL return no match

### Requirement: Wildcard Character Support
The regex engine SHALL support wildcard character `.`.

#### Scenario: Wildcard matches any character
- **WHEN** pattern `a.c` is compiled and matched against input `abc`
- **THEN** the engine SHALL return a successful match

### Requirement: Escape Sequence Support
The regex engine SHALL support basic escape sequences.

#### Scenario: Escape dot character
- **WHEN** pattern `hello\.world` is compiled and matched against input `hello.world`
- **THEN** the engine SHALL return a successful match

#### Scenario: Escape whitespace
- **WHEN** pattern `hello\sworld` is compiled and matched against input `hello world`
- **THEN** the engine SHALL return a successful match

### Requirement: Basic Quantifier Support
The regex engine SHALL support simple quantifier syntax.

#### Scenario: Exact repetition
- **WHEN** pattern `a{3}` is compiled and matched against input `aaa`
- **THEN** the engine SHALL return a successful match