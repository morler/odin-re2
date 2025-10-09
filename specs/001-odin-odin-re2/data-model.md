# Data Model - Odin RE2 Implementation

**Date**: 2025-10-09  
**Purpose**: Core data structures and entity definitions for RE2-compatible regex engine

## Core Entities

### Regexp_Pattern
**Purpose**: Main public API structure representing a compiled regular expression
**Key Attributes**:
- `ast: ^Regexp` - Parsed abstract syntax tree
- `arena: ^Arena` - Memory arena for all allocations
- `error: ErrorCode` - Compilation error status
**Validation Rules**: Must always have valid arena, error must be checked before use
**State Transitions**: Created → Compiled → Freed (no reuse after freeing)

### Regexp (AST Node)
**Purpose**: Abstract syntax tree node representing regex components
**Key Attributes**:
- `op: Regexp_Op` - Operation type (Literal, CharClass, Capture, etc.)
- `flags: Flags` - Regex flags (NonGreedy, CaseInsensitive, etc.)
- `data: rawptr` - Type-specific data pointer
**Validation Rules**: Data pointer must match op type, flags must be valid combinations
**Relationships**: Tree structure via data pointers (concatenation, alternation, capture groups)

### Arena
**Purpose**: High-performance memory allocator for regex compilation and matching
**Key Attributes**:
- `data: []byte` - Raw memory buffer
- `offset: int` - Current allocation position
- `capacity: int` - Total buffer size
- `chunks: []Memory_Chunk` - Memory pool for efficiency
**Validation Rules**: offset ≤ capacity, chunks must be valid memory blocks
**State Transitions**: Created → Allocations → Reset → Freed

### Match_Result
**Purpose**: Result structure containing match information and captures
**Key Attributes**:
- `matched: bool` - Whether pattern matched
- `full_match: Range` - Location of full match
- `captures: []Range` - Capture group locations
- `text: string` - Original input text
**Validation Rules**: If matched=true, full_match must be valid, captures length must match pattern

### Sparse_Set
**Purpose**: Efficient state set management for NFA execution
**Key Attributes**:
- `dense: []uint32` - Dense array of elements
- `sparse: []uint32` - Sparse index array
- `size: uint32` - Current number of elements
**Validation Rules**: size ≤ len(dense), sparse indices must be valid
**Invariants**: sparse[dense[i]] = i for all i < size

## Instruction Set Architecture

### Inst (Instruction)
**Purpose**: Virtual machine instruction for regex execution
**Key Attributes**:
- `op: Inst_Op` - Operation code (Alt, Match, Rune, etc.)
- `out: uint32` - Default next instruction
- `arg: uint32` - Argument (jump target or parameter)
- `rune: [4]rune` - Character data for matching instructions
**Validation Rules**: op must be valid, out/arg must be within program bounds

### Inst_Op Enumeration
**Values**: Alt, AltMatch, Capture, EmptyWidth, Fail, Match, Nop, Rune, Rune1, RuneAny, RuneAnyNotNL, RuneAny
**Purpose**: Defines all operations in RE2's virtual machine
**Constraints**: Must match RE2 exactly for compatibility

## Memory Management Data Structures

### Memory_Chunk
**Purpose**: Individual memory block in arena allocator
**Key Attributes**:
- `data: []byte` - Memory block
- `size: int` - Block size
**Validation Rules**: data must not be nil, size > 0

### String_View
**Purpose**: Zero-copy string representation for performance
**Key Attributes**:
- `data: [^]u8` - Pointer to string data
- `len: int` - String length
**Validation Rules**: data must not be nil if len > 0

## Unicode Processing

### UTF8_Iterator
**Purpose**: Efficient UTF-8 character iteration
**Key Attributes**:
- `data: [^]u8` - UTF-8 byte sequence
- `pos: int` - Current position
- `current: rune` - Current Unicode character
- `width: int` - Width of current character in bytes
**Validation Rules**: pos ≤ len(data), width must be 1-4 for valid UTF-8

### Char_Range
**Purpose**: Unicode character range for character classes
**Key Attributes**:
- `lo: rune` - Range start (inclusive)
- `hi: rune` - Range end (inclusive)
**Validation Rules**: lo ≤ hi, must be valid Unicode code points

## Error Handling

### ErrorCode
**Purpose**: Enumeration of all possible error conditions
**Values**: NoError, ParseError, MemoryError, InternalError, UTF8Error, TooComplex, etc.
**Usage**: Returned from all API functions to indicate success/failure

### Error_Info
**Purpose**: Detailed error context information
**Key Attributes**:
- `code: ErrorCode` - Error type
- `pos: int` - Position in pattern where error occurred
- `message: string` - Human-readable description
- `pattern: string` - Original pattern for context
**Validation Rules**: pos must be within pattern bounds, message must be descriptive

## Performance Optimization Structures

### DFA_State
**Purpose**: DFA state for cached matching results
**Key Attributes**:
- `flag: State_Flag` - State type flags
- `inputs: [256]uint32` - Next state for each possible input
- `next: ^DFA_State` - Linked list pointer
**Validation Rules**: Must be null-terminated in cache lists

### State_Cache
**Purpose**: Bounded cache for DFA states
**Key Attributes**:
- `size: int` - Current cache size
- `max_size: int` - Memory limit
- `list: [256]^DFA_State` - Hash table buckets
**Validation Rules**: size ≤ max_size, must enforce memory bounds

## Data Relationships

```
Regexp_Pattern
├── Arena (owns all memory)
│   ├── Regexp (AST root)
│   │   ├── Literal_Data
│   │   ├── CharClass_Data
│   │   ├── Capture_Data
│   │   └── Repeat_Data
│   └── Inst[] (compiled program)
├── Match_Result (created per match)
│   ├── Range[]
│   └── captures[]
└── Error_Info (if compilation failed)

Execution Context:
├── Sparse_Set (NFA states)
├── Thread[] (execution threads)
├── UTF8_Iterator (text processing)
└── State_Cache (DFA optimization)
```

## Validation Rules Summary

### Memory Safety
- All allocations must use arena allocator
- free_regexp() must be called for all compiled patterns
- No dangling pointers after arena cleanup

### Type Safety  
- Regexp.data pointer must match op type
- Instruction fields must be valid for operation type
- Array bounds must be checked where required

### Performance Constraints
- DFA cache must respect memory limits
- SparseSet operations must remain O(1)
- String operations should use zero-copy when possible

### RE2 Compatibility
- AST structure must match RE2 exactly
- Instruction set must be identical
- Error codes and messages must align with RE2

## State Transition Diagrams

### Pattern Lifecycle
```
Created → Compiled → [Matching Operations] → Freed
   ↓         ↓              ↓
Error ← Parse ← Invalid ← Runtime Error
```

### Match Execution
```
Start → NFA Execution → [DFA Cache Hit?] → Match Found/Not Found
           ↓                    ↓
    State Management ← Cache Miss → DFA Construction
```

This data model provides the foundation for implementing a correct, efficient, and RE2-compatible regular expression engine in Odin while maintaining the project's core principles of algorithm fidelity, linear-time complexity, and memory safety.