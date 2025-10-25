## 1. Analysis and Planning
- [ ] 1.1 Identify all syntax errors from LSP diagnostics
- [ ] 1.2 Categorize errors by type (syntax vs file type mismatches)
- [ ] 1.3 Prioritize critical Odin syntax errors

## 2. Fix Odin Syntax Errors
- [ ] 2.1 Fix map syntax in examples/basic_usage.odin (-> to :)
- [ ] 2.2 Add package declaration to compile_alt_debug.odin
- [ ] 2.3 Fix any other Odin syntax issues in example files

## 3. Handle Non-Odin Files
- [ ] 3.1 Rename TSV files to prevent Odin parsing
- [ ] 3.2 Move or rename markdown files incorrectly parsed
- [ ] 3.3 Handle encoding issues in data files

## 4. Validation
- [ ] 4.1 Run LSP diagnostics to verify fixes
- [ ] 4.2 Ensure all Odin files compile correctly
- [ ] 4.3 Test that examples still work as expected