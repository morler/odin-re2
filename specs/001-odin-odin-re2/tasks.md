---
description: "Task list for Odin RE2 Implementation feature"
---

# Tasks: Odin RE2 Implementation

**Input**: Design documents from `/specs/001-odin-odin-re2/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/
**Tests**: Included as required for RE2 components to ensure compatibility and linear-time guarantees.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `regexp/`, `tests/` at repository root
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create project structure per implementation plan in regexp/ and tests/
- [X] T002 Initialize Odin project with core:fmt, core:testing, core:strings, core:unicode dependencies
- [X] T003 [P] Configure linting and formatting tools (odin check -vet -vet-style)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Setup arena allocation framework in regexp/memory.odin
- [X] T005 [P] Implement SparseSet data structure in regexp/sparse_set.odin for O(1) state management
- [X] T006 [P] Define core instruction set (Inst, Inst_Op) in regexp/inst.odin matching RE2 exactly
- [X] T007 Create base AST structures (Regexp, Regexp_Op) in regexp/ast.odin
- [X] T008 Implement error handling (ErrorCode, Error_Info) in regexp/errors.odin
- [X] T009 Setup UTF-8 iterator and string view utilities in regexp/memory.odin

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Basic Literal Matching (Priority: P1) 🎯 MVP

**Goal**: Compile and match simple literal string patterns using RE2-compatible API in Odin language

**Independent Test**: Can be fully tested by compiling literal patterns like "hello", "test", "abc123" and verifying they match correctly in target strings

### Tests for User Story 1 (REQUIRED for RE2 components) ⚠️

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**
**RE2 Implementation: All pathological patterns must be tested for linear time behavior**

- [X] T010 [P] [US1] Contract test for regexp() and match() functions in tests/test_basic_matching.odin
- [X] T011 [P] [US1] Integration test for literal pattern matching in tests/test_basic_matching.odin
- [X] T012 [P] [US1] RE2 compliance test for literal patterns in regexp/test_basic_matching.odin
- [X] T013 [P] [US1] Linear time verification for pathological literal patterns in regexp/test_basic_matching_linear.odin

### Implementation for User Story 1

- [X] T014 [P] [US1] Create Regexp_Pattern struct and basic API in regexp/regexp.odin
- [X] T015 [P] [US1] Implement literal AST node in regexp/ast.odin
- [X] T016 [US1] Add literal parsing in regexp/parser.odin (depends on T015)
- [X] T017 [US1] Implement basic NFA execution for literals in regexp/matcher.odin
- [X] T018 [US1] Add Match_Result structure and matching logic in regexp/regexp.odin
- [X] T019 [US1] Integrate arena allocation for pattern compilation in regexp/regexp.odin

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Character Classes and Special Characters (Priority: P2)

**Goal**: Use character classes [a-z], special characters like . (dot), and basic quantifiers * + ? for more flexible pattern matching

**Independent Test**: Can be tested by matching patterns like "[0-9]+", "a.*b", "test?" against various input strings

### Tests for User Story 2 (REQUIRED for RE2 components) ⚠️

- [X] T020 [P] [US2] Contract test for character class compilation in tests/test_char_classes.odin
- [X] T021 [P] [US2] Integration test for dot and quantifier matching in tests/test_char_classes.odin
- [X] T022 [P] [US2] RE2 compliance test for character classes in regexp/test_char_classes.odin
- [X] T023 [P] [US2] Linear time verification for pathological quantifier patterns in regexp/test_char_classes_linear.odin

### Implementation for User Story 2

- [X] T024 [P] [US2] Extend AST for character classes and quantifiers in regexp/ast.odin
- [X] T025 [US2] Implement character class parsing in regexp/parser.odin (depends on T024)
- [X] T026 [US2] Add quantifier handling in regexp/matcher.odin
- [X] T027 [US2] Implement dot (any character) matching in regexp/matcher.odin
- [X] T028 [US2] Integrate char class and quantifier execution in regexp/regexp.odin

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Groups and Alternation (Priority: P3)

**Goal**: Use capturing groups (parentheses) and alternation (pipe operator) for complex pattern matching and extraction

**Independent Test**: Can be tested with patterns like "(hello|world)", "(\d+)-(\d+)" against appropriate text

### Tests for User Story 3 (REQUIRED for RE2 components) ⚠️

- [X] T029 [P] [US3] Contract test for group and alternation compilation in tests/test_groups.odin
- [X] T030 [P] [US3] Integration test for capture group extraction in tests/test_groups.odin
- [X] T031 [P] [US3] RE2 compliance test for groups and alternation in regexp/test_groups.odin
- [X] T032 [P] [US3] Linear time verification for pathological group patterns in regexp/test_groups_linear.odin

### Implementation for User Story 3

- [X] T033 [P] [US3] Extend AST for capture groups and alternation in regexp/ast.odin
- [X] T034 [US3] Implement group and alternation parsing in regexp/parser.odin (depends on T033)
- [X] T035 [US3] Add capture group handling in regexp/matcher.odin
- [X] T036 [US3] Implement alternation logic in regexp/matcher.odin
- [X] T037 [US3] Integrate group and alternation execution in regexp/regexp.odin

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T038 [P] Documentation updates in docs/ and examples/
- [X] T039 Code cleanup and refactoring across regexp/ package
- [X] T040 Performance optimization for common patterns in regexp/matcher.odin
- [X] T041 [P] Additional unit tests for edge cases in tests/test_comprehensive.odin
- [X] T042 Security hardening for memory and input validation
- [X] T043 Run quickstart.md validation and update examples

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
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Contract test for regexp() and match() functions in tests/test_basic_matching.odin"
Task: "Integration test for literal pattern matching in tests/test_basic_matching.odin"

# Launch all models for User Story 1 together:
Task: "Create Regexp_Pattern struct and basic API in regexp/regexp.odin"
Task: "Implement literal AST node in regexp/ast.odin"
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
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence