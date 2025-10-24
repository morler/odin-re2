## Context
The regex engine has critical syntax failures that make it unusable. Core features like alternation (|), wildcards (.), and escape sequences are completely broken.

## Goals
- Fix the most critical syntax gaps identified in testing
- Keep changes minimal and focused
- Maintain existing performance characteristics

## Implementation Strategy
Fix syntax issues in the existing parser rather than redesigning the architecture. Focus on the specific failing features identified in the test results.