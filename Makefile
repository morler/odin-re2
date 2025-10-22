# Odin RE2 Makefile
.PHONY: lib test check clean help examples

# Default target
help:
	@echo "Odin RE2 Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  lib     - Build the regex library"
	@echo "  test    - Run tests"
	@echo "  check   - Check code syntax and style"
	@echo "  examples- Build example programs"
	@echo "  clean   - Clean build artifacts"
	@echo "  help    - Show this help message"

# Build the regex library
lib:
	@echo "Building regex library..."
	odin build src/ -no-bounds-check -build-mode:static -out:libregexp

# Run tests
test:
	@echo "Running tests..."
	@for test in tests/test_*.odin; do \
		if [ -f "$$test" ]; then \
			echo "Running $$test..."; \
			odin run "$$test" -no-bounds-check || exit 1; \
		fi \
	done

# Check code syntax and style
check:
	@echo "Checking library code..."
	odin check src/ -no-entry-point -ignore-warnings

# Build example programs
examples:
	@echo "Building examples..."
	@for example in examples/*.odin; do \
		if [ -f "$$example" ]; then \
			basename=$$(basename "$$example" .odin); \
			echo "Building $$basename..."; \
			odin build "$$example" -no-bounds-check -out:"$$basename"; \
		fi \
	done

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f *.a
	rm -f examples/*.exe
	rm -f tests/*.exe
	rm -f *.exe

# Install dependencies (placeholder for future use)
deps:
	@echo "No external dependencies required"