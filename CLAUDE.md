<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# Claude Context for Odin RE2 Implementation

**Last Updated**: 2025-10-11  
**Current Feature Branch**: 001-odin-odin-re2

## Active Technologies

- Odin + core:fmt, core:testing, core:strings, core:unicode (001-odin-odin-re2)
- Arena Allocation Memory Management (001-odin-odin-re2)
- NFA-based Regex Engine (001-odin-odin-re2)
- RE2 Compatibility Layer (001-odin-odin-re2)

## Project Overview

**Current Feature**: Odin RE2 Implementation  
**Type**: Single Project (Library Package)  
**Performance Goals**: Within 2x RE2 performance, O(n) matching time, bounded memory usage

## Recent Changes

- 001-odin-odin-re2: Added Odin + core:fmt, core:testing, core:strings, core:unicode
- 001-odin-odin-re2: Added Arena Allocation Memory Management
- 001-odin-odin-re2: Added NFA-based Regex Engine
- 001-odin-odin-re2: Added RE2 Compatibility Layer

## Development Guidelines

### Language Conventions
Odin: Follow standard conventions - tabs for indentation, PascalCase for types, camelCase for procedures

### Commands
```bash
# Build the regex library
odin build . -o:speed

# Run tests  
odin test .

# Check code style and validate
odin check . -vet -vet-style
```

### Key Constraints
- Linear-time complexity guarantee for all regex operations
- No exponential backtracking allowed
- Arena allocation for memory management
- Full RE2 compatibility required
- Test-first development mandatory

### Current Implementation Status
Phase 1 Complete - Ready for Implementation
- Constitution Check: All gates PASSED
- Technical Context: Fully defined
- Project Structure: Single package structure (regexp/, tests/)
- All Phase 0 and Phase 1 artifacts generated

### Important Notes
- This is a performance-critical regex engine implementation
- Memory safety is paramount - use arena allocation patterns
- All regex patterns must execute in O(n) time
- RE2 test compatibility is non-negotiable
- Follow Odin best practices for memory management and performance
