## Why
Odin LSP reports 278 syntax errors across the project, primarily due to non-Odin files being incorrectly parsed as Odin code and Odin syntax errors in example files.

## What Changes
- Fix Odin map syntax in examples/basic_usage.odin (replace -> with :)
- Add package declarations to standalone Odin procedure files
- Move or rename non-Odin files that LSP incorrectly parses
- Fix character encoding issues in data files

## Impact
- Affected specs: code-quality, build-system
- Affected code: examples/, compile_alt_debug.odin, various data files
- **BREAKING**: None - these are bug fixes