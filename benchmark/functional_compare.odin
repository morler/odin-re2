package main

import "core:fmt"
import "core:os"
import os2 "core:os/os2"
import "core:strings"
import "core:time"
import "."

// Test case definition shared with Rust runner through data file
TestCase :: struct {
	name:               string,
	pattern:            string,
	text:               string,
	should_compile:     bool,
	should_match:       bool,
	verify_full_match:  bool,
	expected_match:     string,
	description:        string,
}

CaseResult :: struct {
	test_case:         TestCase,
	compile_ok:        bool,
	actual_match:      bool,
	match_verified:    bool,
	compile_ns:        i64,
	match_ns:          i64,
	status:            string,
	notes:             string,
}

Args :: struct {
	cases_path:   string,
	output_path:  string,
	verbose:      bool,
}

default_cases_path :: "benchmark/data/functionality_cases.txt"
default_output_path :: "benchmark/results/functional_odin.tsv"

main :: proc() {
	args := parse_args()

	content, ok := read_file_as_string(args.cases_path)
	if !ok {
		fmt.printf("Failed to read test cases from %s\n", args.cases_path)
		os.exit(1)
	}

	test_cases, parse_err := parse_test_cases(content)
	if parse_err != "" {
		fmt.printf("Error parsing test cases: %s\n", parse_err)
		os.exit(1)
	}

	if len(test_cases) == 0 {
		fmt.println("No test cases found; aborting.")
		os.exit(1)
	}

	results := run_cases(test_cases, args.verbose)
	write_err := write_results(args.output_path, results)
	if write_err != "" {
		fmt.printf("Failed to write results: %s\n", write_err)
		os.exit(1)
	}

	passed := 0
	for res in results {
		if res.status == "PASS" {
			passed += 1
		}
	}

	fmt.println("=== Odin Regex Functionality Comparison ===")
	fmt.printf("Cases: %d, Passed: %d, Failed: %d\n", len(results), passed, len(results) - passed)
	fmt.printf("Results saved to %s\n", args.output_path)
}

parse_args :: proc() -> Args {
	args := Args{
		cases_path = default_cases_path,
		output_path = default_output_path,
		verbose = false,
	}

	os_args := os.args[1:]
	i := 0
	for i < len(os_args) {
		arg := os_args[i]
		switch arg {
		case "-cases":
			if i + 1 >= len(os_args) {
				fmt.println("Missing value for -cases")
				os.exit(1)
			}
			args.cases_path = os_args[i + 1]
			i += 2
		case "-output":
			if i + 1 >= len(os_args) {
				fmt.println("Missing value for -output")
				os.exit(1)
			}
			args.output_path = os_args[i + 1]
			i += 2
		case "-v", "--verbose":
			args.verbose = true
			i += 1
		case:
			fmt.printf("Unknown argument: %s\n", arg)
			os.exit(1)
		}
	}

	return args
}

read_file_as_string :: proc(path: string) -> (string, bool) {
	data, ok := os.read_entire_file(path)
	if !ok {
		return "", false
	}
	return string(data), true
}

parse_test_cases :: proc(content: string) -> ([]TestCase, string) {
	cases := make([dynamic]TestCase, 0, 32)
	current := make_default_case()
	have_data := false

	index := 0
	for index <= len(content) {
		line, next_index := read_line(content, index)
		index = next_index

		trimmed := trim_space(line)
		if len(trimmed) == 0 {
			continue
		}

		if trimmed == "---" {
			if have_data {
				append(&cases, current)
				current = make_default_case()
				have_data = false
			}
			continue
		}

		key, value, ok := split_key_value(line)
		if !ok {
			err_msg := fmt.tprintf("invalid line: %s", line)
			empty := cases[0:0]
			return empty, err_msg
		}

		key = trim_space(key)
		value = trim_space(value)

		if key == "name" {
			current.name = unescape(value)
			have_data = true
		} else if key == "pattern" {
			current.pattern = unescape(value)
		} else if key == "text" {
			current.text = unescape(value)
		} else if key == "should_compile" {
			current.should_compile = parse_bool(value, true)
		} else if key == "should_match" {
			current.should_match = parse_bool(value, false)
		} else if key == "verify_full_match" {
			current.verify_full_match = parse_bool(value, false)
		} else if key == "expected" {
			current.expected_match = unescape(value)
		} else if key == "description" {
			current.description = unescape(value)
		} else {
			err_unknown := fmt.tprintf("unknown key: %s", key)
			empty := cases[0:0]
			return empty, err_unknown
		}
	}

	if have_data {
		append(&cases, current)
	}

	return cases[:], ""
}

make_default_case :: proc() -> TestCase {
	return TestCase{
		name = "",
		pattern = "",
		text = "",
		should_compile = true,
		should_match = false,
		verify_full_match = false,
		expected_match = "",
		description = "",
	}
}

run_cases :: proc(cases: []TestCase, verbose: bool) -> []CaseResult {
	results := make([dynamic]CaseResult, 0, len(cases))

	for tc in cases {
		res := CaseResult{
			test_case = tc,
			compile_ok = false,
			actual_match = false,
			match_verified = false,
			compile_ns = 0,
			match_ns = 0,
			status = "FAIL",
			notes = "",
		}

		start_compile := time.now()
		pattern, compile_err := regexp.regexp(tc.pattern)
		end_compile := time.now()
		compile_duration := time.diff(end_compile, start_compile)
		res.compile_ns = time.duration_nanoseconds(compile_duration)
		if res.compile_ns < 0 {
			res.compile_ns = -res.compile_ns
		}

		if compile_err != .NoError {
			res.compile_ok = false
			res.notes = fmt.tprintf("compile_error:%v", compile_err)

			if !tc.should_compile {
				res.status = "PASS"
			} else {
				res.status = "FAIL"
			}
		} else {
			res.compile_ok = true

			if !tc.should_compile {
				res.status = "FAIL"
				res.notes = "expected compile failure but succeeded"
				regexp.free_regexp(pattern)
				append(&results, res)
				continue
			}

			start_match := time.now()
			match_result, match_err := regexp.match(pattern, tc.text)
			end_match := time.now()
			match_duration := time.diff(end_match, start_match)
			res.match_ns = time.duration_nanoseconds(match_duration)
			if res.match_ns < 0 {
				res.match_ns = -res.match_ns
			}

			if match_err != .NoError {
				res.status = "FAIL"
				res.notes = fmt.tprintf("match_error:%v", match_err)
				regexp.free_regexp(pattern)
				append(&results, res)
				continue
			}

			res.actual_match = match_result.matched
			if match_result.matched && tc.verify_full_match {
				substring := extract_substring(tc.text, match_result.full_match)
				if substring == tc.expected_match {
					res.match_verified = true
				} else {
					res.match_verified = false
					res.notes = fmt.tprintf("expected_full_match:%s, got:%s", tc.expected_match, substring)
				}
			} else if !match_result.matched && tc.verify_full_match && len(tc.expected_match) == 0 {
				// Empty match expectation
				res.match_verified = true
			}

			expected_match := tc.should_match
			actual_match := match_result.matched

			if expected_match == actual_match {
				if tc.verify_full_match {
					if res.match_verified {
						res.status = "PASS"
					} else {
						res.status = "FAIL"
						if res.notes == "" {
							res.notes = "full match verification failed"
						}
					}
				} else {
					res.status = "PASS"
				}
			} else {
				res.status = "FAIL"
				if actual_match {
					res.notes = "unexpected match"
				} else {
					res.notes = "missing expected match"
				}
			}

			regexp.free_regexp(pattern)
		}

		if verbose {
			fmt.printf("[%-5s] %s :: %s\n", res.status, tc.name, res.notes)
		}

		append(&results, res)
	}

	return results[:]
}

write_results :: proc(path: string, results: []CaseResult) -> string {
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

	header := "name\tshould_compile\tcompile_ok\tshould_match\tactual_match\tverify_full_match\tmatch_verified\tcompile_ns\tmatch_ns\tstatus\tnotes\n"
	_, write_err := os.write_string(file, header)
	if write_err != nil {
		return fmt.tprintf("failed to write header: %v", write_err)
	}

	for res in results {
		line := fmt.tprintf(
			"%s\t%t\t%t\t%t\t%t\t%t\t%t\t%d\t%d\t%s\t%s\n",
			res.test_case.name,
			res.test_case.should_compile,
			res.compile_ok,
			res.test_case.should_match,
			res.actual_match,
			res.test_case.verify_full_match,
			res.match_verified,
			res.compile_ns,
			res.match_ns,
			res.status,
			sanitize_notes(res.notes),
		)
		_, line_err := os.write_string(file, line)
		if line_err != nil {
			return fmt.tprintf("failed to write line for %s: %v", res.test_case.name, line_err)
		}
	}

	return ""
}

sanitize_notes :: proc(notes: string) -> string {
	if len(notes) == 0 {
		return ""
	}
	builder := strings.Builder{}
	for c in notes {
		if c == '\t' || c == '\n' || c == '\r' {
			strings.write_byte(&builder, ' ')
		} else {
			strings.write_byte(&builder, u8(c))
		}
	}
	return strings.to_string(builder)
}

extract_substring :: proc(text: string, range: regexp.Range) -> string {
	if range.start < 0 || range.end > len(text) || range.start >= range.end {
		return ""
	}
	return text[range.start:range.end]
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
