package main

import "core:fmt"

main :: proc() {
	str := "hello"
	fmt.println("String:", str)
	fmt.println("Length:", len(str))
	
	for i, ch in str {
		r := rune(ch)
		fmt.printf("  %d: ch='%c' (%d), rune=%d\n", i, ch, ch, r)
	}
}