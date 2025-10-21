## ADDED Requirements

### Requirement: Word Boundary AST Nodes
The AST SHALL include operation types for word boundary anchors.

#### Scenario: Word boundary node creation
- **WHEN** creating AST node for `\b`
- **THEN** use `OpWordBoundary` operation with no additional data

#### Scenario: Non-word boundary node creation
- **WHEN** creating AST node for `\B`
- **THEN** use `OpNoWordBoundary` operation with no additional data

### Requirement: Backreference AST Nodes
The AST SHALL include operation types and data structures for backreferences.

#### Scenario: Numeric backreference node
- **WHEN** creating AST node for `\1`
- **THEN** use backreference operation with numeric group identifier

#### Scenario: Named backreference node
- **WHEN** creating AST node for `\g{name}`
- **THEN** use backreference operation with named group identifier

#### Scenario: Backreference data structure
- **WHEN** storing backreference information
- **THEN** include group type (numeric/named) and identifier value

### Requirement: Lookahead AST Nodes
The AST SHALL include operation types and data structures for lookahead assertions.

#### Scenario: Positive lookahead node
- **WHEN** creating AST node for `(?=...)`
- **THEN** use positive lookahead operation with assertion sub-expression

#### Scenario: Negative lookahead node
- **WHEN** creating AST node for `(?!...)`
- **THEN** use negative lookahead operation with assertion sub-expression

#### Scenario: Lookahead data structure
- **WHEN** storing lookahead information
- **THEN** include assertion type (positive/negative) and sub-expression AST

### Requirement: Unicode Property AST Nodes
The AST SHALL include operation types and data structures for Unicode properties.

#### Scenario: Unicode property node
- **WHEN** creating AST node for `\p{Script}`
- **THEN** use Unicode property operation with script identifier and negation flag

#### Scenario: Negated Unicode property node
- **WHEN** creating AST node for `\P{Script}`
- **THEN** use Unicode property operation with script identifier and negation flag set

#### Scenario: Unicode property data structure
- **WHEN** storing Unicode property information
- **THEN** include property name, property type, and negation flag

## MODIFIED Requirements

### Requirement: Regexp_Op Enumeration
The Regexp_Op enum SHALL include new operation types for all added features.

#### Scenario: Extended operation enumeration
- **WHEN** defining Regexp_Op enum
- **THEN** include OpWordBoundary, OpNoWordBoundary, OpBackreference, OpLookahead, OpUnicodeProperty

### Requirement: AST Node Creation Functions
The AST creation functions SHALL support creating nodes for new feature types.

#### Scenario: Word boundary node creation
- **WHEN** calling make_word_boundary function
- **THEN** return properly initialized word boundary AST node

#### Scenario: Backreference node creation
- **WHEN** calling make_backreference function
- **THEN** return properly initialized backreference AST node

#### Scenario: Lookahead node creation
- **WHEN** calling make_lookahead function
- **THEN** return properly initialized lookahead AST node

#### Scenario: Unicode property node creation
- **WHEN** calling make_unicode_property function
- **THEN** return properly initialized Unicode property AST node

### Requirement: AST Validation
The AST validation functions SHALL validate new feature nodes for correctness.

#### Scenario: Backreference validation
- **WHEN** validating backreference node
- **THEN** check that referenced group exists and is valid

#### Scenario: Lookahead validation
- **WHEN** validating lookahead node
- **THEN** check that assertion sub-expression is valid

#### Scenario: Unicode property validation
- **WHEN** validating Unicode property node
- **THEN** check that property name is recognized and valid

### Requirement: AST Cloning
The AST cloning functions SHALL properly clone all new feature node types.

#### Scenario: Clone backreference node
- **WHEN** cloning AST with backreference
- **THEN** preserve backreference type and identifier

#### Scenario: Clone lookahead node
- **WHEN** cloning AST with lookahead
- **THEN** preserve assertion type and sub-expression

#### Scenario: Clone Unicode property node
- **WHEN** cloning AST with Unicode property
- **THEN** preserve property name and negation flag