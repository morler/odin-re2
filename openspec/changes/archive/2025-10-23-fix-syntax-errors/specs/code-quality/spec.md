## ADDED Requirements
### Requirement: Code Syntax Validation
All Odin source files SHALL compile without syntax errors when validated by the Odin Language Server.

#### Scenario: LSP validation passes
- **WHEN** Odin LSP diagnostics are run on the project
- **THEN** zero syntax errors are reported for valid Odin source files

#### Scenario: Non-Odin files are ignored
- **WHEN** LSP scans the project directory
- **THEN** non-Odin files (.md, .tsv, .txt, etc.) are not parsed as Odin code

## MODIFIED Requirements
### Requirement: Example File Correctness
All example files SHALL demonstrate correct Odin syntax and compile successfully.

#### Scenario: Map syntax is correct
- **WHEN** maps are defined in Odin code
- **THEN** they use colon syntax (key: value) not arrow syntax (key -> value)

#### Scenario: Standalone files have packages
- **WHEN** a .odin file contains Odin procedures
- **THEN** it includes a proper package declaration at the top