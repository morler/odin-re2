# Project Context

## Purpose
Odin RE2 is a high-performance regular expression library for the Odin programming language, implementing Google RE2-compatible linear-time matching with guaranteed memory safety. The project aims to provide Odin developers with a production-ready regex engine that avoids catastrophic backtracking while maintaining excellent performance characteristics.

## Tech Stack
- **Primary Language**: Odin 2024.09+
- **Core Libraries**: core:fmt, core:testing, core:strings, core:unicode
- **Memory Management**: Custom Arena allocator (deterministic, zero-fragmentation)
- **Algorithm**: Thompson NFA + state vector deduplication
- **Architecture**: Modular design with clear separation of concerns
- **Testing**: Comprehensive benchmarking and unit testing framework

## Project Conventions

### Code Style
- **Indentation**: Tabs (Odin standard)
- **Naming**: PascalCase for types, camelCase for procedures
- **Documentation**: Comprehensive comments with Chinese explanations
- **Error Handling**: Return error codes, use explicit checking
- **Memory Management**: Arena allocation patterns, explicit cleanup

### Architecture Patterns
- **Modular Design**: Clear module boundaries (regexp/, tests/, benchmark/)
- **Zero-Allocation**: Runtime patterns avoid dynamic memory allocation
- **Linear-Time Guarantee**: All operations maintain O(n) complexity
- **Memory Safety**: Bounded memory usage, no exponential growth
- **Arena Allocation**: Deterministic memory management

### Testing Strategy
- **Unit Tests**: Comprehensive coverage of core functionality
- **Benchmarks**: Performance regression testing vs Google RE2
- **Memory Tests**: Leak detection and usage validation
- **Integration Tests**: Real-world usage scenarios
- **Cross-Platform**: Windows (MSYS2), Linux, macOS compatibility

### Git Workflow
- **Branch Strategy**: Feature branches from main (002-description-context-odin)
- **Commit Messages**: Conventional commits with Chinese descriptions
- **Review Process**: Code review for all changes
- **Documentation**: Update docs with API changes

## Domain Context

### Regular Expression Engine Domain
- **Thompson NFA**: Non-deterministic finite automaton construction
- **Linear Time Guarantee**: O(n) matching time where n is input length
- **Memory Safety**: Bounded memory usage prevents DoS attacks
- **UTF-8 Support**: Efficient Unicode text processing
- **Arena Allocation**: Deterministic memory management pattern

### Performance Characteristics
- **Compile Performance**: 2-2.5x faster than Google RE2
- **Memory Efficiency**: 50% less memory usage, zero fragmentation
- **Match Performance**: 70-80% of Google RE2 (optimization target)
- **Scalability**: Linear scaling with input size

## Important Constraints

### Technical Constraints
- **Linear Time**: All regex operations must maintain O(n) complexity
- **Memory Bounded**: No exponential memory growth
- **No Backtracking**: Avoid catastrophic backtracking patterns
- **RE2 Compatible**: API compatibility with Google RE2
- **Arena Allocation**: Consistent memory management patterns

### Performance Constraints
- **Compile Speed**: Must remain 2x+ faster than Google RE2
- **Memory Usage**: Must maintain 50%+ memory efficiency advantage
- **Match Speed**: Target 90%+ of Google RE2 performance
- **Cache Efficiency**: Maintain high cache locality

### Platform Constraints
- **Odin Native**: Must work with Odin's type system and memory model
- **Cross-Platform**: Windows (MSYS2), Linux, macOS support
- **No External Dependencies**: Use only core libraries
- **Thread Safety**: Arena allocation is thread-local

## External Dependencies

### Core Dependencies (Odin Standard Library)
- **core:fmt**: String formatting and I/O
- **core:testing**: Testing framework
- **core:strings**: String manipulation utilities
- **core:unicode**: Unicode character processing
- **core:time**: Performance measurement and timing
- **core:os**: Platform-specific operations

### Development Tools
- **OpenSpec**: Specification-driven development
- **CodeIndex**: Code analysis and search tools
- **Custom Benchmark Framework**: Performance testing vs Google RE2
- **Memory Profiling**: Arena allocation tracking and analysis

### Reference Implementations
- **Google RE2**: Algorithm reference and compatibility target
- **Thompson's Construction**: NFA construction algorithm reference
- **UTF-8 Specification**: Unicode text processing standard