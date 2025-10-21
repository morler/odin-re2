## ADDED Requirements

### Requirement: Word Boundary AST Nodes (RE2 Compatible)
The AST SHALL include operation types for RE2-compatible word boundary anchors.

#### Scenario: Word boundary node creation
- **WHEN** creating AST node for `\b`
- **THEN** use `OpWordBoundary` operation with no additional data

#### Scenario: Non-word boundary node creation
- **WHEN** creating AST node for `\B`
- **THEN** use `OpNoWordBoundary` operation with no additional data

### Requirement: Unicode Property AST Nodes (RE2 Compatible)
The AST SHALL include operation types and data structures for RE2-compatible Unicode properties.

#### Scenario: Unicode property node with full name
- **WHEN** creating AST node for `\p{Greek}`
- **THEN** use Unicode property operation with script identifier and negation flag

#### Scenario: Negated Unicode property node with full name
- **WHEN** creating AST node for `\P{Greek}`
- **THEN** use Unicode property operation with script identifier and negation flag set

#### Scenario: Unicode property node with one-letter name
- **WHEN** creating AST node for `\pN`
- **THEN** use Unicode property operation with category identifier and negation flag

#### Scenario: Unicode property data structure
- **WHEN** storing Unicode property information
- **THEN** include property type (script/category), identifier, and negation flag

## MODIFIED Requirements

### Requirement: Regexp_Op Enumeration
The Regexp_Op enum SHALL include new operation types for RE2-compatible features.

#### Scenario: Extended operation enumeration
- **WHEN** defining Regexp_Op enum
- **THEN** include OpWordBoundary, OpNoWordBoundary, OpUnicodeProperty

### Requirement: AST Node Creation Functions
The AST creation functions SHALL support creating nodes for RE2-compatible feature types.

#### Scenario: Word boundary node creation
- **WHEN** calling make_word_boundary function
- **THEN** return properly initialized word boundary AST node

#### Scenario: Unicode property node creation
- **WHEN** calling make_unicode_property function
- **THEN** return properly initialized Unicode property AST node

### Requirement: AST Validation
The AST validation functions SHALL validate new feature nodes for RE2 compatibility.

#### Scenario: Unicode property validation
- **WHEN** validating Unicode property node
- **THEN** check that property name is recognized and valid per RE2 specification

#### Scenario: Lazy quantifier validation
- **WHEN** validating quantifier node with non-greedy flag
- **THEN** ensure non-greedy flag is properly set for supported quantifier types

### Requirement: AST Cloning
The AST cloning functions SHALL properly clone all new RE2-compatible feature node types.

#### Scenario: Clone Unicode property node
- **WHEN** cloning AST with Unicode property
- **THEN** preserve property type, identifier, and negation flag

#### Scenario: Clone word boundary node
- **WHEN** cloning AST with word boundary
- **THEN** preserve boundary type (word/non-word)

### Requirement: Non-RE2 Feature Exclusion
The AST SHALL not include operation types for features not supported by Google RE2.

#### Scenario: No backreference operations
- **WHEN** defining Regexp_Op enum
- **THEN** exclude OpBackreference and related operations

#### Scenario: No lookahead operations
- **WHEN** defining Regexp_Op enum
- **THEN** exclude OpLookahead and related operations