package main

import "core:fmt"
import "regexp"

main :: proc() {
	// Test User Story 1 functionality
	pattern, err := regexp.regexp("hello")
	if err != .NoError {
		fmt.printf("Error compiling pattern: %v\n", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	result, match_err := regexp.match(pattern, "hello world")
	if match_err != .NoError {
		fmt.printf("Error matching: %v\n", match_err)
		return
	}
	
	fmt.printf("Pattern: 'hello'\n")
	fmt.printf("Text: 'hello world'\n")
	fmt.printf("Matched: %v\n", result.matched)
	fmt.printf("Pattern AST: %v\n", pattern.ast)
	if pattern.ast != nil {
		fmt.printf("Pattern op: %v\n", pattern.ast.op)
		if pattern.ast.data != nil && pattern.ast.op == .OpConcat {
			concat_data := (^regexp.Concat_Data)(pattern.ast.data)
			fmt.printf("Concat subs count: %d\n", len(concat_data.subs))
			for i := 0; i < len(concat_data.subs); i += 1 {
				sub := concat_data.subs[i]
				if sub != nil {
					fmt.printf("  Sub %d: op=%v\n", i, sub.op)
					if sub.op == .OpConcat && sub.data != nil {
						sub_concat := (^regexp.Concat_Data)(sub.data)
						fmt.printf("    Sub-concat subs count: %d\n", len(sub_concat.subs))
						for j := 0; j < len(sub_concat.subs); j += 1 {
							sub_sub := sub_concat.subs[j]
							if sub_sub != nil {
								fmt.printf("      Sub-sub %d: op=%v\n", j, sub_sub.op)
								if sub_sub.op == .OpLiteral && sub_sub.data != nil {
									lit_data := (^regexp.Literal_Data)(sub_sub.data)
									lit_str := regexp.to_string(lit_data.str)
									fmt.printf("        Literal: '%s'\n", lit_str)
								}
							}
						}
					} else if sub.op == .OpLiteral && sub.data != nil {
						lit_data := (^regexp.Literal_Data)(sub.data)
						lit_str := regexp.to_string(lit_data.str)
						fmt.printf("    Literal: '%s'\n", lit_str)
					}
				}
			}
		}
	}
	if result.matched {
		fmt.printf("Capture: [%d, %d]\n", result.captures[0], result.captures[1])
	}
}