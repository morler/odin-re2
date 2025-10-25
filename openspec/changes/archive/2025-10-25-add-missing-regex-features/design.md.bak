## Context
The Odin RE2 engine handles basic regex patterns well but lacks commonly used features that prevent real-world usage: Unicode properties for international text, lookbehinds for complex matching, and basic flags for case/line handling.

## Goals / Non-Goals
- Goals: Enable real-world regex usage with Unicode, lookbehinds, and flags
- Non-Goals: Full RE2 feature parity, advanced optimization, experimental features

## Decisions
- Decision: Focus on high-impact missing features used in 80% of real regex patterns
- Alternatives considered: Full RE2 compatibility (too large), Minimal fixes (insufficient)

## Trade-offs
- Adding features increases complexity but is necessary for practical use
- Unicode properties add memory cost for lookup tables
- Lookbehinds increase matcher complexity but provide essential functionality

## Implementation Plan
1. Extend AST with minimal new node types
2. Update parser for new syntax
3. Implement matching logic incrementally
4. Add comprehensive tests