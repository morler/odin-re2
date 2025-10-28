package main

import "core:fmt"
import "core:time"
import "core:strings"

main :: proc() {
	fmt.println("🔧 测试不同的导入方法")
	fmt.println(strings.repeat("=", 40))
	
	// 测试方法1: 使用collection参数
	fmt.println("\n方法1: 使用collection参数")
	fmt.println("命令: odin run test.odin -collection:regexp=src -file")
	
	// 测试方法2: 尝试相对导入
	fmt.println("\n方法2: 尝试相对导入")
	
	test_relative_import()
	
	// 测试方法3: 创建符号链接或复制文件
	fmt.println("\n方法3: 创建本地regexp包")
	
	fmt.println("\n推荐解决方案:")
	fmt.println("1. 将src/regexp.odin复制到tests/regexp.odin")
	fmt.println("2. 或者创建符号链接")
	fmt.println("3. 或者使用正确的collection参数")
}

test_relative_import :: proc() {
	fmt.println("尝试相对导入方法...")
	
	// 这个方法在Odin中可能不工作，但让我们试试
	// import "../src/regexp" // 注释掉因为会失败
	
	fmt.println("相对导入在Odin中需要特殊处理")
}