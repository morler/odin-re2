# Odin RE2 vs Rust regex – Functionality Comparison

_Generated on 2025-10-12 15:05:43_

## Summary
- Total cases: **41**
- Odin passes: **36**
- Rust passes: **40**
- Both pass: **36**
- Mismatches: **4**

## Detailed Mismatches

| Case | Odin Status | Rust Status | Odin Match | Rust Match | Notes |
|------|-------------|-------------|------------|------------|-------|
| dotall_fail | FAIL | PASS | True | False | Odin: unexpected match / Rust: - |
| lazy_quantifier | FAIL | PASS | False | True | Odin: missing expected match / Rust: - |
| word_boundary | FAIL | PASS | False | True | Odin: compile_error:ParseError / Rust: - |
| word_boundary_fail | FAIL | PASS | False | False | Odin: compile_error:ParseError / Rust: - |

## Data Artifacts
- `functional_odin.tsv` – raw Odin results
- `functional_rust.tsv` – raw Rust results

> These TSV files use tab delimiters and UTF-8 encoding.