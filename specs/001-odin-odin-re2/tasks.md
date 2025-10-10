---
description: "Task list for Odin RE2 Implementation feature"
---

# Tasks: Odin RE2 Implementation

**Input**: Design documents from `/specs/001-odin-odin-re2/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: REQUIRED for RE2 implementation - all components must be tested for correctness and linear time behavior

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `regexp/`, `tests/` at repository root
- Paths follow the Odin package structure defined in plan.md

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create regexp package directory structure per implementation plan
- [ ] T002 Initialize Odin project with core dependencies (core:fmt, core:testing, core:strings, core:unicode)
- [ ] T003 [P] Configure Odin build system and project files
- [ ] T004 [P] Create basic documentation structure in docs/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Implement Arena memory allocator in regexp/memory.odin
- [ ] T006 [P] Implement ErrorCode enumeration and basic error handling in regexp/errors.odin
- [ ] T007 [P] Implement core AST node structures in regexp/ast.odin
- [ ] T008 Implement SparseSet data structure for NFA execution in regexp/sparse_set.odin
- [ ] T009 Create basic Regexp_Pattern structure and memory management in regexp/regexp.odin
- [ ] T010 Setup test framework structure and basic test utilities in tests/

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Basic Literal Matching (Priority: P1) 🎯 MVP

**Goal**: Compile and match simple literal string patterns using RE2-compatible API

**Independent Test**: Compile literal patterns like "hello", "test", "abc123" and verify they match correctly in target strings

### Tests for User Story 1 (REQUIRED for RE2 components) ⚠️

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**
**RE2 Implementation: All pathological patterns must be tested for linear time behavior**

- [ ] T011 [P] [US1] Basic literal matching test in tests/test_basic_matching.odin
- [ ] T012 [P] [US1] Empty pattern matching test in tests/test_basic_matching.odin
- [ ] T013 [P] [US1] Escape sequence handling test in tests/test_basic_matching.odin
- [ ] T014 [P] [US1] Linear time verification for literal patterns in tests/test_performance.odin
- [ ] T015 [P] [US1] Memory leak detection test in tests/test_memory.odin

### Implementation for User Story 1

- [ ] T016 [US1] Implement literal AST node parsing in regexp/parser.odin
- [ ] T017 [US1] Implement basic pattern compilation (literals only) in regexp/regexp.odin
- [ ] T018 [US1] Implement literal matching engine in regexp/matcher.odin
- [ ] T019 [US1] Implement public API functions: regexp(), free_regexp(), match() in regexp/regexp.odin
- [ ] T020 [US1] Add UTF-8 validation for input text in regexp/matcher.odin
- [ ] T021 [US1] Add error handling for invalid patterns in regexp/parser.odin

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Character Classes and Special Characters (Priority: P2)

**Goal**: Use character classes [a-z], special characters like . (dot), and basic quantifiers * + ? for more flexible pattern matching

**Independent Test**: Match patterns like "[0-9]+", "a.*b", "test?" against various input strings

### Tests for User Story 2 (REQUIRED for RE2 components) ⚠️

- [ ] T022 [P] [US2] Character class matching test in tests/test_char_classes.odin
- [ ] T023 [P] [US2] Special character (dot) matching test in tests/test_char_classes.odin
- [ ] T024 [P] [US2] Basic quantifier test in tests/test_quantifiers.odin
- [ ] T025 [P] [US2] Complex pattern test combining classes and quantifiers in tests/test_comprehensive.odin
- [ ] T026 [P] [US2] Linear time verification for quantifier patterns in tests/test_performance.odin

### Implementation for User Story 2

- [ ] T027 [P] [US2] Implement character class parsing in regexp/parser.odin
- [ ] T028 [P] [US2] Implement character range handling in regexp/parser.odin
- [ ] T029 [US2] Implement special character (dot, anchors) parsing in regexp/parser.odin
- [ ] T030 [US2] Implement quantifier parsing (*, +, ?, {n}) in regexp/parser.odin
- [ ] T031 [US2] Extend matcher to handle character classes in regexp/matcher.odin
- [ ] T032 [US2] Extend matcher to handle quantifiers in regexp/matcher.odin
- [ ] T033 [US2] Add UTF-8 character class support in regexp/matcher.odin
- [ ] T053 [US2] Implement configurable DFA state cache with memory limits in regexp/matcher.odin

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Groups and Alternation (Priority: P3)

**Goal**: Use capturing groups (parentheses) and alternation (pipe operator) for complex pattern matching and extraction

**Independent Test**: Test with patterns like "(hello|world)", "(\d+)-(\d+)" against appropriate text

### Tests for User Story 3 (REQUIRED for RE2 components) ⚠️

- [ ] T034 [P] [US3] Capturing group test in tests/test_groups.odin
- [ ] T035 [P] [US3] Alternation (pipe) test in tests/test_groups.odin
- [ ] T036 [P] [US3] Nested group test in tests/test_groups.odin
- [ ] T037 [P] [US3] Capture extraction test in tests/test_comprehensive.odin
- [ ] T038 [P] [US3] Linear time verification for group patterns in tests/test_performance.odin

### Implementation for User Story 3

- [ ] T039 [P] [US3] Implement group parsing (capturing and non-capturing) in regexp/parser.odin
- [ ] T040 [P] [US3] Implement alternation (pipe) parsing in regexp/parser.odin
- [ ] T041 [US3] Extend AST to support group and alternation nodes in regexp/ast.odin
- [ ] T042 [US3] Implement capture group tracking in matcher in regexp/matcher.odin
- [ ] T043 [US3] Extend Match_Result to include capture arrays in regexp/regexp.odin
- [ ] T044 [US3] Implement group execution logic in NFA in regexp/matcher.odin

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T045 [P] Add comprehensive documentation in docs/SyntaxReference.md
- [ ] T046 [P] Add usage examples in docs/Examples.md
- [ ] T047 [P] Performance optimization across all components
- [ ] T048 [P] Additional edge case tests in tests/test_comprehensive.odin
- [ ] T049 Implement DFA state caching for performance optimization in regexp/matcher.odin
- [ ] T050 Add match_string() convenience function in regexp/regexp.odin
- [ ] T051 Run quickstart.md validation and create examples/
- [ ] T052 Final performance benchmarking against RE2 targets

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Extends US1 functionality but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Builds on US1/US2 but independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Parser implementation before matcher implementation
- Core implementation before API integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Parser components within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Basic literal matching test in tests/test_basic_matching.odin"
Task: "Empty pattern matching test in tests/test_basic_matching.odin"
Task: "Escape sequence handling test in tests/test_basic_matching.odin"
Task: "Linear time verification for literal patterns in tests/test_performance.odin"
Task: "Memory leak detection test in tests/test_memory.odin"

# After tests fail, implement core components:
Task: "Implement literal AST node parsing in regexp/parser.odin"
Task: "Implement basic pattern compilation (literals only) in regexp/regexp.odin"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- RE2 linear-time complexity must be preserved in all implementations
- Memory management must use explicit new()/free() patterns
- All tests must pass before considering any story complete