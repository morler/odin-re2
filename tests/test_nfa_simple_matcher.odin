package main

import "core:fmt"
import "regexp"

// 简化的NFA匹配器实现
simple_nfa_match :: proc(prog: ^regexp.Prog, text: string) -> (bool, []int) {
	if prog == nil || len(prog.inst) == 0 {
		return false, nil
	}
	
	fmt.println("Simple NFA match on:", text)
	fmt.println("Program start PC:", prog.start)
	
	// 尝试从每个位置开始匹配
	for start_pos := 0; start_pos <= len(text); start_pos += 1 {
		fmt.printf("\nTrying start position %d:\n", start_pos)
		
		// 从起始位置开始执行
		matched, end_pos := execute_from_position(prog, prog.start, text, start_pos)
		if matched {
			caps := make([]int, 2)
			caps[0] = start_pos
			caps[1] = end_pos
			fmt.println("Match found! Position:", start_pos, "to", end_pos)
			return true, caps
		}
	}
	
	fmt.println("No match found")
	return false, nil
}

// 从指定位置执行NFA
execute_from_position :: proc(prog: ^regexp.Prog, pc: u32, text: string, pos: int) -> (bool, int) {
	if pc >= u32(len(prog.inst)) {
		return false, pos
	}
	
	inst := prog.inst[pc]
	fmt.printf("  Executing PC %d: %v at pos %d\n", pc, inst.op, pos)
	
	#partial switch inst.op {
	case .Rune1:
		if pos < len(text) && rune(text[pos]) == rune(inst.arg) {
			fmt.printf("    Rune matched '%c'\n", rune(text[pos]))
			return execute_from_position(prog, inst.out, text, pos + 1)
		} else {
			fmt.println("    Rune did not match")
			return false, pos
		}
		
	case .Match:
		fmt.println("    Reached match instruction")
		return true, pos
		
	case .Alt:
		// 尝试第一个分支
		fmt.println("    Trying first branch of Alt")
		matched1, end1 := execute_from_position(prog, inst.out, text, pos)
		if matched1 {
			return true, end1
		}
		
		// 尝试第二个分支
		fmt.println("    Trying second branch of Alt")
		matched2, end2 := execute_from_position(prog, inst.arg, text, pos)
		if matched2 {
			return true, end2
		}
		
		return false, pos
		
	case .Jmp:
		// 无条件跳转
		fmt.println("    Unconditional jump")
		return execute_from_position(prog, inst.out, text, pos)
	}
	
	fmt.println("    Unsupported instruction")
	return false, pos
}

test_pattern :: proc(pattern_str: string, test_cases: []string) {
	fmt.printf("\n======== Testing pattern: '%s' ========\n", pattern_str)
	
	pattern, err := regexp.regexp(pattern_str)
	if err != .NoError {
		fmt.println("Failed to compile pattern:", err)
		return
	}
	defer regexp.free_regexp(pattern)
	
	ast := pattern.ast
	if ast != nil {
		prog, compile_err := regexp.compile_nfa(ast)
		if compile_err != .NoError {
			fmt.println("Failed to compile NFA:", compile_err)
			return
		}
		defer regexp.free_prog(prog)
		
		// 打印指令
		fmt.println("\nProgram instructions:")
		for i in 0..<len(prog.inst) {
			inst := prog.inst[i]
			fmt.printf("  %d: %v, out=%d, arg=%d\n", i, inst.op, inst.out, inst.arg)
		}
		
		// 测试匹配
		for test in test_cases {
			fmt.printf("\n=== Testing '%s' ===\n", test)
			matched, caps := simple_nfa_match(prog, test)
			fmt.println("Result:", matched)
			if matched && len(caps) >= 2 {
				fmt.printf("Match: [%d, %d]\n", caps[0], caps[1])
			}
		}
	}
}

main :: proc() {
	fmt.println("Testing simplified NFA matcher...")
	
	// 测试单字符
	test_pattern("a", []string{"a", "b", "ab", "ba", ""})
	
	// 测试字符类
	test_pattern("[ab]", []string{"a", "b", "c", "ab", "ba", ""})
	
	// 测试交替
	test_pattern("a|b", []string{"a", "b", "c", "ab", "ba", ""})
	
	// 测试连接
	test_pattern("ab", []string{"ab", "a", "b", "abc", "ba", ""})
}