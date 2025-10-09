<!--
Sync Impact Report:
- Version change: None → 1.0.0 (initial constitution)
- Modified principles: None (initial creation)
- Added sections: Core Principles (5), Technical Constraints, Development Workflow, Governance
- Removed sections: None
- Templates requiring updates: 
  ✅ .specify/templates/plan-template.md (Constitution Check section updated)
  ✅ .specify/templates/spec-template.md (RE2-Specific Requirements added)
  ✅ .specify/templates/tasks-template.md (RE2 testing requirements added)
- Follow-up TODOs: None
-->

# Odin RE2 Constitution

## Core Principles

### I. Algorithm Fidelity
RE2 algorithm implementation must be exact, preserving all data structures, state machines, and linear-time complexity guarantees. No deviations from RE2's core design are permitted, even for optimization opportunities. The complexity of RE2 is necessary for its performance guarantees.

### II. Linear-Time Complexity Guarantee
All regex patterns must execute in O(n) time where n is input length. No exponential backtracking is permissible. DFA state cache must be memory-bounded and configurable. This guarantee is non-negotiable and must be preserved in all optimizations.

### III. Memory Safety & Odin Idioms
Use Odin's explicit memory management with new()/free() patterns. Implement arena allocation for regexp nodes. All memory must be explicitly cleaned up using free_regexp() in test procedures. No garbage collection dependencies for core algorithm components.

### IV. Test-Driven Implementation
TDD is mandatory: Write tests first, ensure they fail, then implement. Port complete RE2 test suite without modification. All pathological patterns that cause exponential behavior in other engines must be tested and verified to remain linear.

### V. Unicode & UTF-8 Compliance
Full Unicode UTF-8 support throughout the implementation. Character classes, string handling, and all text processing must be UTF-8 aware. Invalid UTF-8 handling must match RE2 behavior exactly.

## Technical Constraints

### RE2 Compatibility Requirements
- AST structures must match RE2 exactly - no additional node types or missing fields
- Instruction set must be identical to RE2's Inst union representation
- SparseSet data structure implementation is critical for NFA execution performance
- No backreferences supported (RE2 design choice for linear time)

### Performance Standards
- Within 2x RE2 performance on common patterns
- Bounded memory usage with configurable DFA state cache limits
- O(pattern_length) compilation time guarantees
- Linear stack usage for recursive patterns

### Code Quality Standards
- Use tabs for indentation, 1TBS brace style
- Types: Pascal_Case, Procedures: snake_case, Variables: snake_case, Constants: ALL_CAPS
- Explicit imports: core libs first, then local packages
- Trailing commas required for multi-line arrays/structs

## Development Workflow

### Build & Validation Process
- `odin build filename.odin -file` for single file builds
- `odin build . -o:speed` for optimized builds
- `odin test .` for all tests, `odin test filename.odin -file` for single tests
- `odin check . -vet -vet-style` must pass before all commits
- Test both success and error paths for all components

### Implementation Phases
1. **Regexp AST and Parser** - Build RE2-compatible AST with all node types
2. **NFA Construction** - Thompson construction with SparseSet implementation
3. **DFA Construction** - Lazy DFA with subset construction and memory limits
4. **Integration** - Memory management, API design, complete test suite port

## Governance

This constitution supersedes all other development practices and guidelines. All code changes must verify compliance with these principles. Amendments require:

- Documentation of proposed changes with impact analysis
- Approval through project maintainers
- Migration plan for any breaking changes
- Version bump according to semantic versioning rules

All pull requests must include constitution compliance verification. Complexity beyond essential algorithm requirements must be explicitly justified. Use AGENTS.md for runtime development guidance and build commands.

**Version**: 1.0.0 | **Ratified**: 2025-10-09 | **Last Amended**: 2025-10-09