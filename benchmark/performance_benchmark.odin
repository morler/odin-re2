package main

import "core:fmt"
import "core:os"
import os2 "core:os/os2"
import "core:strings"
import "core:time"
import "core:strconv"
import "../regexp"

PerformanceScenario :: struct {
	name:            string,
	pattern:         string,
	text_strategy:   string,
	text_base:       string,
	text_size:       int,
	iterations:      int,
	should_match:    bool,
	insert_interval: int,
	anchor_prefix:   string,
	anchor_suffix:   string,
	description:     string,
}

PerformanceResult :: struct {
	scenario:         PerformanceScenario,
	compile_ns:       i64,
	match_total_ns:   i64,
	match_avg_ns:     i64,
	throughput_mb_s:  f64,
	matched:          bool,
	status:           string,
	notes:            string,
}

Args :: struct {
	scenarios_path: string,
	output_path:    string,
	verbose:        bool,
}

default_scenarios_path :: "benchmark/data/performance_scenarios.txt"
default_output_path :: "benchmark/results/performance_odin.tsv"

main :: proc() {
	args := parse_args()

	content, ok := read_file_as_string(args.scenarios_path)
	if !ok {
		fmt.printf("Failed to read performance scenarios from %s\n", args.scenarios_path)
		os.exit(1)
	}

	scenarios, parse_err := parse_scenarios(content)
	if parse_err != "" {
		fmt.printf("Error parsing scenarios: %s\n", parse_err)
		os.exit(1)
	}

	if len(scenarios) == 0 {
		fmt.println("No scenarios defined; nothing to run.")
		os.exit(1)
	}

	results := run_scenarios(scenarios, args.verbose)
	write_err := write_results(args.output_path, results)
	if write_err != "" {
		fmt.printf("Failed to write performance results: %s\n", write_err)
		os.exit(1)
	}

	pass_count := 0
	for res in results {
		if res.status == "PASS" {
			pass_count += 1
		}
	}

	fmt.println("=== Odin Regex Performance Comparison ===")
	fmt.printf("Scenarios: %d, Passed: %d, Failed: %d\n", len(results), pass_count, len(results) - pass_count)
	fmt.printf("Results saved to %s\n", args.output_path)
}

parse_args :: proc() -> Args {
	result := Args{
		scenarios_path = default_scenarios_path,
		output_path = default_output_path,
		verbose = false,
	}

	os_args := os.args[1:]
	i := 0
	for i < len(os_args) {
		arg := os_args[i]
		switch arg {
		case "-scenarios":
			if i + 1 >= len(os_args) {
				fmt.println("Missing value for -scenarios")
				os.exit(1)
			}
			result.scenarios_path = os_args[i + 1]
			i += 2
		case "-output":
			if i + 1 >= len(os_args) {
				fmt.println("Missing value for -output")
				os.exit(1)
			}
			result.output_path = os_args[i + 1]
			i += 2
		case "-v", "--verbose":
			result.verbose = true
			i += 1
		case:
			fmt.printf("Unknown argument: %s\n", arg)
			os.exit(1)
		}
	}

	return result
}

read_file_as_string :: proc(path: string) -> (string, bool) {
	data, ok := os.read_entire_file(path)
	if !ok {
		return "", false
	}
	return string(data), true
}

parse_scenarios :: proc(content: string) -> ([]PerformanceScenario, string) {
	scenarios := make([dynamic]PerformanceScenario, 0, 16)
	current := default_scenario()
	has_data := false

	index := 0
	for index <= len(content) {
		line, next_index := read_line(content, index)
		index = next_index

		trimmed := trim_space(line)
		if len(trimmed) == 0 {
			continue
		}

		if trimmed == "---" {
			if has_data {
				append(&scenarios, current)
				current = default_scenario()
				has_data = false
			}
			continue
		}

		key, value, ok := split_key_value(line)
		if !ok {
			err_msg := fmt.tprintf("invalid line: %s", line)
			return scenarios[:0], err_msg
		}

		key = trim_space(key)
		value = trim_space(value)

		switch key {
		case "name":
			current.name = unescape(value)
			has_data = true
		case "pattern":
			current.pattern = unescape(value)
		case "text_strategy":
			current.text_strategy = unescape(value)
		case "text_base":
			current.text_base = unescape(value)
		case "text_size":
			size, ok := parse_int(value)
			if !ok {
				err := fmt.tprintf("invalid text_size for scenario %s", current.name)
				return scenarios[:0], err
			}
			current.text_size = size
		case "iterations":
			iters, ok := parse_int(value)
			if !ok {
				err := fmt.tprintf("invalid iterations for scenario %s", current.name)
				return scenarios[:0], err
			}
			current.iterations = iters
		case "should_match":
			current.should_match = parse_bool(value, true)
		case "insert_interval":
			interval, ok := parse_int(value)
			if !ok {
				err := fmt.tprintf("invalid insert_interval for scenario %s", current.name)
				return scenarios[:0], err
			}
			current.insert_interval = interval
		case "anchor_prefix":
			current.anchor_prefix = unescape(value)
		case "anchor_suffix":
			current.anchor_suffix = unescape(value)
		case "description":
			current.description = unescape(value)
		case:
			return scenarios[:0], fmt.tprintf("unknown key: %s", key)
		}
	}

	if has_data {
		append(&scenarios, current)
	}

	return scenarios[:], ""
}

default_scenario :: proc() -> PerformanceScenario {
	return PerformanceScenario{
		name = "",
		pattern = "",
		text_strategy = "repeat",
		text_base = "",
		text_size = 0,
		iterations = 1,
		should_match = true,
		insert_interval = 512,
		anchor_prefix = "",
		anchor_suffix = "",
		description = "",
	}
}

run_scenarios :: proc(scenarios: []PerformanceScenario, verbose: bool) -> []PerformanceResult {
	results := make([dynamic]PerformanceResult, 0, len(scenarios))

	for scenario in scenarios {
		res := PerformanceResult{
			scenario = scenario,
			compile_ns = 0,
			match_total_ns = 0,
			match_avg_ns = 0,
			throughput_mb_s = 0.0,
			matched = false,
			status = "FAIL",
			notes = "",
		}

		if scenario.text_size <= 0 {
			res.notes = "text_size must be > 0"
			append(&results, res)
			continue
		}

		if scenario.iterations <= 0 {
			res.notes = "iterations must be > 0"
			append(&results, res)
			continue
		}

		text, text_err := generate_text(scenario)
		if text_err != "" {
			res.notes = text_err
			append(&results, res)
			continue
		}

		start_compile := time.now()
		pattern, compile_err := regexp.regexp(scenario.pattern)
		end_compile := time.now()
		compile_duration := time.diff(end_compile, start_compile)
		res.compile_ns = time.duration_nanoseconds(compile_duration)
		if res.compile_ns < 0 {
			res.compile_ns = -res.compile_ns
		}

		if compile_err != .NoError {
			res.notes = fmt.tprintf("compile_error:%v", compile_err)
			append(&results, res)
			continue
		}

		match_total_ns: i64 = 0
		match_fail := false
		matched_any := false

		for iter := 0; iter < scenario.iterations; iter += 1 {
			start_match := time.now()
			match_result, match_err := regexp.match(pattern, text)
			end_match := time.now()

			match_duration := time.diff(end_match, start_match)
			duration_ns := time.duration_nanoseconds(match_duration)
			if duration_ns < 0 {
				duration_ns = -duration_ns
			}
			match_total_ns += duration_ns

			if match_err != .NoError {
				res.notes = fmt.tprintf("match_error:%v", match_err)
				match_fail = true
				break
			}

			if match_result.matched {
				matched_any = true
			}
		}

		regexp.free_regexp(pattern)

		if match_fail {
			append(&results, res)
			continue
		}

		res.match_total_ns = match_total_ns
		if scenario.iterations > 0 {
			res.match_avg_ns = match_total_ns / i64(scenario.iterations)
		}

		total_bytes := i64(scenario.text_size) * i64(scenario.iterations)
		if match_total_ns > 0 {
			seconds := f64(match_total_ns) / 1_000_000_000.0
			res.throughput_mb_s = (f64(total_bytes) / 1_048_576.0) / seconds
		}

		res.matched = matched_any

		if scenario.should_match {
			if matched_any {
				res.status = "PASS"
			} else {
				res.status = "FAIL"
				res.notes = "expected match missing"
			}
		} else {
			if matched_any {
				res.status = "FAIL"
				res.notes = "unexpected match"
			} else {
				res.status = "PASS"
			}
		}

		if verbose {
			fmt.printf("[%-5s] %s :: compile=%dns match_avg=%dns throughput=%.2f MB/s %s\n",
				res.status,
				scenario.name,
				res.compile_ns,
				res.match_avg_ns,
				res.throughput_mb_s,
				res.notes,
			)
		}

		append(&results, res)
	}

	return results[:]
}

generate_text :: proc(scenario: PerformanceScenario) -> (string, string) {
	strategy := scenario.text_strategy
	if strategy == "" {
		strategy = "repeat"
	}
	strategy = lower_ascii(strategy)

	switch strategy {
	case "repeat":
		return generate_repeat_text(scenario.text_base, scenario.text_size)
	case "inject":
		return generate_inject_text(scenario.text_base, scenario.text_size, scenario.pattern, scenario.insert_interval)
	case "anchor":
		return generate_anchor_text(scenario)
	case:
		return "", fmt.tprintf("unknown text_strategy: %s", strategy)
	}
}

generate_repeat_text :: proc(base: string, size: int) -> (string, string) {
	if len(base) == 0 {
		return "", "text_base cannot be empty for repeat strategy"
	}

	builder := strings.Builder{}
	current := 0

	for current < size {
		remaining := size - current
		chunk := base
		if remaining < len(base) {
			chunk = base[:remaining]
		}
		strings.write_string(&builder, chunk)
		current += len(chunk)
	}

	text := strings.to_string(builder)
	if len(text) > size {
		text = text[:size]
	}
	return text, ""
}

generate_inject_text :: proc(base: string, size: int, pattern: string, interval: int) -> (string, string) {
	text, err := generate_repeat_text(base, size)
	if err != "" {
		return "", err
	}

	interval_value := interval
	if interval_value <= 0 {
		interval_value = 256
	}

	builder := strings.Builder{}
	position := 0

	for position < len(text) {
		next := position + interval_value
		if next > len(text) {
			next = len(text)
		}
		segment := text[position:next]
		strings.write_string(&builder, segment)
		position = next

		if position < len(text) {
			strings.write_string(&builder, pattern)
		}
	}

	result := strings.to_string(builder)
	if len(result) > size {
		result = result[:size]
	}
	return result, ""
}

generate_anchor_text :: proc(scenario: PerformanceScenario) -> (string, string) {
	if len(scenario.anchor_prefix) == 0 || len(scenario.anchor_suffix) == 0 {
		return "", "anchor strategy requires anchor_prefix and anchor_suffix"
	}
	if scenario.text_size < len(scenario.anchor_prefix)+len(scenario.anchor_suffix) {
		return "", "text_size too small for anchor strategy"
	}

	filler_size := scenario.text_size - len(scenario.anchor_prefix) - len(scenario.anchor_suffix)
	filler, err := generate_repeat_text(scenario.text_base, filler_size)
	if err != "" {
		return "", err
	}

	builder := strings.Builder{}
	strings.write_string(&builder, scenario.anchor_prefix)
	strings.write_string(&builder, filler)
	strings.write_string(&builder, scenario.anchor_suffix)
	text := strings.to_string(builder)
	return text, ""
}

write_results :: proc(path: string, results: []PerformanceResult) -> string {
	dir := parent_directory(path)
	if len(dir) != 0 {
		dir_err := os2.make_directory_all(dir, 0o755)
		if dir_err != nil {
			return fmt.tprintf("failed to create directory %s: %v", dir, dir_err)
		}
	}

	file, open_err := os.open(path, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o666)
	if open_err != nil {
		return fmt.tprintf("failed to open output file: %s", path)
	}
	defer os.close(file)

	header := "name\tpattern\ttext_size\titerations\tcompile_ns\tmatch_total_ns\tmatch_avg_ns\tthroughput_mb_s\tmatched\tstatus\tnotes\n"
	_, write_err := os.write_string(file, header)
	if write_err != nil {
		return fmt.tprintf("failed to write header: %v", write_err)
	}

	for res in results {
		line := fmt.tprintf(
			"%s\t%s\t%d\t%d\t%d\t%d\t%d\t%.4f\t%t\t%s\t%s\n",
			res.scenario.name,
			res.scenario.pattern,
			res.scenario.text_size,
			res.scenario.iterations,
			res.compile_ns,
			res.match_total_ns,
			res.match_avg_ns,
			res.throughput_mb_s,
			res.matched,
			res.status,
			sanitize_notes(res.notes),
		)
		_, line_err := os.write_string(file, line)
		if line_err != nil {
			return fmt.tprintf("failed to write line for %s: %v", res.scenario.name, line_err)
		}
	}

	return ""
}

sanitize_notes :: proc(notes: string) -> string {
	if len(notes) == 0 {
		return ""
	}
	builder := strings.Builder{}
	for r in notes {
		if r == '\t' || r == '\n' || r == '\r' {
			strings.write_byte(&builder, ' ')
		} else {
			strings.write_byte(&builder, u8(r))
		}
	}
	return strings.to_string(builder)
}

parse_bool :: proc(value: string, default_value: bool) -> bool {
	if len(value) == 0 {
		return default_value
	}

	if value == "true" || value == "TRUE" || value == "True" ||
	   value == "1" || value == "yes" || value == "YES" || value == "Yes" {
		return true
	}

	if value == "false" || value == "FALSE" || value == "False" ||
	   value == "0" || value == "no" || value == "NO" || value == "No" {
		return false
	}

	return default_value
}

parse_int :: proc(value: string) -> (int, bool) {
	result, ok := strconv.parse_int(value)
	return result, ok
}

split_key_value :: proc(line: string) -> (string, string, bool) {
	for i := 0; i < len(line); i += 1 {
		if line[i] == '=' {
			return line[:i], line[i+1:], true
		}
	}
	return "", "", false
}

trim_space :: proc(value: string) -> string {
	start := 0
	end := len(value) - 1

	for start < len(value) && is_space(value[start]) {
		start += 1
	}

	for end >= start && is_space(value[end]) {
		end -= 1
	}

	if end < start {
		return ""
	}

	return value[start:end+1]
}

is_space :: proc(b: byte) -> bool {
	return b == ' ' || b == '\t' || b == '\r' || b == '\n'
}

read_line :: proc(content: string, index: int) -> (string, int) {
	if index >= len(content) {
		return "", len(content) + 1
	}

	start := index
	i := index
	for i < len(content) {
		ch := content[i]
		if ch == '\n' || ch == '\r' {
			break
		}
		i += 1
	}

	line := content[start:i]

	if i < len(content) {
		if content[i] == '\r' {
			i += 1
		}
		if i < len(content) && content[i] == '\n' {
			i += 1
		}
	}

	return line, i
}

unescape :: proc(value: string) -> string {
	builder := strings.Builder{}
	i := 0
	for i < len(value) {
		ch := value[i]
		if ch == '\\' && i + 1 < len(value) {
			next := value[i + 1]
			switch next {
			case 'n':
				strings.write_byte(&builder, '\n')
			case 't':
				strings.write_byte(&builder, '\t')
			case 'r':
				strings.write_byte(&builder, '\r')
			case '\\':
				strings.write_byte(&builder, '\\')
			case:
				strings.write_byte(&builder, next)
			}
			i += 2
		} else {
			strings.write_byte(&builder, ch)
			i += 1
		}
	}
	return strings.to_string(builder)
}

lower_ascii :: proc(value: string) -> string {
	if len(value) == 0 {
		return value
	}
	builder := strings.Builder{}
	for r in value {
		if r >= 'A' && r <= 'Z' {
			strings.write_byte(&builder, u8(r - 'A' + 'a'))
		} else {
			strings.write_rune(&builder, r)
		}
	}
	return strings.to_string(builder)
}

parent_directory :: proc(path: string) -> string {
	last := -1
	for i := 0; i < len(path); i += 1 {
		c := path[i]
		if c == '/' || c == '\\' {
			last = i
		}
	}
	if last < 0 {
		return ""
	}
	return path[:last]
}
