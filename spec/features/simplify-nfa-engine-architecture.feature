@done
@feature-management
@parser
@optimization
@memory
@matcher
@phase1
@SIMP-001
Feature: Simplify NFA Engine Architecture
  """
  Critical requirements: All benchmarks must pass, 50% code reduction target in matcher.odin, preserve functionality
  """

  # ========================================
  # EXAMPLE MAPPING CONTEXT
  # ========================================
  #
  # BUSINESS RULES:
  #   1. Public API must remain unchanged - no breaking changes for users
  #   2. RE2 compatibility must be preserved - all valid regex patterns should behave identically
  #   3. Code reduction target: eliminate at least 50% of lines in matcher.odin while maintaining functionality
  #   4. Public API must remain completely stable - only internal implementation can change
  #   5. Linear-time performance guarantee is non-negotiable - must be preserved in simplification
  #   6. Clean up both matcher.odin and memory.odin - eliminate over-engineering in both modules
  #   7. All existing benchmarks must pass - simplification cannot break performance or correctness
  #   8. Arena allocator should be simplified to basic allocation without over-engineered alignment and pooling
  #   9. Thread pool elimination must not affect linear-time guarantee - use simple state management instead
  #
  # EXAMPLES:
  #   1. Thread pool with 64 threads and complex allocation patterns should be replaced by simple recursive NFA execution
  #   2. State vector with bit manipulation and deduplication should be replaced by simple slice of active states
  #   3. 32-element capture buffer copying should be replaced by dynamic slice allocation only when needed
  #   4. Complex 64-byte aligned arena allocation should be replaced by simple 8-byte aligned allocation
  #   5. Memory pool with freelist and tracking should be replaced by direct arena allocation
  #   6. All benchmark tests (performance, functionality, memory) must pass after simplification
  #
  # QUESTIONS (ANSWERED):
  #   Q: What is our compatibility commitment? Can we change internal APIs while keeping public API stable?
  #   A: true
  #
  #   Q: Do we need to maintain the current 'linear-time performance guarantee' or can we accept small regressions for simplicity?
  #   A: true
  #
  #   Q: Should we simplify only matcher.odin or also clean up memory.odin's over-engineered arena allocator?
  #   A: true
  #
  #   Q: What is our test coverage requirement? Must all existing benchmarks pass after simplification?
  #   A: true
  #
  # ========================================
  Background: User Story
    As a developer maintaining Odin RE2
    I want to simplify the over-engineered NFA engine
    So that I get cleaner, more maintainable code without losing performance or functionality

  Scenario: Replace thread pool with simple NFA execution
    Given the matcher contains a complex thread pool with 64 threads and capture buffers
    When the thread pool is replaced with simple recursive NFA execution
    Then the code should be reduced by at least 200 lines while maintaining linear-time performance

  Scenario: Replace state vectors with simple state slices
    Given the matcher uses complex bit vectors for state representation and deduplication
    When state vectors are replaced with simple slices of active states
    Then the state management code should be reduced by at least 150 lines

  Scenario: Simplify capture buffer management
    Given the system uses 32-element fixed capture buffers with manual copying
    When capture buffers are replaced with dynamic slice allocation
    Then capture management code should be simplified by at least 100 lines

  Scenario: Simplify arena allocator alignment
    Given the arena allocator uses complex 64-byte alignment with padding calculations
    When alignment is simplified to basic 8-byte alignment
    Then memory allocation code should be reduced by at least 80 lines

  Scenario: Eliminate memory pool complexity
    Given the system uses memory pools with freelists and tracking
    When memory pools are replaced with direct arena allocation
    Then pool management code should be eliminated entirely

  Scenario: Validate all benchmarks pass after simplification
    Given all simplification changes are implemented
    When the complete benchmark suite is executed
    Then all performance, functionality, and memory benchmarks must pass without regression
