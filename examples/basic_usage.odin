package main

import "core:fmt"
import "core:time"
import "../src"

main :: proc() {
	fmt.println("=== Odin RE2 Basic Usage Examples ===")

	// Create memory arena for all regex operations
	arena := regexp.new_arena()

	// Example 1: Simple literal matching
	example_simple_literal(arena)

	// Example 2: Character class matching
	example_character_classes(arena)

	// Example 3: Unicode property matching
	example_unicode_properties(arena)

	// Example 4: Anchors and word boundaries
	example_anchors(arena)

	// Example 5: Performance benchmarking
	example_performance_benchmark(arena)

	fmt.println("\nAll examples completed!")
}

// Example 1: Simple literal matching
example_simple_literal :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- Example 1: Simple Literal Matching ---")

	// Parse pattern
	ast, err := regexp.parse_regexp_internal("hello\\s+world", {})
	if err != .NoError {
		fmt.printf("Parse error: %v\n", err)
		return
	}

	// Compile to NFA
	program, err := regexp.compile_nfa(ast, arena)
	if err != .NoError {
		fmt.printf("Compile error: %v\n", err)
		return
	}

	// Create matcher
	matcher := regexp.new_matcher(program, false, true)

	// Test texts
	test_texts := []string{
		"hello world",
		"hello   wonderful world",
		"hello\tworld",
		"goodbye world",
	}

	for text in test_texts {
		matched, caps := regexp.match_nfa(matcher, text)
		fmt.printf("'%s' -> %v", text, matched)
		if matched && len(caps) >= 2 {
			fmt.printf(" (match: '%s')", text[caps[0]:caps[1]])
		}
		fmt.println()
	}
}

// Example 2: Character class matching
example_character_classes :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- Example 2: Character Classes ---")

	patterns := map[string]string{
		"digits"        -> "\\d+",
		"letters"       -> "[a-zA-Z]+",
		"alphanumeric"  -> "[a-zA-Z0-9]+",
		"word"          -> "\\w+",
		"email_simple"  -> "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
	}

	test_text := "User123@example.com has 5 messages and 2 notifications"

	for name, pattern in patterns {
		// Parse and compile
		ast, err := regexp.parse_regexp_internal(pattern, {})
		if err != .NoError {
			fmt.printf("Parse error for %s: %v\n", name, err)
			continue
		}

		program, err := regexp.compile_nfa(ast, arena)
		if err != .NoError {
			fmt.printf("Compile error for %s: %v\n", name, err)
			continue
		}

		matcher := regexp.new_matcher(program, false, true)
		matched, caps := regexp.match_nfa(matcher, test_text)

		fmt.printf("%-15s: %v", name, matched)
		if matched && len(caps) >= 2 {
			fmt.printf(" -> '%s'", test_text[caps[0]:caps[1]])
		}
		fmt.println()
	}
}

// Example 3: Unicode property matching
example_unicode_properties :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- Example 3: Unicode Properties ---")

	// Test texts with different scripts
	test_texts := []string{
		"Hello World",
		"Bonjour le monde",
		"Привет мир",
		"Γειά σου κόσμε",
		"世界你好",
	}

	patterns := map[string]string{
		"latin_letters"   -> "\\p{Letter}+",
		"cyrillic"        -> "[\\u0400-\\u04FF]+",
		"greek"           -> "[\\u0370-\\u03FF]+",
		"chinese"         -> "[\\u4e00-\\u9fff]+",
	}

	for text in test_texts {
		fmt.printf("Text: '%s'\n", text)

		for name, pattern in patterns {
			ast, err := regexp.parse_regexp_internal(pattern, {})
			if err != .NoError {
				continue
			}

			program, err := regexp.compile_nfa(ast, arena)
			if err != .NoError {
				continue
			}

			matcher := regexp.new_matcher(program, false, true)
			matched, caps := regexp.match_nfa(matcher, text)

			if matched && len(caps) >= 2 {
				fmt.printf("  %s: '%s'\n", name, text[caps[0]:caps[1]])
			}
		}
		fmt.println()
	}
}

// Example 4: Anchors and word boundaries
example_anchors :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- Example 4: Anchors and Word Boundaries ---")

	patterns := map[string]string{
		"start_anchor"    -> "^Hello",
		"end_anchor"      -> "world$",
		"word_boundary"   -> "\\bword\\b",
		"not_word"        -> "\\Bword\\B",
		"both_anchors"    -> "^Hello.*world$",
	}

	test_texts := []string{
		"Hello world",
		"Hello wonderful world!",
		"Say Hello to the world",
		"Thewordisbound",
		"Hello world and more",
	}

	for text in test_texts {
		fmt.printf("'%s'\n", text)

		for name, pattern in patterns {
			ast, err := regexp.parse_regexp_internal(pattern, {})
			if err != .NoError {
				continue
			}

			program, err := regexp.compile_nfa(ast, arena)
			if err != .NoError {
				continue
			}

			matcher := regexp.new_matcher(program, false, true)
			matched, _ := regexp.match_nfa(matcher, text)

			fmt.printf("  %-15s: %v\n", name, matched)
		}
		fmt.println()
	}
}

// Example 5: Performance benchmarking
example_performance_benchmark :: proc(arena: ^regexp.Arena) {
	fmt.println("\n--- Example 5: Performance Benchmark ---")

	// Test pattern
	pattern := "[a-zA-Z0-9]+"
	test_text := "The quick brown fox jumps over 123 lazy dogs 456 times"

	// Compile pattern
	ast, err := regexp.parse_regexp_internal(pattern, {})
	if err != .NoError {
		fmt.printf("Parse error: %v\n", err)
		return
	}

	program, err := regexp.compile_nfa(ast, arena)
	if err != .NoError {
		fmt.printf("Compile error: %v\n", err)
		return
	}

	matcher := regexp.new_matcher(program, false, true)

	// Benchmark parameters
	iterations := 100000

	// Warm up
	for i in 0..<1000 {
		regexp.match_nfa(matcher, test_text)
	}

	// Actual benchmark
	start := time.now()
	match_count := 0

	for i in 0..<iterations {
		matched, _ := regexp.match_nfa(matcher, test_text)
		if matched {
			match_count += 1
		}
	}

	elapsed := time.since(start)

	// Calculate metrics
	avg_time_ns := f64(elapsed) / f64(iterations)
	matches_per_second := f64(iterations) / (f64(elapsed) / 1_000_000_000)
	text_len := len(test_text)
	throughput_mbps := (f64(text_len) * f64(match_count)) / (f64(elapsed) / 1_000_000_000) / (1024 * 1024)

	fmt.printf("Pattern: '%s'\n", pattern)
	fmt.printf("Text: '%s'\n", test_text)
	fmt.printf("Text length: %d bytes\n", text_len)
	fmt.printf("Iterations: %d\n", iterations)
	fmt.printf("Matched: %d/%d (%.1f%%)\n", match_count, iterations,
		f64(match_count) / f64(iterations) * 100)
	fmt.printf("Average time: %.2f ns/op\n", avg_time_ns)
	fmt.printf("Matches/sec: %.0f\n", matches_per_second)
	fmt.printf("Throughput: %.2f MB/s\n", throughput_mbps)
}