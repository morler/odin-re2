# Odin RE2 Implementation

RE2-compatible regular expression engine implemented in Odin language.

## Features

- RE2-compatible regex syntax
- Linear-time complexity guarantee (O(n))
- Full Unicode UTF-8 support
- Thread-safe concurrent matching
- Memory-efficient arena allocation

## Building

```bash
odin build . -o:speed
```

## Testing

```bash
odin test .
```

## Usage

```odin
import "regexp"

pattern, err := regexp("hello\\s+world")
if err != .NoError {
    // handle error
}
defer regexp.free_regexp(pattern)

result, err := regexp.match(pattern, "hello   world")
if result.matched {
    // process match
}
```

## Structure

- `regexp/` - Core implementation package
- `tests/` - Test suite
- `examples/` - Usage examples
- `docs/` - Documentation