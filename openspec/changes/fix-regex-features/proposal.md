## Why
The Odin RE2 regex engine currently lacks critical regex features that are essential for RE2 compatibility and practical usage. Users encounter compilation failures or incorrect behavior when trying to use standard regex constructs like word boundaries, backreferences, lookaheads, lazy quantifiers, and Unicode properties.

## What Changes
- **Add word boundary matching**: Implement `\b` and `\B` anchors with proper word character detection
- **Add backreference support**: Implement `\1` and `\g{name}` syntax for referring to captured groups
- **Add lookahead assertions**: Implement positive `(?=...)` and negative `(?!...)` lookaheads
- **Fix lazy quantifier implementation**: Correct the behavior of `*?`, `+?`, and `??` quantifiers
- **Expand Unicode property support**: Enhance `\p{Script}` and related Unicode property matching

## Impact
- Affected specs: `regexp/parser`, `regexp/matcher`, `regexp/ast`
- Affected code: `src/parser.odin`, `src/regexp.odin`, `src/ast.odin`, `src/matcher.odin`
- **BREAKING**: May change compilation behavior for previously unsupported patterns
- Performance impact: Minimal for existing features, new features will have appropriate optimizations