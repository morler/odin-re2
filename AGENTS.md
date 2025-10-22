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

﻿# Repository Guidelines

## Project Structure & Module Organization
- `main.odin` wires the CLI entry point and demonstration harness.
- `regexp/` contains the core engine: `parser.odin`, `matcher.odin`, `inst.odin`, and `memory.odin` for arena-based allocation.
- `tests/` hosts generated executables and `test_*.odin` cases consumed by `run_tests.odin`; treat `.odin.bak` as live sources managed by automation.
- `examples/` shows high-level usage; `docs/` stores spec notes; `benchmark/` compares Odin and Rust RE2 runners; `debug/` captures reproducible diagnostics—keep artifacts small.

## Build, Test, and Development Commands
- `odin build . -o:speed` produces `odin-re2.exe` with release optimizations.
- `odin test .` runs module-level unit tests embedded in the Odin packages.
- `odin test run_tests.odin` executes the custom integration suite that stitches the `.bak` cases together.
- `odin run benchmark/performance_benchmark.odin` validates throughput against the reference data in `benchmark/target`.

## Coding Style & Naming Conventions
- Format with `odin fmt .` before committing; the codebase assumes tab indentation and 100-column lines.
- Keep package names lower_snake_case (`regexp`), proc names lower_snake_case (`new_matcher`), and types in UpperCamelCase (`Matcher`).
- Favor explicit slices and structs over interface-style abstractions; avoid ad-hoc heap usage—leverage the arena helpers in `regexp/memory.odin`.

## Testing Guidelines
- New scenarios belong in `tests/test_<feature>.odin` with `@(test)` procs and descriptive log output for debugging.
- Ensure each test covers both matching and error behavior to guard the RE2 compatibility promise.
- When touching performance-sensitive paths, capture benchmarks via `odin run benchmark/performance_benchmark.odin` and document deltas in the PR.

## Commit & Pull Request Guidelines
- Follow the existing `type: summary` convention (`feat: add sparse set allocator`). Keep the first line ≤72 characters.
- PRs must describe the change, list affected modules, reference related specs in `specs/001-odin-odin-re2`, and attach test or benchmark output.
- Flag potential compatibility risks explicitly; the bar is “never break existing users” even for experimental agents.
